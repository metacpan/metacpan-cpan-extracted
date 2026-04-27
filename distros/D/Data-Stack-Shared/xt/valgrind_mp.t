use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

plan skip_all => 'set VALGRIND=1 to run' unless $ENV{VALGRIND};
plan skip_all => 'valgrind not found' unless `which valgrind 2>/dev/null`;

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";

require Data::Stack::Shared;
my $s = Data::Stack::Shared::Int->new($path, 128);

my $N = 3;
my $OPS = 200;
my @pids;
for my $k (0..$N-1) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $inner = qq{
            use Data::Stack::Shared;
            my \$s = Data::Stack::Shared::Int->new('$path', 128);
            for (1..$OPS) { \$s->push(\$_); \$s->pop if (\$_ % 2) }
        };
        exec('valgrind', '--error-exitcode=42', '--errors-for-leak-kinds=definite',
             '-q', $^X, '-Mblib', '-e', $inner) or _exit(2);
    }
    push @pids, $pid;
}

my $fails = 0;
for my $pid (@pids) { waitpid $pid, 0; $fails++ if $? != 0 }
unlink $path;

is $fails, 0, "$N valgrind-instrumented children completed without errors";

done_testing;
