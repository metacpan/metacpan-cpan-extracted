package Dancer2::Plugin::Auth::OAuth::Provider::Facebook;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://www.facebook.com/dialog/oauth',
        access_token_url => 'https://graph.facebook.com/oauth/access_token',
        user_info        => 'https://graph.facebook.com/me',
    },
    query_params => {
        authorize => {
            response_type => 'code',
            scope         => 'email,public_profile,user_friends',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $fields = '';
    if ( exists $self->provider_settings->{fields} ) {
        $fields = "&fields=".$self->provider_settings->{fields};
    }

    my $session_data = $session->read('oauth');

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info}."?access_token=".
            $session_data->{facebook}{access_token}.
            $fields
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->content )
        );
        $session_data->{facebook}{user_info} = $user;
        $session->write('oauth', $session_data);
    }

}

1;
