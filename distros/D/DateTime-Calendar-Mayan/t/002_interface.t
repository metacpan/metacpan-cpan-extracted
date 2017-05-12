use strict;
use warnings;

use Test::More tests => 27;

use DateTime::Duration;
use DateTime::Calendar::Mayan;

{
    ok( my $dtcm = DateTime::Calendar::Mayan->new() );
    ok( $dtcm = DateTime::Calendar::Mayan->now() );
    ok( $dtcm = DateTime::Calendar::Mayan->today() );
    ok( $dtcm->clone() );
    ok( DateTime::Calendar::Mayan->from_object( object => $dtcm ) );
    ok( my @values = $dtcm->utc_rd_values );
    ok( defined $dtcm->epoch );
    ok( $dtcm->from_epoch( epoch => 0 ) );
    ok( $dtcm->mayan_epoch );
    ok( $dtcm->set_mayan_epoch( object => $dtcm ) );
    ok( defined $dtcm->bktuk );
    ok( defined $dtcm->date );
    ok( defined $dtcm->baktun);
    ok( defined $dtcm->katun );
    ok( defined $dtcm->tun );
    ok( defined $dtcm->uinal );
    ok( defined $dtcm->kin );
    ok( defined $dtcm->set_baktun);
    ok( defined $dtcm->set_katun );
    ok( defined $dtcm->set_tun );
    ok( defined $dtcm->set_uinal );
    ok( defined $dtcm->set_kin );
    ok( $dtcm->set( baktun => 1 ) );
    ok( $dtcm->add( baktun => 1 ) );
    ok( $dtcm->subtract( baktun => 1 ) );
    ok( $dtcm->add_duration( DateTime::Duration->new( days => 1 ) ));
    ok( $dtcm->subtract_duration( DateTime::Duration->new( days => 1 ) ));
}
