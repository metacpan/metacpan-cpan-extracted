use strict;
use Test::More 0.98 tests => 2;

use_ok('Captcha::reCAPTCHA::V3');                                                       # 01
my $rc = new_ok( 'Captcha::reCAPTCHA::V3', [ secret => 'Dummy', sitekey => 'Dummy' ]);  # 02

done_testing;

