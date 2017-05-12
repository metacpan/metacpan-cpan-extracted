use strict;
use warnings;

use Test::More tests => 11;

use DateTime::Duration;
use DateTime::Calendar::Mayan;

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun  => 5,
            katun   => 4,
            tun     => 3,
            uinal   => 2,
            kin     => 1,
        );

    is( $dtcm->baktun, 5, 'baktun accessor' );
    is( $dtcm->katun, 4, 'katun accessor' );
    is( $dtcm->tun, 3, 'tun accessor' );
    is( $dtcm->uinal, 2, 'uinal accessor' );
    is( $dtcm->kin, 1, 'kin accessor' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->set(
        baktun    => 1,
        katun    => 1,
        tun    => 1,
        uinal    => 1,
        kin    => 1,
    );

    is( $dtcm->date, '1.1.1.1.1', 'set' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->baktun( 5 );    
    $dtcm->katun( 4 );
    $dtcm->tun( 3 );
    $dtcm->uinal( 2 );
    $dtcm->kin( 1 );

    is( $dtcm->date, '5.4.3.2.1', 'mutators' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun  => 5,
            katun   => 5,
            tun     => 5,
            uinal   => 5,
            kin     => 5,
        );

    $dtcm->add(
        baktun  => 1,
        katun   => 1,
        tun     => 1,
        uinal   => 1,
        kin     => 1,
    );

    is( $dtcm->date, '6.6.6.6.6', 'add' );

    $dtcm->subtract(
        baktun  => 1,
        katun   => 1,
        tun     => 1,
        uinal   => 1,
        kin     => 1,
    );

    is( $dtcm->date, '5.5.5.5.5', 'subtract' );
}

{
    my $dtd = DateTime::Duration->new( days => 21 );
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun  => 5,
            katun   => 5,
            tun     => 5,
            uinal   => 5,
            kin     => 5,
        );
    $dtcm->add_duration( $dtd );

    is( $dtcm->date, '5.5.5.6.6', 'add DT:Duration' );
}

{
    my $dtd = DateTime::Duration->new( days => 21 );
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun  => 5,
            katun   => 5,
            tun     => 5,
            uinal   => 5,
            kin     => 5,
        );
    $dtcm->subtract_duration( $dtd );

    is( $dtcm->date, '5.5.5.4.4', 'add DT:Duration' );
}
