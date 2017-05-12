#!/usr/bin/perl -w
use strict;

use lib './t';
use Test::More;
use TestData;
use Calendar::Functions qw(:all :test);

eval "use Time::Piece";
if($@) {
	plan skip_all => "Time::Piece not installed.";
}

plan qw|no_plan|;

# date formatting
foreach my $test (@format03) {
	my $str = format_date(@{$test->{array}});
	is($str,$test->{result});
}
