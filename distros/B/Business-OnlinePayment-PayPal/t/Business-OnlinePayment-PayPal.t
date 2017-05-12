#!/usr/bin/perl
# $Id: Business-OnlinePayment-PayPal.t,v 1.2 2007/02/16 04:44:43 plobbes Exp $
# Before `make install' is performed this script should be runnable
# with `make test'. After `make install' it should work as `perl
# Business-OnlinePayment-PayPal.t'

use strict;
use warnings;
use Test::More tests => 35;

BEGIN { use_ok("Business::OnlinePayment") or exit; }

my $package = "Business::OnlinePayment";
my $driver  = "PayPal";

my %new_args = (
    "username"  => "phil",
    "password"  => "nopass",
    "signature" => "my.sig",
);

{    # Business::OnlinePayment
    can_ok( $package, qw(new build_subs content submit) );
}

{    # new
    my $obj;

    $obj = $package->new($driver);
    isa_ok( $obj, $package );

    # new (via build_subs) automatically creates accessors for arguments
    $obj = $package->new( $driver, qw(attr1 a1 ATTR2 a2 -Attr3 a3) );
    can_ok( $package, qw(attr1 attr2) );

    # notice accessors are all lowercase
    is( $obj->attr1, "a1", "value of attr1  (method attr1) is a1" );
    is( $obj->attr2, "a2", "value of ATTR2  (method attr2) is a2" );
    is( $obj->attr3, "a3", "value of -Attr3 (method attr3) is a3" );
}

{    # convenience methods
    my $obj = $package->new($driver);
    can_ok(
        $obj, qw(authorization transactionid
          order_number correlationid
          server_response result_code avs_code cvv2_code
          is_success error_message set_defaults __map_fields_data)
    );
}

{    # get_credentials
    my ( $obj, %auth );

    $obj = $package->new( $driver );
    %auth = $obj->get_credentials;
    is_deeply( \%auth, {}, "get_credentials with no data" );

    $obj = $package->new( $driver, %new_args );
    %auth = $obj->get_credentials;

    my ( $uA, $pA, $sA ) = @auth{qw(Username Password Signature)};
    my ( $uW, $pW, $sW ) = @new_args{qw(username password signature)};
    is( $uA, $uW, "get_credentials: test Username:  '$uA' eq '$uW'" );
    is( $pA, $pW, "get_credentials: test Password:  '$pA' eq '$pW'" );
    is( $sA, $sW, "get_credentials: test Signature: '$sA' eq '$sW'" );
}

{    # get_request_data
    my $obj = $package->new($driver);
    my %in  = (
        "action"     => "Normal Authorization",
	"type"       => "visa",
	"expiration" => "9/2011",
	"cvv2"       => "123",
        "name"       => "Phil Lobbes",
	"fax"        => "should be deleted",
    );
    my %exp = (
        "PaymentAction"  => "Sale",
        "CreditCardType" => "Visa",
        "ExpMonth"       => "09",
        "ExpYear"        => "2011",
        "CVV2"           => "123",
        "FirstName"      => "Phil Lobbes",
    );
    $obj->content(%in);
    my %res = $obj->get_request_data;
    is_deeply( \%res, \%exp , "get_request_data" );
}

#{    # submit
#}

{    # get_remap_fields
    my $obj = $package->new($driver);
    my %in  = qw(act Sale amt 0.99 cvv2 123 Other OK);
    my %map = ( "PayAct" => "act", "Tot" => "amt", "CVV2" => undef);
    my %exp = qw(PayAct Sale Tot 0.99 CVV2 123 Other OK);
    my %res = $obj->get_remap_fields(
        content => \%in,
        map     => \%map,
    );
    is_deeply( \%res, \%exp , "get_remap_fields" );
}

{    # normalize_creditcardtype
    my $obj = $package->new($driver);
    my @cc  = (
        [qw(Bogus      Bogus)],
        [qw(visa       Visa)],
        [qw(Mastercard MasterCard)],
        [q(American Express), q(Amex) ],
        [qw(disCOver   Discover)],
    );
    foreach my $aref ( @cc ) {
        my ( $in, $want ) = @$aref;
        my $out = $obj->normalize_creditcardtype($in);
        is( $out, $want, "normalize_creditcardtype($in): '$out' eq '$want'" );
    }
}

{    # parse_expiration
    my $obj = $package->new( $driver, %new_args );
    my @exp = (
        [qw(1999.8  1999 08)],
        [qw(1984-11 1984 11)],
        [qw(06/7    2006 07)],
        [qw(06-12   2006 12)],
        [qw(12/06   2006 12)],
        [qw(6/2000  2000 06)],
        [qw(10/2000 2000 10)],
        [qw(1/99    2099 01)],
    );
    foreach my $aref ( @exp ) {
        my ( $exp, $yr, $mo ) = @$aref;
        my ( $y, $m ) = $obj->parse_expiration($exp);
        is( $y, $yr, "$exp: year  extracted '$y' eq '$yr'" );
        is( $m, $mo, "$exp: month extracted   '$m' eq   '$mo'" );
    }
}

# $tx->content( qw(a one b two c three) );
