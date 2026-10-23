#!perl

# tests for the resource methods of Business::GoCardless::Pro, and the
# operations on the resource objects, against a mocked API

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use HTTP::Response;
use JSON ();
use Encode ();
use FindBin qw/ $Bin /;
use Digest::SHA ();

use Business::GoCardless::Pro;

my $GoCardless = Business::GoCardless::Pro->new( token => 'foo' );

# monkey patching LWP here to make this test work without having to actually
# hit the endpoints - each request is recorded, and gets the next response
no warnings 'redefine';
no warnings 'once';

my ( @responses,@requests );

*LWP::UserAgent::request = sub {
    my ( $ua,$req ) = @_;
    push( @requests,{
        method  => $req->method,
        path    => $req->uri->path,
        query   => $req->uri->query,
        headers => $req->headers,
        body    => length( $req->content ) ? JSON->new->utf8->decode( $req->content ) : undef,
    } );
    my $data = shift( @responses ) // die "No more responses";
    my $res  = HTTP::Response->new( 200 );
    $res->content( Encode::encode_utf8( JSON->new->encode( $data ) ) );
    return $res;
};

sub _respond { @responses = @_; @requests = (); }

note( "get / list / create methods" );

# endpoint => [ class, singular, path (if different to endpoint), operations ]
my %resources = (
    mandates                          => [ 'Mandate',                       'mandate',                          undef,                   qw/ list create / ],
    subscriptions                     => [ 'Subscription',                  'subscription',                     undef,                   qw/ create / ],
    customers                         => [ 'Customer',                      'customer',                         undef,                   qw/ create / ],
    refunds                           => [ 'Refund',                        'refund',                           undef,                   qw/ get list create / ],
    events                            => [ 'Webhook::Event',                'event',                            undef,                   qw/ get list / ],
    billing_requests                  => [ 'BillingRequest',                'billing_request',                  undef,                   qw/ get list create / ],
    billing_request_flows             => [ 'BillingRequestFlow',            'billing_request_flow',             undef,                   qw/ create / ],
    billing_request_templates         => [ 'BillingRequestTemplate',        'billing_request_template',         undef,                   qw/ get list create / ],
    bank_authorisations               => [ 'BankAuthorisation',             'bank_authorisation',               undef,                   qw/ get create / ],
    institutions                      => [ 'Institution',                   'institution',                      undef,                   qw/ list / ],
    customer_bank_accounts            => [ 'CustomerBankAccount',           'customer_bank_account',            undef,                   qw/ get list create / ],
    bank_details_lookups              => [ 'BankDetailsLookup',             'bank_details_lookup',              undef,                   qw/ create / ],
    creditors                         => [ 'Creditor',                      'creditor',                         undef,                   qw/ get list create / ],
    creditor_bank_accounts            => [ 'CreditorBankAccount',           'creditor_bank_account',            undef,                   qw/ get list create / ],
    verification_details              => [ 'VerificationDetail',            'verification_detail',              undef,                   qw/ list create / ],
    instalment_schedules              => [ 'InstalmentSchedule',            'instalment_schedule',              undef,                   qw/ get list / ],
    tax_rates                         => [ 'TaxRate',                       'tax_rate',                         undef,                   qw/ get list / ],
    mandate_imports                   => [ 'MandateImport',                 'mandate_import',                   undef,                   qw/ get create / ],
    mandate_import_entries            => [ 'MandateImportEntry',            'mandate_import_entry',             undef,                   qw/ list create / ],
    transferred_mandates              => [ 'TransferredMandate',            'transferred_mandate',              undef,                   qw/ get / ],
    payout_items                      => [ 'PayoutItem',                    'payout_item',                      undef,                   qw/ list / ],
    balances                          => [ 'Balance',                       'balance',                          undef,                   qw/ list / ],
    negative_balance_limits           => [ 'NegativeBalanceLimit',          'negative_balance_limit',           undef,                   qw/ list / ],
    currency_exchange_rates           => [ 'CurrencyExchangeRate',          'currency_exchange_rate',           undef,                   qw/ list / ],
    blocks                            => [ 'Block',                         'block',                            undef,                   qw/ get list create / ],
    logos                             => [ 'Logo',                          'logo',                             '/branding/logos',       qw/ create / ],
    payer_themes                      => [ 'PayerTheme',                    'payer_theme',                      '/branding/payer_themes',qw/ create / ],
    scheme_identifiers                => [ 'SchemeIdentifier',              'scheme_identifier',                undef,                   qw/ get list create / ],
    exports                           => [ 'Export',                        'export',                           undef,                   qw/ get list / ],
    outbound_payments                 => [ 'OutboundPayment',               'outbound_payment',                 undef,                   qw/ get list create / ],
    outbound_payment_imports          => [ 'OutboundPaymentImport',         'outbound_payment_import',          undef,                   qw/ get list create / ],
    outbound_payment_import_entries   => [ 'OutboundPaymentImportEntry',    'outbound_payment_import_entry',    undef,                   qw/ list / ],
    bank_account_holder_verifications => [ 'BankAccountHolderVerification', 'bank_account_holder_verification', undef,                   qw/ get create / ],
    payment_accounts                  => [ 'PaymentAccount',                'payment_account',                  undef,                   qw/ get list / ],
    payment_account_transactions      => [ 'PaymentAccountTransaction',     'payment_account_transaction',      undef,                   qw/ get / ],
);

