package Business::GoCardless::Pro;

=head1 NAME

Business::GoCardless::Pro - Perl library for interacting with the GoCardless Pro v2 API
(https://gocardless.com)

=head1 DESCRIPTION

Module for interacting with the GoCardless Pro (v2) API.

B<You should refer to the official gocardless API documentation in conjunction>
B<with this perldoc>, as the official API documentation explains in more depth
some of the functionality including required / optional parameters for certain
methods. L<https://developer.gocardless.com>, specifically the docs for the
v2 GoCardless API at L<https://developer.gocardless.com/api-reference>.

This module supports the resources of the GoCardless API (see
L</RESOURCE METHODS>), as well as being a back compatibility wrapper to allow
migration from the v1 (Basic) API (see L</BACK COMPATIBILITY METHODS>). Note
that new integrations should use Billing Requests rather than Redirect Flows
(which the back compatibility methods use), see
L</Setting up a mandate with a Billing Request>.

Also note this class also currently inherits from L<Business::GoCardless>
so has all attributes and methods available on that class (some of which may not
make sense from the context of the Pro API).

=head1 SYNOPSIS

The following examples show instantiating the object and getting a resource
(Payment in this case) to manipulate. For more examples see the t/004_end_to_end_pro.t
script, which can be run against the gocardless sandbox (or even live) endpoint
when given the necessary ENV variables.

    my $GoCardless = Business::GoCardless::Pro->new(
        token           => $your_gocardless_token
        client_details  => {
            base_url       => $gocardless_url, # defaults to https://api.gocardless.com
            webhook_secret => $secret,
        },
    );

    # create URL for a one off payment
    my $new_bill_url = $GoCardless->new_bill_url(
        session_token        => 'foo',
        description          => "Test Payment",
        success_redirect_url => "http://example.com/rflow/confirm?jwt=$jwt",
    );

    # having sent the user to the $new_bill_url and them having complete it,
    # we need to confirm the resource using the details sent by gocardless to
    # the redirect_uri (https://developer.gocardless.com/api-reference/#redirect-flows-complete-a-redirect-flow)
    my $Payment = $GoCardless->confirm_resource(
        redirect_flow_id => $id,
        type             => 'payment', # bill / payment / pre_auth / subscription
        amount           => 0,
        currency         => 'GBP',
    );

    # get a specfic Payment
    $Payment = $GoCardless->payment( $id );

    # cancel the Payment
    $Payment->cancel;

    # too late? maybe we should refund instead (note: needs to be enabled on GoCardless end)
    $Payment->refund;

    # or maybe it failed?
    $Payment->retry if $Payment->failed;

    # get a list of Payment objects (filter optional: https://developer.gocardless.com/#filtering)
    my @payments = $GoCardless->payments( %filter );

    # on any resource object:
    my %data = $Payment->to_hash;
    my $json = $Payment->to_json;

=head1 PAGINATION

Any methods marked as B<pager> have a dual interface, when called in list context
they will return the first page of resource objects (50 by default, you can pass
a C<limit> filter of up to 500), when called in scalar context they will return a
L<Business::GoCardless::Paginator> object allowing you to iterate through all the
objects using the API's cursor based pagination:

    # get a list of L<Business::GoCardless::Payment> objects
    # (filter optional: https://developer.gocardless.com/#filtering)
    my @payments = $GoCardless->payments( %filter );

    # or using the Business::GoCardless::Paginator object:
    my $Pager = $GoCardless->payments;

    while( my @payments = $Pager->next ) {
        foreach my $Payment ( @payments ) {
            ...
        }
    }

=cut

use strict;
use warnings;

use Carp qw/ confess /;
use Encode ();
use Moo;
extends 'Business::GoCardless';

use Business::GoCardless::Payment;
use Business::GoCardless::RedirectFlow;
use Business::GoCardless::Subscription;
use Business::GoCardless::Customer;
use Business::GoCardless::Webhook::V2;
use Business::GoCardless::Exception;

=head1 ATTRIBUTES

All attributes are inherited from L<Business::GoCardless>.

=cut

has api_version => (
    is       => 'ro',
    required => 0,
    default  => sub { 2 },
);

=head1 Payment Methods

=head2 payment

Get an individual payment, returns a L<Business::GoCardless::Payment> object:

    my $Payment = $GoCardless->payment( $id );

=head2 payments (B<pager>)

Get a list of Payment objects (%filter is optional)

    my @payments = $GoCardless->payments( %filter );

=head2 create_payment

Create a payment with the passed params

    my $Payment = $GoCardless->create_payment(
        "amount"      => 100,
        "currency"    => "GBP",
        "charge_date" => "2014-05-19",
        "reference"   => "WINEBOX001",
        "metadata"    => {
          "order_dispatch_date" => "2014-05-22"
        },
        "links" => {
          "mandate"   => "MD123"
        }
    );

As with all of the create methods you can pass an C<idempotency_key>, see
L</IDEMPOTENCY KEYS>.

=cut

sub payment {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Payment','payments' );
}

sub payments {
    my ( $self,%filters ) = @_;
    return $self->_list( 'payments',\%filters );
}

sub create_payment {
    my ( $self,%params ) = @_;
    return $self->_create( 'payments',\%params );
}

=head1 Subscription Methods

=head2 subscription

Get an individual subscription, returns a L<Business::GoCardless::Subscrption> object:

    my $Subscription = $GoCardless->subscription( $id );

=head2 subscriptions (B<pager>)

Get a list of Subscription objects (%filter is optional)

    my @subscriptions = $GoCardless->subscriptions( %filter );

=cut

sub subscription {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Subscription','subscriptions' );
}

sub subscriptions {
    my ( $self,%filters ) = @_;
    return $self->_list( 'subscriptions',\%filters );
}

=head1 RedirectFlow Methods

See L<Business::GoCardless::RedirectFlow> for more information on RedirectFlow operations.

=head2 pre_authorization

Get an individual redirect flow, returns a L<Business::GoCardless::RedirectFlow> object:

    my $RedirectFlow = $GoCardless->pre_authorization( $id );

=head2 pre_authorizations (B<pager>)

This is meaningless in the v2 API so will throw an exception if called.

=cut

sub pre_authorization {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'RedirectFlow','redirect_flows' );
};

