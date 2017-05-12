BEGIN { $| = 1; print "1..3\n"; }

use AnyEvent::Fork::Early;

if (1) {
   #d# win32 perls corrupt memory when forking early
   print "ok 1\n";
   $AnyEvent::Fork::EARLY = AnyEvent::Fork->new_exec;
} else {
   print $AnyEvent::Fork::TEMPLATE == $AnyEvent::Fork::EARLY ? "" : "not ", "ok 1\n";
}

$AnyEvent::Fork::EARLY->eval ('syswrite STDOUT, "ok 2\n"; exit 0');

my $w = AE::io $AnyEvent::Fork::EARLY->[1], 0, my $cv = AE::cv;
$cv->recv;

print "ok 3\n";
