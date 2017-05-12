use strict;
use warnings;
use autodie qw(:file);

use Cwd;
use List::AllUtils;
use Test::More;

if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 5;
}

use_ok('Business::PayPal::API::TransactionSearch');
#########################

require 't/API.pl';

my %args = do_args();

=pod

The following four tests shows the methodology to use TransactionSearch to
find transactions that are part of the same ProfileID.  This method was
discovered by trial-and-error.  Specifically, it's somewhat odd that
TransactionSearch is used with the parameter of 'ProfileID' with the value
set to a specific TransactionID to find the ProfileID via the "Created"
transaction.  Then, in turn, that ProfileID can find the subscription payments
related to the original transaction.

This works, and seems to be correct, albeit odd.

=cut

open SUBSCRIPTION_PAY_HTML, '>', 'subscription-payment.html';

print SUBSCRIPTION_PAY_HTML <<_SUBSCRIPTION_PAYMENT_DATA_
<html>
    <body>
        <form action="https://www.sandbox.paypal.com/cgi-bin/webscr" method="post" target="_top">
            <input type="hidden" name="business" value="$args{SellerEmail}" />
            <input type="hidden" name="item_name" value="Monthly Payment" />
            <input type="hidden" name="cmd" value="_xclick-subscriptions">
            <input id="no_shipping" type="hidden" name="no_shipping" value="0" />
            <input type="hidden" name="lc" value="US">
            <input type="hidden" name="no_note" value="1">
            <input type="hidden" name="t3" value="M" />
            <input type="hidden" name="p3" value="1" />
            <input type="hidden" name="src" value="1" />
            <input type="hidden" name="srt" value="0" />
            <input id="no_shipping" type="hidden" name="no_shipping" value="0" />
            <input type="hidden" name="no_note" value="1">
            <input id="amount" type="text" name="a3" size="5" minimum="10" value="10" />
            <input type="image" border="0" name="submit" alt="Make test monthly payment now">
        </form>
    </body>
</html>
_SUBSCRIPTION_PAYMENT_DATA_
    ;
close SUBSCRIPTION_PAY_HTML;

my $cwd = getcwd;

print STDERR <<"_PROFILEID_";
Please note the next series of tests will not succeeed unless there is at
least one transaction that is part of a subscription payments in your business
account.

if you haven't made one yet, you can visit:
      file:///$cwd/subscription-payment.html

and use the sandbox buyer account to make the payment.
_PROFILEID_

my $start_date = '1998-01-01T01:45:10.00Z';

my $ts = Business::PayPal::API::TransactionSearch->new(%args);

my $resp = $ts->TransactionSearch( StartDate => $start_date );

ok( scalar @{$resp} > 0, 'Some transactions found' );

my ( $profileID, %possible_txn_ids );

foreach my $record ( @{$resp} ) {
    if ( $record->{Type} =~ /Recurring/ ) {
        if ( $record->{Status} =~ /Completed/ ) {
            $possible_txn_ids{ $record->{TransactionID} } = $record;
        }
        elsif ( $record->{Status} =~ /Created/ ) {
            $profileID = $record->{TransactionID};
        }
    }
}

ok(
    defined $profileID,
    'Subscription Payment Creation Record and ProfileID Found'
);
ok(
    scalar keys %possible_txn_ids > 0,
    'Subscription Payment Transactions Found'
);

my $date_search_res = $ts->TransactionSearch(
    ProfileID => $profileID,
    StartDate => $start_date,
);

# One of these will need to be in the possibleTransactionID list (i.e., we're
# assuming that at least one payment has occured in this repeating).

ok(
    List::AllUtils::any {
        defined $possible_txn_ids{ $_->{TransactionID} }
    }
    @{$date_search_res},
    'Found one payment transaction under the given Profile ID'
);
