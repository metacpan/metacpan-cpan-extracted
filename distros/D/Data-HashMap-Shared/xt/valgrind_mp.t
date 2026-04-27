use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use File::Temp qw(tmpnam);

plan skip_all => 'set VALGRIND=1 to run' unless $ENV{VALGRIND};
plan skip_all => 'valgrind not found' unless `which valgrind 2>/dev/null`;

use Data::HashMap::Shared::II;

my $path = tmpnam() . ".$$";

# Parent creates, children concurrently mutate under valgrind
my $N = 3;
my $OPS = 200;

my $m = Data::HashMap::Shared::II->new($path, 1024);

my @pids;
for my $k (0..$N-1) {
    my $pid = fork // die;
    if ($pid == 0) {
        # Child re-exec itself under valgrind to detect leaks/UB in this process
        my $inner = qq{
            use Data::HashMap::Shared::II;
            my \$c = Data::HashMap::Shared::II->new('$path', 1024);
            for (1..$OPS) { \$c->put(int(rand(500)), \$_); \$c->get(int(rand(500))); \$c->remove(int(rand(500))) }
        };
        exec('valgrind', '--error-exitcode=42', '--errors-for-leak-kinds=definite',
             '-q', $^X, '-Mblib', '-e', $inner)
            or _exit(2);
    }
    push @pids, $pid;
}

my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? != 0 }

unlink $path;

is $fails, 0, "$N valgrind-instrumented children completed without errors";

done_testing;
