#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use Business::OnlinePayment;

my $package = "Business::OnlinePayment";
my $driver  = "PlugnPay";

{    # new
    my $obj;

    $obj = $package->new($driver);
    isa_ok( $obj, $package );

    # convenience methods
    can_ok( $obj, qw(order_number avs_code cvv2_response) );
    can_ok( $obj, qw(debug expdate_mmyy) );

    # internal methods
    can_ok( $obj, qw(_map_fields _revmap_fields) );

    # defaults
    my $server = "pay1.plugnpay.com";

    is( $obj->server, $server, "server($server)" );
    is( $obj->port, "443", "port(443)" );
    is( $obj->path, "/payment/pnpremote.cgi", "pnpremote.cgi" );
}

{    # expdate
    my $obj = $package->new($driver);
    my @exp = (

        #OFF [qw(1999.8   08/99)],
        #OFF [qw(1984-11  11/84)],
        #OFF [qw(06/7     07/06)],
        #OFF [qw(06-12    12/06)],
        [qw(12/06    12/06)],
        [qw(6/2000   06/00)],
        [qw(10/2000  10/00)],
        [qw(1/99     01/99)],
    );
    foreach my $aref (@exp) {
        my ( $exp, $moyr ) = @$aref;
        my ($mmyy) = $obj->expdate_mmyy($exp);
        is( $mmyy, $moyr, "$exp: MMYY '$mmyy' eq '$moyr' from $exp" );
    }
}
