# https://github.com/briandfoy/business--isbn/issues/3
use Test::More 0.95;
use_ok( 'Business::ISBN' );

subtest good_checksum => sub {
	my $string = '9789990022575';
	my $isbn = Business::ISBN->new( $string );

	is( $isbn->publisher_code, undef, 'Publisher code is bad' );
	isnt( $isbn->is_valid, Business::ISBN::GOOD_ISBN(), 'Not a good ISBN' );
	
	$isbn->fix_checksum;

	is( $isbn->publisher_code, undef, 'Publisher code is still bad' );
	isnt( $isbn->is_valid, Business::ISBN::GOOD_ISBN(), 'Still not a good ISBN' );
	
	};

subtest bad_checksum => sub {
	my $string = '9789990002576';
	my $isbn = Business::ISBN->new( $string );

	is( $isbn->is_valid_checksum, Business::ISBN::BAD_CHECKSUM() );

	is( $isbn->publisher_code, undef, 'Publisher code is bad' );
	isnt( $isbn->is_valid, Business::ISBN::GOOD_ISBN(), 'Not a good ISBN' );

	$isbn->fix_checksum;

	is( $isbn->publisher_code, undef, 'Publisher code is still bad' );
	isnt( $isbn->is_valid, Business::ISBN::GOOD_ISBN(), 'Still not a good ISBN' );
	};

done_testing();
