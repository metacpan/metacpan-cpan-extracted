use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use IO::Pipe;

use Data::HashMap::Shared::II;

# A reader yielding to a parked writer that crashed must recover on the 2s
# timeout via CAS-decrement of writers_waiting.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $m = Data::HashMap::Shared::II->new($path, 1024);
$m->put(1, 100);

my $pipe = IO::Pipe->new;
my $writer_pid = fork // die;
if ($writer_pid == 0) {
    $pipe->writer;
    my $c = Data::HashMap::Shared::II->new($path, 1024);
    print $pipe "go\n";
    $pipe->close;
    # keys >= 2: key 1 is the one the test reads
    for (2..1_000_000) { $c->put($_, $_) }
    _exit(0);
}
$pipe->reader;
<$pipe>;
$pipe->close;

# let the writer make progress and park
select undef, undef, undef, 0.1;
kill 9, $writer_pid;
waitpid $writer_pid, 0;
diag "killed writer $writer_pid";

my $t0 = time;
my $v = $m->get(1);
my $dt = time - $t0;
is $v, 100, 'reader got value after writer crash';
ok $dt < 5, sprintf('reader advanced in %.2fs (regression for writers_waiting recovery)', $dt);

unlink $path;
done_testing;
