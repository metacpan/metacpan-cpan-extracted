package Authen::NZRealMe::XMLSig;
{
  $Authen::NZRealMe::XMLSig::VERSION = '1.16';
}

use strict;
use warnings;

=head1 NAME

Authen::NZRealMe::XMLSig - XML digital signature generation/verification

=head1 DESCRIPTION

This module implements the subset of http://www.w3.org/TR/xmldsig-core/
required to interface with the New Zealand RealMe Login service using SAML 2.0
messaging.

=cut


use Carp          qw(croak);
use Digest::SHA   qw(sha1 sha1_base64 sha256);
use MIME::Base64  qw(encode_base64 decode_base64);

require XML::LibXML;
require XML::LibXML::XPathContext;
require XML::Generator;
require Crypt::OpenSSL::RSA;
require Crypt::OpenSSL::X509;

use constant URI => 1;

my $ns_ds      = [ ds     => 'http://www.w3.org/2000/09/xmldsig#'   ];
my $ns_exc14n  = [ exc14n => 'http://www.w3.org/2001/10/xml-exc-c14n#' ];
my $ns_soap    = [ soap   => 'http://www.w3.org/2003/05/soap-envelope' ];
my $ns_wsu     = [ wsu   => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd' ];
my $ns_wsse    = [ wsse  => 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd' ];


my $uri_rsa_sha1_sig    = 'http://www.w3.org/2000/09/xmldsig#rsa-sha1';
my $uri_env_sig         = 'http://www.w3.org/2000/09/xmldsig#enveloped-signature';
my $uri_c14n            = 'http://www.w3.org/TR/2001/REC-xml-c14n-20010315';
my $uri_ec14n           = 'http://www.w3.org/2001/10/xml-exc-c14n';
my $uri_digest_sha1     = 'http://www.w3.org/2000/09/xmldsig#sha1';
my $uri_digest_sha256   = 'http://www.w3.org/2001/04/xmlenc#sha256';
my $uri_key_encoding    = 'http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-soap-message-security-1.0#Base64Binary';
my $uri_key_valuetype   = 'http://docs.oasis-open.org/wss/oasis-wss-soap-message-security-1.1#ThumbprintSHA1';

my $digest_method_from_uri = {
    $uri_digest_sha1   => "_xml_digest_sha1",
    $uri_digest_sha256 => "_xml_digest_sha256",
};

use constant WITH_COMMENTS    => 1;
use constant WITHOUT_COMMENTS => 0;

sub new {
    my $class = shift;

    my $self = bless {
        id_attr => 'ID',
        @_
    }, $class;
    return $self;
}


sub id_attr { shift->{id_attr}; }


sub sign {
    my($self, $xml, $target_id) = @_;

    my $doc      = $self->_xml_to_dom($xml);
    $target_id   ||= $self->default_target_id($doc);
    my $id_attr  = $self->id_attr;
    my($target)  = $doc->findnodes("//*[\@${id_attr}='${target_id}']")
        or croak "Can't find element with ${id_attr}='${target_id}'";

    my $sig_xml  = $self->_make_signature_xml($target, $target_id);
    my $sig_frag = $self->_xml_to_dom($sig_xml);

    if($target->hasChildNodes()) {
        $target->insertBefore($sig_frag, $target->firstChild);
    }
    else {
        $target->appendChild($sig_frag);
    }

    return $doc->toString;
}

sub sign_multiple_targets {
    my($self, $xml, $target_ids) = @_;
    my $doc      = $self->_xml_to_dom($xml);

    die 'Passed in ref should be an array' if (ref $target_ids ne 'ARRAY');

    my $x = XML::Generator->new();

    # Generate the reference blocks for each target
    my $signedinfo;
    foreach my $target( @$target_ids ) {
        $signedinfo .= $self->_generate_reference_block($doc, $target->{id}, $target->{namespaces});
    }
    $signedinfo = $x->SignedInfo( $ns_ds,
        $x->CanonicalizationMethod( $ns_ds, { Algorithm => $ns_exc14n->[URI] }),
        $x->SignatureMethod( $ns_ds, { Algorithm => $uri_rsa_sha1_sig } ),
        $signedinfo,
    ).'';

    # Generate SignatureValue for whole SignedInfo block
    my $canonical_signedinfo = $self->_canonicalize( $ns_exc14n->[URI], $signedinfo);
    my $signature = $self->rsa_signature($canonical_signedinfo, '');

    # Generate and add key info block
    my $x509 = Crypt::OpenSSL::X509->new_from_string($self->pub_cert_text);
    my $keyinfo_block = $x->KeyInfo( $ns_ds, { Id => 'KI-'.$self->_key_fingerprint($x509).'1' },
        $x->SecurityTokenReference( $ns_wsse, { Id => 'STR-'.$self->_key_fingerprint($x509).'2' },
            $x->KeyIdentifier( $ns_wsse, { EncodingType => $uri_key_encoding, ValueType => $uri_key_valuetype },
                $self->_hex_to_b64($x509->fingerprint_sha1()), # RealMe uses the raw fingerprint bytes b64encoded, rather than a plain fingerprint
            ),
        ),
    ).'';

    # Build combined xml block
    my $signature_block = $x->Signature( $ns_ds, { Id => 'SIG-4' },
        $signedinfo,
        $x->SignatureValue( $ns_ds, $signature ),
        $keyinfo_block,
    ).'';

    # Insert whole block as the last element in the soap:Header section
    my $sig_dom = $self->_xml_to_dom($signature_block);
    my $xc     = XML::LibXML::XPathContext->new( $doc );
    foreach my $ns ( [$ns_soap, $ns_wsse] ) {
        $xc->registerNs( @$ns );
    }
    my ( $security_node ) = $xc->findnodes("/soap:Envelope/soap:Header/wsse:Security");
    $security_node->appendChild($sig_dom);
    return $doc->toString(0);
}

sub _key_fingerprint {
    my ($self, $x509) = @_;
    my $fingerprint = $x509->fingerprint_sha1();
    $fingerprint =~ s/://g;
    return $fingerprint;
}

sub _hex_to_b64 {
    shift;
    my $hex = shift;
    $hex =~ s/://g;
    my $bin = pack("H*", $hex);
    my $b64 = encode_base64($bin, '');
    return $b64;
}

sub _generate_reference_block {
    my ($self, $doc, $target_id, $inclusive_namespaces) = @_;

    my $digest = $self->_generate_digest($doc, $target_id, $inclusive_namespaces);
    my $x = XML::Generator->new();

    my $prefix_hash = {};
    $prefix_hash = { PrefixList => join( ' ', @$inclusive_namespaces) } if ($inclusive_namespaces);

    my $block = $x->Reference( $ns_ds, { URI => "#$target_id" },
        $x->Transforms( $ns_ds,
            $x->Transform( $ns_ds, { Algorithm => $uri_ec14n.'#' },
                $x->InclusiveNamespaces( $ns_exc14n, $prefix_hash ),
            ),
        ),
        $x->DigestMethod( $ns_ds, { Algorithm => $uri_digest_sha256 } ),
        $x->DigestValue( $ns_ds, $digest ),
    ) . '';
    return $block."\n";
}

sub _generate_digest {
    my ($self, $doc, $target_id, $inclusive_namespaces) = @_;
    my $id_attr  = $self->id_attr;
    my($target)  = $doc->findnodes("//*[\@${id_attr}='${target_id}']")
            or croak "Can't find element with ${id_attr}='${target_id}'";

    my $c14n_frag = $self->_ec14n_xml($target, WITHOUT_COMMENTS, $inclusive_namespaces);

    return $self->_xml_digest_sha256($c14n_frag, $inclusive_namespaces);
}


sub default_target_id {
    my($self, $doc) = @_;

    my $id_attr    = $self->id_attr;
    my($target_id) = map { $_->to_literal } $doc->findnodes("//*/\@${id_attr}")
        or croak "Can't find element with '${id_attr}' attribute";

    return $target_id;
}


sub _canonicalize {
    my($self, $c14n_method_uri, $xml, $inclusive_namespaces) = @_;

    my($base_uri, $hash_frag) =
        $c14n_method_uri =~ m{\A(http:[^#]+)(?:#(.*))\z}
            or die "Can't parse CanonicalizationMethod: $c14n_method_uri";
    my $comments = WITHOUT_COMMENTS;
    if($hash_frag && $hash_frag eq 'WithComments') {
        $comments = WITH_COMMENTS;
    }
    if($base_uri eq $uri_c14n) {
        return $self->_c14n_xml($xml, $comments);
    }
    elsif($base_uri eq $uri_ec14n) {
        return $self->_ec14n_xml($xml, $comments, $inclusive_namespaces);
    }
    die "Unsupported canonicalization method: $c14n_method_uri";
}


sub _c14n_xml {
    my($self, $frag, $comments) = @_;

    if(not ref $frag) {   # convert XML string to a DOM node
        $frag = $self->_xml_to_dom($frag);
    }

    return $frag->toStringC14N($comments);
}

sub _ec14n_xml {
    my($self, $frag, $comments, $inclusive_namespaces) = @_;

    $inclusive_namespaces //= [];

    if(not ref $frag) {   # convert XML string to a DOM node
        $frag = $self->_xml_to_dom($frag);
    }

    return $frag->toStringEC14N($comments,'',$inclusive_namespaces);
}


sub _xml_digest_sha1 {
    my($self, $frag_xml) = @_;

    my $bin_digest = sha1($frag_xml);
    return encode_base64($bin_digest, '');
}

sub _xml_digest_sha256 {
    my($self, $frag_xml) = @_;

    my $bin_digest = sha256($frag_xml);
    return encode_base64($bin_digest, '');
}


sub _xml_to_dom {
    my($self, $xml) = @_;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($xml);
    return $doc->documentElement;
}


sub _make_signature_xml {
    my($self, $frag, $id) = @_;

    my $c14n_frag  = $self->_ec14n_xml($frag);
    my $digest     = $self->_xml_digest_sha1($c14n_frag);
    my $sig_info   = $self->_signed_info_xml($id, $digest);
    my $sig_value  = $self->rsa_signature($self->_ec14n_xml($sig_info));

    return qq{<dsig:Signature xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
        ${sig_info}
    <dsig:SignatureValue>${sig_value}</dsig:SignatureValue>
</dsig:Signature>};
}


sub rsa_signature {
    my($self, $plaintext, $eol) = @_;

    $eol //= "\n";

    my $rsa_key = Crypt::OpenSSL::RSA->new_private_key($self->key_text);
    $rsa_key->use_pkcs1_padding();

    my $bin_signature = $rsa_key->sign($plaintext);
    return encode_base64($bin_signature, $eol);
}


sub _verify_rsa_signature {
    my($self, $plaintext, $signature) = @_;
    my $rsa_cert = Crypt::OpenSSL::RSA->new_public_key($self->pub_key_text);
    $rsa_cert->use_pkcs1_padding();
    my $bin_sig = decode_base64($signature);
    return $rsa_cert->verify($plaintext, $bin_sig);
}


sub _signed_info_xml {
    my($self, $frag_id, $frag_digest) = @_;

    return qq{<dsig:SignedInfo xmlns:dsig="http://www.w3.org/2000/09/xmldsig#">
            <dsig:CanonicalizationMethod Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
            <dsig:SignatureMethod Algorithm="http://www.w3.org/2000/09/xmldsig#rsa-sha1" />
            <dsig:Reference URI="#${frag_id}">
                <dsig:Transforms>
                    <dsig:Transform Algorithm="http://www.w3.org/2000/09/xmldsig#enveloped-signature" />
                    <dsig:Transform Algorithm="http://www.w3.org/2001/10/xml-exc-c14n#" />
                </dsig:Transforms>
                <dsig:DigestMethod Algorithm="http://www.w3.org/2000/09/xmldsig#sha1" />
                <dsig:DigestValue>${frag_digest}</dsig:DigestValue>
            </dsig:Reference>
        </dsig:SignedInfo>};
}


sub verify {
    my($self, $xml) = @_;

    my $doc = $self->_xml_to_dom($xml);
    my $xc  = XML::LibXML::XPathContext->new($doc);

    $xc->registerNs( @$ns_ds );
    $xc->registerNs( @$ns_exc14n );
    $xc->registerNs( @$ns_soap );
    $xc->registerNs( @$ns_wsu );

    my @signature_blocks;
    foreach my $sig ( $xc->findnodes(q{//ds:Signature[not(ancestor::soap:Body)]}) ) { # Exclude signatures encapsulated in the SOAP body
        push @signature_blocks, $self->_parse_signature($xc, $sig);
        $sig->parentNode->removeChild($sig);
    }
    croak "XML document contains no signatures" unless @signature_blocks;

    my $id_attr  = $self->id_attr;

    foreach my $block ( @signature_blocks ) {
        foreach my $reference ( @$block ) {
            my($frag)  = $xc->findnodes("//*[\@${id_attr}='$reference->{ref_id}']")
                or croak "Can't find element with ${id_attr}='$reference->{ref_id}'";

            my $digest_function = $digest_method_from_uri->{$reference->{digest_method}};

            my $c14n_frag = $self->_ec14n_xml( $frag, WITHOUT_COMMENTS, $reference->{inclusive_namespaces} );

            my $digest = $self->$digest_function($c14n_frag);

            if($digest ne $reference->{digest}) {
                die "Digest of signed element '$reference->{ref_id}' "
                    . "differs from that given in reference block\n"
                    . "Expected:   '$reference->{digest}'\n"
                    . "Calculated: '$digest'\n ";
            }
        }
    }

    return 1;
}

sub _parse_signature {
    my($self, $xc, $sig) = @_;

    my($sig_info) = $xc->findnodes(q{./ds:SignedInfo}, $sig)
        or die "Can't verify a signature without a 'SignedInfo' element";

    my $c14n_method = $xc->findvalue(q{./ds:CanonicalizationMethod/@Algorithm}, $sig_info)
        or die "Can't find CanonicalizationMethod in " . $sig->toString;

    my $c14n_namespaces = [split ' ', $xc->findvalue( q{./ds:CanonicalizationMethod/exc14n:InclusiveNamespaces/@PrefixList}, $sig_info)];

    my $algorithm = $xc->findvalue(q{./ds:SignatureMethod/@Algorithm}, $sig_info)
        or die "Can't find SignatureMethod in " . $sig->toString;

    die "Unsupported signature algorithm: '$algorithm'"
        unless $algorithm eq $uri_rsa_sha1_sig;

    my $references = [];

    foreach my $ref ( $xc->findnodes(q{.//ds:Reference}, $sig) ) {
        my $ref_data = {};

        my $ref_uri = $xc->findvalue('./@URI', $ref)
            or die "Reference element is missing the URI attribute";
        $ref_uri =~ s{^#}{};
        $ref_data->{ref_id} = $ref_uri;

        my($digest_method) = map { $_->to_literal } $xc->findnodes(
            './ds:DigestMethod/@Algorithm',
            $ref
        ) or die "Unable to determine Signature Reference DigestMethod for $ref_uri";
        die "Unsupported Signature DigestMethod: '$digest_method' for $ref_uri"
            unless $digest_method_from_uri->{$digest_method};
        $ref_data->{digest_method} = $digest_method;

        my($digest) = map { $_->to_literal } $xc->findnodes(
            './ds:DigestValue',
            $ref
        ) or die "Unable to determine Signature DigestValue";
        $ref_data->{digest} = $digest;

        foreach my $xform (
            map { $_->to_literal } $xc->findnodes(
                q{./ds:Transforms/ds:Transform/@Algorithm},
                $ref
            )
        ) {
            next if $xform eq $uri_env_sig;
            next if $xform =~ m{\A\Q$uri_c14n\E(?:#(?:WithComments)?)?\z};
            if ( $xform =~ m{\A\Q$uri_ec14n\E(?:#(?:WithComments)?)?\z} ) {
                my $inc_namespaces = $xc->findvalue(
                    q{./ds:Transforms/ds:Transform/exc14n:InclusiveNamespaces/@PrefixList},
                    $ref
                );
                $ref_data->{inclusive_namespaces} = [split ' ', $inc_namespaces] if $inc_namespaces;
                next;
            }
            die "Unsupported transformation: '$xform' on digest for $ref_uri";
        }
        push @$references, $ref_data;
    }
    my $sig_val = $xc->findvalue(q{./ds:SignatureValue}, $sig)
        or die "Can't find SignatureValue in " . $sig->toString;
    my $plaintext = $self->_canonicalize($c14n_method, $sig_info, $c14n_namespaces);

    $self->_verify_rsa_signature($plaintext, $sig_val)
        or die "SignedInfo block signature does not match";

    return $references;
}


sub key_text {
    my($self) = @_;

    return $self->{key_text} if $self->{key_text};

    my $path = $self->{key_file}
        or croak "signing key must be set with 'key_file' or 'key_text'";

    $self->{key_text} = $self->_slurp_file($path);

    return $self->{key_text};
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


sub _slurp_file {
    my($self, $path) = @_;

    local($/) = undef;
    open my $fh, '<', $path or die "open($path): $!";
    my $text = <$fh>;

    return $text;
}


1;

=head1 SYNOPSIS

  my $signer = Authen::NZRealMe->class_for('xml_signer')->new(
      key_file => $path_to_private_key_file,
  );

  my $signed_xml = $signer->sign($xml, $target_id);

  my $verifier = Authen::NZRealMe->class_for('xml_signer')->new(
      pub_cert_text => $self->signing_cert_pem_data(),
  );

  $verifier->verify($xml);

=head1 METHODS

=head2 new( )

Constructor.  Should not be called directly.  Instead, call:

  Authen::NZRealMe->class_for('xml_signer')->new( options );

Options are passed in as key => value pairs.

When creating digital signatures, a private key must be passed to the
constructor using either the C<key_text> or the C<key_file> option.

When verifying digital signatures, a public key is required.  This may be
passed in using the C<pub_key_text> option or it will be extracted from the
X509 certificate provided in the C<pub_cert_text> or the C<pub_cert_file>
option.

=head2 id_attr( )

Returns the name of the attribute used to identify the element being signed.
Defaults to 'ID'.  Can be set by passing an C<id_attr> option to the
constructor.

=head2 sign( $xml, $target_id )

Takes an XML document and an optional element ID value and returns a string of
XML with a digital signature added.  The XML document can be provided either as
a string or as an XML::LibXML DOM object.

=head2 sign_multiple_targets ( $xml, $target_ids )

Takes an XML document and an array of hashes representing the ID and
InclusiveNamespaces of any DOM elements to sign, identified by an ID attribute
value. The input array should resemble this example:

        [ {
            id          => 's23a05470f2ac691e7ebc19a90b8f04a6336dad2fe',
            namespaces  => ['soap'],
        },  {
            id          => 's254212e7245af1ee3a909a364273b0be7726e8808',
        } ]

The name of the attribute is determined by the id_attr method above.
The document will have a signature block generated and inserted into it, and
the method will return a string of the document and it's included signatures.

=head2 default_target_id( )

When signing a document, if no target ID is provided, this method is used to
find the first element with an 'ID' attribute.

=head2 rsa_signature( $plaintext, $eol )

Takes a plaintext string, calculates an RSA signature using the private key
passed to the constructor and returns a base64-encoded string. The C<$eol>
parameter can be used to specify the line-ending character used in the base64
encoding process (default: \n).

=head2 verify( $xml )

Takes an XML string (or DOM object); searches for signature elements; verifies
the provided signature and message digest for each; and returns true on success.

If the provided document does not contain any signatures, or if an invalid
signature is found, an exception will be thrown.

=head2 key_text( )

Returns the private key text which will be used to initialise the
L<Crypt::OpenSSL::RSA> object used for generating signatures.

=head2 pub_key_text( )

Returns the public key text used to initialise the L<Crypt::OpenSSL::RSA>
object used for verifing signatures.

=head2 pub_cert_text( )

If the public key is being extracted from an X509 certificate, this method is
used to retrieve the text which defines the certificate.


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2014 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

