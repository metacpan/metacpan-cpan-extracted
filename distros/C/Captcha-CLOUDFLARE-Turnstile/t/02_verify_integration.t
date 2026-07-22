use strict;
use Test::More 0.98;

use Captcha::Cloudflare::Turnstile;

my $secret   = $ENV{RECAPTCHA_TEST_SECRET}   // '1x0000000000000000000000000000000AA';
my $response = $ENV{RECAPTCHA_TEST_RESPONSE} // 'dummy-token-for-test-key';

my $rc = Captcha::Cloudflare::Turnstile->new( secret => $secret );
my $content = eval { $rc->verify($response) };

ok !$@, 'verify() does not die';
ok exists $content->{success}, 'response has success key';
is $content->{success}, 1, 'test key returns success';

done_testing;
