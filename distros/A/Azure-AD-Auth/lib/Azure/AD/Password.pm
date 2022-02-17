package Azure::AD::Password;
  use Moo;
  use Azure::AD::Errors;
  use Types::Standard qw/Str Int InstanceOf/;
  use JSON::MaybeXS;
  use HTTP::Tiny;

  our $VERSION = '0.02';

  has ua_agent => (is => 'ro', isa => Str, default => sub {
    'Azure::AD::Password ' . $Azure::AD::Password::VERSION
  });

  has ua => (is => 'rw', required => 1, lazy => 1,
    default     => sub {
      my $self = shift;
      HTTP::Tiny->new(
        agent => $self->ua_agent,
        timeout => 60,
      );
    }
  );

  has username => (is => 'ro', isa => Str, required => 1);
  has password => (is => 'ro', isa => Str, required => 1);

  has resource_id => (
    is => 'ro',
    isa => Str,
    required => 1,
  );

  has tenant_id => (
    is => 'ro',
    isa => Str,
    required => 1,
    default => sub {
      $ENV{AZURE_TENANT_ID}
    }
  );

  has client_id => (
    is => 'ro',
    isa => Str,
    required => 1,
    default => sub {
      $ENV{AZURE_CLIENT_ID}
    }
  );

  has ad_url => (
    is => 'ro',
    isa => Str,
    default => sub {
      'https://login.microsoftonline.com'
    },
  );

  has token_endpoint => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
      my $self = shift;
      sprintf "%s/%s/oauth2/token", $self->ad_url, $self->tenant_id;
    }
  );

  sub access_token {
    my $self = shift;
    $self->_refresh;
    $self->current_creds->{ access_token };
  }

  has current_creds => (is => 'rw');

  has expiration => (
    is => 'rw',
    isa => Int,
    lazy => 1,
    default => sub { 0 }
  );

  sub _refresh_from_cache {
    my $self = shift;
    #TODO: implement caching strategy
    return undef;
  }

  sub _save_to_cache {
    my $self = shift;
    #TODO: implement caching strategy
  }

  sub _refresh {
    my $self = shift;

    if (not defined $self->current_creds) {
      $self->_refresh_from_cache;
      return $self->current_creds if (defined $self->current_creds);
    }

    return if $self->expiration >= time;

    my $auth_response = $self->ua->post_form(
      $self->token_endpoint,
      {
        grant_type    => 'password',
        client_id     => $self->client_id,
        resource      => $self->resource_id,
        username      => $self->username,
        password      => $self->password,
      }
    );

    if (not $auth_response->{ success }) {
      Azure::AD::RemoteError->throw(
        message => $auth_response->{ content },
        code => 'GetClientCredentialsFailed',
        status => $auth_response->{ status }
      );
    }

    my $auth = decode_json($auth_response->{content});
    $self->current_creds($auth);
    $self->expiration($auth->{ expires_on });
    $self->_save_to_cache;
  }

1;

=encoding UTF-8

=head1 NAME

Azure::AD::Password - Azure AD Password authentication flow

=head1 SYNOPSIS

  use Azure::AD::Password;
  my $creds = Azure::AD::Password->new(
    resource_id => 'https://management.core.windows.net/',
    client_id => '',
    tenant_id => '',
    username => '',
    password => '',
  );
  say $creds->access_token;

=head1 DESCRIPTION

Implements the Azure AD Password flow. In general Microsoft does not advise 
customers to use it as it's less secure than the other flows, and it is not 
compatible with conditional access. See L<Azure::AD::Auth> for more
information and alternative flows.

=head1 ATTRIBUTES

=head2 resource_id

The URL for which you want a token extended (the URL of the service which you want
to obtain a token for).

C<https://graph.windows.net/> for using the MS Graph API

C<https://management.core.windows.net/> for using the Azure Management APIs

=head2 tenant_id

The ID of the Azure Active Directory Tenant

=head2 client_id

The Client ID (also referred to as the Application ID) of an application. In the 
case of the password flow, the application should be of type C<Native>.

=head2 username

The user name to use for authentication.

=head2 password

The password of the user.

=head2 ad_url

This defaults to C<https://login.microsoftonline.com>, and generally doesn't need to
be specified. Azure AD has more endpoints for some clouds: 

C<https://login.chinacloudapi.cn> China Cloud

C<https://login.microsoftonline.us> US Gov Cloud

C<https://login.microsoftonline.de> German Cloud

=head1 METHODS

=head2 access_token

Returns the access token that has to be sent to the APIs you want to access. This
is normally sent in the Authentication header of HTTPS requests as a Bearer token.

The access_token is cached in the object as long as it's valid, so subsequent calls
to access_token will return the appropriate token without reauthenticating to Azure AD. 
If the token has expired, access_token will call Azure AD to obtain a new token transparently.

Example usage:

  my $auth = Azure::AD::Password->new(...);

  use HTTP::Tiny;
  my $ua = HTTP::Tiny->new;
  my $response = $ua->get(
    'http://aservice.com/orders/list', 
    {
      headers => { Authorization => 'Bearer ' . $auth->access_token }
    }
  );

=head1 SEE ALSO

L<Azure::AD::Auth>

=head1 COPYRIGHT and LICENSE

Copyright (c) 2020 by Jose Luis Martinez

This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
