use Test::More;

my $class = 'Business::ISBN';

use_ok( $class ) or BAIL_OUT( "$class did not compile" );
can_ok( $class, qw( error_text error ) );

subtest bad_group => sub {
	can_ok( $class, qw(error_is_bad_group error_text error) );
	# blake and taylor fake ISBNs for their DVDs
	my @bad_isbns = qw(9786316294241 6316294247);

	foreach my $try ( @bad_isbns ) {
		my $isbn = $class->new( $try );
		ok( ! $isbn->is_valid, "ISBN $try is invalid" );
		ok( $isbn->error, "ISBN $try is an error" );
		like( $isbn->error_text, qr/group/, "ISBN $try error text mentions 'group'" );
		ok( $isbn->error_is_bad_group, "ISBN $try has a bad group" );
		}

	my @good_isbns = qw(0596527241);

	foreach my $try ( @good_isbns ) {
		my $isbn = $class->new( $try );
		ok( $isbn->is_valid, "ISBN $try is valid" );
		ok( ! $isbn->error, "ISBN $try is not an error" );
		}
	};

subtest bad_publisher => sub {
	can_ok( $class, qw(error_is_bad_publisher) );

	my @bad_isbns = qw(9656123456);

	foreach my $try ( @bad_isbns ) {
		my $isbn = $class->new( $try );
		ok( ! $isbn->is_valid, "ISBN $try is invalid" );
		ok( $isbn->error, "ISBN $try is an error" );
		like( $isbn->error_text, qr/publisher/, "ISBN $try error text mentions 'publisher'" );
		ok( $isbn->error_is_bad_publisher, "ISBN $try has a bad publisher" );
		}
	};


done_testing();
