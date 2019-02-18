package AuthenNZRealMeSigTestHelper;

# Helper routines for testing signing and signature verification

use strict;
use warnings;

use AuthenNZRealMeTestHelper;

use Authen::NZRealMe;

require XML::LibXML;
require XML::LibXML::XPathContext;


sub sign {
    my %args = @_;

    my $key_file    = $args{key_file} or die "need key_file";
    my $input_file  = $args{xml_file} or die "need xml_file";
    my $algorithm   = $args{sig_alg}  or die "need sig_alg";
    my $cert_file   = $args{cert_file};
    my $command     = $args{command}  or die "need command";
    my $targets     = $args{targets}  or die "need targets";

    my $xml = do {
        local($/) = undef;
        $input_file = test_data_file($input_file);
        open my $fh, '<', $input_file;
        <$fh>;
    };

    $key_file = test_conf_file($key_file);

    %args = (
        key_file    => $key_file,
        xml         => $xml,
        algorithm   => $algorithm,
        cert_file   => $cert_file,
        targets     => $targets,
    );

    if($command eq 'rsa_signature') {
        return rsa_signature(%args);
    }
    elsif($command eq 'xml_digest') {
        return xml_digest(%args);
    }
    elsif($command eq 'sign_one_ref') {
        return sign_one_ref(%args);
    }
    elsif($command eq 'sign_multiple_refs') {
        return sign_multiple_refs(%args);
    }

    die "Unrecognised command: '$command'";
}


sub sign_one_ref {
    my %args = @_;
    my $id_attr    = undef;

    my($target_id) = $args{targets}->[0];
    if($target_id =~ /^(\w+)=(.+)$/) {
        ($id_attr, $target_id) = ($1, $2);
    }

    my $signer = Authen::NZRealMe->class_for('xml_signer')->new(
        algorithm     => $args{algorithm},
        key_file      => $args{key_file},
        id_attr       => $id_attr,
        pub_cert_file => $args{cert_file},
    );

    return $signer->sign($args{xml}, $target_id, include_x509 => 1) . "\n";
}


1;
