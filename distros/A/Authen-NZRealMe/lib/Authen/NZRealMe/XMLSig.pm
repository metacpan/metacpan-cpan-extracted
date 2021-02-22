package Authen::NZRealMe::XMLSig;
$Authen::NZRealMe::XMLSig::VERSION = '1.21';
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

use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);

require XML::LibXML;
require XML::LibXML::XPathContext;
require XML::Generator;
require Crypt::OpenSSL::RSA;
require Crypt::OpenSSL::X509;

my(%transforms_by_name, %transforms_by_uri);
__PACKAGE__->register_transform_method($_, URI($_)) foreach (qw(
    c14n
    c14n_wc
    c14n11
    c14n11_wc
    ec14n
    ec14n_wc
    sha1
    sha256
    env_sig
));

my(%sig_alg_by_name, %sig_alg_by_uri);
__PACKAGE__->register_signature_methods($_, URI($_)) foreach (qw(
    rsa_sha1
    rsa_sha256
));

use constant WITH_COMMENTS    => 1;
use constant WITHOUT_COMMENTS => 0;

sub new {
    my $class = shift;

    my $self = bless {
        reference_transforms    => [ 'env_sig', 'ec14n' ],
        reference_digest_method => 'sha1',
        c14n_method             => 'ec14n',
        signature_algorithm     => 'rsa_sha1',
        include_x509_cert       => 0,
        @_
    }, $class;
    return $self;
}


sub id_attr                 { shift->{id_attr};    }
sub reference_transforms    { shift->{reference_transforms}; }
sub reference_digest_method { shift->{reference_digest_method}; }
sub c14n_method             { shift->{c14n_method}; }
sub signature_algorithm     { shift->{signature_algorithm}; }
sub include_x509_cert       { shift->{include_x509_cert}; }
sub _signed_fragment_paths  { @{ shift->{signed_fragment_paths} }; }


sub sign {
    my($self, $xml, $target_id, %options) = @_;

    my $return_signature_xml = delete $options{return_signature_xml};

    my $refs      = $options{references} // [ { ref_id  => $target_id } ];
    my $ns_map    = delete($options{namespaces}) // [];
    my $xc        = $self->_xcdom_from_xml($xml, @$ns_map);
    my $doc       = $xc->getContextNode();
    my $sig_xml   = $self->_make_sig_xml($xc, %options, references => $refs);

    # Just return the XML of the signature block if that's what the caller wants
    return $sig_xml if $return_signature_xml;

    # Otherwise, add sig fragment to source doc as first child of first ref
    my $sig_frag  = $self->_xml_to_dom($sig_xml);
    my $ref_id_0  = $refs->[0]->{ref_id};
    my $target    = $self->_find_element_by_uri_reference($xc, $ref_id_0);
    if($target->hasChildNodes()) {
        $target->insertBefore($sig_frag, $target->firstChild);
    }
    else {
        $target->appendChild($sig_frag);
    }

    return $doc->toString;
}


sub _xml_to_dom {
    my($self, $xml) = @_;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($xml);
    return $doc->documentElement;
}


sub verify {
    my $self        = shift;
    my $xml         = shift or croak "Need XML to verify";
    my $selector    = shift // '//ds:Signature';
    my @namespaces  = @_;

    # Verifying an enveloped signature performs destructive operations on the
    # DOM, so we need a new DOM for each <Signature> block.

    my $sig_count = do {
        my $xc   = $self->_xcdom_from_xml($xml, @namespaces);
        my @sigs = $xc->findnodes($selector);
        scalar(@sigs);
    };
    my @signed_fragment_paths;

    eval {
        for(my $i = 0; $i < $sig_count; $i++) {
            my $xc = $self->_xcdom_from_xml($xml, @namespaces);
            my($sig_node) = ($xc->findnodes($selector))[$i];
            die "No signature block match for selector: '$selector'"
                unless $sig_node;
            my $sig_block = $self->_parse_signature_block($xc, $sig_node);
            my @frags = $self->_verify_one_signature_block($xc, $sig_block);
            push @signed_fragment_paths, @frags;
        }
        1;
    } or do {
        my $message = $@ =~ s/\n+\z//r;
        croak "Signature verification failed. $message";
    };

    croak "XML document contains no signatures" unless @signed_fragment_paths;
    $self->{signed_fragment_paths} = \@signed_fragment_paths;

    return 1;
}


