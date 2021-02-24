#!perl

use strict;
use warnings;

use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper qw(test_conf_dir test_data_file slurp_file);
use AuthenNZRealMeEncTestHelper;
use Authen::NZRealMe;

Authen::NZRealMe->register_class(service_provider   => 'MockSP');
Authen::NZRealMe->register_class(identity_provider  => 'MockIdP');

my $conf_dir = test_conf_dir();
my $sp = Authen::NZRealMe->service_provider(
    conf_dir  => $conf_dir,
    type      => 'login',
);

isa_ok($sp => 'MockSP', 'test SP');
isa_ok($sp => 'Authen::NZRealMe::ServiceProvider', 'parent class');

my $idp = $sp->idp;

isa_ok($idp => 'MockIdP', 'test IdP');
isa_ok($idp => 'Authen::NZRealMe::IdentityProvider', 'parent class');

my $saml_response_file = 'login-assertion-post-1.b64';
# Following was used to generate static test data - should be commented out
# AuthenNZRealMeEncTestHelper::regenerate_saml_response_post_file(
#     assertion_source_file => 'encrypted-assertion-plaintext.xml',
#     signature_target_id   => 'e8d5cceba9d7a33ddcd239df0c358a2c6df326f04',
#     algorithms            => {
#         encrypt    => 'xenc_aes256cbc',
#         random_key => 'xenc_rsa_oaep_mgf1p',
#         signer     => 'rsa_sha256',
#     },
#     base64_encode_output  => 1,
#     output_file           => $saml_response_file,
# );
my $saml_response = slurp_file(test_data_file($saml_response_file));

my $request_id  = '28f429d03eeb8b06432d1578d268e1b63a460e58f';

# Try resolving without providing original request_id

my $resp = eval {
    $sp->resolve_posted_assertion(saml_response => $saml_response);
};

is($resp => undef, 'resolution failed');
like($@, qr{original request ID}, 'because original request ID not provided');

# Try again, but assertion has expired (old static test data)

$resp = eval {
    $sp->resolve_posted_assertion(
        saml_response => $saml_response,
        request_id    => $request_id
    );
};

is($resp => undef, 'resolution failed');
like($@, qr{SAML assertion.*expired}, 'because assertion has expired');

# Wind back the clock so it's not expired

$sp->wind_back_clock('2020-01-21T09:16:52Z');

$resp = eval {
    $sp->resolve_posted_assertion(
        saml_response => $saml_response,
        request_id    => $request_id
    );
};

is($@ => '', 'no exceptions with clock wound back');

# At this point, we could make some assertions about the raw request document
# which the MockSP logged for us (see: $sp->test_request_log).  That is done
# in 80-resolve-identity.t.
#
# So let's just press on and examine the response

isa_ok($resp => 'Authen::NZRealMe::ResolutionResponse', 'resolution response');

ok($resp->is_success,         'response status is success');
ok(!$resp->is_error,          'response status is not error');
ok(!$resp->is_timeout,        'response status is not timeout');
ok(!$resp->is_cancel,         'response status is not cancel');
ok(!$resp->is_not_registered, 'response status is not "not registered"');

is(
    $resp->flt => 'CHCBD4387DCB7782F1D97B5C4E6A57267B3',
    'response includes flt'
);

is($resp->surname       => undef, 'surname is not defined');
is($resp->first_name    => undef, 'first_name is not defined');
is($resp->mid_names     => undef, 'mid_names is not defined');
is($resp->date_of_birth => undef, 'date_of_birth is not defined');

# Now try a request where response has borked signature

$saml_response_file = 'login-assertion-post-2.b64';
# Following was used to generate static test data - should be commented out
# AuthenNZRealMeEncTestHelper::regenerate_saml_response_post_file(
#     assertion_source_file => 'encrypted-assertion-plaintext.xml',
#     signature_target_id   => 'e8d5cceba9d7a33ddcd239df0c358a2c6df326f04',
#     algorithms            => {
#         encrypt    => 'xenc_aes256cbc',
#         random_key => 'xenc_rsa_oaep_mgf1p',
#         signer     => 'rsa_sha256',
#     },
#     bad_sig               => 1,
#     base64_encode_output  => 1,
#     output_file           => $saml_response_file,
# );
$saml_response = slurp_file(test_data_file($saml_response_file));

