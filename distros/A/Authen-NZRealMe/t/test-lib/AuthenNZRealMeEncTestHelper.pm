package AuthenNZRealMeEncTestHelper;

# Helper routine for generating signed and encrypted assertions

use 5.014;
use strict;
use warnings;
use autodie;

use AuthenNZRealMeTestHelper qw(test_conf_file test_data_file slurp_file);
use AuthenNZRealMeSigTestHelper;

use Authen::NZRealMe;

require XML::LibXML;
require XML::LibXML::XPathContext;

use MIME::Base64    qw(encode_base64);


sub regenerate_saml_response_post_file {
    my %args = @_;

    my $source_xml_file = $args{assertion_source_file}
        or die "need assertion_source_xml";

    my $output_file = $args{output_file}
        or die "need output_file to save signed, encrypted, encoded assertion";

    my $target_id = $args{signature_target_id};

    my $idp_key_file      = test_conf_file('idp-assertion-sign-key.pem');
    my $idp_pub_cert_file = test_conf_file('idp-assertion-sign-crt.pem');
    my $sp_key_file       = test_conf_file('sp-sign-key.pem');
    my $sp_pub_cert_file  = test_conf_file('sp-sign-crt.pem');

    # Issue a warning, because this code path is intended for to be used to
    # generate static test files - we don't want our tests to only confirm
    # consuming assertions that were created by the version of the same
    # codebase.

    warn "\nWARNING: Generating a signed & encrypted assertion in"
        . " $args{output_file} from $args{assertion_source_file}\n";

    # Start with the base assertion file (not signed and not encrypted)

    my $xml = slurp_file( test_data_file($source_xml_file) );

    # Sign and encrypt assertion (if needed)

    my $encrypted_xml;
    if($target_id) {
        my $signer_algorithm     = $args{algorithms}{signer}     or die "need signer algorithm";
        my $random_key_algorithm = $args{algorithms}{random_key} or die "need random_key algorithm";
        my $encrypt_algorithm    = $args{algorithms}{encrypt}    or die "need encrypt algorithm";

        # Add a signature (using incorrect key if a bad sig is required)

        if($args{bad_sig}) {
            $idp_key_file      = $sp_key_file;
            $idp_pub_cert_file = $sp_pub_cert_file;
        }
        my $signer = Authen::NZRealMe->class_for('xml_signer')->new(
            key_file          => $idp_key_file,
            pub_cert_file     => $idp_pub_cert_file,
            algorithm         => $signer_algorithm,
            id_attr           => 'ID',
            include_x509_cert => 1,
        );

        my $signed_xml = $signer->sign($xml, $target_id) . "\n";

        # Encrypt the contents of the <EncryptedAssertion> element

        my $encrypter = Authen::NZRealMe->class_for('xml_encrypter')->new(
            pub_cert_file     => $sp_pub_cert_file,
            id_attr           => 'ID',
            include_x509_cert => 1,
        );

        $encrypted_xml = $encrypter->encrypt_one_element($signed_xml,
            algorithm         => $encrypt_algorithm,
            key_algorithm     => $random_key_algorithm,
            target_id         => $target_id,
        );
        $encrypted_xml =~ s{\A\s*<[?]xml.*?[?]>\s+}{};
    }
    else {
        warn "no signature_target_id skipping signing and encryption\n";
        $encrypted_xml = $xml;
    }

    my $output = $args{base64_encode_output}
        ? encode_base64($encrypted_xml) . "\n"
        : $encrypted_xml;

    open my $out, '>', test_data_file($output_file);
    print $out $output;
}

1;
