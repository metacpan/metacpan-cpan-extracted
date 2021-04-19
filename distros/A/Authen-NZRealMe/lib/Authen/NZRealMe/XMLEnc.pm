package Authen::NZRealMe::XMLEnc;
$Authen::NZRealMe::XMLEnc::VERSION = '1.23';
use strict;
use warnings;

=head1 NAME

Authen::NZRealMe::XMLEnc - XML encryption/decryption

=head1 DESCRIPTION

This module implements the subset of http://www.w3.org/2001/04/xmlenc#
required to interface with the New Zealand RealMe Login service using SAML 2.0
messaging.  In particular, this is used for decrypting the contents of the
EncryptedAssertion element in the SAMLResponse parameter of an HTTP-POST from
the IdP.

=cut

use Carp          qw(croak);
use MIME::Base64  qw(encode_base64 decode_base64);

use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);

require XML::LibXML;
require XML::LibXML::XPathContext;
require Crypt::OpenSSL::RSA;
require Crypt::OpenSSL::X509;
require Crypt::Mode::CBC;
require Crypt::Cipher::AES;

use Crypt::PRNG qw(random_bytes);


my $ns_xenc       = [ NS_PAIR('xenc') ];
my $ns_ds         = [ NS_PAIR('ds') ];

my(%enc_alg_by_name, %enc_alg_by_uri);
__PACKAGE__->register_encryption_algorithm($_, URI($_)) foreach (qw(
    xenc_rsa15
    xenc_aes128cbc
    xenc_rsa_oaep_mgf1p
    xenc_aes256cbc
));


sub new {
    my $class = shift;

    my $self = bless {
        id_attr => 'ID',
        @_
    }, $class;
    return $self;
}


sub id_attr { shift->{id_attr}; }


sub decrypt_encrypted_data_elements {
    my($self, $xml) = @_;

    my $xc = $self->_xcdom_from_xml($xml);

    my $frag_parser = XML::LibXML->new();
    foreach my $ed_node ($xc->findnodes('//xenc:EncryptedData')) {
        my $node_type = $ed_node->{Type} // '<undefined>';
        die "Unable to process EncryptedData of type '$node_type'"
            unless $node_type eq URI('xenc_type_element');
        my $plaintext = $self->_decrypt_one_encrypted_data_element($xc, $ed_node);
        my $frag = $frag_parser->parse_balanced_chunk($plaintext);
        my $parent = $ed_node->parentNode;
        $parent->replaceChild($frag, $ed_node);
    }

    my($root) = $xc->findnodes('/');

    return $root->toString();
}


