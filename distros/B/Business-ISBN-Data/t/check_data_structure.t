#!/usr/bin/perl

use Test::More;

use File::Spec::Functions qw(catfile);

subtest 'setup' => sub {
	use_ok( 'Business::ISBN::Data' );
	ok( %Business::ISBN::country_data );
	};

subtest 'included_range_message' => sub {
	# Test with included RangeMessage.xml in the same spot as the module
	like( $Business::ISBN::country_data{_source}, qr/RangeMessage\.xml/ );
	like( $Business::ISBN::country_data{_source}, qr/blib/ );
	foreach my $isbn_prefix ("978", "979") {
		foreach my $key ( sort { $a <=> $b } grep { ! /\A_/ } keys %{ $Business::ISBN::country_data{$isbn_prefix} } ) {
			my $value = $Business::ISBN::country_data{$isbn_prefix}->{$key};
			isa_ok( $value, ref [], "Value is array ref for country $key" );

			my( $country, $ranges ) = @$value;

			my $count = @$ranges;

			ok( ($count % 2) == 0, "Even number of elements ($count) for country $key" );
			}
		}
	};


subtest 'env_range_message' => sub {
	# Test with RangeMessage.xml set in ISBN_RANGE_MESSAGE
	local $ENV{ISBN_RANGE_MESSAGE} = catfile( qw(lib Business ISBN RangeMessage.xml) );
	local %Business::ISBN::country_data = Business::ISBN::Data::_get_data();
	ok( -e $ENV{ISBN_RANGE_MESSAGE}, 'Alternate RangeMessage.xml exists' );
	unlike( $Business::ISBN::country_data{_source}, qr/blib/ );
	like( $Business::ISBN::country_data{_source}, qr/RangeMessage\.xml/ );
	foreach my $isbn_prefix ("978", "979") {
		foreach my $key ( sort { $a <=> $b } grep { ! /\A_/ } keys %{ $Business::ISBN::country_data{$isbn_prefix} } ) {
			my $value = $Business::ISBN::country_data{$isbn_prefix}->{$key};
			isa_ok( $value, ref [], "Value is array ref for country $key" );

			my( $country, $ranges ) = @$value;

			my $count = @$ranges;

			ok( ($count % 2) == 0, "Even number of elements ($count) for country $key" );
			}
		}
	};

subtest 'missing_range_message' => sub {
	# Test with RangeMessage.xml set in ISBN_RANGE_MESSAGE

	my $file = catfile( qw(blib lib Business ISBN RangeMessage.xml) );
	my $out_of_the_way = $file . '.hidden';

	rename $file => $out_of_the_way;

	ok( ! -e $file, 'RangeMessage.xml is out of the way' );
	local %Business::ISBN::country_data = Business::ISBN::Data::_get_data();

	like( $Business::ISBN::country_data{_source}, qr/\bData\.pm/, 'Data source is the default data structure' );

	rename $out_of_the_way => $file;
	};

subtest 'default_data' => sub {
	# Test with default data
	local %Business::ISBN::country_data = Business::ISBN::Data::_default_data();
	like( $Business::ISBN::country_data{_source}, qr/Data\.pm/ );

	foreach my $isbn_prefix ("978", "979") {
		foreach my $key ( sort { $a <=> $b } grep { ! /\A_/ } keys %{ $Business::ISBN::country_data{$isbn_prefix} } ) {
			my $value = $Business::ISBN::country_data{$isbn_prefix}->{$key};
			isa_ok( $value, ref [], "Value is array ref for country $key" );

			my( $country, $ranges ) = @$value;

			my $count = @$ranges;

			ok( ($count % 2) == 0, "Even number of elements ($count) for country $key" );
			}
		}
	};

done_testing();