$resp = eval {
    $sp->resolve_posted_assertion(
        saml_response => $saml_response,
        request_id    => $request_id
    );
};

is($resp => undef, 'resolution failed');
like(
    $@, qr{Signature verification failed.},
    'because signature verification failed.'
);

$sp = Authen::NZRealMe->service_provider(
    conf_dir              => $conf_dir,
    type                  => 'login',
    skip_signature_check  => 2,
);
$sp->wind_back_clock('2020-01-21T09:16:52Z');

$resp = eval {
    $sp->resolve_posted_assertion(
        saml_response => $saml_response,
        request_id    => $request_id
    );
};

is($@ => '', 'no exceptions with skip_signature_check');

# Now try a response containing a JSON WEB Token

$saml_response_file = 'login-assertion-post-3.b64';
# Following was used to generate static test data - should be commented out
# AuthenNZRealMeEncTestHelper::regenerate_saml_response_post_file(
#     assertion_source_file => 'encrypted-assertion-and-flt-json.xml',
#     signature_target_id   => '_836fed88-04ee-4c4a-92ad-dd80ea49bf93',
#     algorithms            => {
#         encrypt    => 'xenc_aes256cbc',
#         random_key => 'xenc_rsa_oaep_mgf1p',
#         signer     => 'rsa_sha256',
#     },
#     base64_encode_output  => 1,
#     output_file           => $saml_response_file,
# );
$saml_response = slurp_file(test_data_file($saml_response_file));

$request_id = 'd70e226fd22aea999d43b5a4d7cba1d4336e85278';
$sp->wind_back_clock('2020-11-26T01:19:56Z');

$resp = eval {
    $sp->resolve_posted_assertion(
        saml_response => $saml_response,
        request_id    => $request_id
    );
};

is($@ => '', 'no exceptions with clock wound back');

isa_ok($resp => 'Authen::NZRealMe::ResolutionResponse', 'resolution response');

ok($resp->is_success,         'response status is success');
ok(!$resp->is_error,          'response status is not error');
ok(!$resp->is_timeout,        'response status is not timeout');
ok(!$resp->is_cancel,         'response status is not cancel');
ok(!$resp->is_not_registered, 'response status is not "not registered"');

is(
    $resp->flt => 'CHCBD4387DCB7782F1D97B5C4E6A57267B3',
    'response includes flt'
);

is($resp->surname       => undef, 'surname is not defined');
is($resp->first_name    => undef, 'first_name is not defined');
is($resp->mid_names     => undef, 'mid_names is not defined');
is($resp->date_of_birth => undef, 'date_of_birth is not defined');

# Now try a response containing a timeout status and no assertion

$saml_response_file = 'login-assertion-post-4.b64';
# Following was used to generate static test data - should be commented out
# AuthenNZRealMeEncTestHelper::regenerate_saml_response_post_file(
#     assertion_source_file => 'encrypted-timeout-plaintext.xml',
#     base64_encode_output  => 1,
#     output_file           => $saml_response_file,
# );
$saml_response = slurp_file(test_data_file($saml_response_file));

$request_id = 'e1db069d533bcb0a5c75f489c739ba52e625cb827';
$sp->wind_back_clock('2020-01-21T09:16:52Z');

$resp = eval {
    $sp->resolve_posted_assertion(
        saml_response => $saml_response,
        request_id    => $request_id
    );
};

is($@ => '', 'no exceptions with clock wound back');

isa_ok($resp => 'Authen::NZRealMe::ResolutionResponse', 'resolution response');

ok(!$resp->is_success,        'response status is not success');
ok($resp->is_error,           'response status is error');
ok($resp->is_timeout,         'response status is timeout');
ok(!$resp->is_cancel,         'response status is not cancel');
ok(!$resp->is_not_registered, 'response status is not "not registered"');

is(
    $resp->status_urn,
    'urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:status:Timeout',
    'response status_urn'
);

is(
    $resp->status_message,
    'RealMe login service session timeout',
    'response status_message'
);

is($resp->flt, undef, 'response FLT not defined');

done_testing;
exit;

