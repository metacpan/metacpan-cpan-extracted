#!perl

use strict;
use warnings;

use Test::Most;
use Test::Deep;
use Test::Exception;
use Business::Mondo;

use FindBin qw/ $Bin /;

plan skip_all => "MONDO_ENDTOEND required"
    if ! $ENV{MONDO_ENDTOEND};

# this is an "end to end" test - it will call the Mondo API
# using the details defined in the ENV variables below.
my ( $token,$url,$skip_cert ) = @ENV{qw/
    MONDO_TOKEN
    MONDO_URL
    SKIP_CERT_CHECK
/};

$ENV{PERL_LWP_SSL_VERIFY_HOSTNAME} = !$skip_cert;

# this makes Business::Mondo::Exception show a stack
# trace when any error is thrown so i don't have to keep
# wrapping stuff in this test in evals to debug
$ENV{MONDO_DEBUG} = 1;

note( "Mondo" );
my $Mondo = Business::Mondo->new(
    token   => $token,
    ( $url ? ( api_url => $url ) : () ),
);

isa_ok( $Mondo,'Business::Mondo' );

note( "Account" );
my @accounts = $Mondo->accounts;

isa_ok(
	my $Account = $accounts[0],
	'Business::Mondo::Account'
);

my @transactions = $Mondo->transactions( account_id => $Account->id );

isa_ok(
	my $Transaction = $transactions[0],
    'Business::Mondo::Transaction',
);

note( "Transaction" );
isa_ok(
    $Transaction = $Mondo->transaction(
		id => $Transaction->id,
		expand => 'merchant'
	),
    'Business::Mondo::Transaction'
);

isa_ok(
    $Transaction->get,
    'Business::Mondo::Transaction',
);

my $time = time;

isa_ok(
    $Transaction = $Transaction->annotate(
		testing_at => $time,
	),
    'Business::Mondo::Transaction',
);

cmp_deeply(
    my $annotations = $Transaction->annotations,
    {
        testing_at => $time,
    },
    '->annotations',
);

ok( $Account->add_feed_item(
	url => 'https://metacpan.org/release/Business-Mondo',
	params => {
		title     => 'Hello from the perl API client',
		image_url => 'http://pix.iemoji.com/images/emoji/apple/ios-9/256/dromedary-camel.png',
		body      => '🐪',
	}
),'->add_feed_item' );

note( "Webhook" );
isa_ok( my $Webhook = $Account->register_webhook(
    callback_url => 'http://www.foo.com',
),'Business::Mondo::Webhook' );

ok( my @webhooks = $Account->webhooks,'->webhooks' );

foreach $Webhook ( @webhooks ) {
	ok( $Webhook->delete,'->delete' );
}

note( "Balance" );
isa_ok(
	my $Balance = $Mondo->balance( account_id => $Account->id ),
	'Business::Mondo::Balance'
);

like( $Balance->account_id,qr/acc_0000/,'->account_id' );
ok( $Balance->balance,'->balance' );
isa_ok( $Balance->currency,'Data::Currency','->currency' );
is( $Balance->spend_today,0,'->spend_today' );

note( "Attachment" );
isa_ok( my $Attachment = $Mondo->upload_attachment(
	file_name => 'foo.png',
	file_type => 'image/png',
),'Business::Mondo::Attachment' );

is( $Attachment->file_name,'foo.png','->file_name' );
is( $Attachment->file_type,'image/png','->file_type' );
like( $Attachment->file_url,qr/^http/,'->file_url' );
like( $Attachment->upload_url,qr/^http/,'->upload_url' );

isa_ok( $Attachment = $Attachment->register(
	external_id => $Transaction->id,
	file_url    => 'http://www.nyan.cat/cats/original.gif',
	file_type   => 'image/gif',
),'Business::Mondo::Attachment' );

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
