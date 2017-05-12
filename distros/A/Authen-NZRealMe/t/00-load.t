#!perl -T

use Test::More tests => 1;

use Authen::NZRealMe;

diag( "Testing Authen::NZRealMe $Authen::NZRealMe::VERSION, Perl $], $^X" );

foreach my $key (qw(
    service_provider
    identity_provider
    xml_signer
    sp_builder
    sp_cert_factory
    resolution_request
    resolution_response
    authen_request
    logon_strength
)) {
    Authen::NZRealMe->class_for($key);
}

ok(1, 'successfully loaded all support modules');
