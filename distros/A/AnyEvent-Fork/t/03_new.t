BEGIN { $| = 1; print "1..9\n"; }

use AnyEvent::Fork;

print "ok 1\n";

my $proc = new AnyEvent::Fork;

print $proc ? "" : "not ", "ok 2\n";
print $AnyEvent::Fork::TEMPLATE ? "" : "not ", "ok 3\n";
print !$AnyEvent::Fork::EARLY ? "" : "not ", "ok 4\n";

use AnyEvent::Util;
print +(my ($r, $w) = AnyEvent::Util::portable_pipe) ? "" : "not ", "ok 5\n";

$proc->send_fh ($w);
$proc->eval ('syswrite $arg[0], "173"');
undef $w;

{ my $w = AE::io $r, 0, my $cv = AE::cv; $cv->recv }

print "ok 6\n";

undef $proc;

print "ok 7\n";

$r = <$r>;
print $r eq "173" ? "" : "not ", "ok 8 # $r\n";

print "ok 9\n";
