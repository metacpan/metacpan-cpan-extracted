# class tests

# use Test::More tests => 8;
use Test::More skip_all => 'tests require db';

use lib qw/t/;

my @attribute_names = qw/StreetNumber StreetAddress Town City County/;
my @lc_attribute_names = map(lc,@attribute_names);

# 1) use Class::PINT
BEGIN { use_ok('Class::PINT') };

# 2) use Address Class
BEGIN { use_ok( 'Address', 'Address Class'); }

# 3) general accessors
can_ok('Address',@attribute_names, @lc_attribute_names);

# 4) ro accessors
can_ok('Address',map ("get_$_", @attribute_names, @lc_attribute_names));

# 5) wo mutators
can_ok('Address',map ("set_$_", @attribute_names, @lc_attribute_names));

# 6) Array methods
can_ok('Address',map ("${_}_StreetAddress", qw/push pop insert delete/));

# 7) Hash methods
can_ok('Address',map ("${_}_Dictionary", qw/insert delete/),map ("Dictionary_$_", qw/contains keys values/));

# 8) Boolean methods
can_ok('Address',"is_Flag",map ("Flag_is_$_", qw/true false defined/));
