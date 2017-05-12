#!/usr/bin/perl

use strict;
use warnings;
use Test::More;
use Captcha::reCAPTCHA::V2;

my $rc2 = Captcha::reCAPTCHA::V2->new;

$rc2->{json_options} = { canonical => 1 };

my $script = $rc2->_recaptcha_script(
    'ThisIsASitekey',
    {
        theme => 'light',
        type  => 'image',
        size  => 'normal',
    }
);

my $grecaptcha_script = q^<script type="text/javascript">var onloadCallback = function(){grecaptcha.render('recaptcha_ThisIsASit',{"sitekey":"ThisIsASitekey","size":"normal","theme":"light","type":"image"});};</script>^;

is( $script, $grecaptcha_script, 'get correct javascript function' );

my $html = $rc2->html(
    'ThisIsASitekey',
    {
        theme => 'light',
        type  => 'image',
        size  => 'normal',
    }
);

my $captcha_widget_html = $grecaptcha_script . q^<script src="https://www.google.com/recaptcha/api.js?onload=onloadCallback&render=explicit" type="text/javascript"></script><div id="recaptcha_ThisIsASit"></div>^;

is( $html, $captcha_widget_html, 'get correct html to render the widget' );

done_testing