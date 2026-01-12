#!perl
use 5.006;
use strict;
use warnings;
use JSON::PP;
use Test::More;

use Business::Stripe::Webhook;

plan tests => 3;

my $payload = <<'JSON';
{
  "id": "evt_test",
  "object": "event",
  "type": "customer.created",
  "data": {
    "object": {
      "id": "cus_123"
    }
  }
}
JSON

my $called = 0;

my $webhook = Business::Stripe::Webhook->new(
    'payload'      => $payload,
    'all-webhooks' => sub { $called++ },
);

$ENV{'HTTP_STRIPE_SIGNATURE'} = 't=123,v1=abc';

$webhook->process();

ok( $called, 'all-webhooks callback invoked' );

my $output = '';
{
    local *STDOUT;
    open STDOUT, '>', \$output or die "Cannot capture STDOUT: $!";
    $webhook->reply();
}

$output =~ s/^Content-type: application\/json\n\n//;
my $reply = decode_json($output);

is( $reply->{'sent_to_all'}, 'true', 'reply reports sent_to_all true' );

ok( scalar(grep { $_ eq 'all-webhooks' } @{$reply->{'sent_to'}}),
    'reply sent_to includes all-webhooks' );
