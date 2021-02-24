#!perl

use strict;
use warnings;

use Test::More;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');
use Time::Local qw(timegm);

use AuthenNZRealMeTestHelper;

require Authen::NZRealMe;

my $conf_dir = test_conf_dir();

my $sp = Authen::NZRealMe->service_provider( conf_dir => $conf_dir );

isa_ok($sp, 'Authen::NZRealMe::ServiceProvider');

my $req = $sp->new_request();

isa_ok($req, 'Authen::NZRealMe::AuthenRequest');

my $req_id = $req->request_id;
like($req_id, qr{^\w{16,}$}, "request id comprises at least 16 'word' chars");
like($req_id, qr{^\D}, "request id does not start with a digit");

is($req->entity_id, $sp->entity_id, 'request entity_id matches SP');

my($year, $month, $day, $hour, $min, $sec) =
    $req->request_time =~ qr{^(\d\d\d\d)-(\d\d)-(\d\d)T(\d\d):(\d\d):(\d\d)Z$};
ok(defined($sec), 'format of request time looks good');
my $req_time = timegm($sec, $min, $hour, $day, $month - 1, $year - 1900);
ok((time() - $req_time) < 10,
    'request time seems to be a UTC version of current time');

is($req->destination_url, $sp->idp->single_signon_location,
    'request destination URL matches IdP metadata setting');

is($req->relay_state, undef, 'request has no default relay state');
is($req->allow_create, 'false', 'request does not enable account creation by default');

my $strength = $req->auth_strength;
isa_ok($strength, 'Authen::NZRealMe::LogonStrength');
eval { $strength->assert_match('low', 'exact'); };
is($@, '', "default auth strength is low");

my $url = $req->as_url;
my($idp_url, $payload, $sig_alg, $sig) = $url =~ m{
    ^(https://.*?)[?]
    SAMLRequest=(.*?)&
    SigAlg=(.*?)&
    Signature=(.*?)(?:$|&)
}x;

ok(defined($sig), 'format of request as URL looks good');
is($idp_url, $sp->idp->single_signon_location, 'host and path are correct');

my $plaintext = "SAMLRequest=$payload&SigAlg=$sig_alg";

($payload, $sig_alg, $sig) = map {
    s{%([0-9a-f]{2})}{chr(hex($1))}ieg;
    $_;
} ($payload, $sig_alg, $sig);

my $b64chr = '[A-Za-z0-9+/]';

like($payload, qr/^$b64chr{200,}=*$/, 'request payload is base64 encoded');
is($sig_alg, 'http://www.w3.org/2000/09/xmldsig#rsa-sha1',
    "signature algorithm is correct");
like($sig, qr/^$b64chr{200,}=*$/, 'signature is base64 encoded');

my $cert_path = test_conf_file('sp-sign-crt.pem');
my $signer = Authen::NZRealMe->class_for('xml_signer')->new(
    pub_cert_file => $cert_path,
);
ok($signer->verify_detached_signature($plaintext, $sig),
    'signature verified successfully using public key from cert');

my $xml = Authen::NZRealMe::AuthenRequest->_request_from_uri($url);
ok($xml, 'extracted XML request for analysis');

xml_found_node_ok($xml, q{/nssamlp:AuthnRequest});
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/@Version} => '2.0');
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/@AssertionConsumerServiceIndex} => '1');
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/@ID} => $req_id);
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/@IssueInstant} => $req->request_time);
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/@Destination} => $sp->idp->single_signon_location);
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/nssaml:Issuer} => $sp->entity_id);
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/nssamlp:NameIDPolicy/@AllowCreate} => 'false');
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/nssamlp:NameIDPolicy/@Format}
    => 'urn:oasis:names:tc:SAML:2.0:nameid-format:persistent');
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/nssamlp:RequestedAuthnContext/nssaml:AuthnContextClassRef}
    => 'urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:LowStrength');


my $req2 = $sp->new_request(
    allow_create  => 1,
    relay_state   => 'pending',
    auth_strength => 'sms',
);

is($req2->allow_create, 'true',    'request enables account creation');
is($req2->relay_state,  'pending', 'request has expected relay state');

$strength = $req2->auth_strength;
isa_ok($strength, 'Authen::NZRealMe::LogonStrength');
eval { $strength->assert_match('mod', 'minimum'); };
is($@, '', "auth strength is at least 'moderate'");
eval { $strength->assert_match('mod', 'exact'); };
is($@, '', "auth strength is 'moderate'");
eval { $strength->assert_match('sms', 'exact'); };
is($@, '', "auth strength is 'moderate-SMS'");

$url = $req2->as_url;
my($relay);
($idp_url, $payload, $relay, $sig_alg, $sig) = $url =~ m{
    ^(https://.*?)[?]
    SAMLRequest=(.*?)&
    RelayState=(.*?)&
    SigAlg=(.*?)&
    Signature=(.*?)(?:$|&)
}x;

ok(defined($sig), 'format of request as URL looks good');
is($relay, 'pending', 'RelayState parameter looks good');

$plaintext = "SAMLRequest=$payload&RelayState=$relay&SigAlg=$sig_alg";

$sig =~ s{%([0-9a-f]{2})}{chr(hex($1))}ieg;

ok($signer->verify_detached_signature($plaintext, $sig),
    'signature verified successfully using public key from cert');


$xml = Authen::NZRealMe::AuthenRequest->_request_from_uri($url);
ok($xml, 'extracted XML request for analysis');

xml_found_node_ok($xml, q{/nssamlp:AuthnRequest});
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/nssamlp:NameIDPolicy/@AllowCreate} => 'true');
xml_node_content_is($xml, q{/nssamlp:AuthnRequest/nssamlp:RequestedAuthnContext/nssaml:AuthnContextClassRef}
    => 'urn:nzl:govt:ict:stds:authn:deployment:GLS:SAML:2.0:ac:classes:ModStrength::OTP:Token:SMS');

done_testing();

