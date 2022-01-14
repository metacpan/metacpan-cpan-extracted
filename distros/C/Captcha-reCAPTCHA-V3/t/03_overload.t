use strict;
use Test::More 0.98 tests => 3;

use Captcha::reCAPTCHA::V3;
my $rc = Captcha::reCAPTCHA::V3->new( secret => 'Dummy', sitekey => 'Dummy' );

is $rc->name(), 'g-recaptcha-response', "the dfault name is g-recaptcha-response";
is $rc,         'g-recaptcha-response', "the overload works";

$rc->name('another');
is $rc, 'another', "succeed to rename";

done_testing;
