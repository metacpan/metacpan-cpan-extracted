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

my $testname        = 'Long test';
my $expected_result = ' 97 98 99 94 95 96 93 90 91 92';

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


Long test.

Ingredients.
100 kg time
100 lines of code
1 number

Method.
Put time into 1st mixing bowl.
Put time into 2nd mixing bowl.
Put time into 3rd mixing bowl.
Put time into 4th mixing bowl.
Put time into 5th mixing bowl.
Put time into 6th mixing bowl.
Put time into 7th mixing bowl.
Put time into 8th mixing bowl.
Put time into 9th mixing bowl.
Put time into 10th mixing bowl.
Remove number from 1st mixing bowl.
Remove number from 2nd mixing bowl.
Remove number from 2nd mixing bowl.
Remove number from 3st mixing bowl.
Remove number from 3st mixing bowl.
Remove number from 3st mixing bowl.
Remove number from 4st mixing bowl.
Remove number from 4st mixing bowl.
Remove number from 4st mixing bowl.
Remove number from 4st mixing bowl.
Remove number from 5st mixing bowl.
Remove number from 5st mixing bowl.
Remove number from 5st mixing bowl.
Remove number from 5st mixing bowl.
Remove number from 5st mixing bowl.
Remove number from 6st mixing bowl.
Remove number from 6st mixing bowl.
Remove number from 6st mixing bowl.
Remove number from 6st mixing bowl.
Remove number from 6st mixing bowl.
Remove number from 6st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 7st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 8st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 9st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Remove number from 10st mixing bowl.
Pour contents of the 1st mixing bowl into 1st baking dish.
Pour contents of the 2rd mixing bowl into 1st baking dish.
Pour contents of the 3st mixing bowl into 1st baking dish.
Pour contents of the 4st mixing bowl into 2st baking dish.
Pour contents of the 5st mixing bowl into 2st baking dish.
Pour contents of the 6st mixing bowl into 2st baking dish.
Pour contents of the 7st mixing bowl into 3st baking dish.
Pour contents of the 8st mixing bowl into the 4st baking dish.
Pour contents of 9st mixing bowl into the 4st baking dish.
Pour contents of 10nd mixing bowl into 4st baking dish.
Needless lines of code.
Put number into 11st mixing bowl.
Yes lines of code until needlessed.
Refrigerate.
Add number to 11st mixing bowl.
Add number to the 11st mixing bowl.
Combine number into 11st mixing bowl.
Combine number into the 11st mixing bowl.
Divide number into 11st mixing bowl.
Divide number into the 11st mixing bowl.
Divide the number into 11th mixing bowl.
Divide the number into the 11st mixing bowl.
Add dry ingredients to 11st mixing bowl.
Add dry ingredients to the 11st mixing bowl.
Add the dry ingredients to 11st mixing bowl.
Add the dry ingredients to the 11st mixing bowl.
Liquify the contents of the 11nd mixing bowl.
Liquefy contents of the 11nd mixing bowl.
Liquify the contents of 11nd mixing bowl.
Liquefy contents of 11nd mixing bowl.
Liquify the lines of code.
Stir the 11th mixing bowl for 100 minutes.
Stir 11th mixing bowl for 100 minutes.
Stir number into the 11rd mixing bowl.
Stir number into 11rd mixing bowl.
Mix the 11st mixing bowl well.

Serves 4.


