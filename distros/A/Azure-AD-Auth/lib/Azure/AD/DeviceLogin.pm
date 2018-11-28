package Azure::AD::DeviceLogin;
  use Moo;
  use Azure::AD::Errors;
  use Types::Standard qw/Str Int InstanceOf CodeRef/;
  use JSON::MaybeXS;
  use HTTP::Tiny;

  our $VERSION = '0.02';

  has ua_agent => (is => 'ro', isa => Str, default => sub {
    'Azure::AD::DeviceLogin ' . $Azure::AD::DeviceLogin::VERSION
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

  has resource_id => (
    is => 'ro',
    isa => Str,
    required => 1,
  );

  has message_handler => (
    is => 'ro',
    isa => CodeRef,
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

  has device_endpoint => (
    is => 'ro',
    isa => Str,
    lazy => 1,
    default => sub {
      my $self = shift;
      sprintf '%s/%s/oauth2/devicecode', $self->ad_url, $self->tenant_id;
    }
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

  sub get_device_payload {
    my $self = shift;
    my $device_response = $self->ua->post_form(
      $self->device_endpoint,
      {
        client_id => $self->client_id,
        resource  => $self->resource_id,
      }
    );

    if (not $device_response->{ success }) {
      Azure::AD::RemoteError->throw(
        message => $device_response->{ content },
        code => 'GetDeviceCodeFailed',
        status => $device_response->{ status }
      );
    }

    return decode_json($device_response->{ content });
  }

  sub get_auth_payload_for {
    my ($self, $device_payload) = @_;

    my $code_expiration = time + $device_payload->{ expires_in };
    my $auth_response;
    while ($code_expiration > time and not $auth_response->{ success }) {
      sleep($device_payload->{ interval });

      $auth_response = $self->ua->post_form(
        $self->token_endpoint,
        {
          grant_type => 'device_code',
          code       => $device_payload->{ device_code },
          client_id  => $self->client_id,
          resource   => $self->resource_id,
        }
      );
    }
 
    if (not $auth_response->{ success }) {
      Azure::AD::RemoteError->throw(
        message => $auth_response->{ content },
        code => 'GetAuthTokenFailed',
        status => $auth_response->{ status }
      );
    }

    return decode_json($auth_response->{content});
  }

  sub _refresh {
    my $self = shift;

    if (not defined $self->current_creds) {
      $self->_refresh_from_cache;
      return $self->current_creds if (defined $self->current_creds);
    }

    return if $self->expiration >= time;

    my $device_payload = $self->get_device_payload;

    $self->message_handler->($device_payload->{ message });

    my $auth = $self->get_auth_payload_for($device_payload);

    $self->current_creds($auth);
    $self->expiration($auth->{ expires_on });
    $self->_save_to_cache;
  }

1;

=encoding UTF-8

=head1 NAME

Azure::AD::DeviceLogin - Azure AD Device Login authentication flow

=head1 SYNOPSIS

  use Azure::AD::DeviceLogin;
  my $creds = Azure::AD::ClientCredentials->new(
    resource_id => 'https://management.core.windows.net/',
    message_handler => sub { say $_[0] },
    client_id => '',
    tenant_id => '',
  );
  say $creds->access_token;

=head1 DESCRIPTION

Implements the Azure AD Device Login flow. See L<Azure::AD::Auth> for more
information and alternative flows.

=head1 ATTRIBUTES

=head2 resource_id

The URL for which you want a token extended (the URL of the service which you want
to obtain a token for).

C<https://graph.windows.net/> for using the MS Graph API

C<https://management.core.windows.net/> for using the Azure Management APIs

=head2 message_handler

Callback that receives the message for the user as it's first argument. This callback 
should transmit the message to the end user, who has to follow the instructions embedded
in it.

=head2 tenant_id

The ID of the Azure Active Directory Tenant

=head2 client_id

The Client ID (also referred to as the Application ID) of an application

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

The call to access_token will start the Device Login flow, which involves transmitting
a message to the user (see message_handler attribute). The user will have to visit a 
URL with a browser, insert the code in the message, authorize the application, and then 
the authentication will proceed. Meanwhile the call to access_code will be blocked,
awaiting the user to complete the flow. Once the user completes the instructions the access_code
will be returned.

The access_token is cached in the object as long as it's valid, so subsequent calls
to access_token will return the appropiate token without reauthenticating to Azure AD. 
If the token has expired, access_token will call Azure AD to obtain a new token.

Example usage:

  my $auth = Azure::AD::DeviceLogin->new(...);

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

Copyright (c) 2018 by CAPSiDE
This code is distributed under the Apache 2 License. The full text of the 
license can be found in the LICENSE file included with this module.

=cut
