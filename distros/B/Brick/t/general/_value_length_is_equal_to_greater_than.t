#!/usr/bin/perl

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $sub = $bucket->_value_length_is_equal_to_greater_than(
	{
	field          => 'string',
	minimum_length => 5,
	}
	);

isa_ok( $sub, ref sub {}, "_value_length_is_equal_to_less_than returns a code ref" );

{
my $result = eval {
	$sub->( { string => "Buster" } )
	};

ok( defined $result, "Result succeeds" );
diag( "Eval error: $@" ) unless defined $result;
}

{
my $result = eval {
	$sub->( { string => "Mimi" } )
	};

my $at = $@;

    ok( ! defined $result, "Result fails (as expected) with short input" );
isa_ok( $at, ref {}, "death returns a hash ref in \$@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}
