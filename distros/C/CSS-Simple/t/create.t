use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 2);

use_ok('CSS::Simple');

my $simple = CSS::Simple->new();

#test creation of empty selector
$simple->add_selector({selector => '.empty', properties => {}});

#test creation of initialized selector
$simple->add_selector({selector => '.bar', properties => { color => 'blue', 'font-size' => '16px'}});

#test default creation of selector through property addition
my $new_properties = { color => 'red', 'font-family' => 'Tahoma'};
$simple->add_properties({ selector => '.foo', properties => $new_properties});
$simple->add_properties({ selector => '.foo2', properties => $new_properties});
$simple->add_properties({ selector => '.foo3', properties => $new_properties});

#test getting properties and setting on an existing selector
my $bar_properties = $simple->get_properties({selector => '.bar'});
$simple->add_properties({ selector => '.foo', properties => $bar_properties});

$simple->delete_property({selector => '.foo3', property => 'font-family'});

my $ordered = $simple->write();

my $expected = <<END;
.bar {
	color: blue;
	font-size: 16px;
}
.foo {
	color: blue;
	font-family: Tahoma;
	font-size: 16px;
}
.foo2 {
	color: red;
	font-family: Tahoma;
}
.foo3 {
	color: red;
}
END

ok($expected eq $ordered);
