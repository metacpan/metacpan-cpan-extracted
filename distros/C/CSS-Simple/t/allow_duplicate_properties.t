use strict;
use warnings;
use lib qw( ./lib ../lib );

use Test::More;

plan(tests => 13);

use_ok('CSS::Simple');

my $css = <<END;
h1 {
	color: blue; 
	background-color: red;
	font-size: large;
	background-color: green;
}
END

# Default behaviour does not allow for duplicate value on properties
{
	my $simple1 = CSS::Simple->new();
	$simple1->read({css => $css});

	# property names
	my $properties1 = [sort keys %{$simple1->get_properties({selector => 'h1'})}];
	my $expected1 = [qw/background-color color font-size/];

	is_deeply($expected1, $properties1, 'properties have been processed');

	# property values
	$properties1 = $simple1->get_properties({selector => 'h1'});
	cmp_ok($properties1->{color}, 'eq', 'blue', 'color value is scalar'); 
	cmp_ok($properties1->{'font-size'}, 'eq', 'large', 'font-size value is scalar'); 
	cmp_ok($properties1->{'background-color'}, 'eq', 'green', 
		'background-color value is a scalar, the value is last one read (green)'); 

	# write can restore only one bg colour
	my $expected = qq(h1 {
\tbackground-color: green;
\tcolor: blue;
\tfont-size: large;
}
);
	cmp_ok($simple1->write, 'eq', $expected, 'Write css outputs only one background-color');

	# test output_selector method   
	cmp_ok($simple1->output_selector({selector =>'h1'}), 'eq', 
	q{background-color:green;color:blue;font-size:large;},
	'Output selector as string');
}

# Set the flag to allow for duplicated values
{
	my $simple1 = CSS::Simple->new({allow_duplicate_properties => 1});
	$simple1->read({css => $css});

	# property names
	my $properties1 = [sort keys %{$simple1->get_properties({selector => 'h1'})}];
	my $expected1 = [qw/background-color color font-size/];

	is_deeply($expected1, $properties1, 'properties have been processed');

	# property values
	$properties1 = $simple1->get_properties({selector => 'h1'});
	cmp_ok($properties1->{color}, 'eq', 'blue', 'color value is scalar'); 
	cmp_ok($properties1->{'font-size'}, 'eq', 'large', 'font-size value is scalar'); 

	# background color was encountered more than once for a specific selector
	# and multiple values have been stored;
	is_deeply($properties1->{'background-color'}, [ qw/red green/ ],
			'background-color value is an arrayref');

	# write can restore the 2 background colours
	my $expected = qq(h1 {
\tbackground-color: red;
\tbackground-color: green;
\tcolor: blue;
\tfont-size: large;
}
);
	cmp_ok($simple1->write, 'eq', $expected, 'Write css outputs 2 background-colors');

	# test output_selector method
	cmp_ok($simple1->output_selector({selector =>'h1'}), 'eq', 
	q{background-color:red;background-color:green;color:blue;font-size:large;},
	'Output selector as string');
}

exit(0);
