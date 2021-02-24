#!perl
#
# One document may contain multiple <Signature> blocks and each one may contain
# multiple <Reference>s.  Also, due to enveloping transport protocols, each of
# the signatures may have been signed with a different key.  The verifier API
# only allows for one key, so the caller can provide an XPath filter to select
# which <Signature> block they wish to verify (or which ones to ignore).
#
# This test script exercises these scenarios:
#  - a document with more than one signature
#  - signatures created using different keys
#  - a signature which includes multiple references

use strict;
use warnings;

use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper;
use Authen::NZRealMe;
use Authen::NZRealMe::CommonURIs qw(NS_PAIR);
use XML::LibXML;


my $dispatcher    = 'Authen::NZRealMe';
my $sig_class     = $dispatcher->class_for('xml_signer');
my $sp_key_file   = test_conf_file('sp-sign-key.pem');
my $sp_cert_file  = test_conf_file('sp-sign-crt.pem');
my $idp_cert_file = test_conf_file('idp-assertion-sign-crt.pem');

my($verifier, $signer, $xml, $xc, $node, $input, $output, $error);

ok(1, 'initial module load');

$signer = $sig_class->new(key_file => $sp_key_file);
$xml = slurp_file(test_data_file('icms-req-unsigned.xml'));

my $namespaces = [
    soap  => 'http://www.w3.org/2003/05/soap-envelope',
];

my $refs = [
    { ref_id => 'a00d40059264bb32f4f774bc3378c7addb0140a5b', namespaces  => [], transforms => [ 'env_sig', 'ec14n' ] },
    { ref_id => 'c37b3b3b88c6b5d4fe2b8b7460bcdbdd393e262d2', namespaces  => [],  },
    { ref_id => 'b7be00cce26c8cc663dba2b56f84cbdfd6c70d497', namespaces  => ['soap'] },
    { ref_id => 'c84a70491703b6c1fdc615d56a3ca24ba4fab6ab6', namespaces  => ['soap'] },
    { ref_id => 'a605811fea6bfc70f64c64c12fac2495706ea8590', namespaces  => ['soap'] },
    { ref_id => 'c11a21379497138bed1057ec428f99cce72deeef2', namespaces  => ['soap'] },
];

my $signed_xml = $signer->sign(
    $xml,
    undef,    # refs in options
    references              => $refs,
    reference_transforms    => [ 'ec14n' ],
    reference_digest_method => 'sha256',
    namespaces              => $namespaces,
);

ok($signed_xml, 'added a multi-reference signature');

$verifier = $sig_class->new(pub_cert_text  => slurp_file($sp_cert_file));
eval {
    $verifier->verify($signed_xml);
};
like($@, qr{signature does not match}, 'verify failed using SP cert');

$verifier = $sig_class->new(pub_cert_text  => slurp_file($idp_cert_file));
eval {
    $verifier->verify($signed_xml);
};
like($@, qr{signature does not match}, 'verify failed using IdP cert');

$verifier = $sig_class->new(pub_cert_text  => slurp_file($sp_cert_file));
eval {
    my $selector = '//ds:Signature[not(ancestor::soap12:Body)]';
    $verifier->verify($signed_xml, $selector, NS_PAIR('soap12'));
};
is($@, '', 'verify succeeded using SP cert with XPath filter');

$verifier = $sig_class->new(pub_cert_text  => slurp_file($idp_cert_file));
eval {
    my $selector = '//ds:Signature[ancestor::soap12:Body]';
    $verifier->verify($signed_xml, $selector, NS_PAIR('soap12'));
};
is($@, '', 'verify succeeded using IdP cert with XPath filter');

$xc = $sig_class->_xcdom_from_xml($signed_xml);
$xc->registerNs(NS_PAIR('soap12'));
$xc->registerNs(NS_PAIR('wsse'));

my($sig) = $xc->findnodes('//wsse:Security//ds:Signature');
ok($sig, 'found the multi-ref signature block');

my $ref = $verifier->_parse_signature_block($xc, $sig);
ok($ref, 'successfully parsed signature block');

is(
    scalar(@{ $ref->{references} }),
    6,
    'SigInfo block contains multiple references'
);

($sig) = $xc->findnodes('//soap12:Body//ds:Signature');
ok($sig, 'found the single-ref signature block');

$ref = $verifier->_parse_signature_block($xc, $sig);
ok($ref, 'successfully parsed signature block');

is(
    scalar(@{ $ref->{references} }),
    1,
    'SigInfo block contains one reference'
);

done_testing(); exit;

my @frags = eval {
    $verifier->_verify_one_signature_block($xc, $ref);
};
is($@, '', 'verification did not throw exception');

eval {
    $verifier->verify($xml);
};
like(
    $@,
    qr{SignedInfo block signature does not match},
    'verification threw exception due to wrong key for sig in soap:Body'
);

eval {
    my $selector = '//ds:Signature[not(ancestor::soap12:Body)]';
    $verifier->verify($xml, $selector, NS_PAIR('soap12'));
};
is(
    $@,
    '',
    'verification succeeded when sig in soapBody filtered out'
);

done_testing();
exit;

