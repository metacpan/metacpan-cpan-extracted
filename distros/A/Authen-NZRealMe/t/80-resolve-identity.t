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
    type      => 'assertion',
);

isa_ok($sp => 'MockSP', 'test SP');
isa_ok($sp => 'Authen::NZRealMe::ServiceProvider', 'parent class');

my $idp = $sp->idp;

isa_ok($idp => 'MockIdP', 'test IdP');
isa_ok($idp => 'Authen::NZRealMe::IdentityProvider', 'parent class');

my $artifact    = $idp->make_artifact(1); # identity-assertion-1.xml
my $request_id  = 'fb015601b411971db9e258f12f4b1c107';

my $resp = eval {
    $sp->resolve_artifact( artifact => $artifact);
};

is($resp => undef, 'resolution failed');
like($@, qr{original request ID}, 'because original request ID not provided');

$resp = eval {
    $sp->resolve_artifact(artifact => $artifact, request_id => $request_id);
};

is($resp => undef, 'resolution failed');
like($@, qr{SAML assertion.*expired}, 'because assertion has expired');

$sp->wind_back_clock('2014-05-29T20:55:00Z');

$resp = eval {
    $sp->resolve_artifact(artifact => $artifact, request_id => $request_id);
};

is($@ => '', 'no exceptions!');

# Dissect the request first

my($xml) = $sp->test_request_log;

xml_found_node_ok($xml, q{/nssoapenv:Envelope});
xml_found_node_ok($xml, q{/nssoapenv:Envelope/nssoapenv:Body});

xml_node_content_is($xml,
    q{/nssoapenv:Envelope/nssoapenv:Body/nssamlp:ArtifactResolve/@Version},
    '2.0'
);

xml_node_content_is($xml,
    q{/nssoapenv:Envelope/nssoapenv:Body/nssamlp:ArtifactResolve/@IssueInstant},
    '2014-05-29T20:55:00Z'
);

xml_node_content_is($xml,
    q{/nssoapenv:Envelope/nssoapenv:Body/nssamlp:ArtifactResolve/nssaml:Issuer},
    'https://www.example.govt.nz/app/sample-identity'
);

xml_node_content_is($xml,
    q{/nssoapenv:Envelope/nssoapenv:Body/nssamlp:ArtifactResolve/nssamlp:Artifact},
    $artifact
);

# And then the response
isa_ok($resp => 'Authen::NZRealMe::ResolutionResponse', 'resolution response');

ok($resp->is_success,         'response status is success');
ok(!$resp->is_error,          'response status is not error');
ok(!$resp->is_timeout,        'response status is not timeout');
ok(!$resp->is_cancel,         'response status is not cancel');
ok(!$resp->is_not_registered, 'response status is not "not registered"');
is($resp->first_name        => 'Ignatius',        'first_name'        );
is($resp->mid_names         => 'Quantifico',      'mid_names'         );
is($resp->surname           => 'Wallaphocter',    'surname'           );
is($resp->date_of_birth     => '1988-07-06',      'date_of_birth'     );
is($resp->place_of_birth    => 'Pahiatua',        'place_of_birth'    );
is($resp->country_of_birth  => 'New Zealand',     'country_of_birth'  );
is($resp->gender            => 'M',               'gender'            );
is($resp->address_unit      => '208',             'address_unit'      );
is($resp->address_street    => 'Queen Street',    'address_street'    );
is($resp->address_suburb    => 'Petone',          'address_suburb'    );
is($resp->address_town_city => 'Hutt City',       'address_town_city' );
is($resp->address_postcode  => '1234',            'address_postcode'  );
is($resp->fit               => 'GIGANAIRE',       'fit'               );
is($resp->flt               => undef,             'flt (not present)' );

# Try again but with iCMS resolution as well

$resp = eval {
    $sp->resolve_artifact(
        artifact    => $artifact,
        request_id  => $request_id,
        resolve_flt => 1,
    );
};

is($@ => '', 'no exceptions!');

# Dissect the iCMS request first

(undef, $xml) = $sp->test_request_log;
#diag($xml);
# TODO: add some assertions about the structure/content of iCMS request

isa_ok($resp => 'Authen::NZRealMe::ResolutionResponse', 'resolution response');

# And then the response
ok($resp->is_success, 'response status is success');
is($resp->surname     => 'Wallaphocter',  'surname'         );
is($resp->flt         => 'BLAHBLAHBLAH',  'flt now present' );

done_testing();
exit;

