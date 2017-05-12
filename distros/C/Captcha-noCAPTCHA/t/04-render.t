#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;

use_ok('Captcha::noCAPTCHA');

my $cap = Captcha::noCAPTCHA->new({
	site_key   => 'fake site key',
	secret_key => 'fake secret key',
	api_url    => 'file:t/success_response.json',
});

my $expected=<<EOT;
<script src="https://www.google.com/recaptcha/api.js" async defer></script>
<div class="g-recaptcha" data-sitekey="fake site key" data-theme="light"></div>
EOT

is($cap->html,$expected,'make sure no unexpected output changes are made');

$cap->theme('dark');
my $text = $cap->html;

like($text,qr/data-theme="dark"/,'should render data-theme dark');

unlike( $cap->html, qr/noscript/, 'noscript rendering is absent' );
$cap->noscript(1);
like( $cap->html, qr/noscript/, 'noscript rendering is present' );
$cap->noscript(0);
unlike( $cap->html, qr/noscript/, 'noscript rendering is absent' );

done_testing();
