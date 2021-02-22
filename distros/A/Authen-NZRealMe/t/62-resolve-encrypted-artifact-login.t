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

# Following was used to generate static test data - should be commented out
# AuthenNZRealMeEncTestHelper::regenerate_saml_response_post_file(
#     assertion_source_file => 'encrypted-soap-response-plaintext.xml',
#     signature_target_id   => 'sa5856952693ea21cb1a76b25b7ed1c7e74cb982ad',
#     algorithms            => {
#         encrypt    => 'xenc_aes128cbc',
#         random_key => 'xenc_rsa15',
#         signer     => 'rsa_sha256',
#     },
#     output_file           => 'login-assertion-3.xml',
# );
my $artifact    = $idp->make_artifact(3); # login-assertion-3.xml
my $request_id  = 'fdaeb8f254369ef21ba2e4230a24371b0f6a7df01';

# Try resolving without providing original request_id

my $resp = eval {
    $sp->resolve_artifact(artifact => $artifact);
};

is($resp => undef, 'resolution failed');
like($@, qr{original request ID}, 'because original request ID not provided');

# Try again, but assertion has expired (old static test data)

$resp = eval {
    $sp->resolve_artifact(artifact => $artifact, request_id => $request_id);
};

is($resp => undef, 'resolution failed');
like($@, qr{SAML assertion.*expired}, 'because assertion has expired');

# Wind back the clock so it's not expired

$sp->wind_back_clock('2020-01-30T22:19:11Z');

$resp = eval {
    $sp->resolve_artifact(artifact => $artifact, request_id => $request_id);
};

is($@ => '', 'no exceptions!');

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
    $resp->flt => 'CHCC4E6AB97B57DCB57267B3D4387782F1D',
    'response includes flt'
);

is($resp->surname       => undef, 'surname is not defined');
is($resp->first_name    => undef, 'first_name is not defined');
is($resp->mid_names     => undef, 'mid_names is not defined');
is($resp->date_of_birth => undef, 'date_of_birth is not defined');

done_testing;
exit;

