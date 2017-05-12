use Test::More 'no_plan';

require_ok( 'Business::ISBN' );

can_ok( 'Business::ISBN', 'import' );

ok( %Business::ISBN::EXPORT_TAGS );
ok( exists $Business::ISBN::EXPORT_TAGS{'all'} );

isa_ok( $Business::ISBN::EXPORT_TAGS{'all'}, ref [] );

ok( defined Business::ISBN->import( ':all' ) );

foreach my $sub ( qw( INVALID_GROUP_CODE INVALID_PUBLISHER_CODE BAD_CHECKSUM
	GOOD_ISBN BAD_ISBN )
	) {
	no strict 'refs';
	
	ok( defined &{$sub}, "Constant '$sub' is defined" );
	}

__END__
sub INVALID_GROUP_CODE     () { -2 };
sub INVALID_PUBLISHER_CODE () { -3 };
sub BAD_CHECKSUM           () { -1 };
sub GOOD_ISBN              () {  1 };
sub BAD_ISBN               () {  0 };
