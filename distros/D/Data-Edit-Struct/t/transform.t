#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];

subtest 'hash w/ array' => sub {
    my %dest = ( array => [ 0, 10, 20, 40 ], );

    edit(
        transform => {
            dest     => \%dest,
            dpath    => '/array',
            callback => sub {
                my ( $point, $data ) = @_;
                my $array = ${ $point->ref };
                $_ *= $data for @$array;
            },
            callback_data => 2
        },
    );

    is( \%dest, { array => [ 0, 20, 40, 80 ] }, "values" );
};


subtest 'hash values' => sub {
    my %dest = ( a => '1', 'b' => 2 );

    edit(
        transform => {
            dest     => \%dest,
            dpath    => '/*',
            callback => sub {
                my ( $point, $data ) = @_;
                ${ $point->ref } .= $point->attrs->key;
            },
        },
    );

    is( \%dest, { a => '1a', 'b' => '2b' }, 'values' );

};

subtest 'array values' => sub {
    my @dest = qw( a b c );

    edit(
        transform => {
            dest     => \@dest,
            dpath    => '/*',
            callback => sub {
                my ( $point, $data ) = @_;
                ${ $point->ref } .= $point->attrs->{idx};
            },
            callback_data => 2
        },
    );

    is( \@dest, [ 'a0', 'b1', 'c2' ], 'values' );

};


done_testing;
