BEGIN { $| = 1; print "1..4\n"; }

use Convert::Scalar qw(:taint grow);

$b = "1234";

# difficult to test these

grow $b, 5000;	print "ok 1\n";
taint $b;	print "ok 2\n";
tainted $b;	print "ok 3\n";
untaint $b;	print "ok 4\n";



