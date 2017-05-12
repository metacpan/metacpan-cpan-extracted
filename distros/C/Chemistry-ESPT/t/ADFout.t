use strict;
use warnings;

use Test::More;

# module loads properly
BEGIN {
	plan tests => 12;
	use_ok('Chemistry::ESPT::ADFout');
	}

# create oject
my $obj = Chemistry::ESPT::ADFout->new();

# methods 
my @methods = ('new', 'analyze', '_digest');
foreach my $m (@methods) {
	can_ok($obj, $m);
}

# constructor
isa_ok($obj, 'Chemistry::ESPT::ADFout');

# number of attributes
is(keys %$obj, 31, "Default number of attributes");

# default values
is($obj->{"BASIS"}, 'Mixed', "BASIS default");
is($obj->{"EINFO"}, 'Bonding E(elec)', "EINFO default");
is($obj->{"NBASIS"}, 0, "NBASIS default");
is($obj->{"PROGRAM"}, 'ADF', "PROGRAM default");
is($obj->{"THEORY"}, 'DFT', "THEORY default");
is($obj->{"TYPE"}, 'out', "TYPE default");


