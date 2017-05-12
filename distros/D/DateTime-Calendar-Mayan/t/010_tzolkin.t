use strict;
use warnings;

use Test::More tests => 22;

use DateTime::Calendar::Mayan;

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    is( $dtcm->tzolkin, '4 Ahau', 'Haab epoch' );

    # calendar repeats every 260 days
    $dtcm->add( kin => 260 );
    is( $dtcm->tzolkin, '4 Ahau', 'Full Cycle' );
}

{
    # rewind to start of tzolkin cycle
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->subtract( kin => 159 );
    
    is( $dtcm->tzolkin, '1 Imix', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '2 Ik', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '3 Akbal', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '4 Kan', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '5 Chicchan', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '6 Cimi', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '7 Manik', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '8 Lamat', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '9 Muluc', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '10 Oc', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '11 Chuen', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '12 Eb', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '13 Ben', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '1 Ix', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '2 Men', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '3 Cib', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '4 Caban', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '5 Etznab', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '6 Cauac', 'Tzolkin name' );

    $dtcm->add( kin => 1 );
    is( $dtcm->tzolkin, '7 Ahau', 'Tzolkin name' );
}