sub encrypt_one_element {
    my($self, $xml, %args) = @_;

    my $xc = $self->_xcdom_from_xml($xml);

    my $target_id                 = $args{target_id}     or croak "Need target_id";
    my $algorithm_name            = $args{algorithm}     or croak "Need algorithm";
    my $random_key_algorithm_name = $args{key_algorithm} or croak "Need random key algorithm";

    my $id_attr   = '@' . $self->id_attr;

    my($node) = $xc->findnodes(qq{//*[$id_attr='$target_id']})
        or croak "failed to find element with $id_attr='$target_id'";

    my $frag_xml = $node->toStringC14N();

    my $algorithm = $self->_find_enc_alg($algorithm_name);
    my $key_info = $self->_gen_key($algorithm);

    my $rsa_alg = $self->_find_enc_alg($random_key_algorithm_name);
    my $rsa_key = $self->rsa_public_key();
    $key_info->{encrypted_key} =
        $self->_encrypt_bytes($rsa_alg, $rsa_key, $key_info->{key});

    my $ciphertext = $self->_encrypt_bytes($algorithm, $key_info, $frag_xml);
    my $enc_frag = $self->_generate_encrypted_data_element(
        $key_info, $ciphertext, $random_key_algorithm_name, $algorithm_name
    );
    my $frag_parser = XML::LibXML->new();
    my $ed_node = $frag_parser->parse_balanced_chunk($enc_frag);
    my $parent = $node->parentNode;
    $parent->replaceChild($ed_node, $node);

    my($root) = $xc->findnodes('/');
    return $root->toString();
}


sub _generate_encrypted_data_element {
    my($self, $key_info, $ciphertext, $random_key_algorithm_name, $algorithm_name) = @_;

    my $encrypted_key_b64 = encode_base64($key_info->{encrypted_key});
    my $ciphertext_b64 = encode_base64($key_info->{iv} . $ciphertext);
    my $x = XML::Generator->new(':strict', pretty => 2);

    my $enc_frag = $x->EncryptedData($ns_xenc,
        { Type => URI('xenc_type_element'), },
        $x->EncryptionMethod($ns_xenc,
            { Algorithm => URI($algorithm_name) },
        ),
        $x->KeyInfo($ns_ds,
            $x->EncryptedKey($ns_xenc,
                $x->EncryptionMethod($ns_xenc,
                    { Algorithm => URI($random_key_algorithm_name) },
                ),
                $x->CipherData($ns_xenc,
                    $x->CipherValue($ns_xenc, "\n" . $encrypted_key_b64),
                ),
            ),
        ),
        $x->CipherData($ns_xenc,
            $x->CipherValue($ns_xenc, "\n" . $ciphertext_b64),
        ),
    ) . '';

    return $enc_frag;
}


sub _xcdom_from_xml {
    my($self, $xml, @namespaces) = @_;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($xml);
    my $xc     = XML::LibXML::XPathContext->new($doc->documentElement);

    $xc->registerNs( NS_PAIR('xenc') );
    $xc->registerNs( NS_PAIR('ds') );

    while(@namespaces) {
        my $prefix = shift @namespaces;
        my $uri    = shift @namespaces;
        $xc->registerNs($prefix, $uri);
    }

    return $xc;
}


sub _decrypt_one_encrypted_data_element {
    my($self, $xc, $ed_node) = @_;

    my $algorithm_uri = $xc->findvalue(
        './xenc:EncryptionMethod/@Algorithm', $ed_node
    );
    my $algorithm = $self->_find_enc_alg($algorithm_uri);

    my $key = eval {
        $self->_extract_encrypted_key($xc, $ed_node);
    } or do {
        die "Error decrypting <KeyInfo> for"
          . " algorithm=$algorithm->{name} error: $@";
    };

    my $b64_value = $xc->findvalue(
        './xenc:CipherData/xenc:CipherValue', $ed_node
    ) or die "Unable to find <CipherData><CipherValue> for <EncryptedData>";
    my $ciphertext = decode_base64($b64_value);
    my $plaintext = eval {
        $self->_decrypt($algorithm, $key, $ciphertext);
    } or do {
        die "Error decrypting <EncryptedData> using"
          . " algorithm=$algorithm->{name} error: $@";
    };
    return $plaintext;
}


sub _extract_encrypted_key {
    my($self, $xc, $ed_node) = @_;

    my($key_info) = $xc->findnodes('./ds:KeyInfo', $ed_node)
        or die "Unable to find <KeyInfo> in <EncryptedData> element";
    my($encrypted_key) = $xc->findnodes('./xenc:EncryptedKey', $key_info)
        or die "Unable to find <EncryptedKey> in <KeyInfo> element";

    my $algorithm_ns = $xc->findvalue(
        './xenc:EncryptionMethod/@Algorithm', $encrypted_key
    ) or die "Unable to find Algorithm in <EncryptedKey>";
    my $algorithm = $self->_find_enc_alg($algorithm_ns);

    my $b64_value = $xc->findvalue(
        './xenc:CipherData/xenc:CipherValue', $encrypted_key
    ) or die "Unable to find <CipherData><CipherValue> for <EncryptedKey>";
    my $ciphertext = decode_base64($b64_value);

    return $self->_decrypt($algorithm, $self->rsa_private_key, $ciphertext);
}


sub _encrypt_bytes {
    my($self, $algorithm, @args) = @_;

    my $method = $algorithm->{encrypt_method}
        or die "no encrypt_method for $algorithm->{name}";

    $self->$method(@args);
}


sub rsa_private_key {
    my($self) = @_;

    return Crypt::OpenSSL::RSA->new_private_key($self->key_text);
}


sub rsa_public_key {
    my($self) = @_;

    return Crypt::OpenSSL::RSA->new_public_key($self->pub_key_text);
}


sub pub_key_text {
    my($self) = @_;

    return $self->{pub_key_text} if $self->{pub_key_text};

    my $cert_text = $self->pub_cert_text();
    my $x509 = Crypt::OpenSSL::X509->new_from_string($cert_text);
    $self->{pub_key_text} = $x509->pubkey();

    return $self->{pub_key_text};
}


sub pub_cert_text {
    my($self) = @_;

    return $self->{pub_cert_text} if $self->{pub_cert_text};
    my $path = $self->{pub_cert_file}
        or croak "signing cert must be set with 'pub_cert_file' or 'pub_cert_text'";

    $self->{pub_cert_text} = $self->_slurp_file($path);

    return $self->{pub_cert_text};
}


sub key_text {
    my($self) = @_;

    return $self->{key_text} if $self->{key_text};

    my $path = $self->{key_file}
        or croak "signing key must be set with 'key_file' or 'key_text'";

    $self->{key_text} = $self->_slurp_file($path);

    return $self->{key_text};
}


sub _slurp_file {
    my($self, $path) = @_;

    local($/) = undef;
    open my $fh, '<', $path or die "open($path): $!";
    my $text = <$fh>;

    return $text;
}


##############################################################################
# Methods for encrypting, decrypting and generating keys using specific
# algorithms.
#


sub register_encryption_algorithm {
    my($class, $name, $uri) = @_;
    my $short_name = $name =~ s/^xenc_//r;
    my $encryption_algorithm = {
        name            => $name,
        uri             => $uri,
        encrypt_method  => '_encrypt_' . $short_name,
        decrypt_method  => '_decrypt_' . $short_name,
        keygen_method   => '_key_gen_' . $short_name,
    };
    $enc_alg_by_name{$name} = $encryption_algorithm;
    $enc_alg_by_uri{$uri}   = $encryption_algorithm;
}


sub _find_enc_alg {
    my($self, $identifier) = @_;

    my $sig_alg = $enc_alg_by_name{$identifier} // $enc_alg_by_uri{$identifier}
       or die "Unknown encryption algorithm: '$identifier'";
    return $sig_alg;
}


sub _decrypt {
    my($self, $algorithm, $key, $ciphertext) = @_;

    my $method = $algorithm->{decrypt_method}
        or die "no decrypt_method for $algorithm->{name}";

    $self->$method($key, $ciphertext);
}


sub _gen_key {
    my($self, $algorithm) = @_;

    my $method = $algorithm->{keygen_method}
        or die "no keygen_method for $algorithm->{name}";

    my $key_info = $self->$method();
    return $key_info;
}


sub _strip_padding {
    my($self, $plaintext, $blocksize) = @_;

    my $length = length($plaintext);
    die "_strip_padding(): plaintext length of $length bytes is less than"
      . " blocksize of $blocksize bytes"
        if $length < $blocksize;

    my $last = substr($plaintext, -1);
    my $pad_len = ord($last);
    die "_strip_padding(): pad length of $pad_len bytes is greater than"
      . " blocksize of $blocksize bytes"
        if $pad_len > $blocksize;

    substr($plaintext, -$pad_len, $pad_len, '');

    return $plaintext;
}


sub _add_padding {
    my($self, $plaintext, $blocksize) = @_;

    my $length = length($plaintext);
    my $pad_len = $blocksize - ($length % $blocksize); # result > 0
    # The 0xB0-0xFF byte range is used to maximise the chance of triggering an
    # XML parse failure in the event of failing to handle padding removal
    my @pad_bytes = map { 176 + rand(80) } 2..$pad_len;
    return $plaintext . pack("C*", @pad_bytes, $pad_len);
}


sub _decrypt_rsa15 {
    my($self, $rsa_key, $ciphertext) = @_;
    $rsa_key->use_pkcs1_padding;
    my $plaintext = $rsa_key->decrypt($ciphertext);
    return $plaintext;
}


sub _encrypt_rsa15 {
    my($self, $rsa_key, $plaintext) = @_;
    $rsa_key->use_pkcs1_padding;
    my $ciphertext = $rsa_key->encrypt($plaintext);
    return $ciphertext;
}

sub _decrypt_rsa_oaep_mgf1p {
    my($self, $rsa_key, $ciphertext) = @_;
    $rsa_key->use_pkcs1_oaep_padding;
    my $plaintext = $rsa_key->decrypt($ciphertext);
    return $plaintext;
}


sub _encrypt_rsa_oaep_mgf1p {
    my($self, $rsa_key, $plaintext) = @_;
    $rsa_key->use_pkcs1_oaep_padding;
    my $ciphertext = $rsa_key->encrypt($plaintext);
    return $ciphertext;
}



sub _decrypt_aes128cbc {
    my($self, $aes128_key, $ciphertext) = @_;

    my $cipher    = 'AES';
    my $padding   = 0; # no padding - we handle that below
    my $blocksize = Crypt::Cipher::blocksize($cipher);
    my $iv        = substr($ciphertext, 0, $blocksize, '');
    my $cbc = Crypt::Mode::CBC->new($cipher, $padding);
    my $plaintext = $cbc->decrypt($ciphertext, $aes128_key, $iv);
    return $self->_strip_padding($plaintext, $blocksize);
}


sub _encrypt_aes128cbc {
    my($self, $key_info, $plaintext) = @_;

    my $cipher     = 'AES';
    my $padding    = 0; # no padding - we handle that below
    my $blocksize  = Crypt::Cipher::blocksize($cipher);
    my $aes128_key = $key_info->{key} or die "No key in key_info";
    my $iv         = $key_info->{iv}  or die "No iv in key_info";
    $plaintext     = $self->_add_padding($plaintext, $blocksize);
    my $cbc = Crypt::Mode::CBC->new($cipher, $padding);
    my $ciphertext = $cbc->encrypt($plaintext, $aes128_key, $iv);
    return $ciphertext;
}


sub _key_gen_aes128cbc {
    my($self) = @_;

    my $aes128_key  = random_bytes(Crypt::Cipher::keysize('AES'));
    my $iv          = random_bytes(Crypt::Cipher::blocksize('AES'));
    return {
        key   => $aes128_key,
        iv    => $iv,
    };
}


sub _decrypt_aes256cbc {
    my($self, $aes256_key, $ciphertext) = @_;

    my $cipher    = 'AES';
    my $padding   = 0; # no padding - we handle that below
    my $blocksize = Crypt::Cipher::blocksize($cipher);
    my $iv        = substr($ciphertext, 0, $blocksize, '');
    my $cbc = Crypt::Mode::CBC->new($cipher, $padding);
    my $plaintext = $cbc->decrypt($ciphertext, $aes256_key, $iv);
    return $self->_strip_padding($plaintext, $blocksize);
}


sub _encrypt_aes256cbc {
    my($self, $key_info, $plaintext) = @_;

    my $cipher     = 'AES';
    my $padding    = 0; # no padding - we handle that below
    my $blocksize  = Crypt::Cipher::blocksize($cipher);
    my $aes256_key = $key_info->{key} or die "No key in key_info";
    my $iv         = $key_info->{iv}  or die "No iv in key_info";
    $plaintext     = $self->_add_padding($plaintext, $blocksize);
    my $cbc = Crypt::Mode::CBC->new($cipher, $padding);
    my $ciphertext = $cbc->encrypt($plaintext, $aes256_key, $iv);
    return $ciphertext;
}


sub _key_gen_aes256cbc {
    my($self) = @_;

    my $aes256_key  = random_bytes(Crypt::Cipher::keysize('AES'));
    my $iv          = random_bytes(Crypt::Cipher::blocksize('AES'));
    return {
        key   => $aes256_key,
        iv    => $iv,
    };
}

1;

__END__

=head1 SYNOPSIS

  my $decrypter = Authen::NZRealMe->class_for('xml_encrypter')->new(
      pub_cert_file => $self->signing_cert_pathname,
      key_file      => $path_to_private_key_file,
  );

  my $xml = $decrypter->decrypt_encrypted_data_elements($xml);

=head1 METHODS

=head2 new( )

Constructor.  Generally called indirectly via the
L<Authen::NZRealMe::ServiceProvider/resolve_posted_assertion> method, which
does so like this:

  Authen::NZRealMe->class_for('xml_encrypter')->new( options );

Options are passed in as key => value pairs.

For decryption, the Service Provider's RSA signing private key must be passed
to the constructor using either the C<key_text> or the C<key_file> option.
This key is used to decrypt the random key used by the block cipher to encrypt
the assertion.

In normal use (consuming assertions from the RealMe service), this module is
never called upon to perform encryption.  It does include an implementation of
encryption for use by the test suite.  When creating an encrypted assertion,
two rounds of encryption are performed.  First, an AES key is generated at
random and used by the block cipher to encrypt the assertion.  Next, the AES
key is encrypted using the Service Provider's RSA public key and the result is
included along with the encrypted assertion.  See the test suite for more
details.

=head2 decrypt_encrypted_data_elements( $xml )

Takes an XML document (as a string) and returns a modified version (also as a
string) in which all C<< <EncryptedData> >> elements are replaced with the
unencrypted document fragment.

=head2 encrypt_one_element

Currently only needed by the test suite, which calls it like this:

  my $encrypted_xml = $encrypter->encrypt_one_element($signed_xml,
      algorithm => 'xenc_aes128cbc',
      target_id => $target_id,
  );

Returns a new XML string in which one element from the supplied XML document
has been replaced with an C<< <EncryptedData> >> element.

=head2 id_attr

An accessor method for the attribute name used by C<encrypt_one_element> to
find the target element to be encrypted.  The default name is 'ID', and can be
overriden by passing a new value for the 'id_attr' option to the constructor.

=head2 key_text

An accessor for the PEM-encoded text used to instantiate an RSA private key
object for decryption.  The value can be supplied directly using the
'key_text' argument to the constructor, or indirectly with the 'key_file'
argument.

=head2 pub_cert_text

An accessor for the PEM-encoded text used to instantiate an X509 certificate
which in turn is used to create an RSA public key object for encryption.  The
value can be supplied directly using the 'pub_cert_text' argument to the
constructor, or indirectly with the 'pub_cert_file' argument.

=head2 pub_key_text

An accessor for the PEM-encoded text used to instantiate an RSA public key
object for encryption.  The value can be supplied directly using the
'pub_key_text' argument to the constructor, or indirectly with the
'pub_cert_text' or 'pub_cert_file' arguments.

=head2 register_encryption_algorithm

Used at module-load-time to register handler methods for each supported
encryption algorithm - i.e.: the method is called once per algorithm.  A
sub-class which added support for addition algorithms would need to ensure that
this routine is called for each.

=head2 rsa_private_key

Accessor method which returns a L<Crypt::OpenSSL::RSA> private key object
using the C<key_text> method.

=head2 rsa_public_key

Accessor method which returns a L<Crypt::OpenSSL::RSA> public key object
using the C<pub_key_text> method.

=head1 SUPPORTED ALGORITHMS

=head2 rsa15 - RSAES-PKCS1-v1_5

Used only to encrypt/decrypt the random key which in turn is used by the block
cipher to encrypt the XML element data. This is used by the old RealMe service to
encrypt the random key.

=head2 aes128cbc - AES128-CBC

This is the oold supported block cipher used for the encryption/decryption of
XML elements.  Whilst it is recognised that use of this cipher is not
recommended due to concerns about its security, it is the cipher used by the
RealMe service to encrypt SAML assertions.

=head2 rsa_oaep_mgf1p - RSA-OAEP-MGF1P

Used only to encrypt/decrypt the random key which in turn is used by the block
cipher to encrypt the XML element data. This is used by the new RealMe service to
encrypt the random key.

=head2 aes256cbc - AES256-CBC

This is the supported block cipher used for the encryption/decryption
of XML elements.  This is the cipher used by the new RealMe service to
encrypt SAML assertions.

=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2022 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


