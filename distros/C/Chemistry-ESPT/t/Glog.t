use strict;
use warnings;

use Test::More;

# module loads properly
BEGIN {
	plan tests => 9;
	use_ok('Chemistry::ESPT::Glog');
	}

# create oject
my $obj = Chemistry::ESPT::Glog->new();

# methods 
my @methods = ('new', 'analyze', '_digest');
foreach my $m (@methods) {
	can_ok($obj, $m);
}

# constructor
isa_ok($obj, 'Chemistry::ESPT::Glog');

# number of attributes
is(keys %$obj, 48, "Default number of attributes");

# default values
is($obj->{"EINFO"}, 'E(elec)', "EINFO default");
is($obj->{"PROGRAM"}, 'Gaussian', "PROGRAM default");
is($obj->{"TYPE"}, 'log', "TYPE default");


