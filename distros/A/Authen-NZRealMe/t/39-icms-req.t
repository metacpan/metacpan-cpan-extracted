#!perl
#
# Generate an iCMS request document that contains an 'opaque token' and has a
# multi-reference signature.  Check it's structure and signature.
#

use strict;
use warnings;

use Test::More;

require XML::LibXML;
require XML::LibXML::XPathContext;

use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper;
use Authen::NZRealMe;
use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);

Authen::NZRealMe->register_class(service_provider   => 'MockSP');

my $dispatcher    = 'Authen::NZRealMe';
my $sig_class     = $dispatcher->class_for('xml_signer');
my $sp_key_file   = test_conf_file('sp-sign-key.pem');
my $sp_cert_file  = test_conf_file('sp-sign-crt.pem');

my @all_ns = (
    [ soap12 => 'http://www.w3.org/2003/05/soap-envelope' ],
    [ wsse   => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' ],
    [ wsu    => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd' ],
    [ wst    => 'http://docs.oasis-open.org/ws-sx/ws-trust/200512' ],
    [ wsa    => 'http://www.w3.org/2005/08/addressing' ],
    [ icms   => 'urn:nzl:govt:ict:stds:authn:deployment:igovt:gls:iCMS:1_0' ],
    [ ds     => 'http://www.w3.org/2000/09/xmldsig#' ],
);


my $conf_dir = test_conf_dir();
my $sp = Authen::NZRealMe->service_provider(
    conf_dir  => $conf_dir,
    type      => 'assertion',
);
ok(1, 'loaded required modules');

my $opaque_token = '[[OPAQUE-TOKEN-GOES-HERE]]';
my $req_builder = Authen::NZRealMe->class_for('icms_resolution_request');
my $req = $req_builder->new($sp, $opaque_token);

my $icms_req = $req->request_data;
ok($icms_req, 'generated an icms request document');

my $verifier = $sig_class->new(pub_cert_file => $sp_cert_file);
my $selector = '//ds:Signature[not(ancestor::soap12:Body)]';
ok(
    $verifier->verify($icms_req, $selector, NS_PAIR('soap12')),
    "verified request signature using SP's public key"
);

my $parser = XML::LibXML->new();
my $doc    = $parser->parse_string($icms_req);
my $xc     = XML::LibXML::XPathContext->new($doc->documentElement);
$xc->registerNs( @$_ ) foreach @all_ns;

my($node) = eval {
    $verifier->find_verified_element($xc, '//soap12:Header');
};
ok(!$node, "failed to find SOAP Header element");
like($@, qr{not in a signed fragment}, '  because it is outside signed areas');

($node) = eval {
    $verifier->find_verified_element($xc, '//soap12:Header/wsa:Action');
};
is($@, '', 'wsa:Action inside SOAP Header is verified');
is(
    $node->to_literal,
    'http://docs.oasis-open.org/ws-sx/ws-trust/200512/RST/Validate',
    '  and has expected content'
);

($node) = eval {
    $verifier->find_verified_element($xc, '//soap12:Header/wsa:To');
};
is($@, '', 'wsa:To inside SOAP Header is verified');
is(
    $node->to_literal,
    'https://ws.test.logon.fakeme.govt.nz/icms/Validate_v1_1',
    '  and has expected content'
);

($node) = eval {
    $verifier->find_verified_element($xc, '//soap12:Header/wsa:ReplyTo/wsa:Address');
};
is($@, '', 'wsa:ReplyTo/wsa:Address inside SOAP Header is verified');
is(
    $node->to_literal,
    'http://www.w3.org/2005/08/addressing/anonymous',
    '  and has expected content'
);

($node) = eval {
    $verifier->find_verified_element($xc,
        '//soap12:Body/wst:RequestSecurityToken/wst:TokenType'
    );
};
is($@, '', 'wst:RequestSecurityToken/wst:TokenType inside SOAP Body is verified');
is(
    $node->to_literal,
    'http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0',
    '  and has expected content'
);

($node) = eval {
    $verifier->find_verified_element($xc,
        '//soap12:Body/wst:RequestSecurityToken/wst:ValidateTarget'
    );
};
is($@, '', 'element containing opaque token inside SOAP Body is verified');
is(
    $node->to_literal,
    '[[OPAQUE-TOKEN-GOES-HERE]]',
    '  and has expected content'
);

($node) = eval {
    $verifier->find_verified_element($xc,
        '//soap12:Body/wst:RequestSecurityToken/icms:AllowCreateFLT'
    );
};
is($@, '', 'iCMS:AllowCreateFLT flag inside SOAP Body is verified');

my($keyinfo) = $xc->findnodes('//ds:Signature/ds:KeyInfo');
ok($keyinfo, 'signature block contains a KeyInfo element');
is(
    $keyinfo->{Id},
    'KI-C3FA9C690ED1545A81EEC4F3F7DDAE806876C8D21',
    '  which has the expected Id attribute'
);

my($sec_token) = $xc->findnodes('./wsse:SecurityTokenReference', $keyinfo);
ok($sec_token, '  and contains a wsse:SecurityTokenReference element');
is(
    $sec_token->{Id},
    'STR-C3FA9C690ED1545A81EEC4F3F7DDAE806876C8D22',
    '    which has the expected Id attribute'
);

my($key_id) = $xc->findnodes('./wsse:KeyIdentifier', $sec_token);
ok($key_id, '    and contains a wsse:KeyIdentifier element');
is(
    $key_id->{ValueType},
    'http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1',
    '      which has the expected ValueType attribute'
);
is(
    $key_id->{EncodingType},
    'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary',
    '      and the expected EncodingType attribute'
);
is(
    $key_id->to_literal,
    'w/qcaQ7RVFqB7sTz992ugGh2yNI=',
    '      and the expected content'
);

done_testing();
exit;
