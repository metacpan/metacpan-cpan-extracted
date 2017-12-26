#! perl

use strict;
use warnings;

use Test2::Bundle::Extended;

use Data::Edit::Struct qw[ edit ];

use Scalar::Util qw[ refaddr ];

subtest 'value' => sub {

    {
        my %dest = ( array => [ 0, 10, 20, 40 ], );

        edit(
            replace => {
                dest  => \%dest,
                dpath => '/array',
                src   => ['foo'],
            },
        );

        is( \%dest, { array => ['foo'] }, "hash" );
    }

    {

        my @dest = ( 0, 10, 20, 40 );

        edit(
            replace => {
                dest  => \@dest,
                dpath => '/*[0]',
                src   => 'foo',
            },
        );

        is( \@dest, [ 'foo', 10, 20, 40 ], "array" );

    }
};

subtest 'hash key' => sub {

    subtest 'string key' => sub {
        my %dest = ( array => [ 0, 10, 20, 40 ], );
        my $aref = $dest{array};

        edit(
            replace => {
                dest    => \%dest,
                dpath   => '/array',
                replace => 'key',
                src     => 'foo',
            },
        );

        is( \%dest, { foo => $aref }, "key replaced" );
        is( refaddr( $dest{foo} ), refaddr( $aref ), "contents retained" );
    };

    subtest 'reference key' => sub {
        my %dest  = ( array => [ 0, 10, 20, 40 ], );
        my $aref  = $dest{array};
        my $raref = refaddr( $aref );
        edit(
            replace => {
                dest    => \%dest,
                dpath   => '/array',
                replace => 'key',
                src     => $aref,
            },
        );

        is( \%dest, { $raref => $aref }, "key replaced" );
        is( refaddr( $dest{$raref} ), $raref, "contents retained" );
    };
};

isa_ok(
    dies {
        edit(
            replace => {
                replace => 'key',
                dest    => [],
            } )
    },
    ['Data::Edit::Struct::failure::input::src'],
    "no source"
);

isa_ok(
    dies {
        edit(
            replace => {
                replace => 'key',
			dest    => [],
			src => ['foo']
            } )
    },
    ['Data::Edit::Struct::failure::input::dest'],
    "can't replace root"
);

isa_ok(
    dies {
        edit(
            replace => {
                replace => 'key',
			dest    => [ 0 ],
			dpath => '/*[0]',
			src => 'foo'
            } )
    },
    ['Data::Edit::Struct::failure::input::dest'],
    "dest must be hash element to replace key"
);

done_testing;
