use strict;
use Test::More 0.98 tests => 1;

use Captcha::reCAPTCHA::V3;
my $rc = Captcha::reCAPTCHA::V3->new( secret => 'Dummy', sitekey => 'Dummy' );

my $content = $rc->verify('Response');
is $content->{'error-codes'}[0], 'invalid-input-secret', "succeed to catch 'invalid-input-secret'";

=ToDo

# These require culculated response value in javascript
# And to verify strictly, we have to set correct secret and sitekey

my $response;
$content = $rc->deny_by_score( response => $response, score => 0 );
$content = $rc->verify_or_die($response);

=cut

done_testing;
