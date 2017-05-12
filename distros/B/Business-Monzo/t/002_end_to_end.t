#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Business::Monzo;

use FindBin qw/ $Bin /;

plan skip_all => "MONZO_ENDTOEND required"
    if ! $ENV{MONZO_ENDTOEND};

# this is an "end to end" test - it will call the Monzo API
# using the details defined in the ENV variables below.
my ( $token,$url,$skip_cert ) = @ENV{qw/
    MONZO_TOKEN
    MONZO_URL
    SKIP_CERT_CHECK
/};

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = !$skip_cert;

# this makes Business::Monzo::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{MONZO_DEBUG} = 1;

note( "Monzo" );
my $Monzo = Business::Monzo->new(
    token   => $token,
    ( $url ? ( api_url => $url ) : () ),
);

isa_ok( $Monzo,'Business::Monzo' );

note( "Account" );
my @accounts = $Monzo->accounts;

isa_ok(
	my $Account = $accounts[0],
	'Business::Monzo::Account'
);

my @transactions = $Monzo->transactions( account_id => $Account->id );

isa_ok(
	my $Transaction = $transactions[0],
    'Business::Monzo::Transaction',
);

note( "Transaction" );
isa_ok(
    $Transaction = $Monzo->transaction(
		id => $Transaction->id,
		expand => 'merchant'
	),
    'Business::Monzo::Transaction'
);

isa_ok(
    $Transaction->get,
    'Business::Monzo::Transaction',
);

my $time = time;

isa_ok(
    $Transaction = $Transaction->annotate(
		testing_at => $time,
	),
    'Business::Monzo::Transaction',
);

cmp_deeply(
    my $annotations = $Transaction->annotations,
    {
        testing_at => $time,
    },
    '->annotations',
);

ok( $Account->add_feed_item(
	url => 'https://metacpan.org/release/Business-Monzo',
	params => {
		title     => 'Hello from the perl API client',
		image_url => 'http://pix.iemoji.com/images/emoji/apple/ios-9/256/dromedary-camel.png',
		body      => '🐪',
	}
),'->add_feed_item' );

note( "Webhook" );
isa_ok( my $Webhook = $Account->register_webhook(
    callback_url => 'http://www.foo.com',
),'Business::Monzo::Webhook' );

ok( my @webhooks = $Account->webhooks,'->webhooks' );

foreach $Webhook ( @webhooks ) {
	ok( $Webhook->delete,'->delete' );
}

note( "Balance" );
isa_ok(
	my $Balance = $Monzo->balance( account_id => $Account->id ),
	'Business::Monzo::Balance'
);

like( $Balance->account_id,qr/acc_0000/,'->account_id' );
ok( $Balance->balance,'->balance' );
isa_ok( $Balance->currency,'Data::Currency','->currency' );
is( $Balance->spend_today,0,'->spend_today' );

note( "Attachment" );
isa_ok( my $Attachment = $Monzo->upload_attachment(
	file_name => 'foo.png',
	file_type => 'image/png',
),'Business::Monzo::Attachment' );

is( $Attachment->file_name,'foo.png','->file_name' );
is( $Attachment->file_type,'image/png','->file_type' );
like( $Attachment->file_url,qr/^http/,'->file_url' );
like( $Attachment->upload_url,qr/^http/,'->upload_url' );

isa_ok( $Attachment = $Attachment->register(
	external_id => $Transaction->id,
	file_url    => 'http://www.nyan.cat/cats/original.gif',
	file_type   => 'image/gif',
),'Business::Monzo::Attachment' );

like( $Attachment->user_id,qr/user_/,'->user_id' );
isa_ok( $Attachment->created,'DateTime' );
is( $Attachment->external_id,$Transaction->id,'->id' );
like( $Attachment->id,qr/attach_/,'->id' );
ok( $Attachment->file_name,'->file_name' );
is( $Attachment->file_type,'image/gif','->file_type' );
like( $Attachment->file_url,qr/^http/,'->file_url' );
like( $Attachment->upload_url,qr/^http/,'->upload_url' );

ok( $Attachment->deregister,'->deregister' );

done_testing();
