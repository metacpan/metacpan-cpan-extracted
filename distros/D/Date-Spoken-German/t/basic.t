#!/usr/bin/env perl -w

use Test::More 'no_plan';
use Date::Spoken::German;
use encoding 'latin1';

my @datetests = (	["dritter Mai neunzehnhundertfünfundsiebzig", [3,5,1975]],
			["sechzehnter Dezember vierzehn", [16,12,14]],
			["einunddreissigster März einhundert" ,[31,3,100]] );

my @timetests = (	["siebter Januar neunzehnhundertsiebzig", 600000],
			["siebzehnter Dezember zweitausenddrei", 1071691040] );

sub do_date_tests {
	my $testvalue = shift;
	my $realanswer;
	my $input = $testvalue->[1];
	my $output = $testvalue->[0];
	ok( ($realanswer = datetospoken( @{$input} )) eq $output, "Converted @{$input} to $realanswer, expected: $output" );
}

sub do_time_tests {
	my $testvalue = shift;
	my $realanswer;
	my $input = $testvalue->[1];
	my $output = $testvalue->[0];
	ok( ($realanswer = timetospoken($input)) eq $output, "Convert $input to $realanswer, expected: $output" );
}

do_date_tests( $_ ) foreach( @datetests );
do_time_tests( $_ ) foreach( @timetests );


