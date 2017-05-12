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

my $testname        = 'Dish quantifier';
my $expected_result = 'HHHH';

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


Many bowls.

This recipe uses many bowls.

Ingredients.
72 g letter H

Method.
Put letter H into the 1st mixing bowl.
Put letter H into the 2nd mixing bowl.
Put letter H into the 3rd mixing bowl.
Put letter H into the 4th mixing bowl.
Liquefy contents of the 1st mixing bowl.
Liquefy contents of the 2nd mixing bowl.
Liquefy contents of the 3rd mixing bowl.
Liquefy contents of the 4th mixing bowl.
Pour contents of the 1st mixing bowl into the baking dish.
Pour contents of the 2nd mixing bowl into the baking dish.
Pour contents of the 3rd mixing bowl into the baking dish.
Pour contents of the 4th mixing bowl into the baking dish.

Serves 1.


