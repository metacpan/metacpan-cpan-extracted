#!/usr/bin/perl

# API Testing for Algorithm::Dependency

use strict;
BEGIN {
	$|  = 1;
	$^W = 1;
}

# Load the API we will be testing
use Test::More 'tests' => 39;
use Test::ClassAPI;
use Algorithm::Dependency               ();
use Algorithm::Dependency::Ordered      ();
use Algorithm::Dependency::Source::File ();
use Algorithm::Dependency::Source::HoA  ();

# Execute the tests
Test::ClassAPI->execute('complete');
exit(0);

# Now, define the API for the classes
__DATA__

Algorithm::Dependency=class
Algorithm::Dependency::Item=abstract
Algorithm::Dependency::Ordered=class
Algorithm::Dependency::Source=abstract
Algorithm::Dependency::Source::File=class
Algorithm::Dependency::Source::HoA=class

[Algorithm::Dependency]
new=method
source=method
selected_list=method
selected=method
item=method
depends=method
schedule=method
schedule_all=method

[Algorithm::Dependency::Item]
new=method
id=method
depends=method

[Algorithm::Dependency::Ordered]
Algorithm::Dependency=isa

[Algorithm::Dependency::Source]
new=method
load=method
item=method
items=method
missing_dependencies=method

[Algorithm::Dependency::Source::File]
Algorithm::Dependency::Source=isa

[Algorithm::Dependency::Source::HoA]
Algorithm::Dependency::Source=isa
