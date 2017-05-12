package Apache2::Instrument::Time;

use strict;
use warnings;

our $VERSION = '0.03';

use base qw(Apache2::Instrument);

use Apache2::Const -compile => qw(OK);
use Time::HiRes qw(gettimeofday tv_interval);

sub before {
    my ( $class, $r, $notes ) = @_;

    $notes->{before} = [gettimeofday];

    return Apache2::Const::OK;
}

sub after {
    my ( $class, $r, $notes ) = @_;
    $notes->{after} = [gettimeofday];
    return Apache2::Const::OK;
}

sub report {
    my ( $class, $r, $notes ) = @_;

    my $e = tv_interval( $notes->{before}, $notes->{after} );
    return { interval => $e };
}
