package Apache2::BalanceLogic::Plugin::DistByCookie;

use strict;
use warnings;
use base qw( Apache2::BalanceLogic::Plugin );
use CGI::Cookie;

sub run {
    my $self = shift;
    my $r    = shift;

    my $distribute_num = $self->{conf}->{distribute_num};
    my $cookie_name    = $self->{conf}->{cookie_name};
    my $route_id;

    my %cookies = parse CGI::Cookie( $r->headers_in->get('Cookie') );
    $cookies{$cookie_name} and my $str = $cookies{$cookie_name}->value();

    if ($str) {
        for ( split( //, $str ) ) {
            $route_id += unpack( "C*", $_ );
        }
        $route_id = $route_id % $distribute_num + 1;
    }

    return $route_id;
}

1;

