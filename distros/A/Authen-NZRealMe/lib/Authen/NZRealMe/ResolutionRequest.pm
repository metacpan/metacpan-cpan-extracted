package Authen::NZRealMe::ResolutionRequest;
$Authen::NZRealMe::ResolutionRequest::VERSION = '1.21';
use warnings;
use strict;

require XML::Generator;

use MIME::Base64 qw(decode_base64);

use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);


my $ns_soap_env = [ NS_PAIR('soap11') ];
my $ns_saml     = [ NS_PAIR('saml') ];
my $ns_samlp    = [ NS_PAIR('samlp') ];


sub new {
    my $class    = shift;
    my $sp       = shift;
    my $artifact = shift;

    my $self = bless {
        artifact   => $artifact,
    }, $class;
    return $self->_init($sp);
}


sub _init {
    my($self, $sp) = @_;

    $self->{request_id}   = $sp->generate_saml_id('ArtifactResolve'),
    $self->{issuer}       = $sp->entity_id;
    $self->{request_time} = $sp->now_as_iso();

    my $bytes = decode_base64($self->artifact);
    my($type_code, $index, $source_id, $msg_handle) = unpack('nna20a20', $bytes);

    if($type_code != 4) {
        die sprintf('Unexpected type code in received artifact: 0x%04X', $type_code);
    }

    my $idp = $sp->idp;
    $idp->validate_source_id($source_id);   # dies on error

    $self->{destination_url} = $sp->idp->artifact_resolution_location($index);

    $self->_generate_artifact_resolve_doc();

    return $self;
}

sub artifact        { shift->{artifact};            }
sub request_id      { shift->{request_id};          }
sub issuer          { shift->{issuer};              }
sub request_time    { shift->{request_time};        }
sub destination_url { shift->{destination_url};     }
sub soap_request    { shift->{soap_request};        }


sub _generate_artifact_resolve_doc {
    my $self = shift;

    my $x = XML::Generator->new(':pretty',
        namespace => [ @$ns_soap_env, @$ns_saml, @$ns_samlp ],
    );

    $self->{soap_request} = $x->Envelope($ns_soap_env,
        $x->Body($ns_soap_env,
            $x->ArtifactResolve($ns_samlp,
                {
                    Version      => '2.0',
                    ID           => $self->request_id(),
                    IssueInstant => $self->request_time(),
                },
                $x->Issuer($ns_saml,
                    $self->issuer
                ),
                $x->Artifact($ns_samlp,
                    $self->artifact
                ),
            ),
        ),
    ) . "\n";  # ensure result is stringified
}

1;

__END__

=head1 NAME

Authen::NZRealMe::ResolutionRequest - Generate a SOAP request for resolving an
artifact to an FLT

=head1 DESCRIPTION

This package is used by the L<Authen::NZRealMe::ServiceProvider> to generate a
properly formatted SOAP Request containing a SAML2 ArtifactResolve message to
resolve an artifact to an FLT.

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call the
C<resolve_artifact> method on the service provider object.

=head2 artifact

Accessor method to return the (base64 encoded) artifact string as returned
by the NZ RealMe Login service Identity Provider.

=head2 request_id

Accessor for the generated unique ID for this request.

=head2 issuer

Accessor for the entity ID of the Service Provider which generated the request.

=head2 request_time

Accessor for the request creation time formatted as an ISO date/time string.

=head2 destination_url

Accessor for the URL of the Identity Provider's artifact resolution service, to
which this request will be sent.

=head2 soap_request

Accessor for the XML document which will be sent as a SOAP request to the
Identity Provider's artifact resolution service.


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