# events have required attributes
my %resource = (
    id            => 'ID123',
    created_at    => '2026-10-21T00:00:00.000Z',
    action        => 'created',
    resource_type => 'payments',
    links         => { payment => 'PM123' },
);

foreach my $endpoint ( sort keys %resources ) {

    my ( $short_class,$singular,$path,@operations ) = @{ $resources{$endpoint} };
    my $class = "Business::GoCardless::$short_class";
    $path //= "/$endpoint";

    foreach my $operation ( @operations ) {

        if ( $operation eq 'get' ) {

            _respond( { $endpoint => { %resource } } );
            my $Object = $GoCardless->$singular( 'ID123' );

            isa_ok( $Object,$class,"->$singular" );
            is( $Object->id,'ID123',"->$singular populates the object" );
            cmp_deeply(
                [ @{ $requests[0] }{ qw/ method path / } ],
                [ 'GET',"$path/ID123" ],
                "->$singular request"
            );

        } elsif ( $operation eq 'list' ) {

            _respond( {
                $endpoint => [ { %resource },{ %resource,id => 'ID456' } ],
                meta      => { cursors => { before => undef,after => undef },limit => 50 },
            } );
            my @objects = $GoCardless->$endpoint( limit => 2 );

            is( scalar( @objects ),2,"->$endpoint returns a list" );
            isa_ok( $objects[1],$class,"->$endpoint" );
            cmp_deeply(
                [ @{ $requests[0] }{ qw/ method path query / } ],
                [ 'GET',$path,'limit=2' ],
                "->$endpoint request"
            );

            _respond( { $endpoint => [ { %resource } ],meta => {} } );
            isa_ok(
                scalar( $GoCardless->$endpoint ),
                'Business::GoCardless::Paginator',
                "->$endpoint in scalar context"
            );

        } elsif ( $operation eq 'create' ) {

            my $method = "create_$singular";

            _respond( { $endpoint => { %resource } } );
            my $Object = $GoCardless->$method(
                name            => 'foo',
                idempotency_key => "key-$endpoint",
            );

            isa_ok( $Object,$class,"->$method" );
            cmp_deeply(
                [ @{ $requests[0] }{ qw/ method path body / } ],
                [ 'POST',$path,{ $endpoint => { name => 'foo' } } ],
                "->$method request"
            );
            is(
                $requests[0]{headers}->header( 'Idempotency-Key' ),
                "key-$endpoint",
                "->$method idempotency_key sent as header"
            );
        }
    }
}

note( "operations on resources" );

