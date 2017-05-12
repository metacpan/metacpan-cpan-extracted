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

my $testname        = 'Exponentiation';
my $expected_result = ' 8';

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

Exponentiation cake.

Calculate exponentiation: sugar ^ flour.

Ingredients.
3 kg flour
2 g sugar
1 egg

Method.
Put flour into mixing bowl.
Bake flour.
Remove egg.
Fold flour into mixing bowl.
Put sugar into mixing bowl.
Cool flour.
Combine sugar.
Water flour until cooled.
Pour contents of the mixing bowl into the baking dish.
Refrigerate for 1 hour.
Heat until baked.
Clean mixing bowl.
Put egg into mixing bowl.
Stir for 2 minutes.
Pour contents of the mixing bowl into the baking dish.
Refrigerate for 1 hour.



