#!perl

use strict;
use warnings;
use Test::More tests => 7;
use Data::PowerSet::Hash 'hash_powerset';
use Test::Deep::NoTest 'eq_deeply';

my @hash = hash_powerset;
is_deeply( [ hash_powerset ], [ {} ], 'Empty powerset' );

{
    my @pset = hash_powerset(
        ack => 'back',
    );

    my $data = [
        { ack => 'back' },
        {},
    ];

    is_deeply( \@pset, $data, 'Simple powerset' );
}

{
    my @pset = hash_powerset(
        husband => 'Homer Simpson',
        wife    => 'Marge Simpson',
    );

    my %data = (
        all => {
            husband => 'Homer Simpson',
            wife    => 'Marge Simpson',
        },
        homer => { husband => 'Homer Simpson' },
        marge => { wife    => 'Marge Simpson' },
        none  => {},
    );

    my %eq = ();
    while ( my $set = shift @pset ) {
        foreach my $name ( keys %data ) {
            my $data = $data{$name};
            eq_deeply( $data, $set ) and $eq{$name}++;
        }
    }

    foreach my $name ( keys %data ) {
        ok( $eq{$name}, "$name exists in power set" );
    }

    cmp_ok( scalar(@pset), '==', 0, 'All sets successfully matched' );
}

