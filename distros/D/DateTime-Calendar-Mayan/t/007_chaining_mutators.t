use strict;
use warnings;

use Test::More tests => 2;

use DateTime::Calendar::Mayan;

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun  => 1,
            katun   => 1,
            tun     => 1,
            uinal   => 1,
            kin     => 1,
        );
    $dtcm->baktun( 2 )->katun( 2 )->tun( 2 )->uinal( 2 )->kin( 2 );

    is( $dtcm->date, '2.2.2.2.2', 'accessor/mutator chaining' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->set(
        baktun    => 3,
        katun    => 3,
        tun    => 3,
        uinal    => 3,
        kin    => 3,
    )->add(
        baktun  => 2,
        katun   => 2,
        tun     => 2,
        uinal   => 2,
        kin     => 2,
    )->subtract(
        baktun  => 1,
        katun   => 1,
        tun     => 1,
        uinal   => 1,
        kin     => 1,
    );

    is( $dtcm->date, '4.4.4.4.4', 'mutator chaining' );
}
