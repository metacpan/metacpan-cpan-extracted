#!/usr/bin/perl
use strict;

use Test::More 'no_plan';

use_ok( 'Brick::Dates' );
use_ok( 'Brick::Bucket' );

use lib qw( t/lib );
use_ok( 'Mock::Bucket' );

my $bucket = Mock::Bucket->new;
isa_ok( $bucket, 'Mock::Bucket' );
isa_ok( $bucket, Mock::Bucket->bucket_class );

can_ok( $bucket, 'at_most_N_days_between' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Trivial case
# Specify start date
# Specify end date
# Specify number of days
{
my $sub = $bucket->at_most_N_days_between( 
	{
	start_date     => '20070205',
	end_date       => '20070314',
	number_of_days => 60,
	}
	);
	
isa_ok( $sub, ref sub {} );

	
my $result = eval { $sub->( {} ) };
is( $result, 1, "Good date works" );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify start date
# Specify end date field
{
my $sub = $bucket->at_most_N_days_between( 
	{
	start_date     => '20070101',
	end_date_field => 'last_date',
	number_of_days => 10,
	}
	);
	
isa_ok( $sub, ref sub {} );

# should work with near date
{
my $input = {
	last_date => 20070108,
	};	
my $result = eval { $sub->( $input ) };
is( $result, 1, "Good date works" );
}

# should fail with with far date
{
my $input = {
	last_date => 20080105,
	};
my $result = eval { $sub->( $input ) };

my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

# should fail with with past date
TODO: {
local $TODO = "End dates in the past aren't working";

my $input = {
	last_date => 20060201,
	};
my $result = eval { $sub->( $input ) };

my $at = $@;

=pod

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
    
=cut 

}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify end date
# Specify start date field
{
my $sub = $bucket->at_most_N_days_between( 
	{
	end_date         => '20070101',
	start_date_field => 'first_date',
	number_of_days   => 10,
	}
	);
	
isa_ok( $sub, ref sub {} );

# should work with near date
{
my $input = {
	first_date => 20061225,
	};
my $result = $sub->( $input );
}

# should fail with with far date
{
my $input = {
	first_date => 20061215,
	};
my $result = eval { $sub->( $input ) };

my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify start date field
# Specify end date field
{
my $sub = $bucket->at_most_N_days_between( 
	{
	end_date_field   => 'last_date',
	start_date_field => 'first_date',
	number_of_days   => 15,
	}
	);
	
isa_ok( $sub, ref sub {} );

# should work with near dates
{
my $input = {
	first_date => 20061225,
	last_date  => 20070101
	};
my $result = $sub->( $input );
}

# should fail with with far date
{
my $input = {
	first_date => 20061201,
	last_date  => 20070101
	};
my $result = eval { $sub->( $input ) };

my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

=pod

# should fail with with last date before start date
{
my $input = {
	first_date => 20070201,
	last_date  => 20060101
	};
my $result = eval { $sub->( $input ) };

my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

=cut

}