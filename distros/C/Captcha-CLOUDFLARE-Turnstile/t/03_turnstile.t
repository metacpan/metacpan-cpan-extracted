use strict;
use Test::More 0.98;

use Captcha::Cloudflare::Turnstile;

my $ts = Captcha::Cloudflare::Turnstile->new(
    secret  => 'Secret',
    sitekey => 'SiteKey',
);

is $ts->name,        'cf-turnstile-response',  'default name for cloudflare';
is "$ts",            'cf-turnstile-response',  'overloaded stringify';

my $api_url = 'https://challenges.cloudflare.com/turnstile/v0/api.js';
is $ts->scriptURL, $api_url, 'scriptURL returns correct API endpoint';
like $ts->scriptTag, qr|<script src="\Q$api_url\E" defer></script>|, 'scriptTag correct';

is $ts->widgetTag,
    '<div class="cf-turnstile" data-sitekey="SiteKey"></div>',
    'widgetTag with stored sitekey';

my $scripts = $ts->scripts( action => 'login' );
like $scripts, qr|<div class="cf-turnstile" data-sitekey="SiteKey" data-action="login"></div>|,
    'scripts includes widget with action';

my $secret   = $ENV{TURNSTILE_TEST_SECRET}   // '1x0000000000000000000000000000000AA';
my $ts_verify = Captcha::Cloudflare::Turnstile->new( secret => $secret );
my $content = eval { $ts_verify->verify('dummy-token') };
ok !$@, 'verify() executes without error';
is ref($content), 'HASH', 'verify() returns hashref';

done_testing;
