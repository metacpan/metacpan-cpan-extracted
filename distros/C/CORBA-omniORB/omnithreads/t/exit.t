use strict;
use warnings;

BEGIN {
    if ($ENV{'PERL_CORE'}){
        chdir 't';
        unshift @INC, '../lib';
    }
    use Config;
    if (! $Config{'useithreads'}) {
        print("1..0 # Skip: Perl not compiled with 'useithreads'\n");
        exit(0);
    }

    require($ENV{PERL_CORE} ? "./test.pl" : "./t/test.pl");
}

use ExtUtils::testlib;

use omnithreads;

BEGIN {
    eval {
        require omnithreads::shared;
        import omnithreads::shared;
    };
    if ($@ || ! $omnithreads::shared::threads_shared) {
        print("1..0 # Skip: omnithreads::shared not available\n");
        exit(0);
    }

    $| = 1;
    print("1..18\n");   ### Number of tests that will be run ###
};

ok(1, 'Loaded');

### Start of Testing ###

$SIG{'__WARN__'} = sub {
    my $msg = shift;
    ok(0, "WARN in main: $msg");
};
$SIG{'__DIE__'} = sub {
    my $msg = shift;
    ok(0, "DIE in main: $msg");
};


my $thr = omnithreads->create(sub {
    omnithreads->exit();
    return (99);  # Not seen
});
ok($thr, 'Created: omnithreads->exit()');
my $rc = $thr->join();
ok(! defined($rc), 'Exited: omnithreads->exit()');


run_perl(prog => 'use omnithreads;' .
                 'omnithreads->exit(86);' .
                 'exit(99);',
         nolib => ($ENV{PERL_CORE}) ? 0 : 1,
         switches => ($ENV{PERL_CORE}) ? [] : [ '-Mblib' ]);
is($?>>8, 86, 'thread->exit(status) in main');


$thr = omnithreads->create({'exit' => 'thread_only'}, sub {
                                                    exit(1);
                                                    return (99);  # Not seen
                                                  });
ok($thr, 'Created: thread_only');
$rc = $thr->join();
ok(! defined($rc), 'Exited: thread_only');


$thr = omnithreads->create(sub {
    omnithreads->set_thread_exit_only(1);
    exit(1);
    return (99);  # Not seen
});
ok($thr, 'Created: omnithreads->set_thread_exit_only');
$rc = $thr->join();
ok(! defined($rc), 'Exited: omnithreads->set_thread_exit_only');


my $WAIT :shared = 1;
$thr = omnithreads->create(sub {
    lock($WAIT);
    while ($WAIT) {
        cond_wait($WAIT);
    }
    exit(1);
    return (99);  # Not seen
});
omnithreads->yield();
ok($thr, 'Created: $thr->set_thread_exit_only');
$thr->set_thread_exit_only(1);
{
    lock($WAIT);
    $WAIT = 0;
    cond_broadcast($WAIT);
}
$rc = $thr->join();
ok(! defined($rc), 'Exited: $thr->set_thread_exit_only');


run_perl(prog => 'use omnithreads qw(exit thread_only);' .
                 'omnithreads->create(sub { exit(99); })->join();' .
                 'exit(86);',
         nolib => ($ENV{PERL_CORE}) ? 0 : 1,
         switches => ($ENV{PERL_CORE}) ? [] : [ '-Mblib' ]);
is($?>>8, 86, "'use omnithreads 'exit' => 'thread_only'");


my $out = run_perl(prog => 'use omnithreads;' .
                           'omnithreads->create(sub {' .
                           '    exit(99);' .
                           '})->join();' .
                           'exit(86);',
                   nolib => ($ENV{PERL_CORE}) ? 0 : 1,
                   switches => ($ENV{PERL_CORE}) ? [] : [ '-Mblib' ],
                   stderr => 1);
is($?>>8, 99, "exit(status) in thread");
like($out, '1 finished and unjoined', "exit(status) in thread");


$out = run_perl(prog => 'use omnithreads qw(exit thread_only);' .
                        'omnithreads->create(sub {' .
                        '   omnithreads->set_thread_exit_only(0);' .
                        '   exit(99);' .
                        '})->join();' .
                        'exit(86);',
                nolib => ($ENV{PERL_CORE}) ? 0 : 1,
                switches => ($ENV{PERL_CORE}) ? [] : [ '-Mblib' ],
                stderr => 1);
is($?>>8, 99, "set_thread_exit_only(0)");
like($out, '1 finished and unjoined', "set_thread_exit_only(0)");


run_perl(prog => 'use omnithreads;' .
                 'omnithreads->create(sub {' .
                 '   $SIG{__WARN__} = sub { exit(99); };' .
                 '   die();' .
                 '})->join();' .
                 'exit(86);',
         nolib => ($ENV{PERL_CORE}) ? 0 : 1,
         switches => ($ENV{PERL_CORE}) ? [] : [ '-Mblib' ]);
is($?>>8, 99, "exit(status) in thread warn handler");


$thr = omnithreads->create(sub {
    $SIG{__WARN__} = sub { omnithreads->exit(); };
    local $SIG{__DIE__} = 'DEFAULT';
    die('Died');
});
ok($thr, 'Created: omnithreads->exit() in thread warn handler');
$rc = $thr->join();
ok(! defined($rc), 'Exited: omnithreads->exit() in thread warn handler');

# EOF
