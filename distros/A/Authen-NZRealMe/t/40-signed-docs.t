#!perl

use strict;
use warnings;
use autodie;

use Test::More;
use FindBin;
use File::Spec;
use lib File::Spec->catdir($FindBin::Bin, 'test-lib');

use AuthenNZRealMeTestHelper;
use Authen::NZRealMe;
use XML::LibXML;

my $doc_dir   = File::Spec->catdir($FindBin::Bin, 'signed-docs');
my $conf_dir  = File::Spec->catdir($FindBin::Bin, 'test-conf');

my $dispatcher    = 'Authen::NZRealMe';
my $sig_class     = $dispatcher->class_for('xml_signer');

my $idp_sign_cert = 'idp-assertion-sign-crt.pem';

my @ns_prefixes   = (
    saml  => 'urn:oasis:names:tc:SAML:2.0:assertion',
);

my @test_docs = (
    {
        xml_file    => '01-simple-rsa-sha1.xml',
        sign_cert   => $idp_sign_cert,
        xpath_query => '//Assertion/AttributeStatement/Attribute[@Name="firstName"]',
        corrupter   => sub { s/1988-08-08/1988-08-09/; },
    },
    {
        xml_file    => '02-simple-rsa-sha256.xml',
        sign_cert   => $idp_sign_cert,
        xpath_query => '//Assertion/AttributeStatement/Attribute[@Name="firstName"]',
        corrupter   => sub { s/1988-08-08/1988-08-09/; },
    },
    {
        xml_file    => '10-login-assertion-rsa-sha1.xml',
        sign_cert   => $idp_sign_cert,
        xpath_query => '//saml:Assertion/saml:Subject',
        corrupter   => sub { s/CHCDF875/CHCDF876/; },
    },
    {
        xml_file    => '11-login-assertion-rsa-sha256.xml',
        sign_cert   => $idp_sign_cert,
        xpath_query => '//saml:Assertion/saml:Subject',
        corrupter   => sub { s/CHC9F824/CHC9F825/; },
    },
    {
        xml_file    => '20-identity-assertion-rsa-sha1.xml',
        sign_cert   => $idp_sign_cert,
        xpath_query => '//saml:Assertion/saml:Subject',
        corrupter   => sub { s/PD94bWwgdmVyc/PD94bWwgdmVyC/; },
    },
    {
        xml_file    => '30-encrypted-assertion-and-flt-json.xml',
        sign_cert   => $idp_sign_cert,
        xpath_query => '//saml:Assertion/saml:Subject',
        corrupter   => sub { s/eyJUcmFuc2F/eyJUcmFuc2f/; },
    },
);

foreach my $test (@test_docs) {
    ok(1, "==== $test->{xml_file} ====");
    my $xml  = slurp_doc($test->{xml_file});
    my $verifier = new_verifier(cert_file => $test->{sign_cert});
    eval { $verifier->verify($xml); };
    is($@, '', 'successfully verified signature');
    if($verifier->can('find_verified_element')) {
        my $xc = parse_xml_to_xc($xml, @ns_prefixes);
        my($node) = eval {
            $verifier->find_verified_element($xc, $test->{xpath_query});
        };
        is($@, '', 'find_verified_element() did not die');
        ok($node, 'found target element in signed section');
    }
    if($test->{corrupter}) {
        $_ = $xml;
        $test->{corrupter}->()
            or die "corrupter function failed to find a match";
        eval { $verifier->verify($_); };
        isnt($@, '', 'signature verification detected document alteration');
    }
}

done_testing();
exit;


sub slurp_doc {
    my($file) = @_;

    return slurp_file(File::Spec->catdir($doc_dir, $file));
}


sub new_verifier {
    my(%opt) = @_;

    my $cert_path = File::Spec->catdir($conf_dir, $opt{cert_file});
    my $cert_text = slurp_file($cert_path);
    my $verifier = $sig_class->new(
        pub_cert_text => $cert_text,
    );
}

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
    return $xc;
}

