#!perl

use strict;
use warnings;

use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper;
use Authen::NZRealMe;
use XML::LibXML;


my $dispatcher    = 'Authen::NZRealMe';
my $sig_class     = $dispatcher->class_for('xml_signer');
my $idp_cert_file = test_conf_file('idp-assertion-sign-crt.pem');
my $idp_key_file  = test_conf_file('idp-assertion-sign-key.pem');

my @ns_ds = (ds => 'http://www.w3.org/2000/09/xmldsig#');

my($verifier, $signer, $xml, $xc, $node, $input, $output, $error);


##############################################################################
# Transform methods

$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);
my($tr_by_name, $tr_by_uri, $expected, $parser, $doc, $frag);

ok('1', '===== C14N Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('c14n');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/TR/2001/REC-xml-c14n-20010315');

is(ref($tr_by_name) => 'HASH', 'found c14n by name');
is(ref($tr_by_uri)  => 'HASH', 'found c14n by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title>
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, $expected, 'canonical output (from string)');

$xc = parse_xml_to_xc($input);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== C14N-With-Comments Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('c14n_wc');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/TR/2001/REC-xml-c14n-20010315#WithComments');

is(ref($tr_by_name) => 'HASH', 'found c14n_wc by name');
is(ref($tr_by_uri)  => 'HASH', 'found c14n_wc by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, $expected, 'canonical output (from string)');

$xc = parse_xml_to_xc($input);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== C14N Fragment Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('c14n');

$input = q{<box:Container xmlns:box="https://example.com/box/"><Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc></box:Container>};

$expected = q{<Doc xmlns="https://example.com/doc/" xmlns:box="https://example.com/box/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title>
</Doc>};

$xc = parse_xml_to_xc($input, 'doc' => 'https://example.com/doc/');
($frag) = $xc->findnodes('//doc:Doc');
isa_ok($frag => 'XML::LibXML::Element', 'fragment node');

$output = $verifier->_apply_transform($tr_by_name, [$xc, $frag]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== C14N11 Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('c14n11');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2006/12/xml-c14n11');

is(ref($tr_by_name) => 'HASH', 'found c14n11 by name');
is(ref($tr_by_uri)  => 'HASH', 'found c14n11 by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title>
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, $expected, 'canonical output (from string)');

$xc = parse_xml_to_xc($input);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== C14N11-With-Comments Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('c14n11_wc');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2006/12/xml-c14n11#WithComments');

is(ref($tr_by_name) => 'HASH', 'found c14n11_wc by name');
is(ref($tr_by_uri)  => 'HASH', 'found c14n11_wc by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, $expected, 'canonical output (from string)');

$xc = parse_xml_to_xc($input);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== C14N11 Fragment Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('c14n11');

$input = q{<box:Container xmlns:box="https://example.com/box/"><Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc></box:Container>};

$expected = q{<Doc xmlns="https://example.com/doc/" xmlns:box="https://example.com/box/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title>
</Doc>};

$xc = parse_xml_to_xc($input, 'doc' => 'https://example.com/doc/');
($frag) = $xc->findnodes('//doc:Doc');
isa_ok($frag => 'XML::LibXML::Element', 'fragment node');

$output = $verifier->_apply_transform($tr_by_name, [$xc, $frag]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== EC14N Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('ec14n');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2001/10/xml-exc-c14n#');

is(ref($tr_by_name) => 'HASH', 'found ec14n by name');
is(ref($tr_by_uri)  => 'HASH', 'found ec14n by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title>
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, $expected, 'canonical output (from string)');

$xc = parse_xml_to_xc($input);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== EC14N-With-Comments Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('ec14n_wc');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2001/10/xml-exc-c14n#WithComments');

is(ref($tr_by_name) => 'HASH', 'found ec14n_wc by name');
is(ref($tr_by_uri)  => 'HASH', 'found ec14n_wc by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, $expected, 'canonical output (from string)');

$xc = parse_xml_to_xc($input);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== EC14N Fragment Canonicalisation =====');

$tr_by_name = $verifier->_find_transform('ec14n');

$input = q{<box:Container xmlns:box="https://example.com/box/"><Doc ccc="three"
bbb="tw&#111;"
aaa="one"
xmlns="https://example.com/doc/">
  <Title>Example Document</Title><!-- a comment -->
</Doc></box:Container>};

$expected = q{<Doc xmlns="https://example.com/doc/" aaa="one" bbb="two" ccc="three">
  <Title>Example Document</Title>
</Doc>};

$xc = parse_xml_to_xc($input, 'doc' => 'https://example.com/doc/');
($frag) = $xc->findnodes('//doc:Doc');
isa_ok($frag => 'XML::LibXML::Element', 'fragment node');

$output = $verifier->_apply_transform($tr_by_name, [$xc, $frag]);
is($output, $expected, 'canonical output (from DOM fragment)');

ok('1', '===== Enveloped Signature =====');

$tr_by_name = $verifier->_find_transform('env_sig');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2000/09/xmldsig#enveloped-signature');

is(ref($tr_by_name) => 'HASH', 'found env-sig by name');
is(ref($tr_by_uri)  => 'HASH', 'found env-sig by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$input = q{<Doc><dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
  <dsig:SignedInfo>
    <content>Random stuff goes here</content>
    <!-- Nobody would put a comment in their <Signature> -->
  </dsig:SignedInfo>
</dsig:Signature>
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$expected = q{<Doc>
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$output = $verifier->_apply_transform($tr_by_name, $input);
isa_ok($output => 'ARRAY', 'fragment node');
$output = $output->[1];
isa_ok($output => 'XML::LibXML::Element', 'transformed document node');
is($output->toStringEC14N(1), $expected, 'env-sig output (from string)');

$xc = parse_xml_to_xc($input, @ns_ds);
$output = $verifier->_apply_transform($tr_by_name, [$xc, $xc->getContextNode]);
isa_ok($output => 'ARRAY', 'fragment node');
$output = $output->[1];
isa_ok($output => 'XML::LibXML::Element', 'transformed document node');
is($output->toStringEC14N(1), $expected, 'env-sig output (from DOM fragment)');

ok('1', '===== SHA1 Digest =====');

$input = q{<Doc>
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$tr_by_name = $verifier->_find_transform('sha1');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2000/09/xmldsig#sha1');

is(ref($tr_by_name) => 'HASH', 'found sha1 by name');
is(ref($tr_by_uri)  => 'HASH', 'found sha1 by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, 'zCGTIejOvqGvd6KSmlk4aFOW4Ro=', 'sha1 digest output (from string)');

# No test for sha1 digest with a DOM fragment as input - since any sane
# implementation would use a c14n transform to provide an input string.

ok('1', '===== SHA256 Digest =====');

$input = q{<Doc>
  <Title>Example Document</Title><!-- a comment -->
</Doc>};

$tr_by_name = $verifier->_find_transform('sha256');
$tr_by_uri  = $verifier->_find_transform('http://www.w3.org/2001/04/xmlenc#sha256');

is(ref($tr_by_name) => 'HASH', 'found sha256 by name');
is(ref($tr_by_uri)  => 'HASH', 'found sha256 by URI');
is($tr_by_name->{uri} => $tr_by_uri->{uri}, 'same transform URI');
is($tr_by_name->{method} => $tr_by_uri->{method}, 'same transform method name');

$output = $verifier->_apply_transform($tr_by_name, $input);
is($output, 'WjnmbezTqKqqU7dyvyFO46FwLTa3KBOsklKGLYK4Ge4=',
    'sha256 digest output (from string)'
);

# No test for sha256 digest with a DOM fragment as input - since any sane
# implementation would use a c14n transform to provide an input string.


##############################################################################
# Raw signature methods

my $plaintext       = 'This is some plain text';
my $mismatched_text = 'This is some different plain text';
$signer = $sig_class->new(
    key_text  => slurp_file($idp_key_file),
);
$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);
my($sig_alg, $b64_sig);

ok('1', '===== RSA-SHA1 Signature =====');

$sig_alg = $signer->_find_sig_alg('rsa_sha1');
$b64_sig = $signer->_create_signature($sig_alg, $plaintext);
$b64_sig =~ s/\s+//g;
is(
    $b64_sig,
    'eUrNfCVSosr1PsyofbeC4PyNQZrNuxHE3iw5YBWL8Q39TSvera9Ef6wYSSETSE6j'
    . 'xSXq4JCapAyaj3EcMeu4ksngLmZ+pfrJX/f71gOUAefHCyvr8KNKG4QuUYeL0X'
    . 'Qw0NDnttmfAt4pduVBIkvFMiX6SfFOGz+pmLIZaZg7wIDQkovOEtmpsg/IL4zy'
    . 'v05z52XTMZdXQ+4RAL/YOdzJZ3ow7l6R/q/yZjakMGWIkqWwa7AcL6YPt/Awyw'
    . '50fMtcGii4GVGbOsVUUjHbld4SG1uffzCpOCqqFKKrQWRPjUJuAs9c3L6aqkKf'
    . '80aODokUFhftgM5sMmg3iyNsao2WLw==',
    'created RSA-SHA1 hash signature'
);
ok(
    $verifier->_verify_signature($sig_alg, $plaintext, $b64_sig),
    'verified RSA-SHA1 hash signature'
);
ok(
    !$verifier->_verify_signature($sig_alg, $mismatched_text, $b64_sig),
    'failed to verify mismatched RSA-SHA1 hash signature'
);

ok('1', '===== RSA-SHA256 Signature =====');

$sig_alg = $signer->_find_sig_alg('rsa_sha256');
$b64_sig = $signer->_create_signature($sig_alg, $plaintext);
$b64_sig =~ s/\s+//g;
is(
    $b64_sig,
    'YeR7ga5hEXBD7BL3NTUjReKG09hSp0sWFNs5WpOD3td0nFARedv5Bn6uy1zf2zuW'
    . 'qZos6cyenUERRypZN0QnD5O7M1OmlV/Kpv40UkcMdFqPT/wQP2OHe+YaKXO3b1'
    . 'V9gq1eGhk5wqW51y3Uu6GawKqJj9VZNPD20cDGvTeegtoNjiY3wrFu4G/v6Ro2'
    . 'OaWXOkyQrXN0Ql2TheK4qMV2fklknKsv87H+BCK75+IWHn63LBvavY5kUyvM/2'
    . 'i2n9aoPLkrlVv32dOGFPdN5PE12B8ujcRiywXAHNffYo7s24rbMk/hKAXCG4Ot'
    . '/sh7T+WbBs2Ny8VPq0lgmfnN6o3x0A==',
    'created RSA-SHA256 hash signature'
);
ok(
    $verifier->_verify_signature($sig_alg, $plaintext, $b64_sig),
    'verified RSA-SHA256 hash signature'
);
ok(
    !$verifier->_verify_signature($sig_alg, $mismatched_text, $b64_sig),
    'failed to verify mismatched RSA-SHA256 hash signature'
);


##############################################################################
# Parse out an 'enveloped signature' from a document

ok('1', '===== Parsing of <Signature> blocks =====');

$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);

$xml =  q{<Container><Assertion ID="Idd02c7c2232759874e1c205587017bed"><dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
  <dsig:SignedInfo>
    <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <dsig:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
    <dsig:Reference URI="#Idd02c7c2232759874e1c205587017bed">
      <dsig:Transforms>
        <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
        <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      </dsig:Transforms>
      <dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
      <dsig:DigestValue>Wgb21Ak30ZPTzFKw5uPlRzVd7zo=</dsig:DigestValue>
    </dsig:Reference>
  </dsig:SignedInfo>
  <dsig:SignatureValue>
oO8JbDW0l0b3KmqAu2LryU2gHTQTGaUrwOyURv/r5YHLa3mtqlF4Gkq3qy7kEgCb
Pqwq1JHuvoG1XZ6j0StSkt+mK12AOubIuLXT/SKBU4X7MBv0HwfL5U1XXEMV8mG8
t67f2kdOBJMeVIKU3Unw9fIWhKSjSeTArqNAdk1yCWS2NmpfG7Peu59mwqve7QTh
8KaD9Ro+PYHpYnB2Ah8OPofo7ym0hK85eM753W/SlWBf4aj5yuZGUCPv3k3sXMbe
VJfZ6GIwOJeGPRuGAZe8zDVsuXwnTeB6pW8huqGJduUP/JPi1LaUjpMRG3+R7yAh
IkDsvPCXLAeAjQ7jeucNpg==
</dsig:SignatureValue>
</dsig:Signature>
  <Identity>
    <Name>Bob</Name><!-- no surname -->
    <DateOfBirth>1954-03-21</DateOfBirth>
  </Identity>
</Assertion>
<Unsafe>
  <Assertion>Elvis is alive</Assertion>
</Unsafe>
</Container>
};

$xc = parse_xml_to_xc($xml, @ns_ds);
($node) = $xc->findnodes('//ds:Signature');
my($sig) = $verifier->_parse_signature_block($xc, $node);

is(ref($sig) => 'HASH', 'found a sig block');
isa_ok($sig->{sig_info_node} => 'XML::LibXML::Element', '<SignedInfo> element');

my $c14n = $sig->{c14n};
is(ref($c14n)      => 'HASH', 'canonicalisation is defined');
is($c14n->{name}   => 'ec14n', '  name');
is($c14n->{uri}    => 'http://www.w3.org/2001/10/xml-exc-c14n#', '  uri');
is($c14n->{method} => '_apply_transform_ec14n', '  method');

my $xc_inp = [ $xc, $sig->{sig_info_node} ];
my $sig_info_plaintext = $verifier->_apply_transform($c14n, $xc_inp);

$sig_alg = $sig->{signature_algorithm};
is(ref($sig_alg)      => 'HASH', 'signature method is defined');
is($sig_alg->{name}   => 'rsa_sha1', '  name');
is($sig_alg->{uri}    => 'http://www.w3.org/2000/09/xmldsig#rsa-sha1', '  uri');
is($sig_alg->{sign_method}   => '_create_signature_rsa_sha1', '  sign_method');
is($sig_alg->{verify_method} => '_verify_signature_rsa_sha1', '  verify_method');

is($sig->{signature_value} =>
    'oO8JbDW0l0b3KmqAu2LryU2gHTQTGaUrwOyURv/r5YHLa3mtqlF4Gkq3qy7kEgCb'
    . 'Pqwq1JHuvoG1XZ6j0StSkt+mK12AOubIuLXT/SKBU4X7MBv0HwfL5U1XXEMV8mG8'
    . 't67f2kdOBJMeVIKU3Unw9fIWhKSjSeTArqNAdk1yCWS2NmpfG7Peu59mwqve7QTh'
    . '8KaD9Ro+PYHpYnB2Ah8OPofo7ym0hK85eM753W/SlWBf4aj5yuZGUCPv3k3sXMbe'
    . 'VJfZ6GIwOJeGPRuGAZe8zDVsuXwnTeB6pW8huqGJduUP/JPi1LaUjpMRG3+R7yAh'
    . 'IkDsvPCXLAeAjQ7jeucNpg==',
    'signature_value'
);

my $v_method = $sig_alg->{verify_method};
my $result = $verifier->_verify_signature(
    $sig_alg, $sig_info_plaintext, $sig->{signature_value}
);
ok($result, 'signature was verified successfully');

# Check the contents of the <SignedInfo> block
my $refs = $sig->{references};
is(ref($refs)      => 'ARRAY', 'references defined');
is(scalar(@$refs)  => 1, '  exactly one in list');

my($ref1) = @$refs;
is(ref($ref1)      => 'HASH', 'first (and only) reference');
is($ref1->{ref_id} => 'Idd02c7c2232759874e1c205587017bed', '  ref_id');

my $trans = $ref1->{transforms};
is(ref($trans)      => 'ARRAY', '  transforms defined');
is(scalar(@$trans)  => 2, '    exactly two in list');

my $t1 = $trans->[0];
is($t1->{name}   => 'env_sig', '    t1 name');
is($t1->{uri}    => 'http://www.w3.org/2000/09/xmldsig#enveloped-signature', '    t1 uri');
is($t1->{method} => '_apply_transform_env_sig', '    t1 method');

my $t2 = $trans->[1];
is($t2->{name}   => 'ec14n', '    t2 name');
is($t2->{uri}    => 'http://www.w3.org/2001/10/xml-exc-c14n#', '    t2 uri');
is($t2->{method} => '_apply_transform_ec14n', '    t2 method');

my $digm = $ref1->{digest_method};
is(ref($digm)      => 'HASH', '  digest method is defined');
is($digm->{name}   => 'sha1', '    name');
is($digm->{uri}    => 'http://www.w3.org/2000/09/xmldsig#sha1', '    uri');
is($digm->{method} => '_apply_transform_sha1', '    method');

is($ref1->{digest_value} => 'Wgb21Ak30ZPTzFKw5uPlRzVd7zo=', '  digest_value');


my $id_attr = $verifier->id_attr;
is($id_attr => undef, 'no default attribute name for references');

$node = $ref1->{xml_node};
my $node_xml = $node->toString();
like($node_xml => qr{\A<Assertion\b}, '  top level tag is <Assertion>');
like($node_xml => qr{\A<[^>]+ ID="Idd02c7c2232759874e1c205587017bed"},
    '  ID attribute value'
);
like($node_xml => qr{<Identity\b}, '  included child tag <Identity>');
like($node_xml => qr{<!-- no surname -->}, '  included comment');

# Apply first transform listed above
my($assertion) = $xc->findnodes('/Container/Assertion');
$input = [ $xc, $assertion ];
$output = $verifier->_apply_transform($t1, $input);
is(ref($output) => 'ARRAY', 'transform 1 output');
my $x1_node = $output->[1];
isa_ok($x1_node => 'XML::LibXML::Element', 'transformed output node');
my $x1_xml = $x1_node->toString();
like($x1_xml => qr{\A<Assertion\b}, '  top level tag is <Assertion>');
like($x1_xml => qr{<Identity\b}, '  included child tag <Identity>');
like($x1_xml => qr{<!-- no surname -->}, '  included comment');
unlike($x1_xml => qr{<dsig:Signature\b}, '  child tag <Signature> not included');

# Apply second transform listed above
$input = $output;
$output = $verifier->_apply_transform($t2, $input);
is(ref($output) => '', 'transform returned a string');
like($output => qr{\A<Assertion\b}, '  top level tag is <Assertion>');
like($output => qr{<Identity\b}, '  included child tag <Identity>');
unlike($output => qr{<!-- no surname -->}, '  comment omitted');
unlike($output => qr{<dsig:Signature\b}, '  child tag <Signature> not included');
is($output => q{<Assertion ID="Idd02c7c2232759874e1c205587017bed">
  <Identity>
    <Name>Bob</Name>
    <DateOfBirth>1954-03-21</DateOfBirth>
  </Identity>
</Assertion>}, '  canonical form');

# Apply digest method
$input = $output;
$output = $verifier->_apply_transform($digm, $input);
is(ref($output) => '', 'digest transform returned a string');
is($output => 'Wgb21Ak30ZPTzFKw5uPlRzVd7zo=', '  calculated digest');
is($output => $ref1->{digest_value}, '  expected digest (from signature block)');


##############################################################################
# Use the verify method (which does all of the above) on the same XML document

ok('1', '===== verify() method =====');

$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);

eval { $verifier->verify($xml); };
is($@, '', 'signature verification was successful');

my @frags = $verifier->_signed_fragment_paths;
is(scalar(@frags), 1, 'one signed fragment was found');
is($frags[0], '/Container/Assertion', 'XPath for signed fragment');

$xc = parse_xml_to_xc($xml);

$node = eval {
    $verifier->find_verified_element($xc, '/Assertion');
};
like($@, qr{No element matches: '/Assertion'}, 'XPath did not match');

$node = eval {
    $verifier->find_verified_element($xc, '/Container/Unsafe/Assertion');
};
like($@,
    qr{Element matching '/Container/Unsafe/Assertion' is not in a signed fragment},
    'XPath matched unsigned element'
);

$node = eval { $verifier->find_verified_element($xc, '/Container/Assertion'); };
is($@, '', 'found a verified element');
isa_ok($node => 'XML::LibXML::Element', 'fragment node');
is($node->{ID} => 'Idd02c7c2232759874e1c205587017bed', 'got the assertion node');
my $name = $xc->findvalue('./Identity/Name', $node);
is($name => 'Bob', 'fragment includes <Name> element');


##############################################################################
# Try again but with referenced content that does not match the signature
# i.e.: tamper with the signed content.

$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);

$xml =~ s{1954-03-21}{1954-03-22};

eval { $verifier->verify($xml); };
$error = $@;
like($@, qr{Signature verification failed.}, 'signature verification failed');
like($@, qr{Digest.*differs.*from.*reference}, 'due to digest mismatch');


##############################################################################
# Try again but alter the expected digest to match the altered content
# i.e.: tamper with the contents of the signed info block too.

$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);

$xml =~ s{1954-03-21}{1954-03-22};
$xml =~ s{Wgb21Ak30ZPTzFKw5uPlRzVd7zo=}{iIixkNtguqdVy8HcCFQSIbeMwMo=};

eval { $verifier->verify($xml); };
$error = $@;
like($@, qr{Signature verification failed.}, 'signature verification failed');
like($@, qr{signature does not match}, 'due to signature mismatch');


##############################################################################
# Try again but with a document that is not signed.

$verifier = $sig_class->new(
    pub_cert_text  => slurp_file($idp_cert_file),
);

eval { $verifier->verify('<Doc>Content Here</Doc>'); };
like($@, qr{XML document contains no signatures}, 'no signature to verify');



##############################################################################
# Test creation of signature

ok('1', '===== _make_sig_xml() method =====');

$xml =  q{<Container><Assertion ID="Idd02c7c2232759874e1c205587017bed">
  <Identity>
    <Name>Bob</Name><!-- no surname -->
    <DateOfBirth>1954-03-21</DateOfBirth>
  </Identity>
</Assertion>
</Container>
};

$xc = parse_xml_to_xc($xml);

$signer = $sig_class->new(
    pub_cert_text => slurp_file($idp_cert_file),
    key_file      => $idp_key_file,
);

my $sig_xml = $signer->_make_sig_xml(
    $xc,
    references => [
        {
            ref_id  => 'Idd02c7c2232759874e1c205587017bed',
        }
    ],
);

is($sig_xml, q{<dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
  <dsig:SignedInfo>
    <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
    <dsig:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1"/>
    <dsig:Reference URI="#Idd02c7c2232759874e1c205587017bed">
      <dsig:Transforms>
        <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature"/>
        <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#"/>
      </dsig:Transforms>
      <dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1"/>
      <dsig:DigestValue>Wgb21Ak30ZPTzFKw5uPlRzVd7zo=</dsig:DigestValue>
    </dsig:Reference>
  </dsig:SignedInfo>
  <dsig:SignatureValue>
oO8JbDW0l0b3KmqAu2LryU2gHTQTGaUrwOyURv/r5YHLa3mtqlF4Gkq3qy7kEgCbPqwq1JHuvoG1
XZ6j0StSkt+mK12AOubIuLXT/SKBU4X7MBv0HwfL5U1XXEMV8mG8t67f2kdOBJMeVIKU3Unw9fIW
hKSjSeTArqNAdk1yCWS2NmpfG7Peu59mwqve7QTh8KaD9Ro+PYHpYnB2Ah8OPofo7ym0hK85eM75
3W/SlWBf4aj5yuZGUCPv3k3sXMbeVJfZ6GIwOJeGPRuGAZe8zDVsuXwnTeB6pW8huqGJduUP/JPi
1LaUjpMRG3+R7yAhIkDsvPCXLAeAjQ7jeucNpg==
</dsig:SignatureValue>
</dsig:Signature>}, 'generated signature block');


done_testing();
exit;


sub parse_xml_to_xc {
    my $xml_source = shift;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($xml_source);
    my $xc     = XML::LibXML::XPathContext->new($doc->documentElement);

    while(@_) {
        my $prefix = shift;
        my $uri    = shift;
        $xc->registerNs($prefix => $uri);
    }
    $xc->setContextNode($doc->documentElement);
    return $xc;
}
