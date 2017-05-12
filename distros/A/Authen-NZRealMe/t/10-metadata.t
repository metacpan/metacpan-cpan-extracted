#!perl

use Test::More;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper;

require Authen::NZRealMe;

ok(1, 'successfully loaded the Authen::NZRealMe package');


# Load our SP metadata for talking to the login service

my $conf_dir = test_conf_dir();

my $sp = Authen::NZRealMe->service_provider( conf_dir => $conf_dir );

isa_ok($sp, 'Authen::NZRealMe::ServiceProvider');

is($sp->conf_dir, $conf_dir, "SP's conf_dir looks good");
is($sp->entity_id, 'https://www.example.govt.nz/app/sample-login',
    "SP EntityID loaded from metadata looks good");
is($sp->url_assertion_consumer, 'https://www.example.govt.nz/app/sample/login-acs',
    "SP ACS URL from metadata looks good");
is($sp->organization_name, 'Department of Examples (login)',
    "SP OrganizationName loaded from metadata looks good");
is($sp->organization_url, 'https://www.example.govt.nz/',
    "SP OrganizationURL loaded from metadata looks good");
is($sp->contact_company, 'Department of Examples Login Services',
    "SP contact company name loaded from metadata looks good");
is($sp->contact_first_name, 'Joseph',
    "SP contact first name loaded from metadata looks good");
is($sp->contact_surname, 'Bloggs',
    "SP contact surname loaded from metadata looks good");

# Load IdP metadata for login service

my $idp = $sp->idp;

isa_ok($idp, 'Authen::NZRealMe::IdentityProvider');
is($idp->entity_id, 'https://test.fakeme.govt.nz/saml2',
    "IdP EntityID loaded from metadata looks good");


# Load our SP metadata for talking to the assertion service

$sp = Authen::NZRealMe->service_provider(
    conf_dir  => $conf_dir,
    type      => 'assertion',
);

isa_ok($sp, 'Authen::NZRealMe::ServiceProvider');

is($sp->conf_dir, $conf_dir, "SP's conf_dir looks good");
is($sp->entity_id, 'https://www.example.govt.nz/app/sample-identity',
    "SP EntityID loaded from metadata looks good");
is($sp->url_assertion_consumer, 'https://www.example.govt.nz/app/sample/identity-acs',
    "SP ACS URL from metadata looks good");
is($sp->organization_name, 'Department of Examples (identity)',
    "SP OrganizationName loaded from metadata looks good");
is($sp->organization_url, 'https://www.example.govt.nz/',
    "SP OrganizationURL loaded from metadata looks good");
is($sp->contact_company, 'Department of Examples Identity Services',
    "SP contact company name loaded from metadata looks good");
is($sp->contact_first_name, 'James',
    "SP contact first name loaded from metadata looks good");
is($sp->contact_surname, 'Briggs',
    "SP contact surname loaded from metadata looks good");


# Load IdP metadata for login service

$idp = $sp->idp;

isa_ok($idp, 'Authen::NZRealMe::IdentityProvider');
is($idp->entity_id, 'https://test.fakeme.govt.nz/fakemetest/fakemeidp',
    "IdP EntityID loaded from metadata looks good");


# Extract a bit of iCMS metadata

my $method = eval { $sp->_icms_method_data('Validate'); } || {};
is($@, '', "parsed iCMS config without error");
is($method->{url}, 'https://ws.test.logon.fakeme.govt.nz/icms/Validate_v1_1',
    'got iCMS endpoint for FLT resolution');


done_testing();


