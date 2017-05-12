package Dancer2::Plugin::Auth::OAuth::Provider::Stackexchange;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    urls => {
        access_token_url => "https://stackexchange.com/oauth/access_token",
        authorize_url => "https://stackexchange.com/oauth",
        user_info => "https://api.stackexchange.com/2.2/me",
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');
    my $provider_settings = $self->provider_settings;

    my $resp = $self->{ua}->request(
        GET $provider_settings->{urls}{user_info}.
            "?access_token=".$session_data->{stackexchange}{access_token}.
            "&site=".$provider_settings->{site}.
            "&key=".$provider_settings->{tokens}{key}
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->decoded_content )
        );
        $session_data->{stackexchange}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
