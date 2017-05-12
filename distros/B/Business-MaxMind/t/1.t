use strict;

use Test::More 0.88;

use Business::MaxMind::CreditCardFraudDetection;

{
    my $ccfs = Business::MaxMind::CreditCardFraudDetection->new();
    ok( $ccfs->{isSecure}, 'https by default' );
}
{
    my $ccfs
        = Business::MaxMind::CreditCardFraudDetection->new( isSecure => 0 );
    ok( !$ccfs->{isSecure}, 'http when asked for' );
}

done_testing;
