package Authen::NZRealMe::AuthenRequest;
{
  $Authen::NZRealMe::AuthenRequest::VERSION = '1.16';
}

use strict;
use warnings;

require XML::Generator;

use MIME::Base64               qw(encode_base64 decode_base64);
use URI::Escape                qw(uri_escape uri_unescape);
use IO::Uncompress::RawInflate qw(rawinflate $RawInflateError);
use IO::Compress::RawDeflate   qw(rawdeflate $RawDeflateError);

my $ns_saml  = [ saml  => 'urn:oasis:names:tc:SAML:2.0:assertion' ];
my $ns_samlp = [ samlp => 'urn:oasis:names:tc:SAML:2.0:protocol'  ];


sub new {
    my $class = shift;
    my $sp    = shift;

    my $self = bless {
        allow_create    => 'false',
        force_auth      => 'true',
        auth_strength   => 'low',
        @_,
    }, $class;
    return $self->_init($sp);
}


sub _init {
    my($self, $sp) = @_;

    $self->{service_type}    = $sp->type;
    $self->{request_id}      = $sp->generate_saml_id('AuthnRequest');
    $self->{entity_id}       = $sp->entity_id;
    $self->{destination_url} = $sp->idp->single_signon_location;
    $self->{request_time}    = $sp->now_as_iso();
    $self->{nameid_format}   = $sp->nameid_format();

    my $strength_class       = Authen::NZRealMe->class_for('logon_strength');
    $self->{auth_strength}   = $strength_class->new($self->{auth_strength});

    my $xml = $self->_generate_authn_request_doc();
    $self->{query_string} = $sp->sign_query_string($self->_raw_query_string);

    return $self;
}


sub service_type    { shift->{service_type};        }
sub request_id      { shift->{request_id};          }
sub entity_id       { shift->{entity_id};           }
sub request_time    { shift->{request_time};        }
sub destination_url { shift->{destination_url};     }
sub saml_request    { shift->{saml_request};        }
sub relay_state     { shift->{relay_state};         }
sub allow_create    { shift->_bool('allow_create'); }
sub force_auth      { shift->_bool('force_auth');   }
sub auth_strength   { shift->{auth_strength};       }
sub _query_string   { shift->{query_string};        }
sub _nameid_format  { shift->{nameid_format};       }
sub _x              { shift->{x};                   }


sub _bool {
    my($self, $flag) = @_;
    my $value = shift->{$flag};
    return (defined($value) && lc($value) =~ /^(1|true)$/)
           ? 'true'
           : 'false';
}


sub as_url {
    my $self = shift;

    return $self->destination_url . '?' . $self->_query_string;
}


sub _raw_query_string {
    my $self = shift;

    my $qs = 'SAMLRequest=' . uri_escape( $self->encoded_saml_request() );

    if(my $rs = $self->relay_state) {
        $qs .= '&RelayState=' . uri_escape($rs);
    }

    return $qs;
}


sub _generate_authn_request_doc {
    my $self = shift;

    my $x = XML::Generator->new(#':pretty',
        namespace => [ @$ns_saml, @$ns_samlp ],
    );
    $self->{x} = $x;

    $self->{saml_request} = $x->AuthnRequest($ns_samlp,
        {
            Version                       => '2.0',
            ID                            => $self->request_id(),
            IssueInstant                  => $self->request_time(),
            Destination                   => $self->destination_url(),
            $self->service_type eq 'login'
                ? (ForceAuthn             => $self->force_auth() )
                : (),
            AssertionConsumerServiceIndex => '0',
        },
        $self->_issuer(),
        $self->_nameid_policy(),
        $self->service_type eq 'login'
            ? $self->_authen_context()
            : (),
    ) . '';  # ensure result is stringified
}


sub _issuer {
    my $self = shift;
    my $x    = $self->_x;

    return $x->Issuer($ns_saml,
        $self->entity_id
    );
}


sub _nameid_policy {
    my $self = shift;

    return $self->_login_nameid_policy()     if $self->service_type eq 'login';
    return $self->_assertion_nameid_policy() if $self->service_type eq 'assertion';
}


sub _login_nameid_policy {
    my $self = shift;
    my $x    = $self->_x;

    return $x->NameIDPolicy($ns_samlp,
        {
            Format      => $self->_nameid_format(),
            AllowCreate => $self->allow_create(),
        },
    );
}


