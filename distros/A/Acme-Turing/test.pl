# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

################## We start with some black magic to print on failure.

BEGIN { $| = 1; print "1..4\n"; }
END {print "not ok 1\n" unless $loaded;}
use Acme::Turing;
$loaded = 1;
print "ok 1\n";

################## End of black magic.

my $failed = 0;

#--- The first example given in Turing's paper. Prints the sequence
#--- 010101....
$m1 = Acme::Turing->new(steps=>100);
$m1->add_spec('START:ANY', "P0,R:C");
$m1->add_spec('C:ANY', "R:E");
$m1->add_spec('E:ANY', "P1, R:Z");
$m1->add_spec('Z:ANY', "R :START");
$m1->run(8,1);

was_it_ok(2, 1);

#--- Turing's second example: 001011011101111...
$m2 = Acme::Turing->new();
$m2->add_spec('START:ANY', "P~,R,P~,R,P0,R,R,P0,L,L:O");
$m2->add_spec('O:1', "R,Px,L,L,L:O");
$m2->add_spec('O:0', ":Q");
$m2->add_spec('Q:ANY', "R,R:Q");
$m2->add_spec('Q: ', "P1,L:P");
$m2->add_spec('P:x', "E,R:Q");
$m2->add_spec('P:~', "R:F");
$m2->add_spec('P: ', "L,L:P");
$m2->add_spec('F:ANY', "R,R:F");
$m2->add_spec('F: ', "P0,L,L:O");
$m2->run();
$m2->print_tape(50,1);

was_it_ok(3, 1);

#--- Logical OR.
$m9 = Acme::Turing->new();
$m9->init_tape(100, '0', '1');
$m9->add_spec('START:0', "R:MAYBE");
$m9->add_spec('START:1', "R:IGNORE");
$m9->add_spec('MAYBE:1', "R, Ptrue:STOP");
$m9->add_spec('MAYBE:0', "R,Pfalse, R:STOP");
$m9->add_spec('IGNORE:ANY', "R,Ptrue:STOP");
$m9->run();

was_it_ok(4, 1);

if ($failed == 0) { print "All tests successful.\n"; }
else {
   $tt = ($failed == 1) ? "1 test" : "$failed tests";
   print "$tt failed!  There is no joy in Mudville.\n";
}


sub was_it_ok {
 my ($num, $test) = @_;
 if ($test) { print "ok $num\n"; }
 else       { print "not ok $num\n"; $failed++; }
}
