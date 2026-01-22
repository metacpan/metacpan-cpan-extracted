use v5.40;
use lib '../lib', 'lib';
use blib;
use Test2::Tools::Affix qw[:all];
use Affix               qw[:all];
$|++;
#
typedef Callback_t => Callback [ [Int] => Void ];
typedef ThreadTask => Struct [ cb   => Callback_t(), val  => Int ];
typedef TaskNode   => Struct [ task => ThreadTask(), next => Pointer [ ThreadTask() ] ];
typedef TaskQueue =>
    Struct [ head => Pointer [ TaskNode() ], tail => Pointer [ TaskNode() ], lock => Pointer [Void], cond => Pointer [Void], stop => Int ];
typedef ThreadPool => Struct [
    threads         => Pointer [Void],
    thread_count    => Int,
    task_queue      => TaskQueue(),
    pool_lock       => Pointer [Void],
    task_available  => Pointer [Void],
    active_threads  => Int,
    tasks_remaining => Int
];
my $c_source = <<~'C';
        #include "std.h"
        //ext: .c
        #if _WIN32
        #include <windows.h>
        #else
        #include <pthread.h>
        #include <unistd.h>
        #endif
        #include <stdlib.h>

        typedef void (*callback_t)(int);

        typedef struct {
            callback_t cb;
            int val;
        } ThreadArgs;

        #if _WIN32
        unsigned __stdcall
        #else
        void *
        #endif
        thread_func(void* arg) {
            ThreadArgs* args = (ThreadArgs*)arg;
            // Brief sleep to ensure we aren't just getting lucky on the main thread stack
            usleep(2000000);
            // Execute Perl callback from this foreign thread
            // This will SEGFAULT if Affix doesn't inject Perl context!
            args->cb(args->val);
            return 0;
        }

        void run_in_foreign_thread(callback_t cb, int val) {
        #if _WIN32
            ThreadArgs* args = (ThreadArgs*)malloc(sizeof(ThreadArgs));
            args->cb = cb;
            args->val = val;
            unsigned threadID;
            HANDLE hThread = (HANDLE)_beginthreadex(NULL, 0, &thread_func, args, 0, &threadID);
            // Block main thread to simulate WebUI/MainLoop behavior
            WaitForSingleObject(hThread, INFINITE);
            CloseHandle(hThread);
            free(args);
        #else
            pthread_t thread_id;
            ThreadArgs* args = (ThreadArgs*)malloc(sizeof(ThreadArgs));
            args->cb = cb;
            args->val = val;
            pthread_create(&thread_id, NULL, thread_func, args);
            // Block main thread to simulate WebUI/MainLoop behavior
            pthread_join(thread_id, NULL);
            free(args);
        #endif
        }
    C

# Pass reference (\$c_source) so Affix::Build treats it as code, not a filename
my $lib = compile_ok($c_source);
ok $lib && -e $lib, 'Compiled a threaded test library';
#
ok affix( $lib, 'run_in_foreign_thread', [ Callback_t(), Int ] => Void ), 'affix run_in_foreign_thread';
#
my $ok_flag = 0;
my $str;

# This calls C, which spawns a thread, which calls this sub
run_in_foreign_thread(
    sub ($val) {

        # Allocating memory here (creating SVs) tests the memory allocator context
        $str     = 'Received: ' . $val;
        $ok_flag = $val;
    },
    123
);
is $ok_flag, 123, 'Callback executed successfully from foreign thread without crashing';
diag $str;
#
done_testing();
