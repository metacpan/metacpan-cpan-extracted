# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl test.pl'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use strict;
use warnings;

use lib 'lib';

use Test::More tests => 8;

use Acme::Chef;

ok(1, "Module compiled."); # If we made it this far, we're ok.

#########################

my $testname        = 'Factorial';
my $expected_result = ' 1 2 6 24 120 720 5040 40320 362880 3628800 39916800 479001600';

local $/ = undef;
my $code = <DATA>;

my $compiled = Acme::Chef->compile( $code );
ok(ref $compiled eq 'Acme::Chef', "$testname code compiled.");

my $result = $compiled->execute();
ok($result eq $expected_result, "Correct result.");

my $dump = $compiled->dump();
ok((defined $dump and not ref $dump), "Dumped.");

local $@ = undef;
my $reconstructed = eval $dump;
ok((not $@ and ref $reconstructed eq 'Acme::Chef'), "Reconstruction from dump successful.");

$result = $reconstructed->execute();
ok($result eq $expected_result, "Correct result after reconstruction.");

$dump = $compiled->dump('autorun');
ok((defined $dump and not ref $dump), "Dumped with autorun enabled.");

$result = eval $dump;
ok((not $@ and $result eq $expected_result), "Correct result after reconstruction.");

__DATA__


Factorial.

Ingredients.
12 cups vodka
1 bucket
1 toilet

Method.
Waste vodka. Put vodka into mixing bowl. Serve with drug coctail. Fold
toilet into mixing bowl. Clean mixing bowl. Put toilet into mixing bowl.
Pour contents of the mixing bowl into the baking dish. Puke vodka until
wasted.

Serves 1.


Drug coctail.

Ingredients.
300 cigarettes
1 kg cannabis

Method.
Fold cigarettes into the mixing bowl. Put the cannabis into the mixing bowl.
Smoke the cigarettes. Combine cigarettes. Breathe the cigarettes until smoked.
Fold cigarettes into the mixing bowl. Clean mixing bowl. Put cigarettes into
mixing bowl.


