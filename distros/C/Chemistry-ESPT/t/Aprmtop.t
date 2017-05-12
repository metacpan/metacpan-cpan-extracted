use strict;
use warnings;

use Test::More;

# module loads properly
BEGIN {
	plan tests => 9;
	use_ok('Chemistry::ESPT::Aprmtop');
	}

# create oject
my $obj = Chemistry::ESPT::Aprmtop->new();

# methods 
my @methods = ('new', 'analyze', '_digest', 'mass2sym');
foreach my $m (@methods) {
	can_ok($obj, $m);
}

# constructor
isa_ok($obj, 'Chemistry::ESPT::Aprmtop');

# number of attributes
is(keys %$obj, 21, "Default number of attributes");

# default values
is($obj->{"PROGRAM"}, 'AMBER', "PROGRAM default");
is($obj->{"TYPE"}, 'prmtop', "TYPE default");


