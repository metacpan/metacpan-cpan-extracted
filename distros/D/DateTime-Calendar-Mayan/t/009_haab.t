use strict;
use warnings;

use Test::More tests => 21;

use DateTime::Calendar::Mayan;

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    is( $dtcm->haab, '8 Cumku', 'Haab epoch' );

    # calendar repeats every 365 days
    $dtcm->add( kin => 365 );
    is( $dtcm->haab, '8 Cumku', 'Full cycle' );
}

{
    # rewind to start of haab cycle
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->subtract( kin => 348 );

    is( $dtcm->haab, '0 Pop', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Uo', 'Haab month' );
    
    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Zip', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Zotz', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Tzec', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Xul', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Yaxkin', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Mol', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Chen', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Yax', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Zac', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Ceh', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Mac', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Kankin', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Muan', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Pax', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Kayab', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Cumku', 'Haab month' );

    $dtcm->add( kin => 20 );
    is( $dtcm->haab, '0 Uayeb', 'Haab month' );
}
