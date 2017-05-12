package Apache2::BalanceLogic::Plugin::DistByTime;

use strict;
use warnings;
use base qw( Apache2::BalanceLogic::Plugin );

sub run {
    my $self = shift;
    my $r    = shift;

    my $route_id;
    my @route_array;
    my $hour = [ localtime(time) ]->[2];

    while ( my ( $key, $value ) = each( %{ $self->{conf} } ) ) {
        if ( $key =~ /(\d+)-(\d+)/ ) {
            my $from = $1;
            my $to   = $2;
            if ( $hour >= $from && $from <= $to ) {
                @route_array = @$value;
            }
        }
        elsif ( $key =~ /^(\d+)$/ ) {
            if ( $hour == $1 ) {
                @route_array = @$value;
            }
        }
    }

    @route_array = @{ $self->{conf}->{other} } unless @route_array;
    my $i = int( rand( $#route_array + 1 ) );
    $route_id = $route_array[$i];

    return $route_id;
}

1;

