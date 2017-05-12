#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::General' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

my $sub = $bucket->_is_defined( 
	{
	field         => 'one',
	}
	);
	
isa_ok( $sub, ref sub {}, "_defined_fields returns a code ref" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Field is there, and true
{
my $input = { one => 1 };

my $result = eval {  $sub->( $input )  }; 
	
ok( defined $result, "Result succeeds for defined field, true" );
diag( "Eval error: $@" ) unless defined $result;
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# Field is there, and false
{
my $input = { one => 0 };

my $result = eval {  $sub->( $input )  }; 
	
ok( defined $result, "Result succeeds for defined field, false" );
diag( "Eval error: $@" ) unless defined $result;
}


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# An undef field triggers die
{
my $input = { one => undef };

my $result = eval {  $sub->( $input )  }; 
	
my $at = $@;
print STDERR Data::Dumper->Dump( [$at], [qw(at)] ) if $ENV{DEBUG};

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in \$@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 
# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # 

