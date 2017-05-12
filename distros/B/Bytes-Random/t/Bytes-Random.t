# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Bytes-Random.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 41 + 0x100 + 1;
use Statistics::Basic qw(stddev);
BEGIN { use_ok('Bytes::Random') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

for( 1..40 )
{
  is(
    length( random_bytes($_) ) => $_,
    "Got $_ random bytes"
  );
}# end for()


{
    my $amount = 1e6;
    my %dispersion;
    $dispersion{ord random_bytes(1)}++ for 1..$amount;
    my @slots = 0..0xff;

    for my $slot (@slots) {
        ok exists $dispersion{$slot},
          "could produce bytes of numeric value $slot";
    }

    my $s = stddev(map {defined $_ ? $_ : 0} @dispersion{@slots})->query;
    ok 2 > log($s) / log(10),
      "$amount values are roughly evenly distributed "
      . "(standard deviation was $s, should be about 60)";
}
