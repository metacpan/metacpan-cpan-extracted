# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..1\n"; }
END {print "not ok 1\n" unless $loaded;}
use Data::Hash::Flatten;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

  use Data::Hash::Flatten;
use Data::Dumper;

  my $a = { bill => { '5/27/96' => { 'a.dat' => 1, 'b.txt' => 2, 'c.lsp' => 3 } },
            jimm => { '6/22/98' => { 'x.prl' => 9, 'y.pyt' => 8, 'z.tcl' => 7 } } } ;

my @a = Data::Hash::Flatten->this($a, [qw(name date file hits)]);
warn Dumper(\@Data::Hash::Flatten::flattened, \@a);