sub pre_authorizations {
    Business::GoCardless::Exception->throw({
        message => "->pre_authorizations is no longer meaningful in the Pro API",
    });
};

=head1 Mandate Methods

See L<Business::GoCardless::Mandate> for more information on Mandate operations.

=head2 mandate

Get an individual mandate, returns a L<Business::GoCardless::Mandate> object:

    my $Mandate = $GoCardless->mandate( $id );

=cut

sub mandate {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Mandate','mandates' );
}

=head1 Customer Methods

See L<Business::GoCardless::Customer> for more information on Customer operations.

=head2 customer

Get an individual customer, returns a L<Business::GoCardless::Customer>.

    my $Customer = $GoCardless->customer( $id );

=head2 customers (B<pager>)

Get a list of L<Business::GoCardless::Customer> objects.

    my @customers = $GoCardless->customers;

=cut

sub customer {
    my ( $self,$id ) = @_;
    return $self->_generic_find_obj( $id,'Customer','customers' );
}

sub customers {
    my ( $self,%filters ) = @_;
    return $self->_list( 'customers',\%filters );
}

=head1 Webhook Methods

See L<Business::GoCardless::Webhook::V2> for more information on Webhook operations.

=head2 webhooks (B<pager>)

Get a list of L<Business::GoCardless::Webhook::V2> objects.

    my @webhooks = $GoCardless->webhooks

=cut

sub webhooks {
    my ( $self,%filters ) = @_;
    return $self->_list( 'webhooks',\%filters );
}

=head2 webhook

Get a L<Business::GoCardless::Webhook::V2> object from the data sent to you via a
GoCardless webhook:

    my $Webhook = $GoCardless->webhook( $json_data,$signature );

Note that GoCardless may continue to send old style webhooks even after you have
migrated from the Basic to the Pro API, so to handle this the logic in this method
will check the payload and if it is a legacy webhook will return a legacy Webhook
object. You can check this like so:

    if ( $Webhook->is_legacy ) {
        # process webhook using older legacy code
        ...
    } else {
        # process webhook using new style code
        ...
    }

=cut

sub webhook {
    my ( $self,$data,$signature ) = @_;

    my $webhook = Business::GoCardless::Webhook::V2->new(
        client     => $self->client,
        json       => $data,
        # load ordering handled by setting _signature rather than signature
        # signature will be set in the json trigger
        _signature => $signature,
    );

    return $webhook->has_legacy_data
        ? $webhook->legacy_webhook
        : $webhook;
}

# payout methods are in the SUPER class
=head1 Payout Methods

See L<Business::GoCardless::Payout> for more information on Payout operations.

=head2 payouts (B<pager>)

Get a list of L<Business::GoCardless::Payout> objects.

    my @payouts = $GoCardless->payouts

=head2 payout

Get an individual payout, returns a L<Business::GoCardless::Payout> object:

    my $Payout = $GoCardless->payout( $id );

=cut

=head1 RESOURCE METHODS

Methods for the resources of the Pro API follow the same pattern. For example
for billing requests:

    # get a single resource, returns a Business::GoCardless::BillingRequest
    my $BillingRequest = $GoCardless->billing_request( $id );

    # get a list of resources (pager), %filters are optional
    my @billing_requests = $GoCardless->billing_requests( %filters );

    # create a resource, returns a Business::GoCardless::BillingRequest
    my $BillingRequest = $GoCardless->create_billing_request( %params );

Operations on a resource (cancel, update, etc) are methods on the resource
objects, see the documentation of each resource class for these. The parameters
and filters are as documented in the GoCardless API reference. Note that some of
the endpoints are restricted, for example to GoCardless Embed customers or to
those with custom payment pages enabled, see the GoCardless API reference for
details.

=head2 Setting up a mandate with a Billing Request

Billing Requests have replaced Redirect Flows, for example to set up a mandate
using the GoCardless hosted payment pages:

    my $BillingRequest = $GoCardless->create_billing_request(
        mandate_request => { scheme => 'bacs' },
    );

    my $Flow = $BillingRequest->create_flow(
        redirect_uri => 'https://example.com/mandate/complete',
        exit_uri     => 'https://example.com/mandate/exit',
    );

    # send the customer to $Flow->authorisation_url, once they have completed
    # the flow GoCardless will send you a billing_requests fulfilled webhook
    # (or you can check the billing request):

    $BillingRequest = $GoCardless->billing_request( $BillingRequest->id );

    if ( $BillingRequest->fulfilled ) {
        my $Mandate = $GoCardless->mandate( $BillingRequest->mandate_id );
        ...
    }

