package Dancer2::Plugin::Auth::OAuth::Provider::Odnoklassniki;

# It's a rewritten 'Facebook.pm' to work with 'https://ok.ru'.
# 
# To configure this add something like:
#
#     Odnoklassniki:
#       tokens:
#         client_id: '...'
#         client_secret: '...'
#         application_key: '...'
#       method: 'users.getCurrentUser'
#       format: 'json'
#       fields: 'email,name,gender,birthday,location,uid,pic_full'
#
# to your providers configuration.

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;
use Digest::MD5 qw/md5_hex/;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://connect.ok.ru/oauth/authorize',
        access_token_url => 'https://api.ok.ru/oauth/token.do',
        user_info        => 'https://api.ok.ru/fb.do',
    },
    query_params => {
        authorize => {
            response_type => 'code',
            scope         => 'GET_EMAIL',
        }
    }
} }

sub post_process {
    my ($self, $session) = @_;

    my $application_key = '';
    if ( exists $self->provider_settings->{tokens}{application_key} ) {
        $application_key = "application_key=".$self->provider_settings->{tokens}{application_key};
    }

    my $method = '';
    if ( exists $self->provider_settings->{method} ) {
        $method = "method=".$self->provider_settings->{method};
    }

    my $format = '';
    if ( exists $self->provider_settings->{format} ) {
        $format = "format=".$self->provider_settings->{format};
    }

    my $fields = '';
    if ( exists $self->provider_settings->{fields} ) {
        $fields = "fields=".$self->provider_settings->{fields};
    }

    my $session_data = $session->read('oauth');

	my $sig = "&sig=";
	my $secret_key = lc(md5_hex($session_data->{odnoklassniki}{access_token} . $self->provider_settings->{tokens}{client_secret}));
	
	$sig .= lc(md5_hex($application_key.$fields.$format.$method.$secret_key));

	$application_key = "?".$application_key;
	$fields = "&".$fields if $fields;
	$format = "&".$format if $format;
	$method = "&".$method if $method;

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info}.
			$application_key.
			$fields.
			$format.
			$method.
			$sig.
			"&access_token=".$session_data->{odnoklassniki}{access_token}
    );

    if( $resp->is_success ) {
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $resp->content )
        );
        $session_data->{odnoklassniki}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
}

1;