# class => [ endpoint, [ action, params ], ... ] ( 'update' for PUT )
my %operations = (
    Payment              => [ payments               => [ cancel => { metadata => { a => 1 } } ],[ retry => {} ],[ 'update' ] ],
    Mandate              => [ mandates               => [ cancel => {} ],[ reinstate => { metadata => { a => 1 } } ],[ 'update' ] ],
    Subscription         => [ subscriptions          => [ cancel => {} ],[ pause => { pause_cycles => 2 } ],[ resume => {} ],[ 'update' ] ],
    Customer             => [ customers              => [ 'update' ] ],
    Payout               => [ payouts                => [ 'update' ] ],
    BillingRequest       => [ billing_requests       =>
        [ collect_customer_details => { customer => { email => 'a@example.com' } } ],
        [ collect_bank_account     => { account_holder_name => 'Lee' } ],
        [ confirm_payer_details    => {} ],
        [ fulfil                   => {} ],
        [ cancel                   => {} ],
        [ notify                   => { notification_type => 'email' } ],
        [ fallback                 => {} ],
        [ choose_currency          => { currency => 'EUR' } ],
        [ select_institution       => { institution => 'monzo',country_code => 'GB' } ],
    ],
    BillingRequestFlow     => [ billing_request_flows     => [ initialise => {} ] ],
    BillingRequestTemplate => [ billing_request_templates => [ 'update' ] ],
    CustomerBankAccount    => [ customer_bank_accounts    => [ disable => {} ],[ 'update' ] ],
    CustomerNotification   => [ customer_notifications    => [ handle => {} ] ],
    Creditor               => [ creditors                 => [ 'update' ] ],
    CreditorBankAccount    => [ creditor_bank_accounts    => [ disable => {} ] ],
    InstalmentSchedule     => [ instalment_schedules      => [ cancel => {} ],[ 'update' ] ],
    MandateImport          => [ mandate_imports           => [ submit => {} ],[ cancel => {} ] ],
    Block                  => [ blocks                    => [ disable => {} ],[ enable => {} ] ],
    OutboundPayment        => [ outbound_payments         => [ approve => {} ],[ cancel => {} ],[ 'update' ] ],
    Refund                 => [ refunds                   => [ 'update' ] ],
);

foreach my $short_class ( sort keys %operations ) {

    my ( $endpoint,@ops ) = @{ $operations{$short_class} };
    my $class = "Business::GoCardless::$short_class";

    foreach my $op ( @ops ) {

        my ( $action,$params ) = @{ $op };

        my $Object = $class->new( client => $GoCardless->client,id => 'ID123' );

        _respond( { $endpoint => {
            id => 'ID123',
            ( $class->can( 'status' ) ? ( status => 'updated' ) : () ),
        } } );

        if ( $action eq 'update' ) {

            isa_ok( $Object->update( metadata => { a => 1 } ),$class,"$short_class->update" );
            cmp_deeply(
                [ @{ $requests[0] }{ qw/ method path body / } ],
                [ 'PUT',"/$endpoint/ID123",{ $endpoint => { metadata => { a => 1 } } } ],
                "$short_class->update request"
            );

        } else {

            isa_ok( $Object->$action( %{ $params } ),$class,"$short_class->$action" );
            cmp_deeply(
                [ @{ $requests[0] }{ qw/ method path body / } ],
                [
                    'POST',"/$endpoint/ID123/actions/$action",
                    keys( %{ $params } ) ? { data => $params } : undef,
                ],
                "$short_class->$action request"
            );
        }

        is( $Object->status,'updated',"$short_class->$action updates the object" )
            if $class->can( 'status' );
    }
}

_respond( { customers => { id => 'CU123' } } );
Business::GoCardless::Customer->new( client => $GoCardless->client,id => 'CU123' )->remove;
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path / } ],
    [ 'DELETE','/customers/CU123' ],
    'Customer->remove'
);

note( "billing requests" );

my $BillingRequest = Business::GoCardless::BillingRequest->new(
    client => $GoCardless->client,
    id     => 'BRQ123',
    links  => {
        customer                                        => 'CU123',
        mandate_request_mandate                         => 'MD123',
        payment_request_payment                         => 'PM123',
        subscription_request_subscription               => 'SB123',
        instalment_schedule_request_instalment_schedule => 'IS123',
    },
);

is( $BillingRequest->customer_id,'CU123','->customer_id' );
is( $BillingRequest->mandate_id,'MD123','->mandate_id' );
is( $BillingRequest->payment_id,'PM123','->payment_id' );
is( $BillingRequest->subscription_id,'SB123','->subscription_id' );
is( $BillingRequest->instalment_schedule_id,'IS123','->instalment_schedule_id' );

_respond( { billing_request_flows => { id => 'BRF123',authorisation_url => 'https://pay/BRF123' } } );
my $Flow = $BillingRequest->create_flow( redirect_uri => 'https://example.com' );
isa_ok( $Flow,'Business::GoCardless::BillingRequestFlow','->create_flow' );
is( $Flow->authorisation_url,'https://pay/BRF123',' ... authorisation_url' );
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path body / } ],
    [ 'POST','/billing_request_flows',{ billing_request_flows => {
        redirect_uri => 'https://example.com',
        links        => { billing_request => 'BRQ123' },
    } } ],
    ' ... request'
);

