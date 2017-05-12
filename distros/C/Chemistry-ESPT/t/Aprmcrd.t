use strict;
use warnings;

use Test::More;

# module loads properly
BEGIN {
	plan tests => 8;
	use_ok('Chemistry::ESPT::Aprmcrd');
	}

# create oject
my $obj = Chemistry::ESPT::Aprmcrd->new();

# methods 
my @methods = ('new', 'analyze', '_digest');
foreach my $m (@methods) {
	can_ok($obj, $m);
}

# constructor
isa_ok($obj, 'Chemistry::ESPT::Aprmcrd');

# number of attributes
is(keys %$obj, 21, "Default number of attributes");

# default values
is($obj->{"PROGRAM"}, 'AMBER', "PROGRAM default");
is($obj->{"TYPE"}, 'prmcrd', "TYPE default");


