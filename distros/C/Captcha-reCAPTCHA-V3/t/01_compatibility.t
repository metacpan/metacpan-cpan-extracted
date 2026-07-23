use strict;
use Test::More 0.98 tests => 6;

# test for there is a curl
my $curl = `which curl`;
chomp $curl;
like $curl, qr|/curl$|, "curl command is available";

use Captcha::reCAPTCHA::V3;
my $rc = Captcha::reCAPTCHA::V3->new( secret => 'Dummy', sitekey => 'Dummy' );

my $either = 0;

SKIP: {
    skip "curl command is not available", 2 unless $curl;
    my $json = $rc->get_json_with_curl('dummy-response-token');
    is $json->{'error-codes'}[0], 'invalid-input-response', "succeed to catch 'invalid-input-secret' with curl";
    is $json->{success}, 0, "succeed to catch failure with curl";
    $either = 1;
}

SKIP: {
    skip "HTTP::Tiny is not available", 2 unless eval { require HTTP::Tiny };
    my $ua  = HTTP::Tiny->new;
    skip "SSL is not available in HTTP::Tiny", 2 unless $ua->can_ssl();
    my $content = $rc->get_json_with_http_tiny('dummy-response-token');
    is $content->{success}, 0, "succeed to catch failure with HTTP::Tiny";
    is $content->{'error-codes'}[0], 'invalid-input-response', "succeed to catch 'invalid-input-secret' with HTTP::Tiny";
    $either ||= 1;
}

is $either, 1, "succeed to catch 'invalid-input-secret' with either curl or HTTP::Tiny";

=ToDo

# These require culculated response value in javascript
# And to verify strictly, we have to set correct secret and sitekey

my $response;
$content = $rc->deny_by_score( response => $response, score => 0 );
$content = $rc->verify_or_die($response);

=cut

done_testing;