_respond( { institutions => [ { id => 'monzo',name => 'Monzo' } ] } );
my @institutions = $BillingRequest->institutions( country_code => 'GB' );
isa_ok( $institutions[0],'Business::GoCardless::Institution','->institutions' );
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path query / } ],
    [ 'GET','/billing_requests/BRQ123/institutions','country_code=GB' ],
    ' ... request'
);

_respond( { billing_request_with_actions => {
    billing_requests    => { id => 'BRQ123',status => 'pending' },
    bank_authorisations => { id => 'BAU123',url => 'https://bank' },
} } );

my ( $WithActions,$BankAuthorisation ) = $GoCardless->create_billing_request_with_actions(
    payment_request => { amount => 100,currency => 'GBP' },
);
isa_ok( $WithActions,'Business::GoCardless::BillingRequest','->create_billing_request_with_actions' );
isa_ok( $BankAuthorisation,'Business::GoCardless::BankAuthorisation',' ... and bank authorisation' );
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path body / } ],
    [ 'POST','/billing_requests/create_with_actions',{ billing_request_with_actions => {
        payment_request => { amount => 100,currency => 'GBP' },
    } } ],
    ' ... request'
);

note( "other resource methods" );

foreach my $variant ( qw/ dates schedule / ) {
    my $method = "create_instalment_schedule_with_$variant";
    _respond( { instalment_schedules => { id => 'IS123' } } );
    isa_ok(
        $GoCardless->$method( name => 'Bike' ),
        'Business::GoCardless::InstalmentSchedule',
        "->$method"
    );
    cmp_deeply(
        [ @{ $requests[0] }{ qw/ method path body / } ],
        [ 'POST',"/instalment_schedules/create_with_$variant",{ instalment_schedules => { name => 'Bike' } } ],
        ' ... request'
    );
}

_respond( { mandate_pdfs => { url => 'https://pdf',expires_at => '2026-10-21T00:00:00.000Z' } } );
my $Pdf = $GoCardless->create_mandate_pdf( links => { mandate => 'MD123' },accept_language => 'fr' );
isa_ok( $Pdf,'Business::GoCardless::MandatePdf','->create_mandate_pdf' );
is( $Pdf->url,'https://pdf',' ... url' );
is( $requests[0]{headers}->header( 'Accept-Language' ),'fr',' ... Accept-Language header' );
cmp_deeply( $requests[0]{body},{ mandate_pdfs => { links => { mandate => 'MD123' } } },' ... request body' );

_respond( { bank_account_details => { protected => 'p',ciphertext => 'c' } } );
my $Detail = $GoCardless->bank_account_detail( 'BA123','PK123' );
isa_ok( $Detail,'Business::GoCardless::BankAccountDetail','->bank_account_detail' );
is( $Detail->id,'BA123',' ... id' );
is( $Detail->ciphertext,'c',' ... ciphertext' );
is( $requests[0]{path},'/bank_account_details/BA123',' ... path' );
is( $requests[0]{headers}->header( 'Gc-Key-Id' ),'PK123',' ... Gc-Key-Id header' );
throws_ok( sub { $GoCardless->bank_account_detail( 'BA123' ) },qr/key_id is required/,' ... requires key_id' );

foreach my $response (
    [ { available => JSON::true },1 ],
    [ { available => JSON::false },0 ],
    [ { funds_availabilities => { available => JSON::true } },1 ],
) {
    _respond( $response->[0] );
    is( $GoCardless->funds_available( 'MD123',1000 ),$response->[1],'->funds_available' );
}
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path query / } ],
    [ 'GET','/funds_availability/MD123','amount=1000' ],
    ' ... request'
);

_respond( { blocks => [ { id => 'BLC123' },{ id => 'BLC456' } ] } );
my @blocks = $GoCardless->block_by_ref( reference_type => 'customer',reference_value => 'CU123' );
is( scalar( @blocks ),2,'->block_by_ref' );
isa_ok( $blocks[0],'Business::GoCardless::Block',' ... returns blocks' );
is( $requests[0]{path},'/blocks/block_by_ref',' ... path' );

_respond( {} );
ok( $GoCardless->run_scenario_simulator( 'payment_paid_out','PM123' ),'->run_scenario_simulator' );
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path body / } ],
    [ 'POST','/scenario_simulators/payment_paid_out/actions/run',{ data => { links => { resource => 'PM123' } } } ],
    ' ... request'
);

