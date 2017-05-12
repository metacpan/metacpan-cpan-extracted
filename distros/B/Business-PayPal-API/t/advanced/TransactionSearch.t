use Test::More;
if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 2;
}

use_ok('Business::PayPal::API::TransactionSearch');
#########################

require 't/API.pl';

my %args = do_args();
my $pp   = new Business::PayPal::API::TransactionSearch(%args);

print STDERR <<"_TRANSID_";

Please login to the PayPal Developer's site, and start a sandbox in
the Business account you want to test. This function will allow you
to view MassPayment transactions by transaction ID's. It may fail for
other types of transaction ID's. The GetTransactionDetails can be
used in those cases but not for Mass Payment transactions. I know, I'm
just the messenger.

Review the Business accounts transaction history:

    My Account -> History (tab)

Click the 'Details' link for a Mass Payment transaction whose status is
'Processed'. Go to the bottom of the page and click "View Detail". It will
give you download choices. Download it however you prefer the copy the 
Transaction ID from the message.

_TRANSID_

print STDERR "\nType or paste that Transaction ID here and hit Enter: \n";

my $transid = <STDIN>;
chomp $transid;

die "Need a transaction id.\n" unless $transid;

my $startdate = '1998-01-01T01:45:10.00Z';

#$Business::PayPal::API::Debug = 1;
my $resp = $pp->TransactionSearch(
    StartDate     => $startdate,
    TransactionID => $transid,
);
ok( scalar @$resp, "Matching Transactions Found" );

