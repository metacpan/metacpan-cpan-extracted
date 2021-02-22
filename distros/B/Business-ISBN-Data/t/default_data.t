#!/usr/bin/perl

# If you run into an ISBN that you think is valid but this module
# says is invalid, put it here.
#
# Grab the latest RangeMessage.xml file and see if the distributed
# data is just out of date.
my @isbns_from_issues = qw(
	9782021183061
	);


use Test::More;

use Data::Dumper;
use File::Spec::Functions qw(catfile);

SKIP: {
	my $tests = @isbns_from_issues + 3;
	skip "Need Business::ISBN 3.006 to run this test", $tests unless eval {
		require Business::ISBN;
		# 3.005 fixed a major problem with 979 numbers and the data
		# structure changed.
		Business::ISBN->VERSION('3.006');
		};

	diag( "Business::ISBN is " . Business::ISBN->VERSION );

	my $file = catfile( qw(blib lib Business ISBN RangeMessage.xml) );
	my $out_of_the_way = $file . '.hidden';

	ok( rename($file => $out_of_the_way), 'Renamed file' );

	subtest 'compile' => sub {
		my @modules = qw( Business::ISBN::Data );
		foreach my $module ( @modules ) {
			BAIL_OUT( "Could not load $module" ) unless eval{ use_ok( $module ) };
			}
		};

	local %Business::ISBN::country_data = Business::ISBN::Data::_get_data();
	like( $Business::ISBN::country_data{_source}, qr/\bData\.pm/, 'Data source is the default data structure' );

	subtest 'check_isbns' => sub {
		foreach my $isbn ( @isbns_from_issues ) {
			my $i = Business::ISBN->new( $isbn );
			ok( $i->is_valid, "<$isbn> is valid" );
			}
		};

	rename $out_of_the_way => $file;
	}

done_testing();
