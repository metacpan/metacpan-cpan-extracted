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

can_ok( $bucket, '__get_ymd_as_hashref' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Proper date
# SHOULD WORK
my $hash = $bucket->__get_ymd_as_hashref( "20070212" );

isa_ok( $hash, ref {}, "Returns hashref" );
ok( exists $hash->{year}, "Key for year is there" );
ok( exists $hash->{month}, "Key for year is there" );
ok( exists $hash->{day}, "Key for year is there" );


# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Improper date
# SHOULD FAIL
{
my $result = eval { $bucket->__get_ymd_as_hashref( "2007021" ) };
ok( $@, "Improper date croaks" );
ok( ! defined $result, "Improper date returns undef" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# Improper date
# SHOULD FAIL
{
my $result = eval { $bucket->__get_ymd_as_hashref( "20070230" ) };
ok( $@, "February 30 croaks" );
ok( ! defined $result, "Improper date returns undef" );
}
