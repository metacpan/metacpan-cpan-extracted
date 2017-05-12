#!/usr/bin/perl

use strict;
use warnings;
use Test::More;

{    # fake test driver (with a submit method)

    package Business::OnlinePayment::MOCK;
    use strict;
    use warnings;
    use base qw(Business::OnlinePayment);
    sub submit { my $self = shift; return 1; }
}
$INC{"Business/OnlinePayment/MOCK.pm"} = "testing";

use Business::OnlinePayment;

my $package = "Business::OnlinePayment";
my $fddrv   = "preCharge";

eval {
    my $tobj = $package->new("MOCK");
    $tobj->fraud_detect($fddrv);
    $tobj->submit;
};

if ( $@ =~ /One of Net::SSLeay.*?or Crypt::SSLeay/ ) {
    plan skip_all => "fraud_detect: $@\n";
}
else {
    plan tests => 5;
}

my $obj = $package->new("MOCK");
can_ok( $obj, qw(fraud_detect) );

# fraud detection failure modes
my $fdbog = "__BOGUS_PROCESSOR";

is( $obj->fraud_detect($fdbog), $fdbog, "fraud_detect set to '$fdbog'" );
eval { $obj->submit; };
like(
    $@,
    qr/^Unable to locate fraud_detection /,
    "fraud_detect with unknown processor croaks"
);

is( $obj->fraud_detect($fddrv), $fddrv, "fraud_detect set to '$fddrv'" );
eval { $obj->submit; };
like( $@, qr/^missing required /, "fraud_detect($fddrv) missing fields" );

# XXX: more test cases needed
