package Dancer2::Plugin::Auth::OAuth::Provider::Twitter;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    version => '1.001', # 1.0a
    urls    => {
        access_token_url  => 'https://api.twitter.com/oauth/access_token',
        authorize_url     => 'https://api.twitter.com/oauth/authenticate',
        request_token_url => 'https://api.twitter.com/oauth/request_token',
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');

    my $request = Net::OAuth->request("protected resource")->new(
        $self->_default_args_v1,
        token           => $session_data->{twitter}{access_token},
        token_secret    => $session_data->{twitter}{access_token_secret},
        request_method  => 'GET',
        request_url     => 'https://api.twitter.com/1.1/account/verify_credentials.json',
    );
    $request->sign;

    my $resp = $self->ua->request(GET $request->to_url);
    if ($resp->is_success) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->decoded_content )
        );
        $session_data->{twitter}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
