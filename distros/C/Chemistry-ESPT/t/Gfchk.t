use strict;
use warnings;

use Test::More;

# module loads properly
BEGIN {
	plan tests => 15;
	use_ok('Chemistry::ESPT::Gfchk');
	}

# create oject
my $obj = Chemistry::ESPT::Gfchk->new();

# methods 
my @methods = ('new', 'analyze', '_digest', 'sci2dec');
foreach my $m (@methods) {
	can_ok($obj, $m);
}

# constructor
isa_ok($obj, 'Chemistry::ESPT::Gfchk');

# number of attributes
is(keys %$obj, 45, "Default number of attributes");

# default values
is($obj->{"EINFO"}, 'E(elec)', "EINFO default");
is($obj->{"IRCPOINTS"}, 0, "IRCPOINTS default");
is($obj->{"NREDINT"}, 0, "NREDINT default");
is($obj->{"REDINTANGLE"}, 0, "REDINTANGLE default");
is($obj->{"REDINTBOND"}, 0, "REDINTBOND default");
is($obj->{"REDINTDIHEDRAL"}, 0, "REDINTDIHEDRAL default");
is($obj->{"PROGRAM"}, 'Gaussian', "PROGRAM default");
is($obj->{"TYPE"}, 'fchk', "TYPE default");


