package ExamplePackage;

use strict;
use warnings;

use base 'Attribute::Default';

sub introduce : Default('Jimmy') {
	my ($name) = @_;
	
	print "My name is $name\n";
}

sub vitals : Default({ 'age' => 14, 'sex' => 'male' }) {
	my %vitals = @_;
	print "I'm $vitals{'sex'}, $vitals{'age'} years old, ",
		"and am from $vitals{'location'}\n";

}

1;