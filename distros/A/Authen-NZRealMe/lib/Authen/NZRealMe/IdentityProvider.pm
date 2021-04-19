package Authen::NZRealMe::IdentityProvider;
$Authen::NZRealMe::IdentityProvider::VERSION = '1.23';
use strict;
use warnings;

require XML::LibXML;
require XML::LibXML::XPathContext;

use MIME::Base64 qw(encode_base64);
use Digest::SHA  qw(sha1_base64);

use Authen::NZRealMe::CommonURIs qw(URI NS_PAIR);


my %metadata_cache;


my $ns_ds         = [ NS_PAIR('ds') ];

my $soap_binding  = URI('saml_b_soap');

my %saml_binding = (
    URI('saml_binding_artifact') => 'artifact',
    URI('saml_binding_redirect') => 'redirect',
    URI('saml_binding_post')     => 'post',
);

sub new {
    my $class = shift;

    my $self = bless {
        type  => 'login',
        @_
    }, $class;
    $self->_load_metadata();

    return $self;
}


sub conf_dir              { shift->{conf_dir};               }
sub type                  { shift->{type};                   }
sub entity_id             { shift->{entity_id};              }
sub signing_cert_pem_data { shift->{signing_cert_pem_data};  }

sub login_cert_pem_data {
    my $self = shift;
    my $type = 'login';
    my $cache_key = $self->conf_dir . '-' . $type;
    my $params = $metadata_cache{$cache_key} || $self->_read_metadata_from_file($type);
    return $params->{signing_cert_pem_data};
}

sub single_signon_location {
    my($self, $binding) = @_;

    my @locations = values %{$self->{sso}};
    return $locations[0] if @locations == 1;

    die "Need a binding for single_signon_location" unless defined $binding;

    my $location = $self->{sso}->{lc($binding)}
        or die "No mapping for single_signon_location '$binding' binding";
    return $location;
}

sub artifact_resolution_location {
    my($self, $index) = @_;

    die "Need an index for artifact_resolution_location" unless defined $index;
    my $url = $self->{ars}->{$index}
        or die "No mapping for artifact_resolution_location index '$index'";
    return $url;
}


sub verify_signature {
    my($self, $xml) = @_;

    my $verifier;
    eval {
        $verifier = Authen::NZRealMe->class_for('xml_signer')->new(
            pub_cert_text => $self->signing_cert_pem_data(),
        );
        $verifier->verify($xml);
    };
    if($@) {
        die "Failed to verify signature on assertion from IdP:\n  $@\n$xml";
    }
    return $verifier;
}


sub _load_metadata {
    my $self = shift;

    my $cache_key = $self->conf_dir . '-' . $self->type;
    my $params = $metadata_cache{$cache_key} || $self->_read_metadata_from_file;

    $self->{$_} = $params->{$_} foreach keys %$params;
}


