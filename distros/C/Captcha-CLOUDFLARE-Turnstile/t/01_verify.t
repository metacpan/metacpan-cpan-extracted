use strict;
use Test::More 0.98;

use Captcha::Cloudflare::Turnstile;

my $ts = Captcha::Cloudflare::Turnstile
    ->new(secret => 'dummy-secret', sitekey => 'dummy-sitekey');

my $content = $ts->verify('dummy-response-token');
is $content->{'error-codes'}[0], 'invalid-input-secret', "verify detects invalid secret";

$ts = Captcha::Cloudflare::Turnstile->new(
    secret => '2x0000000000000000000000000000000AA',
    sitekey => '2x00000000000000000000AB'
);

$content = $ts->verify('dummy-response-token');
is $content->{'error-codes'}[0], 'invalid-input-response', "verify detects invalid response token";

done_testing;
