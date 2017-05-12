# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

######################### We start with some black magic to print on failure.

# Change 1..1 below to 1..last_test_to_print .
# (It may become useful if the test is moved to ./t subdirectory.)

BEGIN { $| = 1; print "1..10\n"; }
END {print "not ok 1\n" unless $loaded;}
use Chemistry::MolecularMass;
$loaded = 1;
print "ok 1\n";

######################### End of black magic.

# Insert your test code below (better if it prints "ok 13"
# (correspondingly "not ok 13") depending on the success of chunk 13
# of the test code):

my $mm = new Chemistry::MolecularMass;
my $mass;

$mass = $mm->calc_mass("[");
if(defined($mass))
{
   print "not ok 2\n";
}
else
{
   print "ok 2\n";
}

$mass = $mm->calc_mass("[(])");
if(defined($mass))
{
   print "not ok 3\n";
}
else
{
   print "ok 3\n";
}

$mass = $mm->calc_mass("Nosuchelement");
if(defined($mass))
{
   print "not ok 4\n";
}
else
{
   print "ok 4\n";
}

$mass = $mm->calc_mass(" ");
if(defined($mass))
{
   print "not ok 5\n";
}
else
{
   print "ok 5\n";
}

$mass = $mm->calc_mass("");
if($mass == 0)
{
   print "ok 6\n";
}
else
{
   print "not ok 6\n";
}

$mass = $mm->calc_mass("{[](<>)}");
if($mass == 0)
{
   print "ok 7\n";
}
else
{
   print "not ok 7\n";
}

$mass = $mm->calc_mass("NaCl");
if(abs($mass - 58.442) < 0.001)
{
   print "ok 8\n";
}
else
{
   print "not ok 8\n";
}

$mass = $mm->calc_mass("EtOH");
if(abs($mass - 46.068) < 0.001)
{
   print "ok 9\n";
}
else
{
   print "not ok 9\n";
}

$mass = $mm->calc_mass("{[(CH3)3Si]2N}2CHCH3");
if(abs($mass - 348.822) < 0.001)
{
   print "ok 10\n";
}
else
{
   print "not ok 10\n";
}
