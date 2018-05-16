#!/usr/bin/perl

use Test::More 'no_plan';
use Test::Output;

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

ok( defined &Brick::Bucket::__make_constraint, "Method is defined" );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# call it from a subroutine with a leading underscore

sub _leading_underscore
	{
	# this should give a warning
	$bucket->__make_constraint( sub {} );
	}

my $result;
stderr_like { eval { _leading_underscore() } } qr/leading underscore/,
	"Making a constraint from a leading underscore carps";

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# call it without a sub argument

{
my $obj = bless {}, 'Foo';

sub Foo::isa { 0 }

my $result = eval { $bucket->__make_constraint( $obj ) };
is( $result, undef, "Result is undefined" );
ok( $@, "\$@ set is undefined" );
}
