use strict;
use warnings;

use Test::More tests => 10;

use DateTime::Calendar::Mayan;

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    is( $dtcm->date, '13.0.0.0.0', 'empty constructor' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new( kin => 1);
    is( $dtcm->date, '13.0.0.0.1', 'partial constructor' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun    => 1,
            katun    => 1,
            tun    => 1,
            uinal    => 1,
            kin    => 1,
        );
    is( $dtcm->date, '1.1.1.1.1', 'full constructor' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun    => 0,
            katun    => 20,
            tun    => 20,
            uinal    => 18,
            kin    => 20,
        );
    is( $dtcm->date, '1.1.1.1.0', 'promotion of units' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun    => 13,
            katun    => 20,
            tun    => 20,
            uinal    => 18,
            kin    => 20,
        );
    is( $dtcm->date, '1.1.1.1.0', 'same meaning as last test' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun    => 1,
            katun    => 20,
            tun    => 20,
            uinal    => 18,
            kin    => 20,
        );
    is( $dtcm->date, '2.1.1.1.0', 'another promotion' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new(
            baktun    => 1,
            katun    => 20,
            tun    => 20,
            uinal    => 18,
            kin    => 21,
        );
    is( $dtcm->date, '2.1.1.1.1', 'yet another promotion' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    is( $dtcm->date( ',' ), '13,0,0,0,0', 'empty constructor' );
}

{
    my $dtcm1 = DateTime::Calendar::Mayan->now();
    my $dtcm2 = $dtcm1->clone();

    isa_ok( $dtcm2, 'DateTime::Calendar::Mayan', 'isa clone' );
    is( $dtcm1->date, $dtcm2->date, 'clone object' );
}
