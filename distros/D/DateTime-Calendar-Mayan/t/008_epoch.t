use strict;
use warnings;

use Test::More tests => 12;

use DateTime;
use DateTime::Duration;
use DateTime::Calendar::Mayan;

{
    my $dtcm = DateTime::Calendar::Mayan->new();
    my $dt = DateTime->from_object( object => $dtcm );
    is( $dt->ymd, '-3113-08-11', 'default epoch' );
}

{
    my $dt1 = DateTime->new( year => 1970, month => 1, day => 1 );
    my $dtcm = DateTime::Calendar::Mayan->new(
            epoch => $dt1,
        );
    my $dt2 = DateTime->from_object( object => $dtcm );
    
    is( $dt2->ymd, '1970-01-01', 'constructor epoch' );
}

{
    my $dt1 = DateTime->new( year => 6000, month => 1, day => 1 );
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->set_mayan_epoch( object => $dt1 );
    my $dt2 = DateTime->from_object( object => $dtcm );
    
    is( $dt2->ymd, '6000-01-01', 'mutator epoch' );
}

{
    # greater then 1 Mayan year
    my $dt1 = DateTime->new( year => -6000, month => 1, day => 1 );
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->set_mayan_epoch( object => $dt1 );
    my $dt2 = DateTime->from_object( object => $dtcm );
    
    is( $dt2->ymd, '-6000-01-01', 'mutator epoch again' );
}

{
    # greater then 1 Mayan year
    my $dt1 = DateTime->new( year => 6000, month => 1, day => 1 );
    my $dtcm = DateTime::Calendar::Mayan->new();
    $dtcm->set_mayan_epoch( object => $dt1 );
    $dtcm->kin( 1 );
    my $dt2 = DateTime->from_object( object => $dtcm );
    
    is( $dt2->ymd, '6000-01-02', 'mutator epoch yet again' );
}

{
    my $dtcm1 = DateTime::Calendar::Mayan->new();
    my $dtcm2 = $dtcm1->mayan_epoch;

    my $dt = DateTime->from_object( object => $dtcm2 );

    is( $dt->ymd, '-3113-08-11', 'mayan epoch' );
}

{
    my $dtcm1 = DateTime::Calendar::Mayan->new();
    $dtcm1->set_mayan_epoch( object => DateTime->new( year => 42 ) );
    my $dtcm2 = $dtcm1->mayan_epoch;

    my $dt = DateTime->from_object( object => $dtcm2 );

    is( $dt->ymd, '0042-01-01', 'mayan epoch again' );
}

{
    # make sure the epoch is retained
    my $dt1 = DateTime->new( year => 1970, month => 1, day => 1 );
    my $dtcm = DateTime::Calendar::Mayan->new(
            epoch => $dt1,
        );
    $dtcm->add_duration( DateTime::Duration->new( days => 5 ) );
    my $dt2 = DateTime->from_object( object => $dtcm );
    
    is( $dt2->ymd, '1970-01-06', 'add duration' );
}

{
    # make sure the epoch is retained
    my $dt1 = DateTime->new( year => 1970, month => 1, day => 1 );
    my $dtcm = DateTime::Calendar::Mayan->new(
            epoch => $dt1,
        );
    $dtcm->subtract_duration( DateTime::Duration->new( days => 5 ) );
    my $dt2 = DateTime->from_object( object => $dtcm );
    
    is( $dt2->ymd, '1969-12-27', 'subtract duration' );
}

{
    # make sure the epoch is preserved 
    my $dtcm1 = DateTime::Calendar::Mayan->new(
            epoch => DateTime->new( year => 42 ),
        );
    my $dtcm2 = DateTime::Calendar::Mayan->from_object( object => $dtcm1 );
    my $dt = DateTime->from_object( object => $dtcm2->mayan_epoch );

    is( $dt->ymd, '0042-01-01', 'epoch kept from mayan object' );
}

{
    my $dt = DateTime->new( year => 1970, month => 1, day => 2 );
    my $dtcm = DateTime::Calendar::Mayan->from_object( object => $dt );

    is( $dtcm->epoch, '86400', 'UNIX epoch' );
}

{
    my $dtcm = DateTime::Calendar::Mayan->from_epoch( epoch => 0 );
    my $dt = DateTime->from_object( object => $dtcm );

    is( $dt->ymd, '1970-01-01', 'from_epoch' );
}
