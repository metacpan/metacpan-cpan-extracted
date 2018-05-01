package Dancer2::Plugin::Auth::OAuth::Provider::MailRU;

# https://mail.ru provider

use strict;
use parent 'Dancer2::Plugin::Auth::OAuth::Provider';

use HTTP::Request::Common;
use Digest::MD5 qw/md5_hex/;

sub config { {
    version => 2,
    urls => {
        authorize_url    => 'https://connect.mail.ru/oauth/authorize',
        access_token_url => 'https://connect.mail.ru/oauth/token',
        user_info        => 'https://www.appsmail.ru/platform/api',
    },
    query_params => {
        authorize => {
            response_type => 'code',
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

    my $params = {
        app_id => $self->provider_settings->{tokens}{client_id},
        secure => $self->provider_settings->{secure},
        session_key => $session_data->{mailru}{access_token},
        method => $self->provider_settings->{method},
        format => $self->provider_settings->{format},
    };

    my $secret = $self->provider_settings->{tokens}{client_secret};

    my $resp = $self->{ua}->request(
        GET $self->provider_settings->{urls}{user_info}."?".getSig($params, $secret)
    );

    if( $resp->is_success ) {
        (my $res = $resp->content) =~ s/(^\[|\]$)//g;
        my $user = $self->_stringify_json_booleans(
            JSON::MaybeXS::decode_json( $res )
        );
        $session_data->{mailru}{user_info} = $user;
        $session->write('oauth', $session_data);
    }
};

sub getSig {
    my $par = shift;
    my $sec = shift;

    my $pp;
    my $rp;
    foreach my $k (sort keys %{$par}) {
        $pp .= $k."=".$par->{$k};
        $rp .= $k."=".$par->{$k}."&";
    }

    return $rp."sig=".md5_hex($pp.$sec);
};

1;