sub _read_metadata_from_file {
    my ($self, $type) = @_;
    $type //= $self->type;

    my $metadata_file = $self->_metadata_pathname($type);
    die "File does not exist: $metadata_file\n" unless -e $metadata_file;

    my $parser = XML::LibXML->new();
    my $doc    = $parser->parse_file( $metadata_file );
    my $xc     = XML::LibXML::XPathContext->new( $doc->documentElement() );

    $xc->registerNs( md => URI('samlmd') );
    $xc->registerNs( @$ns_ds );

    my %params;
    foreach (
        [ entity_id              => q{/md:EntityDescriptor/@entityID} ],
        [ signing_cert_pem_data  => q{/md:EntityDescriptor/md:IDPSSODescriptor/md:KeyDescriptor[@use = 'signing']/ds:KeyInfo/ds:X509Data/ds:X509Certificate} ],
    ) {
        $params{$_->[0]} = $xc->findvalue($_->[1]);
    }
    # Strip whitespace and re-wrap base64 encoded data to 64 chars per line
    $params{signing_cert_pem_data} =~ s{\s+}{}g;
    my @cert_parts = $params{signing_cert_pem_data} =~ m{(\S{1,64})}g;
    $params{signing_cert_pem_data} = join("\n",
        '-----BEGIN CERTIFICATE-----',
        @cert_parts,
        '-----END CERTIFICATE-----',
    ) . "\n";

    my %ars;
    foreach my $svc ( $xc->findnodes(
        q{/md:EntityDescriptor/md:IDPSSODescriptor/md:ArtifactResolutionService}
    )) {
        my($index)   = $xc->findvalue(q{./@index}, $svc)
            or die "No index for ArtifactResolutionService:\n" . $svc->toString;
        $ars{$index} = $xc->findvalue(q{./@Location}, $svc)
            or die "No Location for ArtifactResolutionService:\n" . $svc->toString;
        my $binding  = $xc->findvalue(q{./@Binding}, $svc)
            or die "No Binding for ArtifactResolutionService:\n" . $svc->toString;
        die "Unrecognised binding '$binding' for ArtifactResolutionService: \n" . $svc->toString
            if $binding ne $soap_binding;
    }
    $params{ars} = \%ars;

    my %sso;
    foreach my $svc ( $xc->findnodes(
        q{/md:EntityDescriptor/md:IDPSSODescriptor/md:SingleSignOnService},
    )) {
        my $binding = $xc->findvalue(q{./@Binding}, $svc)
            or die "No Binding for SingleSignOnService:\n" . $svc->toString;
        my $type = $saml_binding{$binding}
            or die "Unrecognised binding '$binding' for SingleSignOnService: \n" . $svc->toString;
        $sso{$type} = $xc->findvalue(q{./@Location}, $svc)
            or die "No Location for SingleSignOnService binding '$binding':\n" . $svc->toString;
    }
    $params{sso} = \%sso;
    die "No SingleSignOnService element defined in $metadata_file\n" unless keys %sso;

    my $cache_key = $self->conf_dir . '-' . $type;
    $metadata_cache{$cache_key} = \%params;
}


sub _metadata_pathname {
    my ($self, $type) = @_;
    $type //= $self->type;
    my $conf_dir = $self->conf_dir or die "conf_dir not set";
    return $conf_dir . '/metadata-' . $type . '-idp.xml';
}


sub validate_source_id {
    my($self, $source_id) = @_;

    my $got = encode_base64($source_id, '');
    my $exp = sha1_base64( $self->entity_id );

    s/=+$// foreach ( $got, $exp);

    return 1 if $got eq $exp;

    die "Invalid SourceID during artifact resolution\n"
        . "Got     : '$got'\n"
        . "Expected: '$exp'\n";
}


1;


__END__

=head1 NAME

Authen::NZRealMe::IdentityProvider - Class representing the NZ RealMe Login SAML IdP

=head1 DESCRIPTION

This class is used to represent the SAML IdP (Identity Provider) which
implements the RealMe Login service.  An object of this class is initialised
from the F<metadata-login-idp.xml> in the configuration directory.

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call the C<idp> method
on the service provider object.

The C<conf_dir> parameter B<must> be provided.  It specifies the full pathname
of the directory containing the IdP metadata file.

=head2 type

Accessor for the type of service ("login" or "assertion") this IdP provides.

=head2 conf_dir

Accessor for the C<conf_dir> parameter passed in to the constructor.

=head2 entity_id

Accessor for the C<ID> parameter in the Identity Provider metadata file.

=head2 single_signon_location ( binding )

Accessor for the C<SingleSignOnService> parameter in the Service Provider
metadata file.

The optional parameter C<binding> is required if multiple SingleSignOnService
elements are defined:

=over 4

=item artifact => SAML 2.0 HTTP-Artifact binding

=item redirect => SAML 2.0 HTTP-Redirect binding

=item post => SAML 2.0 HTTP-POST binding

=back


=head2 signing_cert_pem_data

Accessor for the signing certificate (X509 format) text from the metadata file.
If supplied with a service type, it will return the certificate appropriate to
that type.

=head2 login_cert_pem_data

Accessor for the signing certificate (X509 format) text from the metadata file
of the login service.  This is used when resolving the opaque token from the
identity assertion through the iCMS service.

=head2 artifact_resolution_location

Accessor for the C<ArtifactResolutionService> parameter in the Service Provider
metadata file.  When calling this method, you must provide an index number
(from the artifact).

=head2 verify_signature

Takes an XML document signed by the Identity provider and returns true if the
signature is valid.

=head2 validate_source_id

Takes a source ID string from an artifact to be resolved and confirms that it
was generated by this Identity Provider.  Returns true on successs, dies on
error.


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


