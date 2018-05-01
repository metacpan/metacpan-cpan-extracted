package Dancer2::Plugin::Auth::OAuth::Provider::Yandex;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request;
use JSON::MaybeXS;
use LWP::UserAgent;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://oauth.yandex.ru/authorize',
        access_token_url => 'https://oauth.yandex.ru/token',
        user_info        => 'https://login.yandex.ru/info',
    },
    query_params => {
        authorize => {
            response_type => 'code',
            scope         => 'login:birthday login:email login:info login:avatar',
            display       => 'popup',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');

    my $ua = LWP::UserAgent->new;
    my $req = HTTP::Request->new(GET => $self->provider_settings->{urls}{user_info});
    $req->content_type('application/x-www-form-urlencoded');
    $req->header(Authorization => 'OAuth '.$session_data->{yandex}{access_token});
    $req->content(
        "format=".$self->provider_settings->{format}.
        "&client_id=".$self->provider_settings->{tokens}{client_id}
    );

    my $resp = $ua->request($req);

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->content )
        );
        $session_data->{yandex}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
