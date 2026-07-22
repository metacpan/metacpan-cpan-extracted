use strict;
use Test::More 0.98 tests => 3;

use_ok('Captcha::Cloudflare::Turnstile');
my $ts = new_ok('Captcha::Cloudflare::Turnstile', [ sitekey => 'Dummy', secret => 'Dummy' ]);
is $ts->isa('Captcha::Cloudflare::Turnstile'), 1, 'is a Captcha::Cloudflare::Turnstile object';

done_testing;
