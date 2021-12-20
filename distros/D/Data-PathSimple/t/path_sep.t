#!/usr/bin/perl

use strict;
use warnings;

use Test::More;

use Data::PathSimple qw[ get set ];

sub test_data {
    {
        a => [ 0, 1, 2, { aa => [ 3, 4, 5 ], } ],
        b => {
            bb => [ 6, 7, 8 ],
        },
    }
}

subtest 'regular expression' => sub {

    my %opts = ( path_sep => qr:[\./]: );


    subtest get => sub {
        is( get( test_data, '/a.3/aa.2', \%opts ), 5,
            "correct value returned" );
    };

    subtest set => sub {
        my $data = test_data;
        isnt( set( $data, '/a.3/aa.2', 88, \%opts ), undef, "set returned ok" );
        is( get( $data, '/a.3/aa.2', \%opts ), 88, "correct value stored" );
    };
};

subtest 'string' => sub {

    # make sure that meta character is treated properly
    my %opts = ( path_sep => '.' );

    subtest get => sub {
        is( get( test_data, '.a.3.aa.2', \%opts ), 5,
            "correct value returned" );
    };

    subtest set => sub {
        my $data = test_data;
        isnt( set( $data, '.a.3.aa.2', 88, \%opts ), undef, "set returned ok" );
        is( get( $data, '.a.3.aa.2', \%opts ), 88, "correct value stored" );
    };
};

done_testing;
