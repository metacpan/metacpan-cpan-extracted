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

can_ok( $bucket, 'days_between_dates_outside_range' );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Trivial case
# Specify start date
# Specify end date
# Specify input date outside range
# SHOULD WORK
{
my $sub = $bucket->days_between_dates_outside_range(
	{
	start_date     => '20070205',
	end_date       => '20070314',
	input_date     => '20090214',
	}
	);

isa_ok( $sub, ref sub {} );

my $result = eval { $sub->( {} ) };
is( $result, 1, "Good date works" );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Trivial case
# Specify start date
# Specify end date
# Specify input date in range
# SHOULD FAIL
{
my $sub = $bucket->days_between_dates_outside_range(
	{
	start_date     => '20070205',
	end_date       => '20070314',
	input_date     => '20070214',
	}
	);

isa_ok( $sub, ref sub {} );

my $result = eval { $sub->( {} ) };
my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify start date
# Specify end date
# Specify input date field
# SHOULD WORK
{
my $sub = $bucket->days_between_dates_outside_range(
	{
	start_date       => '20060606',
	end_date         => '20070314',
	input_date_field => 'foo_date',
	}
	);

isa_ok( $sub, ref sub {} );


my $result = eval { $sub->( { foo_date => 20080101 } ) };
is( $result, 1, "Good date works" );

# fail with date in range
$result = eval { $sub->( { foo_date => 20070120 } ) };
my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify start date
# Specify end date field
# Specify input date
# SHOULD WORK
{
my $sub = $bucket->days_between_dates_outside_range(
	{
	start_date       => '20060606',
	end_date_field   => 'end_date',
	input_date       => '20070101',
	}
	);

isa_ok( $sub, ref sub {} );


my $result = eval { $sub->( { end_date => 20061111 } ) };
is( $result, 1, "Good date works" );

# fail with end date after input date
$result = eval { $sub->( { end_date => 20091225 } ) };
my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );


=pod

# fail with end date before start date
$result = eval { $sub->( { end_date => 20050220 } ) };
$at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );
}

=cut
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Specify start date field
# Specify end date
# Specify input date
# SHOULD WORK
{
my $sub = $bucket->days_between_dates_outside_range(
	{
	start_date_field => 'start_date',
	end_date         => '20071020',
	input_date       => '20060101',
	}
	);

isa_ok( $sub, ref sub {} );


my $result = eval { $sub->( { start_date => 20061111 } ) };
is( $result, 1, "Good date works" );

# fail with start date after input date
$result = eval { $sub->( { start_date => 20051225 } ) };
my $at = $@;

    ok( ! defined $result, "Result fails (as expected)" );
isa_ok( $at, ref {}, "death returns a hash ref in $@" );
    ok( exists $at->{handler}, "hash ref has a 'handler' key" );
    ok( exists $at->{message}, "hash ref has a 'message' key" );

}
