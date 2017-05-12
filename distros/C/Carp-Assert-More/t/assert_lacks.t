#!perl -Tw

use warnings;
use strict;

use Test::More tests => 6;

use Carp::Assert::More;

use Test::Exception;

my %foo = (
    name  => 'Andy Lester',
    phone => '578-3338',
    wango => undef,
);


lives_ok( sub { assert_lacks( \%foo, 'Name' ) } );
throws_ok( sub { assert_lacks( \%foo, 'name' ); }, qr/Assert.+failed/ );
lives_ok( sub { assert_lacks( \%foo, [qw( Wango )] ); } );
lives_ok( sub { assert_lacks( \%foo, [qw( Wango Tango )] ); } );
throws_ok( sub { assert_lacks( \%foo, [qw( Wango Tango name )] ); }, qr/Assertion.+failed/ );
lives_ok( sub { assert_lacks( \%foo, [qw()] ) } );