sub _assertion_nameid_policy {
    my $self = shift;
    my $x    = $self->_x;

    return $x->NameIDPolicy($ns_samlp,
        {
            Format      => $self->_nameid_format(),
        },
    );
}


sub _authen_context {
    my $self = shift;
    my $x    = $self->_x;

    my $strength = $self->auth_strength();
    return $x->RequestedAuthnContext($ns_samlp,
        $x->AuthnContextClassRef($ns_saml, $strength->urn()),
    );
}


sub encoded_saml_request {
    my($self) = @_;

    my $xml    = $self->saml_request();
    my $data   = '';
    my $status = rawdeflate \$xml => \$data, Append => 0
        or die "Can't compress request data: $RawDeflateError\n";

    $data = encode_base64($data);
    $data =~ s{[\r\n]}{}g;

    return $data;
}


sub dump_request {
    my $class = shift;

    # Get data from commandline or slurp from standard input

    my $data = @_
               ? shift
               : do { local($/) = undef; <STDIN>; };

    my $xml  = $data =~ m{^https?:}
               ? $class->_request_from_uri($data)
               : $class->_request_from_uri_param($data);

    print $xml, "\n";
}


sub _request_from_uri {
    my($class, $uri) = @_;

    my($data) = $uri =~ m{\bSAMLRequest=(.*?)(?:&|$)}
        or die "Can't find 'SAMLRequest' parameter in query string";
    return  $class->_request_from_uri_param($data);
}


sub _request_from_uri_param {
    my($class, $data) = @_;

    $data = uri_unescape($data);
    $data = decode_base64($data);

    my($xml, $status);
    $status = rawinflate \$data => \$xml
        or die "Can't decompress request data: $RawInflateError\n";

    return $xml;
}

1;

__END__

=head1 NAME

Authen::NZRealMe::AuthenRequest - Generate a SAML2 AuthenRequest message

=head1 DESCRIPTION

This package is used by the L<Authen::NZRealMe::ServiceProvider> to generate a
SAML2 AuthnRequest message and send it to the NZ RealMe Login service IdP
(Identity Provider) using the HTTP-Redirect binding.

=head1 METHODS

=head2 new

Constructor.  Should not be called directly.  Instead, call the C<new_request>
method on the service provider object.

The following named parameters are recognised:

  allow_create     boolean       (default: false)
  force_auth       boolean       (default: true)
  relay_state      short string  (default: none)
  auth_strength    see below     (default: 'low')

=head2 service_type

Accessor for the type of service ("login" or "assertion") this request is
intended for.

=head2 request_id

Accessor for the generated unique ID for this request.

=head2 entity_id

Accessor for the entity ID of the Service Provider which generated the request.

=head2 request_time

Accessor for the request creation time formatted as an ISO date/time string.

=head2 destination_url

Accessor for the URL of the Identity Provider's single signon service, to which
this request will be sent.

=head2 saml_request

Accessor for the XML document containing the SAML2 AuthenRequest.

=head2 relay_state

Accessor for the C<relay_state> parameter optionally passed to the constructor.
If not provided, no relay state will be passed to the Identity Provider.

=head2 allow_create

Accessor for the C<allow_create> parameter optionally passed to the constructor.
If not provided, this parameter will default to 'false'.

=head2 force_auth

Accessor for the C<force_auth> parameter optionally passed to the constructor.
If not provided, this parameter will default to 'true'.

=head2 auth_strength

Accessor for the C<auth_strength> parameter optionally passed to the
constructor.  If a value is provided, it will be passed to the constructor for
L<Authen::NZRealMe::LogonStrength>.  If not provided, this parameter will
default to the URN for low strength logons.

=head2 as_url

Accessor for the URL to be used in the redirect.  The URL will be constructed
from the URL of the Identity Provider's single signon service and a query
string containing the SAML2 AuthnRequest message an optional relay state
parameter and a digital signature.

=head2 encoded_saml_request

Accessor for the XML SAML AuthnRequest message after deflate compression and
MIME Base64 encoding have been applied.

=head2 dump_request

This method is used by the C<< nzrealme dump-req >> command to decode and
decompress the SAMLRequest parameter from a generated URL.  It is provided as a
diagnostic aid.


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


