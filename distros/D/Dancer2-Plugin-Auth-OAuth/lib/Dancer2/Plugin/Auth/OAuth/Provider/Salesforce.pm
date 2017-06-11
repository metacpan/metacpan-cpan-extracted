package Dancer2::Plugin::Auth::OAuth::Provider::Salesforce;

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://login.salesforce.com/services/oauth2/authorize',
        access_token_url => 'https://login.salesforce.com/services/oauth2/token',
    },
    query_params => {
        authorize => {
            response_type => 'code',
            scope         => 'id',
        },
        access => {
            grant_type => 'authorization_code',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $session_data = $session->read('oauth');

    my $resp = $self->{ua}->request(
        GET $session_data->{salesforce}{id} . '?access_token=' .
        $session_data->{salesforce}{access_token}
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->decoded_content )
        );
        $session_data->{salesforce}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