sub _verify_one_signature_block {
    my($self, $xc, $sig_block) = @_;
    my(@signed_fragment_paths);

    # Confirm that the signature is valid for the <SignedInfo> block
    my $input = [ $xc, $sig_block->{sig_info_node}];
    my $sig_info_plaintext = $self->_apply_transform($sig_block->{c14n}, $input);
    $self->_verify_signature(
        $sig_block->{signature_algorithm},
        $sig_info_plaintext,
        $sig_block->{signature_value}
    ) or die "SignedInfo block signature does not match\n";

    # Confirm the digest value for each reference
    my $references = $sig_block->{references};
    die "Signature block contains no references\n" unless @$references;
    foreach my $ref ( @$references ) {
        my $fragment = [ $xc, $ref->{xml_node} ];
        my $transforms = $ref->{transforms};
        foreach my $transform ( @$transforms ) {
            $fragment = $self->_apply_transform($transform, $fragment);
        }
        my $digest = $self->_apply_transform($ref->{digest_method}, $fragment);
        if($digest ne $ref->{digest_value}) {
            die "Digest of signed element '$ref->{ref_id}' "
              . "differs from that given in reference block\n"
              . "Expected:   '$ref->{digest_value}'\n"
              . "Calculated: '$digest'\n ";
        }

        push @signed_fragment_paths, $ref->{xml_fragment_path};
    }
    return @signed_fragment_paths;
}


