package Authen::NZRealMe::ICMSResolutionRequest;
{
  $Authen::NZRealMe::ICMSResolutionRequest::VERSION = '1.16';
}

use warnings;
use strict;

require XML::Generator;
require Data::UUID;

use POSIX        qw(strftime);
use Digest::MD5  qw(md5_hex);


my $ns_soap     = [ soap  => "http://www.w3.org/2003/05/soap-envelope" ];
my $ns_wsse     = [ wsse  => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-secext-1.0.xsd" ];
my $ns_wsu      = [ wsu   => "http://docs.oasis-open.org/wss/2004/01/oasis-200401-wss-wssecurity-utility-1.0.xsd" ];
my $ns_wst      = [ wst   => "http://docs.oasis-open.org/ws-sx/ws-trust/200512" ];
my $ns_wsa      = [ wsa   => "http://www.w3.org/2005/08/addressing" ];
my $ns_icms     = [ iCMS  => "urn:nzl:govt:ict:stds:authn:deployment:igovt:gls:iCMS:1_0" ];

my $request_type_urn = 'http://docs.oasis-open.org/ws-sx/ws-trust/200512/Validate';
my $token_type_urn   = 'http://docs.oasis-open.org/wss/oasis-wss-saml-token-profile-1.1#SAMLV2.0';
my $addressing_urn   = 'http://www.w3.org/2005/08/addressing/anonymous';


sub new {
    my $class      = shift;
    my $sp         = shift;
    my $icms_token = shift;

    my $self = bless {
        icms_token   => $icms_token,
        signer       => $sp->_signer('wsu:Id'),
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
    my $signed_parts = {
        Action    =>  {
            id          => $sp->generate_saml_id('wsa:Action'),
            namespaces  => ['soap'],
        },
        MessageID =>  {
            id          => $sp->generate_saml_id('wsa:MessageID'),
            namespaces  => ['soap'],
        },
        To        =>  {
            id          => $sp->generate_saml_id('wsa:To'),
            namespaces  => ['soap'],
        },
        ReplyTo   =>  {
            id          => $sp->generate_saml_id('wsa:ReplyTo'),
            namespaces  => ['soap'],
        },
        Timestamp =>  {
            id          => $sp->generate_saml_id('wsa:Timestamp'),
        },
        Body      =>  {
            id          => $sp->generate_saml_id('soap:Body'),
        },
    };

    my $uuid_gen = new Data::UUID;
    $self->{request_id}   = 'urn:uuid:'.$uuid_gen->create_str();

    my $method_data = $self->_method_data;
    $self->{destination_url} = $method_data->{url};

    my $x = XML::Generator->new(
        escape => 'unescaped',  # So we can insert other document bits usefully
    );

    my $soap_request = $x->Envelope($ns_soap,
        $x->Header($ns_soap,
            $x->Action( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $signed_parts->{Action}->{id}}, $method_data->{operation}),
            $x->MessageID( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $signed_parts->{MessageID}->{id}}, $self->request_id),
            $x->To( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $signed_parts->{To}->{id}}, $method_data->{url}),
            $x->ReplyTo( [@$ns_wsa, @$ns_wsu], {'wsu:Id' => $signed_parts->{ReplyTo}->{id}},
                $x->Address( $ns_wsa, $addressing_urn ),
            ),
            $x->Security( [@$ns_wsse, @$ns_wsu], {'soap:mustUnderstand' => 'true'},  # Populated by signing method
                $x->Timestamp( $ns_wsu, {'wsu:Id' => $signed_parts->{Timestamp}->{id}},
                    $x->Created ( $ns_wsu, strftime "%FT%TZ", gmtime() ),
                    $x->Expires ( $ns_wsu, strftime "%FT%TZ", gmtime( time() + 300) ),
                ),
            )
        ),
        $x->Body($ns_soap, {'wsu:Id' => $signed_parts->{Body}->{id}},
            $x->RequestSecurityToken($ns_wst,
                $x->RequestType( $ns_wst, $request_type_urn ),
                $x->TokenType( $ns_wst, $token_type_urn ),
                $x->ValidateTarget( $ns_wst, \$self->icms_token ),
                $x->AllowCreateFLT( $ns_icms),
            ),
        ),
    ) . "";
    my @signed_part_ids = values %$signed_parts;
    $soap_request = $self->_sign_xml( $soap_request, \@signed_part_ids );

    $self->{request_data} = $soap_request;
    return $soap_request
}

sub _sign_xml {
    my($self, $xml, $target_ids) = @_;

    my $signer = $self->_signer;
    return $signer->sign_multiple_targets($xml, $target_ids);
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

Copyright (c) 2010-2014 Enrolment Services, New Zealand Electoral Commission

Written by Haydn Newport E<lt>haydn@catalyst.net.nzE<gt>

This program is free software; you can redistribute it and/or modify it
under the terms of either: the GNU General Public License as published
by the Free Software Foundation; or the Artistic License.

See http://dev.perl.org/licenses/ for more information.

=cut