=head1 IDEMPOTENCY KEYS

All of the create methods take an optional C<idempotency_key> parameter, which
is sent as the C<Idempotency-Key> header rather than in the request body. If you
don't pass one a random key is generated for the request. See
L<Business::GoCardless::Client/IDEMPOTENCY KEYS> for more details.

    my $Payment = $GoCardless->create_payment(
        %params,
        idempotency_key => $your_unique_key,
    );

=head2 Mandates

See L<Business::GoCardless::Mandate>

    my @mandates = $GoCardless->mandates( %filters );
    my $Mandate = $GoCardless->create_mandate( %params );

=head2 Subscriptions

See L<Business::GoCardless::Subscription>

    my $Subscription = $GoCardless->create_subscription( %params );

=head2 Customers

See L<Business::GoCardless::Customer>

    my $Customer = $GoCardless->create_customer( %params );

=head2 Refunds

See L<Business::GoCardless::Refund>

    my $Refund = $GoCardless->refund( $id );
    my @refunds = $GoCardless->refunds( %filters );
    my $Refund = $GoCardless->create_refund( %params );

=head2 Events

See L<Business::GoCardless::Webhook::Event>

    my $Event = $GoCardless->event( $id );
    my @events = $GoCardless->events( %filters );

=head2 Billing Requests

See L<Business::GoCardless::BillingRequest>

    my $BillingRequest = $GoCardless->billing_request( $id );
    my @billing_requests = $GoCardless->billing_requests( %filters );
    my $BillingRequest = $GoCardless->create_billing_request( %params );

=head2 Billing Request Flows

See L<Business::GoCardless::BillingRequestFlow>

    my $BillingRequestFlow = $GoCardless->create_billing_request_flow( %params );

=head2 Billing Request Templates

See L<Business::GoCardless::BillingRequestTemplate>

    my $BillingRequestTemplate = $GoCardless->billing_request_template( $id );
    my @billing_request_templates = $GoCardless->billing_request_templates( %filters );
    my $BillingRequestTemplate = $GoCardless->create_billing_request_template( %params );

=head2 Bank Authorisations

See L<Business::GoCardless::BankAuthorisation>

    my $BankAuthorisation = $GoCardless->bank_authorisation( $id );
    my $BankAuthorisation = $GoCardless->create_bank_authorisation( %params );

=head2 Institutions

See L<Business::GoCardless::Institution>

    my @institutions = $GoCardless->institutions( %filters );

=head2 Customer Bank Accounts

See L<Business::GoCardless::CustomerBankAccount>

    my $CustomerBankAccount = $GoCardless->customer_bank_account( $id );
    my @customer_bank_accounts = $GoCardless->customer_bank_accounts( %filters );
    my $CustomerBankAccount = $GoCardless->create_customer_bank_account( %params );

=head2 Bank Details Lookups

See L<Business::GoCardless::BankDetailsLookup>

    my $BankDetailsLookup = $GoCardless->create_bank_details_lookup( %params );

=head2 Creditors

See L<Business::GoCardless::Creditor>

    my $Creditor = $GoCardless->creditor( $id );
    my @creditors = $GoCardless->creditors( %filters );
    my $Creditor = $GoCardless->create_creditor( %params );

=head2 Creditor Bank Accounts

See L<Business::GoCardless::CreditorBankAccount>

    my $CreditorBankAccount = $GoCardless->creditor_bank_account( $id );
    my @creditor_bank_accounts = $GoCardless->creditor_bank_accounts( %filters );
    my $CreditorBankAccount = $GoCardless->create_creditor_bank_account( %params );

=head2 Verification Details

See L<Business::GoCardless::VerificationDetail>

    my @verification_details = $GoCardless->verification_details( %filters );
    my $VerificationDetail = $GoCardless->create_verification_detail( %params );

=head2 Instalment Schedules

See L<Business::GoCardless::InstalmentSchedule>

    my $InstalmentSchedule = $GoCardless->instalment_schedule( $id );
    my @instalment_schedules = $GoCardless->instalment_schedules( %filters );

=head2 Tax Rates

See L<Business::GoCardless::TaxRate>

    my $TaxRate = $GoCardless->tax_rate( $id );
    my @tax_rates = $GoCardless->tax_rates( %filters );

=head2 Mandate Imports

See L<Business::GoCardless::MandateImport>

    my $MandateImport = $GoCardless->mandate_import( $id );
    my $MandateImport = $GoCardless->create_mandate_import( %params );

=head2 Mandate Import Entries

See L<Business::GoCardless::MandateImportEntry>

    my @mandate_import_entries = $GoCardless->mandate_import_entries( %filters );
    my $MandateImportEntry = $GoCardless->create_mandate_import_entry( %params );

=head2 Transferred Mandates

See L<Business::GoCardless::TransferredMandate>

    my $TransferredMandate = $GoCardless->transferred_mandate( $id );

=head2 Payout Items

See L<Business::GoCardless::PayoutItem>

    my @payout_items = $GoCardless->payout_items( %filters );

=head2 Balances

See L<Business::GoCardless::Balance>

    my @balances = $GoCardless->balances( %filters );

=head2 Negative Balance Limits

See L<Business::GoCardless::NegativeBalanceLimit>

    my @negative_balance_limits = $GoCardless->negative_balance_limits( %filters );

=head2 Currency Exchange Rates

See L<Business::GoCardless::CurrencyExchangeRate>

    my @currency_exchange_rates = $GoCardless->currency_exchange_rates( %filters );

