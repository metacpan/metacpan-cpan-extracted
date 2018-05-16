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

can_ok( $bucket, '_is_tuesday' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# WORKS - overriding localtime
{
my $sub = $bucket->_is_tuesday();

isa_ok( $sub, ref sub {}, "_is_tuesday returns a code ref" );

{
package Brick::Bucket;

use subs qw(localtime);
sub localtime (;$) { qw( 0 0 0 0 0 0 2 ) };

package main;

use subs qw(localtime);
sub localtime (;$) { qw( 0 0 0 0 0 0 2 ) };

is( (localtime)[6], 2, "Overrode localtime" );

# How do I test this?
my $result = eval { $sub->() };
ok( $result, "Passed" );
}

}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# FAILS - overriding localtime
{
my $sub = $bucket->_is_tuesday();

isa_ok( $sub, ref sub {}, "_is_tuesday returns a code ref" );

{
no warnings 'redefine';
*Brick::Bucket::localtime = sub (;$) { qw( 0 0 0 0 0 0 3 ) };
*localtime = sub (;$) { qw( 0 0 0 0 0 0 3 ) };

is( (localtime)[6], 3, "Overrode localtime" );

# How do I test this?
my $result = eval { $sub->() };
is( $result, 0, "Failed (expected)" );
}

}
