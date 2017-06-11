#!perl

use strict;
use warnings;
use utf8;

use Test::Most;
use Test::Deep;
use Test::Exception;
use LWP::Simple;
use Business::GoCardless::Basic;
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
my ( $token,$url,$app_id,$app_secret,$mid,$DEBUG ) = @ENV{qw/
    GOCARDLESS_TOKEN
    GOCARDLESS_URL
    GOCARDLESS_APP_ID
    GOCARDLESS_APP_SECRET
    GOCARDLESS_MERCHANT_ID
	GOCARDLESS_DEBUG
/};

# this makes Business::GoCardless::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{GOCARDLESS_DEV_TESTING} = 1;

my $GoCardless = Business::GoCardless::Basic->new(
    token           => $token,
    # since these are set in %ENV we don't need to pass them
    # but am showing them being passed here for example usage
    client_details  => {
        base_url    => $url,
        app_id      => $app_id,
        app_secret  => $app_secret,
        merchant_id => $mid,
    },
);

isa_ok( $GoCardless,'Business::GoCardless::Basic' );
isa_ok( $GoCardless->merchant,'Business::GoCardless::Merchant' );

my $new_url = $GoCardless->new_bill_url(
    amount       => 100,
    name         => 'Example payment',
    redirect_uri => "http://localhost:3000/merchants/$mid/confirm_resource",
);

_post_to_gocardless( $new_url,'bill' );
my $confirm_resource_data = _get_confirm_resource_data( "$tmp_dir/bill.json" );
isa_ok(
    my $Bill = $GoCardless->confirm_resource( %{ $confirm_resource_data } ),
    'Business::GoCardless::Bill'
);

ok( $Bill->cancel,'cancel bill' );
ok( $Bill->cancelled,'bill cancelled' );

my $NewBill = $GoCardless->bill( $Bill->id );
is( $NewBill->id,$Bill->id,'getting bill with same id gives same bill' );

my $Paginator = $GoCardless->bills(
    per_page => 5,
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
    max_amount         => 100,
    interval_length    => 10,
    interval_unit      => 'day',
    expires_at         => '2020-01-01',
    name               => "Test PreAuthorization",
    description        => "Test PreAuthorization for testing",
);

_post_to_gocardless( $new_pre_auth_url,'pre_authorization' );
$confirm_resource_data = _get_confirm_resource_data(
    "$tmp_dir/pre_authorization.json"
);
isa_ok(
    my $PreAuthorization = $GoCardless->confirm_resource(
        %{ $confirm_resource_data }
    ),
    'Business::GoCardless::PreAuthorization'
);

$Bill = $PreAuthorization->bill( amount => 100 );
$PreAuthorization->cancel;
$GoCardless->pre_authorizations;

my $new_subscription_url = $GoCardless->new_subscription_url(
    amount             => 100,
    interval_length    => 1,
    interval_unit      => 'month',
    name               => "Test Subscription",
    description        => "Test Subscription for testing",
    start_at           => strftime( "%Y-12-31",gmtime ),
);

_post_to_gocardless( $new_subscription_url,'subscription' );
$confirm_resource_data = _get_confirm_resource_data(
    "$tmp_dir/subscription.json"
);

isa_ok(
    my $Subscription = $GoCardless->confirm_resource(
        %{ $confirm_resource_data }
    ),
    'Business::GoCardless::Subscription'
);

$Subscription = $GoCardless->subscription( $Subscription->id );
$Subscription->cancel;

my @users = $GoCardless->users;
my $User = $users[0];
isa_ok( $User,'Business::GoCardless::User' );

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
		'user[email]'                        => 'lee@g3s.ch',
		'user[given_name]'                   => 'Lee',
		'user[family_name]'                  => 'Johnson',
		'user[company_name]'                 => '',
		'user[address_line1]'                => 'My House 14',
		'user[address_line2]'                => 'Somewhere',
		'user[city]'                         => 'Huddersfield',
		'user[postal_code]'                  => 'HD1 1XZ',
		'user[bank_account][sort_code]'      => '200000',
		'user[bank_account][account_number]' => '55779911',
		'user[bank_account][currency]'       => 'GBP',
		'user[bank_account][id]'             => '',
		'authenticity_token'                 => $token,
		'utf8'                               => '✓',
	};

	note explain $account_params if $DEBUG;

	$post_url = join( '',$ENV{GOCARDLESS_URL},$post_url );
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
