BEGIN { $| = 1; print "1..4\n"; }

use AnyEvent::Util;
use AnyEvent::Fork::Remote;
use Proc::FastSpawn;

print "ok 1\n";

my $fork = new_exec AnyEvent::Fork::Remote $^X, "perl";

print "ok 2\n";

$fork->eval ('sub prr { syswrite STDOUT, "ok 3\n"; exit }');

$fork->run ("prr", my $cv = AE::cv);
$fh = $cv->recv;

AnyEvent::Util::fh_nonblocking $fh, 0;

print <$fh>;

print "ok 4\n";

