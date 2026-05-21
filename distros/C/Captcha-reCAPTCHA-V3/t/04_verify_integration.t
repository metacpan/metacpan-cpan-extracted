use strict;
use warnings;
use Test::More 0.98;

use Captcha::reCAPTCHA::V3;

# Google's official test keys: always return success:true with any token.
# https://developers.google.com/recaptcha/docs/faq#id-like-to-run-automated-tests-with-recaptcha-v2-i-have-read-the-dev-guide-and-ran-the-code-loop-in-the-demo-but-how-do-i-automate-integration-tests-with-recaptcha
my $secret   = $ENV{RECAPTCHA_TEST_SECRET}   // '6LeIxAcTAAAAAGG-vFI1TnRWxMZNFuojJ4WifJWe';
my $response = $ENV{RECAPTCHA_TEST_RESPONSE} // 'dummy-token-for-test-key';

my $rc = Captcha::reCAPTCHA::V3->new( secret => $secret );
my $content = eval { $rc->verify($response) };

ok !$@,                       'verify call does not die';
is ref($content), 'HASH',     'verify returns hashref';
ok exists $content->{success}, 'response has success key';
is $content->{success}, 1,    'success is true with test keys';

done_testing;