sub _parse_signature_block {
    my($self, $xc, $sig) = @_;

    my $sig_as_text = $sig->toString;
    my $block = {};

    my($sig_info) = $xc->findnodes(q{./ds:SignedInfo}, $sig)
        or die "Can't verify a signature without a 'SignedInfo' element";
    $block->{sig_info_node} = $sig_info;

    my($c14n_node) = $xc->findnodes(q{./ds:CanonicalizationMethod}, $sig_info)
        or die "Can't find CanonicalizationMethod in: '$sig_as_text'";
    my $c14n_method = $c14n_node->{Algorithm}
        or die "CanonicalizationMethod element lacks Algorithm attribute in: '$sig_as_text'";
    $block->{c14n} = $self->_find_transform($c14n_method);

    my($sigm_node) = $xc->findnodes(q{./ds:SignatureMethod}, $sig_info)
        or die "Can't find SignatureMethod in: '$sig_as_text'";
    my $sig_alg = $sigm_node->{Algorithm}
        or die "SignatureMethod element lacks Algorithm attribute in: '$sig_as_text'";
    $block->{signature_algorithm} = $self->_find_sig_alg($sig_alg);

    $block->{references} = [
        map { $self->_parse_signature_reference($xc, $_); }
            $xc->findnodes(q{.//ds:Reference}, $sig)
    ];

    my($sig_value) = $xc->findvalue(q{./ds:SignatureValue}, $sig)
        or die "Can't find SignatureValue in: '$sig_as_text'";
    $sig_value =~ s/\s+//g;
    $block->{signature_value} = $sig_value;

    return $block;
}


sub _parse_signature_reference {
    my($self, $xc, $ref_node) = @_;

    my $ref_as_text = $ref_node->toString;
    my $ref_data = {};

    my $ref_uri = $xc->findvalue('./@URI', $ref_node)
        or die "Reference element is missing the URI attribute";
    $ref_uri =~ s{^#}{};
    $ref_data->{ref_id} = $ref_uri;

    my $target_node = $self->_find_element_by_uri_reference($xc, $ref_uri);
    $ref_data->{xml_node} = $target_node;
    $ref_data->{xml_fragment_path} = $self->_node_to_clarkian_path($target_node);

    $ref_data->{transforms} = [
        map {
            my $trans_node = $_;
            my $trans_as_text = $trans_node->toString;
            my $algorithm = $trans_node->{Algorithm}
                or die "Transform element lacks Algorithm attribute in: '$trans_as_text'";
            my $transform = $self->_find_transform($algorithm);
            if($xc->findnodes('./*')) {
                $transform->{args} = $trans_node->toStringEC14N();
            }
            $transform;
        } $xc->findnodes(q{./ds:Transforms/ds:Transform}, $ref_node)
    ];

    my($digest_node) = $xc->findnodes(q{./ds:DigestMethod}, $ref_node)
        or die "Can't find DigestMethod in: '$ref_as_text'";
    my $digest_method = $digest_node->{Algorithm}
        or die "DigestMethod element lacks Algorithm attribute in: '$ref_as_text'";
    $ref_data->{digest_method} = $self->_find_transform($digest_method);

    my($digest) = map { $_->to_literal } $xc->findnodes('./ds:DigestValue', $ref_node);
    $ref_data->{digest_value} = $digest if $digest;

    return $ref_data;
}


sub _find_element_by_uri_reference {
    my($self, $xc, $ref_uri) = @_;
    my @elem;
    if(my $id_attr = $self->id_attr) {
        @elem = $xc->findnodes("//*[\@${id_attr}='${ref_uri}']")
            or croak "Can't find element with ${id_attr}='${ref_uri}'";
        if(@elem != 1) {
            croak "Reference URI \@${id_attr}='$ref_uri' is ambiguous";
        }
    }
    else {
        my @attr = $xc->findnodes("//*/\@*[.='${ref_uri}']")
            or croak "Can't find element with ID='${ref_uri}'";
        if(@attr > 1) {
            @attr = grep { lc( $_->localName() ) eq 'id' } @attr;
            if(@attr != 1) {
                croak "Reference URI '$ref_uri' is ambiguous";
            }
        }
        @elem = map { $_->ownerElement() } @attr;
    }
    return $elem[0];
}


sub _node_to_clarkian_path {
    my($self, $node) = @_;

    my $node_path = $node->nodePath();
    my %frag_ns;
    do {
        if(my $prefix = $node->prefix) {
            $frag_ns{$prefix} = $node->namespaceURI;
        }
        $node = $node->parentNode();
    } while($node);
    $node_path =~ s{([\w-]+):}{
        my $prefix = $1;
        my $uri = $frag_ns{$prefix};
        "{$uri}";
    }ge;
    return $node_path;
}


sub _make_sig_xml {
    my($self, $xc, %opt) = @_;

    my $sig = {};

    my $ref_specs = $opt{references} // [];
    die "Can't make a signature without references" unless @$ref_specs;
    my @references = map {
        $_->{digest_method} //= $opt{reference_digest_method} if $opt{reference_digest_method};
        $_->{transforms}    //= $opt{reference_transforms}    if $opt{reference_transforms};
        $self->_make_reference($xc, $_);
    } @$ref_specs;
    $sig->{references} = \@references;

    $sig->{c14n} = $self->_find_transform(
        $opt{c14n} // $self->c14n_method()
    );

    if(my $ns_list = $opt{c14n_namespaces}) {
        $sig->{c14n}->{namespaces} = $ns_list;
    }

    $sig->{signature_algorithm} = $self->_find_sig_alg(
        $opt{signature_algorithm} // $self->signature_algorithm()
    );

    return $self->_sig_as_xml($sig);
}


sub _sig_as_xml {
    my($self, $sig) = @_;

    my $ns_ds   = [ dsig => URI('ds') ];
    my $x = XML::Generator->new(':strict', pretty => 2);

    my @ref_blocks = map {
        my @transforms = map {
            $self->_transform_as_xml($x, 'Transform', $ns_ds, $_);
        } @{ $_->{transforms} };
        $x->Reference($ns_ds, { URI => '#' . $_->{ref_id} },
            $x->Transforms($ns_ds,
                @transforms,
            ),
            $x->DigestMethod($ns_ds, { Algorithm => $_->{digest_method}->{uri} }),
            $x->DigestValue($ns_ds, $_->{digest_value}),
        ),
    } @{ $sig->{references} };

    my $c14n    = $sig->{c14n};
    my $sig_alg = $sig->{signature_algorithm};

    my @key_info;
    if($self->include_x509_cert) {
        my $cert_text = $self->pub_cert_text()
            or die "Need pub_cert_file or pub_cert_text for include_x509_cert";
        $cert_text =~ s{\A\s*-+\s*BEGIN CERTIFICATE\s*-+\s*}{};
        $cert_text =~ s{\s*-+\s*END CERTIFICATE\s*-+\s*}{};
        $cert_text =~ s{^\s+}{}mg;
        @key_info = (
            $x->KeyInfo($ns_ds,
                $x->X509Data($ns_ds,
                    $x->X509Certificate($ns_ds,
                        $cert_text . "\n"
                    )
                )
            )
        );
    }

    my $sig_xml = $x->Signature($ns_ds,
        $x->SignedInfo($ns_ds,
            $self->_transform_as_xml($x, 'CanonicalizationMethod', $ns_ds, $c14n),
            $x->SignatureMethod($ns_ds, { Algorithm => $sig_alg->{uri} }),
            @ref_blocks,
        ),
        $x->SignatureValue($ns_ds),
        @key_info,
    ) . '';

    my $xc = $self->_xcdom_from_xml($sig_xml, @$ns_ds);
    my $doc = $xc->getContextNode();
    my($fragment) = [ $xc, $xc->findnodes('/ds:Signature/ds:SignedInfo') ];
    my $plaintext = $self->_apply_transform($sig->{c14n}, $fragment);
    my $sig_text = "\n" . $self->_create_signature(
        $sig->{signature_algorithm},
        $plaintext,
    );
    my($sig_node) = $xc->findnodes('//dsig:SignatureValue')
        or die "Failed to find SignatureValue in generated signature XML";
    $sig_node->addChild( $doc->ownerDocument->createTextNode($sig_text) );

    # Serialising, parsing and reserialising simplifies ns attr and empty tags
    return $self->_xml_to_dom( $doc->toStringEC14N() )->toString();
}


sub _transform_as_xml {
    my($self, $x, $tag_name, $ns_ds, $trans) = @_;

    my @content;
    if(my $ns_list = $trans->{namespaces}) {
        my $prefixes = join ' ', @$ns_list;
        my $ec_ns = [ 'ec' => URI('ec14n') ];
        push @content, $x->InclusiveNamespaces($ec_ns, { PrefixList => $prefixes });
    }
    my $xml = $x->$tag_name($ns_ds, { Algorithm => $trans->{uri} }, @content);
    return $xml;
}


sub _make_reference {
    my($self, $xc, $spec) = @_;

    if((ref($spec) || '') ne 'HASH') {
        die "references must be specified as hashrefs";
    }

    my $ref = {};
    my $ref_uri = $ref->{ref_id} = $spec->{ref_id}
        // die "need a 'ref_id' to create a reference";

    my $target_node = $self->_find_element_by_uri_reference($xc, $ref_uri);
    $ref->{xml_node} = $target_node;
    my $fragment = [$xc, $target_node];

    my @transforms = map {
        $self->_find_transform($_)
    } @{ $spec->{transforms} // $self->reference_transforms() };

    if(my $ns_list = $spec->{namespaces}) {
        if($transforms[-1]->{uri} ne URI('ec14n')) {
            $transforms[-1] = $self->_find_transform('ec14n');
        }
        $transforms[-1]->{namespaces} = $ns_list;
    }

    $ref->{transforms} = \@transforms;

    foreach my $transform ( @transforms ) {
        $fragment = $self->_apply_transform($transform, $fragment);
    }

    my $digest_method = $ref->{digest_method} = $self->_find_transform(
        $spec->{digest_method} // $self->reference_digest_method()
    );
    $ref->{digest_value} = $self->_apply_transform($digest_method, $fragment);

    return $ref;
}


sub find_verified_element {
    my($self, $xc, $xpath) = @_;

    my($node) = $xc->findnodes($xpath);
    croak "No element matches: '$xpath'" unless $node;

    # Check if the matching node, or one of its ancestors is in one of
    # the signed fragments which were verified earlier.

    my @vfrags = $self->_find_signed_fragment_nodes($xc);
    my $n = $node;
    do {
        foreach my $v (@vfrags) {
            return $node if $v->isEqual($n);
        }
        $n = $n->parentNode;
    } while ($n);
    croak "Element matching '$xpath' is not in a signed fragment";

    return $node;
}


sub _find_signed_fragment_nodes {
    my($self, $xc) = @_;

    my @paths = $self->_signed_fragment_paths;
    my %prefix;
    my $i = 1;
    foreach my $uri ("@paths" =~ m/{(.*?)}/g) {
        my $prefix = $prefix{$uri} //= sprintf('_XSig-%02u', $i++);
        s/{$uri}/$prefix:/g foreach @paths;
    }
    while(my($uri, $pfx) = each %prefix) {
        $xc->registerNs($pfx => $uri);
    }
    my @nodes = map { $xc->findnodes($_) } @paths;
    return @nodes;
}


sub ignore_bad_signatures {   # Called if skip_signature_check is enabled
    shift->{signed_fragment_paths} = [ '/' ];
}


sub create_detached_signature {
    my($self, $plaintext, $eol) = @_;

    $eol //= "\n";
    my $algorithm = $self->_find_sig_alg($self->signature_algorithm);
    my $b64_sig = $self->_create_signature($algorithm, $plaintext);
    $b64_sig =~ s/\s+/$eol/g;
    return $b64_sig;
}


sub verify_detached_signature {
    my($self, $plaintext, $b64_sig) = @_;

    my $algorithm = $self->_find_sig_alg($self->signature_algorithm);
    return $self->_verify_signature($algorithm, $plaintext, $b64_sig);
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


##############################################################################
# Methods for applying transforms
#
# A transform method takes a parameter '$input' which must either be a DOM
# fragment or a string.  Some of the transform methods also accept a second
# parameter '$args' which is a hashref defining the parameters of the transform
# in more detail.
#
# In the case of a DOM fragment, we also need the XPathContext object to
# facilitate the use of namespaces in queries.  Therefore the input parameter
# will be a reference to an array of two elements: the context object, followed
# by the DOM fragment node:
#
#     [ $xc, $node ]
#
# String input will be a simple scalar.  The _input_as_context_dom() helper
# method can be used to turn a string into a DOM fragment/context pair.
#
# The return value from the transform method will either be a DOM fragment
# /context pair or a string - depending on the type of transform.
#
# The process for calling these methods is:
#
# 1. Use $self->_find_transform($name_or_uri) to get a $transform hashref
#    describing the transform.
# 2. Optionally plug some extra parameters into the $transform hashref.
# 3. Call $self->_apply_transform($transform, $input)
#


sub register_transform_method {
    my($class, $name, $uri) = @_;
    my $transform = {
        name    => $name,
        uri     => $uri,
        method  => '_apply_transform_' . $name,
    };
    $transforms_by_name{$name} = $transform;
    $transforms_by_uri{$uri}   = $transform;
}


sub _find_transform {
    my($self, $identifier) = @_;

    my $transform = $transforms_by_name{$identifier}
        // $transforms_by_uri{$identifier}
           or die "Unknown transform: '$identifier'";
    return { %$transform };
}


sub _apply_transform {
    my($self, $transform, $input) = @_;

    my $method = $transform->{method} or die "transform does not include method";
    die "Unimplemented transformation method: '$method'" unless $self->can($method);
    return $self->$method($input, $transform);
}


sub _xcdom_from_xml {
    my($self, $xml, @namespaces) = @_;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($xml);
    my $xc     = XML::LibXML::XPathContext->new($doc->documentElement);

    $xc->registerNs( NS_PAIR('ds') );

    while(@namespaces) {
        my $prefix = shift @namespaces;
        my $uri    = shift @namespaces;
        $xc->registerNs($prefix, $uri);
    }

    return $xc;
}


sub _input_as_context_dom {
    my($self, $xml) = @_;
    my $xc = $self->_xcdom_from_xml($xml);
    return [ $xc, $xc->getContextNode ];
}


sub _apply_transform_env_sig {
    my($self, $input, $transform) = @_;

    $input = $self->_input_as_context_dom($input) unless ref $input;
    my($xc, $node) = @$input;
    my $ns_uri = $xc->lookupNs('ds');
    if(!$ns_uri) {
        $xc->registerNs(ds => URI('ds'));
    }
    elsif($ns_uri ne URI('ds')) {
        die "Namespace prefix 'ds' is mapped to '$ns_uri', expected '" . URI('ds') . "'";
    }
    foreach my $sig ( $xc->findnodes(q{.//ds:Signature}, $node) ) {
        $sig->parentNode->removeChild($sig);
    }
    return [ $xc, $node ];
}


sub _apply_transform_c14n {
    my($self, $input, $transform) = @_;
    return $self->_canonicalisation_transform(
        'toStringC14N', WITHOUT_COMMENTS, $input, $transform
    );
}


sub _apply_transform_c14n_wc {
    my($self, $input, $transform) = @_;
    return $self->_canonicalisation_transform(
        'toStringC14N', WITH_COMMENTS, $input, $transform
    );
}


sub _apply_transform_c14n11 {
    my($self, $input, $transform) = @_;
    return $self->_canonicalisation_transform(
        'toStringC14N_v1_1', WITHOUT_COMMENTS, $input, $transform
    );
}


sub _apply_transform_c14n11_wc {
    my($self, $input, $transform) = @_;
    return $self->_canonicalisation_transform(
        'toStringC14N_v1_1', WITH_COMMENTS, $input, $transform
    );
}


sub _apply_transform_ec14n {
    my($self, $input, $transform) = @_;
    return $self->_canonicalisation_transform(
        'toStringEC14N', WITHOUT_COMMENTS, $input, $transform
    );
}


sub _apply_transform_ec14n_wc {
    my($self, $input, $transform) = @_;
    return $self->_canonicalisation_transform(
        'toStringEC14N', WITH_COMMENTS, $input, $transform
    );
}


sub _canonicalisation_transform {
    my($self, $c14n_method, $want_comments, $input, $transform) = @_;
    $input = $self->_input_as_context_dom($input) unless ref $input;
    my($xc, $node) = @$input;
    my $xpath = undef;
    my $prefix_list = undef;
    if($transform->{namespaces}) {
        $prefix_list = $transform->{namespaces};
    }
    elsif(my $args = $transform->{args}) {
        my $argxc = $self->_xcdom_from_xml($args);
        $argxc->registerNs( NS_PAIR('ec14n') );
        my $prefix_list_xpath = './ec14n:InclusiveNamespaces/@PrefixList';
        my $prefixes = $argxc->findvalue($prefix_list_xpath);
        if($prefixes) {
            $prefix_list = [ $prefixes =~ /(\S+)/g ];
            $transform->{namespaces} = $prefix_list;
        }
    }
    return $node->$c14n_method($want_comments, $xpath, $xc, $prefix_list);
}


sub _apply_transform_sha1 {
    my($self, $input) = @_;
    if(ref($input)) {
        die "The SHA1 digest transform must be passed a string as input"
    }
    my $bin_digest = sha1($input);
    return encode_base64($bin_digest, '');
}


sub _apply_transform_sha256 {
    my($self, $input) = @_;
    if(ref($input)) {
        die "The SHA256 digest transform must be passed a string as input"
    }
    my $bin_digest = sha256($input);
    return encode_base64($bin_digest, '');
}


##############################################################################
# Methods for creating and verifying signatures using specific algorithms.
#
# Signatures are expected to be base64 encoded when provided as input or
# returned as output.
#


sub register_signature_methods {
    my($class, $name, $uri) = @_;
    my $signature_algorithm = {
        name          => $name,
        uri           => $uri,
        sign_method   => '_create_signature_' . $name,
        verify_method => '_verify_signature_' . $name,
    };
    $sig_alg_by_name{$name} = $signature_algorithm;
    $sig_alg_by_uri{$uri}   = $signature_algorithm;
}


sub _find_sig_alg {
    my($self, $identifier) = @_;

    my $sig_alg = $sig_alg_by_name{$identifier} // $sig_alg_by_uri{$identifier}
       or die "Unknown signature algorithm: '$identifier'";
    return $sig_alg;
}


sub _verify_signature {
    my($self, $sig_alg, $plaintext, $signature) = @_;
    my $method = $sig_alg->{verify_method}
        or die "transform does not include method";
    die "Unimplemented signature verification method: '$method'"
        unless $self->can($method);
    my $bin_sig = decode_base64($signature);
    return $self->$method($plaintext, $bin_sig);
}


sub _create_signature {
    my($self, $sig_alg, $plaintext) = @_;
    my $method = $sig_alg->{sign_method}
        or die "transform does not include method";
    die "Unimplemented signature creation method: '$method'"
        unless $self->can($method);
    my $bin_sig = $self->$method($plaintext);
    return encode_base64($bin_sig);
}


sub _verify_signature_rsa_sha1 {
    my($self, $plaintext, $bin_sig) = @_;
    my $rsa_pub_key = Crypt::OpenSSL::RSA->new_public_key($self->pub_key_text);
    $rsa_pub_key->use_pkcs1_padding();
    $rsa_pub_key->use_sha1_hash();
    return $rsa_pub_key->verify($plaintext, $bin_sig);
}


sub _verify_signature_rsa_sha256 {
    my($self, $plaintext, $bin_sig) = @_;
    my $rsa_pub_key = Crypt::OpenSSL::RSA->new_public_key($self->pub_key_text);
    $rsa_pub_key->use_pkcs1_oaep_padding();
    $rsa_pub_key->use_sha256_hash();
    return $rsa_pub_key->verify($plaintext, $bin_sig);
}


sub _create_signature_rsa_sha1 {
    my($self, $plaintext) = @_;
    my $rsa_key = Crypt::OpenSSL::RSA->new_private_key($self->key_text);
    $rsa_key->use_pkcs1_padding();
    $rsa_key->use_sha1_hash();
    return $rsa_key->sign($plaintext);
}


sub _create_signature_rsa_sha256 {
    my($self, $plaintext) = @_;
    my $rsa_key = Crypt::OpenSSL::RSA->new_private_key($self->key_text);
    $rsa_key->use_pkcs1_oaep_padding();
    $rsa_key->use_sha256_hash();
    return $rsa_key->sign($plaintext);
}


1;

__END__

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

Other recognised options are:

=over 4

=item C<c14n_method>

The canonicalisation method to use when creating a signature block.  Default
is 'ec14n'.

=item C<include_x509_cert>

A boolean flag indicating whether the generated signature should include an
X509 representation of the certificate with public key required to verify the
signature.

=item C<signature_algorithm>

The signature algorithm to use when creating a signature block.  Default
is 'rsa_sha1'.

=item C<reference_digest_method>

The digest method to use when creating a reference element in a signature
block.  Default is 'sha1'.

=item C<reference_transforms>

The list of transforms to usewhen creating a reference element in a signature
block.  Must be specified as an arrayref.  Default is [ 'env_sig', 'ec14n' ].

=back

=head2 id_attr( )

Returns the name of the attribute used to identify the element being signed.
By default the attribute name is not used at all and the element references are
resolved by matching the URI to any attribute value.  Can be set by passing
an C<id_attr> option to the constructor.

=head2 sign( $xml, $target_id, options ... )

Takes an XML document and an optional element ID value and returns a string of
XML with a digital signature added.  The XML document can be provided either as
a string or as an XML::LibXML DOM object.

Named options can be provided to customise the transforms and algorithms used
when generating the signature block.  In particular, the C<references> option
can be used to supply a list of multiple references.  In which case, a value
of C<undef> should be provided for the C<$target_id> parameter:

  my $refs = [
      { ref_uri => $first_uri_value },
      { ref_uri => $second_uri_value },
  ];
  $signer->sign($xml, undef, references => $ref);

Each reference can include a list of namespace prefixes to be included in the
canonicalisation transform.

=head2 create_detached_signature( $plaintext, $eol )

Takes a plaintext string, calculates a signature using the private key (and
optionally the signarture algorithm) passed to the constructor and returns a
base64-encoded string. The C<$eol> parameter can be used to specify the
line-ending character used in the base64 encoding process (default: \n).

=head2 verify_detached_signature( $plaintext, $base64_sig )

Takes a plaintext string, and a base64-encoded signature.  Verifies the
signature using the public key or certificate supplied to the constructor.
Returns true if the signature is valid, and false otherwise.

=head2 verify( $xml, $selector_xpath, @namespaces )

Takes an XML string (or DOM object); searches for signature elements; verifies
the provided signature and message digest for each; and returns true on success.
The caller would then typically use C<find_verified_element()> to ensure that
subsequent queries target element which were covered by a verified signature.

The C<$selector_xpath> can be used to identify which C<< <Signature> >> element
should be checked.  This is particularly useful with documents containing
multiple signatures where each was creaated using a different key (since the
API only provides for a single cert/public key).  If not provided, a default
selector of C<'//ds:Signature'> will be used.

If provided, the value for C<$selector_xpath> may use 'ds' as a namespace
prefix for digital signature elements.  If any other namespaces are required,
the following arguments are assumed to be C<< prefix => uri >> pairs. For
example this code might be used to verify signatures in the SOAP envelope while
ignoring signatures in the payload withing the SOAP body:

    my $selector = '//ds:Signature[not(ancestor::soap12:Body)]';
    $verifier->verify($xml, $selector, NS_PAIR('soap12'));

If the provided document does not contain any signatures which match the
selector, or if an invalid signature is found, an exception will be thrown.

=head2 find_verified_element( $xc, $xpath )

This method is a wrapper around the standard  L<XML::LibXML> C<findnodes()>
method, which also confirms that the matching node is within one of the signed
fragments which were identified by the earlier call to the C<verify()> method.

The caller must provide an L<XML::LibXML::XPathContext> object with registered
URIs for all namespace prefixes required by the supplied XPath expression.

=head2 ignore_bad_signatures( )

Calling this method after C<verify()> will tag the root element as a verified
fragment.  This is used in cases where signature verification failed (perhaps
because the other party has just replaced their signing key) but you wish to
proceed with calling C<find_verified_element()> anyway.

=head2 key_text( )

Returns the private key text which will be used to initialise the
L<Crypt::OpenSSL::RSA> object used for generating signatures.

=head2 pub_key_text( )

Returns the public key text used to initialise the L<Crypt::OpenSSL::RSA>
object used for verifing signatures.

=head2 pub_cert_text( )

If the public key is being extracted from an X509 certificate, this method is
used to retrieve the text which defines the certificate.

=head2 register_transform_method( $name, $uri )

Used internally to register methods for implementing transformation algorithms
so that they can be looked by by URI.  May be called by a subclass to add
support for additional algorithms.

=head2 register_signature_methods( $name, $uri )

Used internally to register methods for implementing creation and verification
of signatures using specific algorithms so that they can be looked by by URI.
May be called by a subclass to add support for additional algorithms.

=head1 SUPPORTED SIGNATURE ALGORITHMS

=head3 rsa_sha1

=head3 rsa_sha256


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Enrolment Services, New Zealand Electoral Commission

Written by Grant McLean E<lt>grant@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut

