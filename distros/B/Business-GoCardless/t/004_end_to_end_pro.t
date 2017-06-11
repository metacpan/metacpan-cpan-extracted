#!perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Test::Deep;
use Test::Exception;
use LWP::Simple;
use Business::GoCardless::Pro;
use JSON qw/ decode_json /;
use POSIX qw/ strftime /;

use FindBin qw/ $Bin /;
my $tmp_dir = "$Bin/end_to_end";

plan skip_all => "GOCARDLESS_ENDTOEND required"
    if ! $ENV{GOCARDLESS_ENDTOEND};

eval 'use Mojo::UserAgent';
$@ && plan skip_all => "Install Mojolicious to run this test";

# this is an "end to end" test - it will call the gocardless API
# using the details defined in the ENV variables below. you need
# to run t/gocardless_callback_reader.pl allowing the callbacks
# from gocardless to succeed, which feeds the details back into
# this script (hence "end to end") - note that the redirect URI
# and webhook URI in the sandbox/live developer settings will also
# need to match that of the address running the script
my ( $token,$url,$DEBUG ) = @ENV{qw/
    GOCARDLESS_TOKEN
    GOCARDLESS_URL
	GOCARDLESS_DEBUG
/};

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $GoCardless = Business::GoCardless::Pro->new(
    token           => $token,
    # since these are set in %ENV we don't need to pass them
    # but am showing them being passed here for example usage
    client_details  => {
        base_url    => $url,
    },
);

isa_ok( $GoCardless,'Business::GoCardless::Pro' );

my $new_url = $GoCardless->new_bill_url(
	session_token        => 'foo',
	description          => "Test Bill",
	# not sure about having the amount + currency in the redirect URL (what's
	# to stop user from changing it?) but can't see any other way to be back
	# compat with the Basic API
    success_redirect_url => "http://localhost:3000/rflow/confirm/bill/100/EUR",
);

_post_to_gocardless( $new_url,'bill' );
my $confirm_resource_data = _get_confirm_resource_data( "$tmp_dir/redirect_flow.json" );

note explain $confirm_resource_data;

isa_ok(
    my $Bill = $GoCardless->confirm_resource( %{ $confirm_resource_data } ),
    'Business::GoCardless::Payment'
);

ok( $Bill->cancel,'cancel bill' );
ok( $Bill->cancelled,'bill cancelled' );

my $NewBill = $GoCardless->bill( $Bill->id );
is( $NewBill->id,$Bill->id,'getting bill with same id gives same bill' );

my $Paginator = $GoCardless->bills(
	# TOOD: args here
);

note explain $Paginator->info if $DEBUG;

while ( my @bills = $Paginator->next ) {
	pass( 'Paginator->next' );
	if ( $DEBUG ) {
		note scalar( @bills );
		note explain [ map { $_->id } @bills ];
	}
}

my $new_pre_auth_url = $GoCardless->new_pre_authorization_url(
	session_token        => 'bar',
	description          => "Test Pre Auth",
    success_redirect_url => "http://localhost:3000/rflow/confirm/pre_auth/100/EUR",
);

_post_to_gocardless( $new_pre_auth_url,'pre_authorization' );
$confirm_resource_data = _get_confirm_resource_data(
    "$tmp_dir/redirect_flow.json"
);
isa_ok(
    my $PreAuthorization = $GoCardless->confirm_resource(
        %{ $confirm_resource_data }
    ),
    'Business::GoCardless::RedirectFlow'
);

isa_ok(
	my $Payment = $GoCardless->create_payment(
		amount   => 100,
		currency => 'EUR',
		links    => { mandate => $PreAuthorization->links->{mandate} },
	),
	'Business::GoCardless::Payment',
	'->create_payment',
);

note explain $Payment;

ok( $Bill = $PreAuthorization->bill(
	amount   => 100,
	currency => 'EUR',
),'PreAuthorization->bill' );
ok( $Bill->cancel,'->cancel' );

my $new_subscription_url = $GoCardless->new_subscription_url(
	session_token        => 'bar',
	description          => "Test Subscription",
    success_redirect_url => "http://localhost:3000/rflow/confirm/subscription"
		. "/100/EUR/monthly/1/" . strftime( "%Y-12-31",gmtime ),
);

_post_to_gocardless( $new_subscription_url,'subscription' );
$confirm_resource_data = _get_confirm_resource_data(
    "$tmp_dir/redirect_flow.json"
);

isa_ok(
    my $Subscription = $GoCardless->confirm_resource(
        %{ $confirm_resource_data }
    ),
    'Business::GoCardless::Subscription'
);

isa_ok(
	$Subscription = $GoCardless->subscription( $Subscription->id ),
	'Business::GoCardless::Subscription'
);

ok( $Subscription->cancel,'->cancel' );

my @users = $GoCardless->users;
my $User = $users[0];
isa_ok( $User,'Business::GoCardless::Customer' );

done_testing();

sub _post_to_gocardless {
	my ( $url,$desc ) = @_;

	note( $url ) if $DEBUG;

	my $ua  = Mojo::UserAgent->new;
	$ua->max_redirects( 2 );
	my $res = $ua->get( $url )->result;
	ok( $res->is_success,"GET $desc" );

	if ( $DEBUG ) {
		open( my $out,'>','before.html' );
		print $out $res->body;
		close( $out );
	}

	my $token = $res->dom->at('input[name=authenticity_token]')->val;
	my $post_url = $res->dom->find('form')->map( attr => 'action' )->first;

	note( $post_url ) if $DEBUG;

	my $account_params = {
		'customer[email]'               => 'lee@g3s.ch',
		'customer[given_name]'          => 'Lee',
		'customer[family_name]'         => 'Johnson',
		'customer[country_code]'        => 'FR',
		'customer[bank_accounts][iban]' => 'FR1420041010050500013M02606',
		'authenticity_token'            => $token,
		'utf8'                          => '✓',
		'customer[bank_accounts][account_holder_name]' => 'Lee Johnson',
	};

	note explain $account_params if $DEBUG;

	$post_url = "https://pay-sandbox.gocardless.com$post_url";
	my $tx = $ua->post( $post_url => form => $account_params );
	ok( $tx->success,"POST $post_url" );

	if ( $DEBUG ) {
		open( my $out,'>','after.html' );
		print $out $tx->res->body;
		close( $out );
	}

	if ( ! $tx->success ) {
		my $err = $tx->error;
		BAIL_OUT( "$err->{code} response: $err->{message}" ) if $err->{code};
		BAIL_OUT( "Connection error: $err->{message}" );
	}
}

sub _get_confirm_resource_data {

    my ( $file ) = @_;

    while ( 1 ) {

        if ( -e $file ) {
            sleep( 1 );
            open( my $fh,'<',$file ) || die "Can't open $file for read: $!";
            do {
                local $/;
                my $content = <$fh>;
                close( $fh );
                unlink( $file ) || warn "Couldn't unlink $file: $!";
                return decode_json( $content )
            };
        }

        diag "Waiting for $file to appear...";
        sleep( 5 );
    }
}
