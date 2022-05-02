package Dancer2::Plugin::Auth::OAuth::Provider::Github;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    urls => {
        access_token_url => "https://github.com/login/oauth/access_token",
        authorize_url => "https://github.com/login/oauth/authorize",
        user_info => "https://api.github.com/user",
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info},
        'Authorization' => 'token '.$session_data->{github}{access_token}
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->content )
        );
        $session_data->{github}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
