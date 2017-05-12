#!/usr/bin/perl

use strict;
use warnings;
use Test::More tests => 11;

use Business::OnlinePayment;

my $package = "Business::OnlinePayment";
my $driver  = "ElavonVirtualMerchant";

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
    my $server = "www.myvirtualmerchant.com";

    is( $obj->server, $server, "server($server)" );
    is( $obj->port, "443", "port(443)" );
    is( $obj->path, "/VirtualMerchant/process.do", "VirtualMerchant/process.do" );
}

{    # expdate
    my $obj = $package->new($driver);
    my @exp = (

        #OFF [qw(1999.8   0899)],
        #OFF [qw(1984-11  1184)],
        #OFF [qw(06/7     0706)],
        #OFF [qw(06-12    1206)],
        [qw(12/06    1206)],
        [qw(6/2000   0600)],
        [qw(10/2000  1000)],
        [qw(1/99     0199)],
    );
    foreach my $aref (@exp) {
        my ( $exp, $moyr ) = @$aref;
        my ($mmyy) = $obj->expdate_mmyy($exp);
        is( $mmyy, $moyr, "$exp: MMYY '$mmyy' eq '$moyr' from $exp" );
    }
}
