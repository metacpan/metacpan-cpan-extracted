#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];


subtest 'hash value' => sub {
    my %dest = ( array => [ 0, 10, 20, 40 ], );

    edit(
        delete => {
            dest  => \%dest,
            dpath => '/array',
        },
    );

    is( \%dest, {}, "deleted" );

};

subtest 'array value' => sub {
    my %dest = ( array => [ 0, 10, 20, 40 ], );

    edit(
        delete => {
            dest  => \%dest,
            dpath => '/array/*[idx == 1]',
        },
    );

    is( \%dest, { array => [ 0, 20, 40 ] }, "deleted" );

};

subtest 'array section' => sub {
    my %dest = ( array => [ 0, 10, 20, 40 ], );

    edit(
        delete => {
            dest   => \%dest,
            dpath  => '/array/*[idx == 1]',
            length => 2,
        },
    );

    is( \%dest, { array => [ 0, 40 ] }, "deleted" );

};

subtest 'root' => sub {

    my @dest = ( 0, 10, 20, 40, 50  );

    isa_ok( dies {
	edit(
	     delete => {
			dest   => \@dest,
			dpath  => '/',
		       } ) },
			 [ 'Data::Edit::Struct::failure::input::dest' ],
			 "can't delete root"
    );

};


done_testing;
