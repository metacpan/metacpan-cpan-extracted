#!/usr/bin/perl

# Basic first pass API testing for Data::Vitals

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

use Test::More tests => 83;
use Test::ClassAPI;

# Load the API to test
use Data::Vitals;

# Execute the tests
Test::ClassAPI->execute('complete', 'collisions');
exit(0);

# Define the API
__DATA__

Data::Vitals=class
Data::Vitals::Util=class
Data::Vitals::Height=class
Data::Vitals::Circumference=class
Data::Vitals::Hips=class
Data::Vitals::Waist=class
Data::Vitals::Frame=class
Data::Vitals::Chest=class
Data::Vitals::Underarm=class

[Data::Vitals]
height=method
hips=method
waist=method
frame=method
chest=method
bust=method
underarm=method

[Data::Vitals::Util]
inch2cm=method
cm2inch=method

[Data::Vitals::Height]
new=method
as_string=method
as_metric=method
as_imperial=method
as_cms=method
as_feet=method

[Data::Vitals::Circumference]
new=method
as_string=method
as_metric=method
as_imperial=method
as_cms=method
as_inches=method

[Data::Vitals::Hips]
Data::Vitals::Circumference=isa

[Data::Vitals::Waist]
Data::Vitals::Circumference=isa

[Data::Vitals::Frame]
Data::Vitals::Circumference=isa

[Data::Vitals::Chest]
Data::Vitals::Circumference=isa

[Data::Vitals::Underarm]
Data::Vitals::Circumference=isa