=head2 Blocks

See L<Business::GoCardless::Block>

    my $Block = $GoCardless->block( $id );
    my @blocks = $GoCardless->blocks( %filters );
    my $Block = $GoCardless->create_block( %params );

=head2 Logos

See L<Business::GoCardless::Logo>

    my $Logo = $GoCardless->create_logo( %params );

=head2 Payer Themes

See L<Business::GoCardless::PayerTheme>

    my $PayerTheme = $GoCardless->create_payer_theme( %params );

=head2 Scheme Identifiers

See L<Business::GoCardless::SchemeIdentifier>

    my $SchemeIdentifier = $GoCardless->scheme_identifier( $id );
    my @scheme_identifiers = $GoCardless->scheme_identifiers( %filters );
    my $SchemeIdentifier = $GoCardless->create_scheme_identifier( %params );

=head2 Exports

See L<Business::GoCardless::Export>

    my $Export = $GoCardless->export( $id );
    my @exports = $GoCardless->exports( %filters );

=head2 Outbound Payments

See L<Business::GoCardless::OutboundPayment>

    my $OutboundPayment = $GoCardless->outbound_payment( $id );
    my @outbound_payments = $GoCardless->outbound_payments( %filters );
    my $OutboundPayment = $GoCardless->create_outbound_payment( %params );

=head2 Outbound Payment Imports

See L<Business::GoCardless::OutboundPaymentImport>

    my $OutboundPaymentImport = $GoCardless->outbound_payment_import( $id );
    my @outbound_payment_imports = $GoCardless->outbound_payment_imports( %filters );
    my $OutboundPaymentImport = $GoCardless->create_outbound_payment_import( %params );

=head2 Outbound Payment Import Entries

See L<Business::GoCardless::OutboundPaymentImportEntry>

    my @outbound_payment_import_entries = $GoCardless->outbound_payment_import_entries( %filters );

=head2 Bank Account Holder Verifications

See L<Business::GoCardless::BankAccountHolderVerification>

    my $BankAccountHolderVerification = $GoCardless->bank_account_holder_verification( $id );
    my $BankAccountHolderVerification = $GoCardless->create_bank_account_holder_verification( %params );

=head2 Payment Accounts

See L<Business::GoCardless::PaymentAccount>

    my $PaymentAccount = $GoCardless->payment_account( $id );
    my @payment_accounts = $GoCardless->payment_accounts( %filters );

=head2 Payment Account Transactions

See L<Business::GoCardless::PaymentAccountTransaction>

    my $PaymentAccountTransaction = $GoCardless->payment_account_transaction( $id );

=cut

# the class for each of the resources (keyed on the API endpoint), and the
# path for the resource if it isn't the same as the endpoint
my %RESOURCE_CLASS = (
    payments       => 'Payment',
    redirect_flows => 'RedirectFlow',
    customers      => 'Customer',
    subscriptions  => 'Subscription',
    webhooks       => 'Webhook::V2',
    payouts        => 'Payout',
);

my %RESOURCE_PATH;

