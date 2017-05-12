use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;
plan(tests => 4);

use_ok('CSS::Simple');

my $css = <<END;
h1 {
	color: blue; font-size: large;
}

#program-editor *::after {
	box-sizing: border-box;
	-webkit-touch-callout: none;
	-webkit-user-select: none;
	-moz-user-select: none;
	-ms-user-select: none;
	user-select: none;
}
END

# test for presence of browser specific properties when the related option is enabled
my $simple1 = CSS::Simple->new({browser_specific_properties => 1});

$simple1->read({css => $css});

my $properties1 = [sort keys %{$simple1->get_properties({selector => '#program-editor *::after'})}];

my $expected1 = ['-moz-user-select', '-ms-user-select', '-webkit-touch-callout', '-webkit-user-select', 'box-sizing', 'user-select'];

is_deeply($expected1, $properties1, 'browser specific properties processed');

# test for presence of browser specific properties when the related option is disabled
my $simple2 = CSS::Simple->new({browser_specific_properties => 0});
$simple2->read({css => $css});

my $properties2 = [sort keys %{$simple2->get_properties({selector => '#program-editor *::after'})}];

my $expected2 = ['box-sizing','user-select'];

is_deeply($expected2, $properties2, 'browser specific properties ignored');

# test for presence of browser specific properties when the related option is unspecified
my $simple3 = CSS::Simple->new();
$simple3->read({css => $css});

my $properties3 = [sort keys %{$simple3->get_properties({selector => '#program-editor *::after'})}];

my $expected3 = ['box-sizing','user-select'];

is_deeply($expected3, $properties3, 'browser specific properties ignored');
