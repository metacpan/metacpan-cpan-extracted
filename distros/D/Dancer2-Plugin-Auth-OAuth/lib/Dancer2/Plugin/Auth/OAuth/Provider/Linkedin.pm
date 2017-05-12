package Dancer2::Plugin::Auth::OAuth::Provider::Linkedin;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    version => 2,
    urls => {
        access_token_url => "https://www.linkedin.com/oauth/v2/accessToken",
        authorize_url => "https://www.linkedin.com/oauth/v2/authorization",
        user_info => "https://api.linkedin.com/v1/people/~?format=json",
    },
    query_params => {
        authorize => {
            response_type => 'code',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');

    my $fields = '';
    if ( exists $self->provider_settings->{fields} ) {
        $fields = sprintf(":(%s)", $self->provider_settings->{fields});
        $self->provider_settings->{urls}{user_info} =~ s/~\?/~$fields?/;
    }

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info},
        Authorization => "Bearer ".$session_data->{linkedin}{access_token}
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->decoded_content )
        );
        $session_data->{linkedin}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