_respond( { outbound_payments => { id => 'OUT123' } } );
isa_ok(
    $GoCardless->create_outbound_payment_withdrawal( amount => 100 ),
    'Business::GoCardless::OutboundPayment',
    '->create_outbound_payment_withdrawal'
);
is( $requests[0]{path},'/outbound_payments/withdrawal',' ... path' );

_respond( { outbound_payments => { scheduled_count => 1 } } );
cmp_deeply( $GoCardless->outbound_payment_stats,{ scheduled_count => 1 },'->outbound_payment_stats' );
is( $requests[0]{path},'/outbound_payments/stats',' ... path' );

_respond( { payment_account_transactions => [ { id => 'PATR123' } ],meta => {} } );
my @transactions = $GoCardless->payment_account_transactions( 'BA123',value_date_from => '2026-10-01' );
isa_ok( $transactions[0],'Business::GoCardless::PaymentAccountTransaction','->payment_account_transactions' );
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path query / } ],
    [ 'GET','/payment_accounts/BA123/transactions','value_date_from=2026-10-01' ],
    ' ... request'
);

_respond( { customer_notifications => { id => 'PCN123',action_taken => 'handled' } } );
my $Notification = $GoCardless->handle_customer_notification( 'PCN123' );
isa_ok( $Notification,'Business::GoCardless::CustomerNotification','->handle_customer_notification' );
is( $Notification->action_taken,'handled',' ... action_taken' );
is( $requests[0]{path},'/customer_notifications/PCN123/actions/handle',' ... path' );

note( "webhooks" );

my $body = '{"events":[]}';
my $webhook = {
    id              => 'WB123',
    request_body    => $body,
    request_headers => { 'Webhook-Signature' => Digest::SHA::hmac_sha256_hex( $body,'bar' ) },
    successful      => JSON::false,
};

my $Webhook = Business::GoCardless::Webhook::V2->_new_from_api(
    Business::GoCardless::Client->new( token => 'foo',api_version => 2,webhook_secret => 'bar' ),
    $webhook,
);

_respond( { webhooks => { %{ $webhook },id => 'WB456',successful => JSON::true } } );
my $Retried = $Webhook->retry;
isa_ok( $Retried,'Business::GoCardless::Webhook::V2','Webhook->retry' );
is( $Retried->id,'WB456',' ... returns the new delivery' );
cmp_deeply(
    [ @{ $requests[0] }{ qw/ method path / } ],
    [ 'POST','/webhooks/WB123/actions/retry' ],
    ' ... request'
);

note( "status checks and links" );

my $Schedule = Business::GoCardless::InstalmentSchedule->new(
    client => $GoCardless->client,
    links  => { mandate => 'MD123',customer => 'CU123' },
);
ok( ! $Schedule->active,'status check with no status' );
$Schedule->status( 'active' );
ok( $Schedule->active,'->active' );
ok( ! $Schedule->cancelled,'! ->cancelled' );
is( $Schedule->mandate_id,'MD123','->mandate_id' );
is( $Schedule->customer_id,'CU123','->customer_id' );

note( "resource classes" );

# every attribute documented in the POD of each class should exist
foreach my $short_class ( sort map { $_->[0] } values %resources ) {

    my $class = "Business::GoCardless::$short_class";
    ( my $file = "$Bin/../../../lib/$class.pm" ) =~ s!::!/!g;

    open( my $fh,'<',$file ) or die "Can't open $file: $!";
    my $source = do { local $/; <$fh> };
    close( $fh );

    my ( $attributes ) = $source =~ /^=head1 ATTRIBUTES\n\n(.*?)\n\n/ms;
    my @attributes = grep { length } split( /\s+/,$attributes // '' );

    ok( scalar( @attributes ),"$short_class has documented attributes" );
    can_ok( $class,@attributes );
}

note( "documentation" );

# every generated method should be documented in Business::GoCardless::Pro
open( my $fh,'<',"$Bin/../../../lib/Business/GoCardless/Pro.pm" ) or die $!;
my $pod = do { local $/; <$fh> };
close( $fh );

foreach my $endpoint ( sort keys %resources ) {
    my ( undef,$singular,undef,@operations ) = @{ $resources{$endpoint} };
    my %methods = (
        get    => "->$singular( \$id )",
        list   => "->$endpoint( %filters )",
        create => "->create_$singular( %params )",
    );
    foreach my $operation ( @operations ) {
        ok( index( $pod,$methods{$operation} ) >= 0,"$methods{$operation} is documented" );
    }
}

done_testing();

# vim: ts=4:sw=4:et
