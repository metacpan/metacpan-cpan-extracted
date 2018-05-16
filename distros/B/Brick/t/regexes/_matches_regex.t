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

can_ok( $bucket, '_matches_regex' );

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# croaks if it doesn't get a qr//
{
my $result = eval { $bucket->_matches_regex( { regex => '' } ) };
ok( $@, "croaks without a regex (empty string)" );
}

{
my $result = eval { $bucket->_matches_regex( { regex => undef } ) };
ok( $@, "croaks without a regex (undef)" );
}

{
my $result = eval { $bucket->_matches_regex( { regex => '.*(\S+)' } ) };
ok( $@, "croaks without a regex (string)" );
}

# # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # # #
# returns a sub when I give it a regex
{
my $result = eval { $bucket->_matches_regex( { regex => qr/.*/ } ) };
isa_ok( $result, ref sub {} );
}
