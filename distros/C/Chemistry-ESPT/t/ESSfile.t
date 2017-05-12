use strict;
use warnings;

use Test::More;

# module loads properly
BEGIN {
	plan tests => 14;
	use_ok('Chemistry::ESPT::ESSfile');
	}

# create oject
my $obj = Chemistry::ESPT::ESSfile->new();

# methods 
my @methods = ('new', 'prepare', 'atomconvert', 'debug', 'get', 'MOdecoder', 'printattributes');
foreach my $m (@methods) {
	can_ok($obj, $m);
}

# constructor
isa_ok($obj, 'Chemistry::ESPT::ESSfile');

# number of attributes
is(keys %$obj, 20, "Number of attributes");

# default values
is($obj->{"COMPLETE"}, 0, "COMPLETE default");
is($obj->debug(), 0, "Debug default");
is_deeply($obj->{"TIME"}, [0,0,0,0], "TIME default");

# debug method
my $level = 393;
$obj->debug($level);
is($obj->debug(), $level, "Debug method");
$obj->debug(0);


