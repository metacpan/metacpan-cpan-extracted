#!perl 
 
use Test::More;
 
BEGIN { use_ok( 'Captcha::reCAPTCHA::V2' ); }
BEGIN { use_ok( 'Dancer::Plugin::reCAPTCHA' ); }
 
done_testing;