# most of the resources follow the same pattern in the API, so we generate the
# methods for them from the following. for each resource the operations are:
#
#   get    => $Pro->$singular( $id )
#   list   => $Pro->$endpoint( %filters ) (pager)
#   create => $Pro->create_$singular( %params )
#
my @RESOURCES = (
    # endpoint                         class                            singular                           operations
    [ mandates                          => 'Mandate'                       => mandate                          => qw/ list create / ],
    [ subscriptions                     => 'Subscription'                  => subscription                     => qw/ create / ],
    [ customers                         => 'Customer'                      => customer                         => qw/ create / ],
    [ refunds                           => 'Refund'                        => refund                           => qw/ get list create / ],
    [ events                            => 'Webhook::Event'                => event                            => qw/ get list / ],
    [ billing_requests                  => 'BillingRequest'                => billing_request                  => qw/ get list create / ],
    [ billing_request_flows             => 'BillingRequestFlow'            => billing_request_flow             => qw/ create / ],
    [ billing_request_templates         => 'BillingRequestTemplate'        => billing_request_template         => qw/ get list create / ],
    [ bank_authorisations               => 'BankAuthorisation'             => bank_authorisation               => qw/ get create / ],
    [ institutions                      => 'Institution'                   => institution                      => qw/ list / ],
    [ customer_bank_accounts            => 'CustomerBankAccount'           => customer_bank_account            => qw/ get list create / ],
    [ bank_details_lookups              => 'BankDetailsLookup'             => bank_details_lookup              => qw/ create / ],
    [ creditors                         => 'Creditor'                      => creditor                         => qw/ get list create / ],
    [ creditor_bank_accounts            => 'CreditorBankAccount'           => creditor_bank_account            => qw/ get list create / ],
    [ verification_details              => 'VerificationDetail'            => verification_detail              => qw/ list create / ],
    [ instalment_schedules              => 'InstalmentSchedule'            => instalment_schedule              => qw/ get list / ],
    [ tax_rates                         => 'TaxRate'                       => tax_rate                         => qw/ get list / ],
    [ mandate_imports                   => 'MandateImport'                 => mandate_import                   => qw/ get create / ],
    [ mandate_import_entries            => 'MandateImportEntry'            => mandate_import_entry             => qw/ list create / ],
    [ mandate_pdfs                      => 'MandatePdf'                    => mandate_pdf                      => qw// ],
    [ transferred_mandates              => 'TransferredMandate'            => transferred_mandate              => qw/ get / ],
    [ payout_items                      => 'PayoutItem'                    => payout_item                      => qw/ list / ],
    [ balances                          => 'Balance'                       => balance                          => qw/ list / ],
    [ negative_balance_limits           => 'NegativeBalanceLimit'          => negative_balance_limit           => qw/ list / ],
    [ currency_exchange_rates           => 'CurrencyExchangeRate'          => currency_exchange_rate           => qw/ list / ],
    [ blocks                            => 'Block'                         => block                            => qw/ get list create / ],
    [ logos                             => 'Logo'                          => logo                             => qw/ create / ],
    [ payer_themes                      => 'PayerTheme'                    => payer_theme                      => qw/ create / ],
    [ scheme_identifiers                => 'SchemeIdentifier'              => scheme_identifier                => qw/ get list create / ],
    [ exports                           => 'Export'                        => export                           => qw/ get list / ],
    [ outbound_payments                 => 'OutboundPayment'               => outbound_payment                 => qw/ get list create / ],
    [ outbound_payment_imports          => 'OutboundPaymentImport'         => outbound_payment_import          => qw/ get list create / ],
    [ outbound_payment_import_entries   => 'OutboundPaymentImportEntry'    => outbound_payment_import_entry    => qw/ list / ],
    [ bank_account_holder_verifications => 'BankAccountHolderVerification' => bank_account_holder_verification => qw/ get create / ],
    [ payment_accounts                  => 'PaymentAccount'                => payment_account                  => qw/ get list / ],
    [ payment_account_transactions      => 'PaymentAccountTransaction'     => payment_account_transaction      => qw/ get / ],
    [ bank_account_details              => 'BankAccountDetail'             => bank_account_detail              => qw// ],
    [ customer_notifications            => 'CustomerNotification'          => customer_notification            => qw// ],
);

$RESOURCE_PATH{logos}        = '/branding/logos';
$RESOURCE_PATH{payer_themes} = '/branding/payer_themes';

foreach my $resource ( @RESOURCES ) {

    my ( $endpoint,$class,$singular,@operations ) = @{ $resource };

    $RESOURCE_CLASS{$endpoint} = $class;

    my %methods = (
        get    => [ $singular => sub {
            my ( $self,$id ) = @_;
            return $self->_get( $endpoint,$id );
        } ],
        list   => [ $endpoint => sub {
            my ( $self,%filters ) = @_;
            return $self->_list( $endpoint,\%filters );
        } ],
        create => [ "create_$singular" => sub {
            my ( $self,%params ) = @_;
            return $self->_create( $endpoint,\%params );
        } ],
    );

    foreach my $operation ( @operations ) {

        my ( $method,$code ) = @{ $methods{$operation} };

        # make sure we don't clobber any explicitly defined methods
        confess( "$method is already defined" )
            if __PACKAGE__->can( $method );

        no strict 'refs';
        *{ __PACKAGE__ . "::$method" } = $code;
    }
}

# load all of the resource classes
eval "require Business::GoCardless::$_; 1" || die $@
    for sort values( %RESOURCE_CLASS );

sub _new_resource {
    my ( $self,$endpoint,$data ) = @_;

    my $class = "Business::GoCardless::$RESOURCE_CLASS{$endpoint}";

    return $endpoint eq 'webhooks'
        ? $class->_new_from_api( $self->client,$data )
        : $class->new( client => $self->client,%{ $data // {} } );
}

sub _get {
    my ( $self,$endpoint,$id,$headers ) = @_;

    my $path = $RESOURCE_PATH{$endpoint} // "/$endpoint";
    my $data = $self->client->api_get( "$path/$id",undef,$headers );

    return $self->_new_resource( $endpoint,$data->{$endpoint} );
}

sub _create {
    my ( $self,$endpoint,$params,%opts ) = @_;

    my $data = $self->_create_request( $endpoint,$params,%opts );
    return $self->_new_resource( $endpoint,$data->{$endpoint} );
}

sub _create_request {
    my ( $self,$endpoint,$params,%opts ) = @_;

    my %params  = %{ $params // {} };
    my %headers = %{ $opts{headers} // {} };

    # not part of the request body, see IDEMPOTENCY KEYS
    my $key = delete( $params{idempotency_key} );
    $headers{'Idempotency-Key'} = $key if defined $key;

    my $path = $opts{path} // $RESOURCE_PATH{$endpoint} // "/$endpoint";

    return $self->client->api_post(
        $path,{ $endpoint => \%params },\%headers
    );
}

sub _list {
    my ( $self,$endpoint,$filters,$path ) = @_;

    $filters //= {};
    $path    //= $RESOURCE_PATH{$endpoint} // "/$endpoint";

    my $class = "Business::GoCardless::$RESOURCE_CLASS{$endpoint}";

    my $uri_for = sub {
        my ( %cursor ) = @_;

        # cursor params replace any passed in the original filters
        my %params = ( %{ $filters },%cursor );
        delete( @params{ grep { ! defined $params{$_} } keys %params } );

        return keys( %params )
            ? "$path?" . $self->client->normalize_params( \%params )
            : $path;
    };

    # the v2 API uses cursor based pagination, so we construct the links for
    # next / previous / first from the meta data in each page of results
    my $page_loader = sub {
        my ( $uri ) = @_;

        my ( $data ) = $self->client->api_get( $uri );
        my $cursors  = $data->{meta}{cursors} // {};

        my @objects = map { $self->_new_resource( $endpoint,$_ ) }
            @{ $data->{$endpoint} // [] };

        my $links = {
            first => $uri_for->( before => undef,after => undef ),
            ( $cursors->{after}  ? ( next     => $uri_for->( after  => $cursors->{after},before => undef ) ) : () ),
            ( $cursors->{before} ? ( previous => $uri_for->( before => $cursors->{before},after => undef ) ) : () ),
        };

        return ( \@objects,$links,$data->{meta} // {} );
    };

    my ( $objects,$links,$info ) = $page_loader->( $uri_for->() );

    return wantarray ? ( @{ $objects } ) : Business::GoCardless::Paginator->new(
        class       => $class,
        client      => $self->client,
        links       => $links,
        info        => $info,
        objects     => $objects,
        page_loader => $page_loader,
    );
}

=head1 OTHER RESOURCE METHODS

The following methods are for API endpoints that don't follow the standard
pattern of the L</RESOURCE METHODS>.

=head2 create_billing_request_with_actions

Create a billing request and perform actions on it in a single request (this
is restricted to custom payment pages, and doesn't support ACH/PAD). Returns a
L<Business::GoCardless::BillingRequest> object, and in list context also the
L<Business::GoCardless::BankAuthorisation> if one was created:

    my ( $BillingRequest,$BankAuthorisation )
        = $GoCardless->create_billing_request_with_actions(
            payment_request => { amount => 1000,currency => 'GBP' },
            actions         => {
                collect_customer_details  => { ... },
                create_bank_authorisation => JSON::true,
            },
        );

=head2 create_instalment_schedule_with_dates

Create an L<Business::GoCardless::InstalmentSchedule> with the dates of each
instalment:

    my $Schedule = $GoCardless->create_instalment_schedule_with_dates(
        name         => 'Bike',
        currency     => 'GBP',
        total_amount => 3000,
        instalments  => [
            { charge_date => '2026-11-01',amount => 1500 },
            { charge_date => '2026-12-01',amount => 1500 },
        ],
        links => { mandate => $mandate_id },
    );

=head2 create_instalment_schedule_with_schedule

Create an L<Business::GoCardless::InstalmentSchedule> with a schedule from
which the instalment dates are calculated:

    my $Schedule = $GoCardless->create_instalment_schedule_with_schedule(
        name         => 'Bike',
        currency     => 'GBP',
        total_amount => 3000,
        instalments  => {
            start_date    => '2026-11-01',
            interval      => 1,
            interval_unit => 'monthly',
            amounts       => [ 1500,1500 ],
        },
        links => { mandate => $mandate_id },
    );

Instalment schedules are created asynchronously, so the status will be
C<pending> until it becomes C<active> (or C<creation_failed>).

=head2 create_mandate_pdf

Create a L<Business::GoCardless::MandatePdf>, the PDF can be in a language
other than English by passing C<accept_language>:

    my $Pdf = $GoCardless->create_mandate_pdf(
        links           => { mandate => $mandate_id },
        accept_language => 'fr', # optional
    );

    my $url = $Pdf->url;

=head2 bank_account_detail

Get the encrypted bank account details of a customer bank account (restricted
to the Encrypted Bank Details Access upgrade), you must pass the ID of your
public key. Returns a L<Business::GoCardless::BankAccountDetail> object:

    my $Detail = $GoCardless->bank_account_detail( $bank_account_id,$key_id );

=head2 funds_available

Check if funds are available for a VRP mandate, returns true or false:

    if ( $GoCardless->funds_available( $mandate_id,$amount ) ) {
        ...
    }

=head2 block_by_ref

Create blocks for the details of a customer or mandate, returns a list of the
L<Business::GoCardless::Block> objects created:

    my @blocks = $GoCardless->block_by_ref(
        reference_type  => 'customer',
        reference_value => $customer_id,
        reason_type     => 'no_intent_to_pay',
    );

=head2 run_scenario_simulator

Run a scenario simulator against a resource (sandbox only), for example to
simulate a payment being paid out:

    $GoCardless->run_scenario_simulator( 'payment_paid_out',$payment_id );

See L<https://developer.gocardless.com/api-reference/#testing-scenario-simulators>
for the available scenarios.

=head2 create_outbound_payment_withdrawal

Create an L<Business::GoCardless::OutboundPayment> to withdraw funds to your
verified business bank account:

    my $Withdrawal = $GoCardless->create_outbound_payment_withdrawal(
        amount => 1000,
        scheme => 'faster_payments',
    );

=head2 outbound_payment_stats

Get the statistics of your outbound payments, returns a hashref:

    my $stats = $GoCardless->outbound_payment_stats;

=head2 payment_account_transactions (B<pager>)

Get a list of the L<Business::GoCardless::PaymentAccountTransaction> objects
for a payment account:

    my @transactions = $GoCardless->payment_account_transactions(
        $payment_account_id,
        value_date_from => '2026-10-01',
        value_date_to   => '2026-10-31',
    );

=head2 handle_customer_notification

Handle a customer notification (meaning you have sent it rather than
GoCardless), returns a L<Business::GoCardless::CustomerNotification> object:

    $GoCardless->handle_customer_notification( $notification_id );

=cut

sub create_billing_request_with_actions {
    my ( $self,%params ) = @_;

    my $data = $self->_create_request(
        'billing_request_with_actions',\%params,
        path => '/billing_requests/create_with_actions',
    )->{billing_request_with_actions} // {};

    my $BillingRequest = $self->_new_resource(
        'billing_requests',$data->{billing_requests}
    );

    my $BankAuthorisation = $data->{bank_authorisations}
        ? $self->_new_resource( 'bank_authorisations',$data->{bank_authorisations} )
        : undef;

    return wantarray ? ( $BillingRequest,$BankAuthorisation ) : $BillingRequest;
}

sub create_instalment_schedule_with_dates {
    my ( $self,%params ) = @_;
    return $self->_create(
        'instalment_schedules',\%params,
        path => '/instalment_schedules/create_with_dates',
    );
}

sub create_instalment_schedule_with_schedule {
    my ( $self,%params ) = @_;
    return $self->_create(
        'instalment_schedules',\%params,
        path => '/instalment_schedules/create_with_schedule',
    );
}

sub create_mandate_pdf {
    my ( $self,%params ) = @_;

    my $language = delete( $params{accept_language} );

    return $self->_create(
        'mandate_pdfs',\%params,
        ( $language ? ( headers => { 'Accept-Language' => $language } ) : () ),
    );
}

sub bank_account_detail {
    my ( $self,$id,$key_id ) = @_;

    $key_id // confess( "key_id is required for bank_account_detail" );

    my $Detail = $self->_get( 'bank_account_details',$id,{ 'Gc-Key-Id' => $key_id } );
    $Detail->id( $id );

    return $Detail;
}

sub funds_available {
    my ( $self,$mandate_id,$amount ) = @_;

    my $data = $self->client->api_get(
        "/funds_availability/$mandate_id?"
            . $self->client->normalize_params( { amount => $amount } )
    );

    # the docs show the response as unwrapped, so handle both
    my $availability = ref( $data->{funds_availabilities} ) eq 'HASH'
        ? $data->{funds_availabilities}
        : $data;

    return $availability->{available} ? 1 : 0;
}

sub block_by_ref {
    my ( $self,%params ) = @_;

    my $data = $self->_create_request(
        'blocks',\%params,path => '/blocks/block_by_ref',
    );

    return map { $self->_new_resource( 'blocks',$_ ) } @{ $data->{blocks} // [] };
}

sub run_scenario_simulator {
    my ( $self,$scenario,$resource_id ) = @_;

    $self->client->api_post(
        "/scenario_simulators/$scenario/actions/run",
        { data => { links => { resource => $resource_id } } },
    );

    return 1;
}

sub create_outbound_payment_withdrawal {
    my ( $self,%params ) = @_;
    return $self->_create(
        'outbound_payments',\%params,
        path => '/outbound_payments/withdrawal',
    );
}

sub outbound_payment_stats {
    my ( $self,%filters ) = @_;

    my $uri = '/outbound_payments/stats';
    $uri .= '?' . $self->client->normalize_params( \%filters ) if keys %filters;

    my $data = $self->client->api_get( $uri );

    return ref( $data->{outbound_payments} ) eq 'HASH'
        ? $data->{outbound_payments}
        : $data;
}

sub payment_account_transactions {
    my ( $self,$payment_account_id,%filters ) = @_;
    return $self->_list(
        'payment_account_transactions',\%filters,
        "/payment_accounts/$payment_account_id/transactions",
    );
}

sub handle_customer_notification {
    my ( $self,$id ) = @_;
    return $self->_new_resource( 'customer_notifications',{ id => $id } )->handle;
}

################################################################
#
# BACK COMPATIBILITY WITH V1 (BASIC) API SECTION FOLLOWS
# the Pro version of the API is built on "redirect flows" when
# using their hosted pages, so we can make it back compatible
#
################################################################

=head1 BACK COMPATIBILITY METHODS

These methods are provided for those who want to move from the v1 (Basic)
API with minimal changes in your application code.

The new_bill_url, new_pre_authorization_url, and new_subscription_url methods
all return a URL for redirecting the user to to complete a direct debit mandate
that will allow you to setup payments, and they all take the same parameters.

See L<https://developer.gocardless.com/api-reference/#redirect-flows-create-a-redirect-flow>
for more information.

=head2 new_bill_url

Return a redirect flow URL for setting up a one off payment

=head2 new_pre_authorization_url

Return a redirect flow URL for setting up a mandate

=head2 new_subscription_url

Return a redirect flow URL for setting up a subscription

All three methods take the following parameters:

    my $url = $GoCardless->new_bill_url(

        # required
        session_token        => $session_token,
        success_redirect_url => $success_callback_url,

        # optional
        scheme               => $direct_debit_scheme
        description          => $description,
        prefilled_customer   => { ... }, # see documentation above
        links                => { ... }, # see documentation above
    );

=cut

sub new_bill_url {
    my ( $self,%params ) = @_;
    return $self->_redirect_flow_from_legacy_params( 'bill',%params );
}

sub new_pre_authorization_url {
    my ( $self,%params ) = @_;
    return $self->_redirect_flow_from_legacy_params( 'pre_authorization',%params );
}

sub new_subscription_url {
    my ( $self,%params ) = @_;
    return $self->_redirect_flow_from_legacy_params( 'subscription',%params );
}

sub _redirect_flow_from_legacy_params {
    my ( $self,$type,%params ) = @_;

    for ( qw/ session_token success_redirect_url / ) {
        $params{$_} // confess( "$_ is required for new_${type}_url (v2)" );
    }

    # we can't just pass through %params as GoCardless will throw an error
    # if it receives any unknown parameters
    return $self->client->_new_redirect_flow_url({
        ( $params{scheme}                       ? ( scheme => $params{scheme} ) : () ),
        ( $params{description} // $params{name} ? ( description => $params{description} // $params{name} ) : () ),
        session_token        => $params{session_token},
        success_redirect_url => $params{success_redirect_url},

        ( $params{prefilled_customer}
            ? (
                prefilled_customer   => { %{ $params{prefilled_customer} } }
            )
            : (
                prefilled_customer   => {

                    # only include fields that are defined in the prefilled_customer, otherwise
                    # gocardless will try to assume the user's location and thus the scheme
                    ( $params{user}{billing_address1} ? ( address_line1 => $params{user}{billing_address1} ) : () ),
                    ( $params{user}{billing_address2} ? ( address_line2 => $params{user}{billing_address2} ) : () ),
                    ( $params{user}{billing_address3} ? ( address_line3 => $params{user}{billing_address3} ) : () ),
                    ( $params{user}{billing_town}     ? ( city          => $params{user}{billing_town} ) : () ),
                    ( $params{user}{billing_postcode} ? ( postal_code   => $params{user}{billing_postcode} ) : () ),

                    ( $params{user}{last_name}        ? ( family_name   => $params{user}{last_name} ) : () ),
                    ( $params{user}{first_name}       ? ( given_name    => $params{user}{first_name} ) : () ),

                    (
                        map { ( $params{user}{$_} ? ( $_ => $params{user}{$_} ) : () ) }
                        qw/ city company_name country_code email given_name language region swedish_identity_number postal_code /
                    ),
                },
            )
        ),

        (
            $params{links}{creditor}
                ? ( links => { creditor => $params{links}{creditor} } )
                : ()
        ),
    });
}

=head2 confirm_resource

After a user completes the form in the redirect flow (using a URL generated from
one of the new_.*?url methods above) GoCardless will redirect them back to the
success_redirect_url with a redirect_flow_id, at which point you can call this
method to confirm the mandate and set up a one off payment, subscription, etc

The object returned will depend on the C<type> parameter passed to the method

    my $Payment = $GoCardless->confirm_resource(

        # required 
        redirect_flow_id => $redirect_flow_id,
        type             => 'payment', # one of bill, payment, pre_auth, subscription
        amount           => 0,
        currency         => 'GBP',

        # required in the case of type being "subscription"
        interval_unit    =>
        interval         =>
        start_at         =>
    );

=cut

# BACK COMPATIBILITY method, in which we (try to) return the correct object for
# the required type as this is how the v1 API works
sub confirm_resource {
    my ( $self,%params ) = @_;

    for ( qw/ redirect_flow_id type amount currency / ) {
        $params{$_} // confess( "$_ is required for confirm_resource (v2)" );
    }

    my $r_flow_id = $params{redirect_flow_id};
    my $type      = $params{type};
    my $amount    = $params{amount};
    my $currency  = $params{currency};
    my $int_unit  = $params{interval_unit};
    my $interval  = $params{interval};
    my $start_at  = $params{start_at};

    if ( my $RedirectFlow = $self->client->_confirm_redirect_flow( $r_flow_id ) ) {

        # now we have a confirmed redirect flow object we can create the
        # payment, subscription, whatever
        if ( $type =~ /bill|payment/i ) {

            # Bill -> Payment
            my $post_data = {
                payments => {
                    amount   => $amount,
                    currency => $currency,
                    links    => { mandate => ( $RedirectFlow->links // {} )->{mandate} },
                },
            };

            my $data = $self->client->api_post( "/payments",$post_data );

            return Business::GoCardless::Payment->new(
                client => $self->client,
                %{ $data->{payments} },
            );

        } elsif ( $type =~ /pre_auth/i ) {

            # a pre authorization is, effectively, a redirect flow
            return $RedirectFlow;

        } elsif ( $type =~ /subscription/i ) {

            my $post_data = {
                subscriptions => {
                    amount        => $amount,
                    currency      => $currency,
                    interval_unit => $int_unit,
                    interval      => $interval,
                    start_date    => $start_at,
                    links         => { mandate => ( $RedirectFlow->links // {} )->{mandate} },
                },
            };

            my $data = $self->client->api_post( "/subscriptions",$post_data );

            return Business::GoCardless::Subscription->new(
                client => $self->client,
                %{ $data->{subscriptions} },
            );
        }

        # don't know what to do, complain
        Business::GoCardless::Exception->throw({
            message => "Unknown type ($type) in ->confirm_resource",
        });
    }

    Business::GoCardless::Exception->throw({
        message => "Failed to get RedirectFlow for $r_flow_id",
    });
}

sub users { shift->customers( @_ ); }

=head1 SEE ALSO

L<Business::GoCardless>

L<Business::GoCardless::Resource>

L<Business::GoCardless::Payment>

L<Business::GoCardless::Payout>

L<Business::GoCardless::Client>

L<Business::GoCardless::Subscription>

L<Business::GoCardless::User>

L<Business::GoCardless::Webhook::V2>

=head1 AUTHOR

Lee Johnson - C<lee@payprop.com>

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself. If you would like to contribute documentation,
features, bug fixes, or anything else then please raise an issue / pull request:

    https://github.com/payprop/business-gocardless

=cut

1;

# vim: ts=4:sw=4:et
