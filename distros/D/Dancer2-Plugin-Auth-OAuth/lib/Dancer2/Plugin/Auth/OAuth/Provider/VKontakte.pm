package Dancer2::Plugin::Auth::OAuth::Provider::VKontakte;

# It's a rewritten 'Facebook.pm' to work with 'https://vk.com'.
# 
# To configure this add something like:
#
#     VKontakte:
#       tokens:
#         client_id: '...'
#         client_secret: '...'
#       fields: '...'
#       api_version: '5.8'
#
# to your providers configuration.

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://oauth.vk.com/authorize',
        access_token_url => 'https://oauth.vk.com/access_token',
        user_info        => 'https://api.vk.com/method/users.get',
    },
    query_params => {
        authorize => {
            response_type => 'code',
			# VKontakte sends user's email if exists with access token reply.
			# Because of this I had to modify 'Provider.pm' slightly.
			# If you want the email to be sent you must use 'email' scope.
			# Other user data should be requested with 'fields' configuration option.
            scope         => 'email',
	    display       => 'popup',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $fields = '';
    if ( exists $self->provider_settings->{fields} ) {
        $fields = "&fields=".$self->provider_settings->{fields};
    }

    my $user_id = '';
    if ( exists $session->read('oauth')->{'user_id'} ) {
        $user_id = "&user_ids=".$session->read('oauth')->{'user_id'};
    }

    my $api_version = '';
    if ( exists $self->provider_settings->{api_version} ) {
        $api_version = "&v=".$self->provider_settings->{api_version};
    }

    my $session_data = $session->read('oauth');

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info}."?access_token=".
            $session_data->{vkontakte}{access_token}.
            $fields.
			$user_id.
			$api_version
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->content )
        );
        $session_data->{vkontakte}{user_info} = $user;
        $session->write('oauth', $session_data);
    }

}

1;
