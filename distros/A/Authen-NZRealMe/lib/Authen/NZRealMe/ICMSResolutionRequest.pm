package Authen::NZRealMe::ICMSResolutionRequest;
$Authen::NZRealMe::ICMSResolutionRequest::VERSION = '1.18';
use warnings;
use strict;

require XML::Generator;
require XML::LibXML;
require XML::LibXML::XPathContext;
require Data::UUID;

use POSIX        qw(strftime);
use Digest::MD5  qw(md5_hex);
use MIME::Base64 qw(encode_base64);

use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);


my $ns_soap       = [ 'soap' => URI('soap12') ];
my $ns_wsse       = [ NS_PAIR('wsse') ];
my $ns_wsu        = [ NS_PAIR('wsu') ];
my $ns_wst        = [ NS_PAIR('wst') ];
my $ns_wsa        = [ NS_PAIR('wsa') ];
my $ns_icms       = [ NS_PAIR('icms') ];
my $ns_ds         = [ 'dsig' => URI('ds') ];
my @all_ns = (
    $ns_soap, $ns_wsse, $ns_wsu, $ns_wst, $ns_wsa, $ns_icms
);

my $wst_validate  = URI('wst_validate');
my $wss_saml2     = URI('wss_saml2');
my $wsa_anon      = URI('wsa_anon');


sub new {
    my $class      = shift;
    my $sp         = shift;
    my $icms_token = shift;

    my $self = bless {
        icms_token   => $icms_token,
        signer       => $sp->_signer(),
        method_data  => $sp->_icms_method_data( 'Validate' ),
    }, $class;

    die "The ICMS WSDL file has not been parsed or contains no data."
        unless $self->_method_data;

    return $self->_init($sp);
}


sub _init {
    my $self = shift;
    my $sp   = shift;

    $self->_generate_flt_resolve_doc($sp);

    return $self;
}

sub icms_token      { shift->{icms_token};      }
sub request_id      { shift->{request_id};      }
sub destination_url { shift->{destination_url}; }
sub request_data    { shift->{request_data};    }
sub _method_data    { shift->{method_data};     }
sub _signer         { shift->{signer};          }


sub _generate_flt_resolve_doc {
    my $self = shift;
    my $sp   = shift;

    # The following list of parts will be signed in the request, any with a
    # 'namespaces' array will have those namespaces treated as InclusiveNamespaces
    # as detailed in http://www.w3.org/TR/2002/REC-xml-exc-c14n-20020718/#sec-Specification
    my @signed_parts = (
        {
            name        => 'Action',
            id          => $sp->generate_saml_id('wsa:Action'),
            namespaces  => ['soap'],
        },
        {
            name        => 'MessageID',
            id          => $sp->generate_saml_id('wsa:MessageID'),
            namespaces  => ['soap'],
        },
        {
            name        => 'To',
            id          => $sp->generate_saml_id('wsa:To'),
            namespaces  => ['soap'],
        },
        {
            name        => 'ReplyTo',
            id          => $sp->generate_saml_id('wsa:ReplyTo'),
            namespaces  => ['soap'],
        },
        {
            name        => 'Timestamp',
            id          => $sp->generate_saml_id('wsa:Timestamp'),
        },
        {
            name        => 'Body',
            id          => $sp->generate_saml_id('soap:Body'),
        },
    );

    my %part_id = map { $_->{name} => $_->{id} } @signed_parts;

    my $uuid_gen = new Data::UUID;
    $self->{request_id}   = 'urn:uuid:'.$uuid_gen->create_str();

    my $method_data = $self->_method_data;
    $self->{destination_url} = $method_data->{url};

    my $x = XML::Generator->new(
        escape => 'unescaped',  # So we can insert other document bits usefully
    );

    my $soap_request = $x->Envelope($ns_soap,
        $x->Header($ns_soap,
            $x->Action( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $part_id{Action}}, $method_data->{operation}),
            $x->MessageID( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $part_id{MessageID}}, $self->request_id),
            $x->To( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $part_id{To}}, $method_data->{url}),
            $x->ReplyTo( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $part_id{ReplyTo}},
                $x->Address( $ns_wsa, $wsa_anon ),
            ),
            $x->Security( [@$ns_wsse, @$ns_wsu], {'soap:mustUnderstand' => 'true'},  # Populated by signing method
                $x->Timestamp( $ns_wsu, {'wsu:Id' => $part_id{Timestamp}},
                    $x->Created ( $ns_wsu, strftime "%FT%TZ", gmtime() ),
                    $x->Expires ( $ns_wsu, strftime "%FT%TZ", gmtime( time() + 300) ),
                ),
            )
        ),
        $x->Body($ns_soap, {'wsu:Id' => $part_id{Body}},
            $x->RequestSecurityToken($ns_wst,
                $x->RequestType( $ns_wst, $wst_validate ),
                $x->TokenType( $ns_wst, $wss_saml2 ),
                $x->ValidateTarget( $ns_wst, \$self->icms_token ),
                $x->AllowCreateFLT( $ns_icms),
            ),
        ),
    ) . "";

    my @refs = map {
        my $ref = { ref_id => $_->{id} };
        $ref->{namespaces} = $_->{namespaces} if $_->{namespaces};
        $ref;
    } @signed_parts;
    $soap_request = $self->_sign_xml( $soap_request, \@refs );

    $self->{request_data} = $soap_request;
    return $soap_request;
}

