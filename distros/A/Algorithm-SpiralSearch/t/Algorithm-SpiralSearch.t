# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as
# `perl Algorithm-SpiralSearch.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 19;
BEGIN { use_ok('Algorithm::SpiralSearch') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

my $UBX    = 100;
my $UBY    = 100;
my $ITERS  = 50;
my $FIND_X = 0;
my $FIND_Y = 0;

for (my $i = 1; $i < 10; $i++) {
   $FIND_X = sprintf("%0.2f", (rand() * $UBX));
   $FIND_Y = sprintf("%0.2f", (rand() * $UBY));

   my ($x, $y) = Algorithm::SpiralSearch::spiral_search(0, $UBX, 0, $UBY,
                    $ITERS, \&fmax, 'MAX');

   diag(sprintf("Searching for:($FIND_X, $FIND_Y)\tFound:(%0.2f, %0.2f)" .
                "\tOffset: %0.2f", $x, $y,
                sqrt(($x - $FIND_X)**2 + ($y - $FIND_Y)**2)));

   ok($x != 0 && $y != 0, 'Optimal Parameters Were Not Equal to Zero');
}

for (my $i = 1; $i < 10; $i++) {
   $FIND_X = sprintf("%0.2f", (rand() * $UBX));
   $FIND_Y = sprintf("%0.2f", (rand() * $UBY));

   my ($x, $y) = Algorithm::SpiralSearch::spiral_search(0, $UBX, 0, $UBY,
                    $ITERS, \&fmin, 'MIN');

   diag(sprintf("Searching for:($FIND_X, $FIND_Y)\tFound:(%0.2f, %0.2f)" .
                "\tOffset: %0.2f", $x, $y,
                sqrt(($x - $FIND_X)**2 + ($y - $FIND_Y)**2)));

   ok($x != 0 && $y != 0, 'Optimal Parameters Were Not Equal to Zero');
}

sub fmax {
   my ($x, $y) = @_;
   my $prize   = 1000;
   my $wx      = $FIND_X;
   my $wy      = $FIND_Y;

   return($prize - sqrt(($wx - $x)**2 + ($wy - $y)**2));
}

sub fmin {
   my ($x, $y) = @_;
   my $prize   = -1000;
   my $wx      = $FIND_X;
   my $wy      = $FIND_Y;

   return($prize + sqrt(($wx - $x)**2 + ($wy - $y)**2));
}
