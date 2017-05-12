package Dancer2::Plugin::Auth::OAuth::Provider::Google;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://accounts.google.com/o/oauth2/auth',
        access_token_url => 'https://accounts.google.com/o/oauth2/token',
        user_info        => 'https://www.googleapis.com/oauth2/v2/userinfo',
    },
    query_params => {
        authorize => {
            response_type => 'code',
            scope         => 'openid email',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info},
        Authorization => "Bearer ".$session_data->{google}{access_token}
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->decoded_content )
        );
        $session_data->{google}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
