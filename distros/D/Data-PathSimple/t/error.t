#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::PathSimple qw[ get set ];

my %errors = (
    undef   => undef,
    scalar  => 'scalar',
    coderef => sub { 'coderef' } );


while ( my ( $expected, $option ) = each %errors ) {

    my $label = $expected;
    $expected = undef if $expected eq 'undef';

    my %opts = ( error => $option );

    subtest $label => sub {

	subtest get => sub {

	    is( get( '', '', \%opts ), $expected, "root is not a ref && path length == 0" );
	    is( get( '', 'a', \%opts ), $expected, "root is not a ref && path length == 1" );
	    is( get( '', 'a/1', \%opts ), $expected, "root is not a ref && path length > 1" );

	    is( get( {}, undef, \%opts ), $expected, "no root path" );
	    is( get( {}, '',    \%opts ), $expected, "no root parts" );

	    is( get( [], 'ab', \%opts ),
		$expected, "hash key used as array index" );

	    is( get( {}, 'a', \%opts ), $expected,
		"non-existent hash element" );

	    is( get( [], 0, \%opts ), $expected, "non-existent array element" );
	};

	subtest set => sub {

	    is( set( '', '', 5, \%opts ), $expected, "root is not a ref && path length == 0" );
	    is( set( '', 'a', 5, \%opts ), $expected, "root is not a ref && path length == 1" );
	    is( set( '', 'a/1', 5, \%opts ), $expected, "root is not a ref && path length > 1" );

	    is( set( {}, undef, 5, \%opts ), $expected, "no root path" );
	    is( set( {}, '',    5, \%opts ), $expected, "no root parts" );

	    is( set( [ ], 'ab', 5, \%opts ),
		$expected, "hash key used as array index" );

	    is( set( [ [ 1 ] ], '0/c', 5, \%opts ),
		$expected, "hash key used as array index" );
	};
    };

}

done_testing;
