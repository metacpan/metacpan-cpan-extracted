package Dancer2::Plugin::Auth::OAuth::Provider::AzureAD;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;
use MIME::Base64;

sub config { {
    version => 2,
    urls => {
      authorize_url    => "https://login.microsoftonline.com/common/oauth2/authorize",
      access_token_url => "https://login.microsoftonline.com/common/oauth2/token",
      user_info        => "https://graph.microsoft.com/v1.0/me/"
    },
    query_params => {
      authorize => {
        response_type => 'code',
        response_mode => 'query',
        scope         => 'User.Read',
        resource      => 'https://graph.microsoft.com/',
      }
    }
} }

sub post_process {
  my ($self, $session) = @_;

  my $session_data = $session->read('oauth');

  my @seg = split(/\./, $session_data->{azuread}{id_token});
  if ($seg[1]) {
    my $dec = decode_base64($seg[1]);
    if ($dec) {
      eval {
        $session_data->{azuread}{login_info} = $self->_stringify_json_booleans(
          JSON::MaybeXS::decode_json( $dec )
        );
      };
      if($@) {
        # JSON parse error
      }
    }
  }

  if ($self->provider_settings->{urls}{user_info}) {
    my $resp = $self->{ua}->request(
      GET $self->provider_settings->{urls}{user_info},
      Authorization => "Bearer ".$session_data->{azuread}{access_token},
      Accept => "application/json"
    );

    if ( $resp->is_success ) {
      my $user = $self->_stringify_json_booleans(
        JSON::MaybeXS::decode_json( $resp->decoded_content )
      );
      $session_data->{azuread}{user_info} = $user;
    } else {
      # To-Do: logging error
    }
  }
  $session->write('oauth', $session_data);
  return 1;
}

1;
__END__

=encoding utf-8

=head1 NAME

Dancer2::Plugin::Auth::OAuth::Provider::AzureAD - Provider for Microsoft/AzureAD

=head1 SYNOPSIS

View the documentation for Dancer2::Plugin::Auth::OAuth

Default values; change these in your YML config if needed:

  plugins:
    "Auth::OAuth":
      providers:
        AzureAD:
          urls:
            authorize_url: "https://login.microsoftonline.com/common/oauth2/authorize"
            access_token_url: "https://login.microsoftonline.com/common/oauth2/token"
            user_info: "https://graph.microsoft.com/v1.0/me/"
          tokens:
            client_id: your_client_id
            client_secret: your_client_secret
          query_params:
            authorize:
              scope: 'User.Read',
              resource: 'https://graph.microsoft.com/',

=head1 DESCRIPTION

Generic provider for Microsoft OAuth2.

Note that you will undoubtably need to change some or all of the options above.

After login, the following session key will have contents: C<{oauth}{azuread}>

The token will probably be in C<{id_token}>

When log in has occured, the provider attempts to decode the resulting token
for information about the user. All of the decoded information can be found in
the session key: C<{oauth}{azuread}{login_info}>

The login email address, for example, will probably be in a key called
C<{unique_name}>

If the user_info option is defined (which it is by default!), a corresponding
call is made to that URL to find out more information about the user. This is
stashed in the session key C<{oauth}{azuread}{user_info}>

=head1 ADDING TENANT ID

If you need to add a tenant ID to your calls, this should be done by replacing
"common" in the authorize_url and access_token_url.

=head2 PREVENTING USER LOOKUP WITH GRAPH

By default this provider requests scope and resource to perform a request on
Microsoft's Graph API to return the logged in user details. This is not strictly
necessary, as part of the token returned on authentication is the email address
used to log in.

To prevent this lookup, set "user_info" to a blank string.

=head1 AUTHOR

Pero Moretti E<lt>pero@cpan.orgE<gt>

=head1 COPYRIGHT

Copyright 2022- Pero Moretti

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
