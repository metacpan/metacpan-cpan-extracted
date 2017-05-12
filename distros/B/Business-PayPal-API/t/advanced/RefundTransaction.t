use Test::More;
if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 2;
}

use_ok('Business::PayPal::API::RefundTransaction');
#########################

require 't/API.pl';

my %args = do_args();

my $pp = new Business::PayPal::API::RefundTransaction(%args);

print STDERR <<"_TRANSID_";

Please login to the PayPal Developer's site, and start a sandbox in
the Business account you want to test.

Review the Business accounts transaction history:

    My Account -> History (tab)

Follow the 'Details' link for a transaction (whose status is
'Completed') that occurred in the past 60 days.

Copy the Transaction ID for that transaction. It may appear like this:

    Express Checkout Payment Received (ID # 2DE2563K55B16978M)

_TRANSID_

print STDERR "\nType or paste that Transaction ID here and hit Enter: \n";

my $transid = <STDIN>;
chomp $transid;

die "Need a transaction id.\n" unless $transid;

my %resp = $pp->RefundTransaction(
    TransactionID => $transid,
    RefundType    => 'Full',
    Memo          => 'Fancy refund time.'
);

like( $resp{Ack}, qr/Success/, "Successful refund." );

if ( $resp{Ack} ) {
    print STDERR <<"_REFUND_";

You may now login to your Business sandbox account and verify the
transaction was refunded.

_REFUND_
}
