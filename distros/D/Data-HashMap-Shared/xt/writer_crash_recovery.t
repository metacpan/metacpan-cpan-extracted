use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(time);
use IO::Pipe;

use Data::HashMap::Shared::II;

# Regression: Pass 6 — reader yielding to a parked writer that crashed
# must recover via CAS-decrement of writers_waiting on 2s timeout.

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $m = Data::HashMap::Shared::II->new($path, 1024);
$m->put(1, 100);

# Create contention: parent holds a reader briefly; child spawns a writer
# that will be killed while parked. Test that subsequent reader advances.

my $pipe = IO::Pipe->new;
my $writer_pid = fork // die;
if ($writer_pid == 0) {
    $pipe->writer;
    my $c = Data::HashMap::Shared::II->new($path, 1024);
    # Signal ready, then try to acquire write lock — will be contended
    print $pipe "go\n";
    $pipe->close;
    # Attempt a long-running write; parent will kill us mid-flight.
    # Use keys >= 2 to avoid overwriting key 1 (which the test reads).
    for (2..1_000_000) { $c->put($_, $_) }
    _exit(0);
}
$pipe->reader;
<$pipe>;
$pipe->close;

# Let writer make progress and potentially park
select undef, undef, undef, 0.1;
kill 9, $writer_pid;
waitpid $writer_pid, 0;
diag "killed writer $writer_pid";

# Now reader must not be starved by leaked writers_waiting
my $t0 = time;
my $v = $m->get(1);
my $dt = time - $t0;
is $v, 100, 'reader got value after writer crash';
ok $dt < 5, sprintf('reader advanced in %.2fs (regression for writers_waiting recovery)', $dt);

unlink $path;
done_testing;
