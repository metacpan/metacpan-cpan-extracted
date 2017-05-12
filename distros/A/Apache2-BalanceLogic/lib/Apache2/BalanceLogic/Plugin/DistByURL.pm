package Apache2::BalanceLogic::Plugin::DistByURL;

use strict;
use warnings;
use base qw( Apache2::BalanceLogic::Plugin );

sub run {
    my $self = shift;
    my $r    = shift;

    my $uri = $r->uri;
    my $route_id;
    my @route_array;
    while ( my ( $key, $value ) = each( %{ $self->{conf} } ) ) {
        if ( $key =~ /\/(.+)\// ) {
            my $regex = $1;
            if ( $uri =~ /$regex/ ) {
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
