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

my $testname        = 'JAPH';
my $expected_result = 'Just another Chef/Perl Hacker,';

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



JAPH Souffle.

Ingredients.
44 potatoes
114 onions
101 g flour
107 kg salt
99 bottles of beer
97 cups acid
72 l oil
32 pins
8 l urine
108 pines
101 laptops
80 mouses
47 keyboards
102 idiots
104 hackers
67 voodoo puppets
116 crackpipes
111 megawatts
110 numbers
97 commas
115 dweebs
117 sheep
74 creeps

Method.
Put potatoes into the mixing bowl. Put onions into the mixing bowl. Put
flour into the mixing bowl. Put salt into the mixing bowl. Put bottles
of beer into the mixing bowl. Put acid into the mixing bowl. Put oil into
the mixing bowl. Put pins into the mixing bowl. Put pines into the
mixing bowl. Put onions into the mixing bowl. Put laptops into the mixing
bowl. Put mouses into the mixing bowl. Put keyboards into the mixing
bowl. Put idiots into the mixing bowl. Put flour into the mixing bowl.
Put hackers into the mixing bowl. Put voodoo puppets into the mixing
bowl. Put pins into the mixing bowl. Put onions into the mixing bowl. Put
flour into the mixing bowl. Put hackers into the mixing bowl. Put
crackpipes into the mixing bowl. Put megawatts into the mixing bowl. Put
numbers into the mixing bowl. Put commas into the mixing bowl. Put pins
into the mixing bowl. Put crackpipes into the mixing bowl. Put dweebs into
the mixing bowl. Put sheep into the mixing bowl. Put creeps into the
mixing bowl. Liquify contents of the mixing bowl. Pour contents of the
mixing bowl into the baking dish.

Serves 1.