sub _sign_xml {
    my($self, $xml, $refs) = @_;

    # Just ask the signer to return the signature block
    my $signer = $self->_signer;
    my $sig_xml = $signer->sign(
        $xml,
        undef,    # refs in options
        return_signature_xml    => 1,
        references              => $refs,
        reference_transforms    => [ 'ec14n' ],
        reference_digest_method => 'sha256',
        namespaces              => [ @$ns_soap ],
    );

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_string($xml);
    my $xc     = XML::LibXML::XPathContext->new($doc->documentElement);
    $xc->registerNs( @$_ ) foreach @all_ns;

    my $sig_frag = $parser->parse_string($sig_xml)->documentElement();
    $sig_frag->{Id} = 'SIG-4';  # Add Id attr for backwards compatibility

    # Generate a cert fingerprint and append to the signature block
    my $x509 = Crypt::OpenSSL::X509->new_from_string($signer->pub_cert_text);
    my $fingerprint = $x509->fingerprint_sha1() =~ s/://gr;
    my $fingerprint_sha1 = encode_base64(pack("H*", $fingerprint), '');

    my $x = XML::Generator->new();
    my $keyinfo_block = $x->KeyInfo( $ns_ds, { Id => "KI-${fingerprint}1" },
        $x->SecurityTokenReference( $ns_wsse, { Id => "STR-${fingerprint}2" },
            $x->KeyIdentifier( $ns_wsse, { EncodingType => URI('wss_b64'), ValueType => URI('wss_sha1') },
                $fingerprint_sha1,
            ),
        ),
    ).'';
    my $x509_frag = $parser->parse_string($keyinfo_block)->documentElement();
    $sig_frag->appendChild($x509_frag);

    # Insert signature block as last element in soap:Header/wsse:Security section
    my($sec_node) = $xc->findnodes("/soap:Envelope/soap:Header/wsse:Security");
    $sec_node->appendChild($sig_frag);
    return $doc->toString(0);
}


1;

__END__

=head1 NAME

Authen::NZRealMe::ICMSResolutionRequest - Generate a WS-Trust request
for resolving an opaque token to a RealMe FLT.

=head1 DESCRIPTION

This package is used by the L<Authen::NZRealMe::ServiceProvider> to generate a
properly formatted WS-Trust Request containing an opaque token to
resolve to an FLT.

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call the
C<resolve_artifact> method on the service provider with the 'resolve_flt'
option set to a true value.

=head2 icms_token

Accessor method to return the XML opaque token string as provided by the
assertion service

=head2 request_id

Accessor for the generated unique ID for this request.

=head2 request_data

Accessor for the entity ID of the Service Provider which generated the request.

=head2 request_time

Accessor for the request creation time formatted as an ISO date/time string.

=head2 destination_url

Accessor for the URL of the FLT resolution service, to which this request
will be sent.

=head2 request_data

Accessor for the XML document which will be sent as a SOAP request to the
context mapping service (ICMS).


=head1 SEE ALSO

See L<Authen::NZRealMe> for documentation index.


=head1 LICENSE AND COPYRIGHT

Copyright (c) 2010-2019 Enrolment Services, New Zealand Electoral Commission

Written by Haydn Newport E<lt>haydn@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


