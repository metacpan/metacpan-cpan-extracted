use strict;
use autodie qw(:file);

use Cwd;
use Test::More;

if ( !$ENV{WPP_TEST} || !-f $ENV{WPP_TEST} ) {
    plan skip_all =>
        'No WPP_TEST env var set. Please see README to run tests';
}
else {
    plan tests => 14;
}

use_ok('Business::PayPal::API::TransactionSearch');
use_ok('Business::PayPal::API::GetTransactionDetails');

sub rndStr {
    join '', @_[ map { rand @_ } 1 .. shift ];
}
#########################

require 't/API.pl';

my %args = do_args();

=pod

These tests verify the options work.

=cut

my $itemName;

if ( -f 'options-payment.html' ) {
    open( OPTIONS_PAY_HTML_READ, "<", "options-payment.html" );
    while ( my $line = <OPTIONS_PAY_HTML_READ> ) {
        $itemName = $1 if $line =~ /Field\s*Options\s*Tester:\s*([A-Z]+)/;
    }
    close OPTIONS_PAY_HTML_READ;
}
if ( defined $itemName ) {
    print STDERR "Using existing test transaction with name \"$itemName\"\n";
}
else {
    $itemName = rndStr( 10, 'A' .. 'Z' );
    open( OPTIONS_PAY_HTML, ">", "options-payment.html" );
    print OPTIONS_PAY_HTML <<_OPTIONS_PAYMENT_DATA_
<html>
<body>
<form action="https://www.sandbox.paypal.com/cgi-bin/webscr" method="post" target="_top">
   <input type="hidden" name="cmd" value="_xclick" />
   <input type="hidden" name="business" value="$args{SellerEmail}" />
   <input type="hidden" name="item_name" value="Field Options Tester: $itemName" />
   <input id="no_shipping" type="hidden" name="no_shipping" value="0" />
   <input id="amount" type="text" name="amount" size="7" minimum="120" value="120" />
   <input type="hidden" name="on0" value="firstOption" />
   <input type="hidden" name="os0" value="Yes" />
   <input type="hidden" name="on1" value="size"/>
   <input name="os1" id="os1" value="Large"/>
   <input type="hidden" name="on2" value="lostOption"/>
   <input name="os2" id="os2" value="NeverToBeSeen"/>
   <input type="image" border="0" name="submit" alt="Submit Field Tester, $itemName, with \$120 payment">
</form></body></html>
_OPTIONS_PAYMENT_DATA_
        ;
    close(OPTIONS_PAY_HTML);
    my $cwd = getcwd;

    print STDERR <<"_OPTIONS_LINK_";
Please note the next series of tests will not succeeed unless there is at
least one transaction that is part of a subscription payments in your business
account.

if you haven't made one yet, you can visit:
      file://$cwd/options-payment.html

and use the sandbox buyer account to make the payment.
_OPTIONS_LINK_
}

my $startdate = '1998-01-01T01:45:10.00Z';

my $ts = new Business::PayPal::API::TransactionSearch(%args);
my $td = new Business::PayPal::API::GetTransactionDetails(%args);

my $resp = $ts->TransactionSearch( StartDate => $startdate );
my %detail;

foreach my $record ( @{$resp} ) {
    %detail = $td->GetTransactionDetails(
        TransactionID => $record->{TransactionID} );
    last if $detail{PII_Name} =~ /$itemName/;
    %detail = {};
}
like(
    $detail{PaymentItems}[0]{Name}, qr/$itemName/,
    'Found field options test transaction'
);
like(
    $detail{PII_Name}, qr/$itemName/,
    'Found field options test transaction'
);

=pod

Note that the tests below all pass when only two Options are found, even
though our HTML file above passes through I<three> options.

Yet, if you look at the transaction details in the PayPal sandbox web
interface, you'll see that all three Options are present in its record
description.  Thus, Options beyond the first two appears only partially
supported by PayPal.

Thus, our tests verify this fact by submitting three of these fields, but
expecting only the first two back.

More details on this can be found in the
L<Business:PayPal:API:GetTransactionDetails/"PaymentItem Options Limitations">
documentation.

=cut

foreach
    my $options ( $detail{PaymentItems}[0]{Options}, $detail{PII_Options}[0] )
{
    ok(
        scalar( keys %$options ) == 2,
        "The PaymentItems Options has 2 elements"
    );
    ok( defined $options->{firstOption}, "'firstOption' is present" );
    ok(
        $options->{firstOption} eq 'Yes',
        "'firstOption' is selected as 'Yes'"
    );
    ok( defined $options->{size},    "'size' option is present" );
    ok( $options->{size} eq "Large", "'size' option is selected as 'Large'" );
}
