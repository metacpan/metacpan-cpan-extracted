#!perl

use strict;
use warnings;

use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper;
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

my $artifact    = $idp->make_artifact(1); # login-assertion-1.xml
my $request_id  = 'd41d8cd98f00b204e9800998ecf8427e2';

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

$sp->wind_back_clock('2015-02-19T17:46:30Z');

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
    $resp->flt => 'CHC600C1AE5D993A8AE7E382006E9521C07',
    'response includes flt'
);

is($resp->surname       => undef, 'surname is not defined');
is($resp->first_name    => undef, 'first_name is not defined');
is($resp->mid_names     => undef, 'mid_names is not defined');
is($resp->date_of_birth => undef, 'date_of_birth is not defined');


# Now try a request where response has borked signature

$artifact    = $idp->make_artifact(2); # login-assertion-2.xml
$request_id  = 'f7c3b9c84cd67827b31d5a37fd205e5a';

$resp = eval {
    $sp->resolve_artifact(artifact => $artifact, request_id => $request_id);
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
$sp->wind_back_clock('2015-02-19T17:46:30Z');

$resp = eval {
    $sp->resolve_artifact(artifact => $artifact, request_id => $request_id);
};

is($@ => '', 'no exceptions!');

done_testing;
exit;

