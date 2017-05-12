#!perl

use strict;
use warnings;

use Mojolicious::Lite;
use Mojo::JSON;

$ENV{MOJO_LOG_LEVEL} = 'debug';

plugin 'OAuth2::Server' => {
    access_token_ttl   => 21600,
    authorize_route    => '/',
    access_token_route => '/oauth2/token',
    jwt_secret         => "ThisIsMyMondoJWTSecret",
    clients            => {
        test_client => {
            client_secret => 'test_client_secret',
            scopes        => {},
        },
    },
    users => {
        leejo => "Weeeee",
    }
};

group {

    # all routes must have an access token
    under '/' => sub {
        my ( $c ) = @_;
        return 1 if $c->oauth;
        $c->render( status => 401, text => 'Unauthorized' );
        return undef;
    };

    post '/ping/whoami' => sub {
        my ( $c ) = @_;

        $c->render( json => {
            authenticated => Mojo::JSON::true,
            client_id     => $c->oauth->{client},
            user_id       => $c->oauth->{user_id},
        } );

    };

    get '/accounts' => sub {
        my ( $c ) = @_;

        $c->render( json => {
            accounts => [
                {
                    id          => "acc_00009237aqC8c5umZmrRdh",
                    description => "Peter Pan's Account",
                    created     => "2015-11-13T12:17:42Z",
                },
            ],
        } );
    };

    get '/balance' => sub {
        my ( $c ) = @_;

        my $account_id = $c->param( 'account_id' )
            || return $c->render( status => 400, text => "account_id required" );

        $c->render( json => {
            balance     => 5000,
            currency    => "GBP",
            spend_today => 0,
        } );
    };

    get '/transactions/:transaction_id' => sub {
        my ( $c ) = @_;

        my $tid = $c->param( 'transaction_id' );

        $c->render( json => {
            "transaction" => _transactions( $c->param( 'expand[]' ) )->[1],
        } );
    };

    patch '/transactions/:transaction_id' => sub {
        my ( $c ) = @_;

        my $tid = $c->param( 'transaction_id' );

        my $metadata = _convert_map_params_to_hash( $c,'metadata' );

        $c->render( json => {
            "transaction" => _transactions( undef,$metadata )->[$tid - 1],
        } );
    };

    get '/transactions' => sub {
        my ( $c ) = @_;

        my $account_id = $c->param( 'account_id' )
            || return $c->render( status => 400, text => "account_id required" );

        $c->render( json => {
            "transactions" => _transactions(),
        } );
    };

    post '/feed' => sub {
        my ( $c ) = @_;

        my $account_id = $c->param( 'account_id' )
            || return $c->render( status => 400, text => "account_id required" );

        my $type = $c->param( 'type' )
            || return $c->render( status => 400, text => "type required" );

        my $params = _convert_map_params_to_hash( $c,'params' )
            || return $c->render( status => 400, text => "params required" );

        foreach my $required_param ( qw/ title image_url / ) {
            defined $params->{$required_param} 
                || return $c->render( status => 400, text => "params[$required_param] required" );
        }

        # no-op at present
        $c->render( json => {} );
    };

    post '/webhooks' => sub {
        my ( $c ) = @_;

        my $account_id = $c->param( 'account_id' )
            || return $c->render( status => 400, text => "account_id required" );

        my $url = $c->param( 'url' )
            || return $c->render( status => 400, text => "url required" );

        $c->render( json => {
            webhook => {
                account_id => $account_id,
                url        => $url,
                id         => time,
            }
        } );
    };

    get '/webhooks' => sub {
        my ( $c ) = @_;

        my $account_id = $c->param( 'account_id' )
            || return $c->render( status => 400, text => "account_id required" );

        $c->render( json => {
            webhooks => _webhooks( $account_id ),
        } );
    };

    del '/webhooks/:webhook_id' => sub {
        shift->render( json => {} );
    };

    post '/attachment/upload' => sub {
        my ( $c ) = @_;

        my $file_name = $c->param( 'file_name' )
            || return $c->render( status => 400, text => "file_name required" );

        my $file_type = $c->param( 'file_type' )
            || return $c->render( status => 400, text => "file_type required" );

        my $url = $c->req->url;

        my $entity_id = "user_00009237hliZellUicKuG1";
        $c->render( json => {
            "file_url" => $url->base . "/file/$entity_id/LcCu4ogv1xW28OCcvOTL-foo.png",
            "upload_url" => $url->base . "/upload/$entity_id/LcCu4ogv1xW28OCcvOTL-foo.png?AWSAccessKeyId=AKIAIR3IFH6UCTCXB5PQ\u0026Expires=1447353431\u0026Signature=k2QeDCCQQHaZeynzYKckejqXRGU%!D(MISSING)"
        } );
    };

    post '/attachment/register' => sub {
        my ( $c ) = @_;

        my $external_id = $c->param( 'external_id' )
            || return $c->render( status => 400, text => "external_id required" );

        my $file_url = $c->param( 'file_url' )
            || return $c->render( status => 400, text => "file_url required" );

        my $file_type = $c->param( 'file_type' )
            || return $c->render( status => 400, text => "file_type required" );

        $c->render( json => {
            "attachment" => {
                "id" => "attach_00009238aOAIvVqfb9LrZh",
                "user_id" => "user_00009238aMBIIrS5Rdncq9",
                "external_id" => $external_id,
                "file_url" => $file_url,
                "file_type" => $file_type,
                "created" => "2015-11-12T18:37:02Z"
            }
        } );
    };

    post '/attachment/deregister' => sub {
        my ( $c ) = @_;

        my $id = $c->param( 'id' )
            || return $c->render( status => 400, text => "id required" );

        $c->render( json => {} );
    }
};

# convenience methods for file upload emulation, these endpoints
# do not exist in the Mondo API, they are here to fake uploads
get '/file/:entity_id/:file_name' => sub {
    my ( $c ) = @_;

    $c->render( text => "OK" );
};

post '/upload/:entity_id/:file_name' => sub {
    my ( $c ) = @_;

    $c->render( text => "OK" );
};

sub _convert_map_params_to_hash {
    my ( $c,$prefix ) = @_;

    # converts { params[foo] => bar } to { foo => bar }
    # (this is horrible! why not just send JSON in the request body?)

    my $params = $c->req->params->to_hash;

    my %extracted_params =
        map { my $v = $params->{$_}; s/^$prefix\[//g; chop; $_ => $v }
        grep { /^$prefix\[[^\[]+\]$/ } keys %{ $params // {} };

    return \%extracted_params;
}

sub _transactions {
    my ( $expand,$metadata ) = @_;

    $expand   //= 'none';
    $metadata //= {
        stuff      => 'yes',
        more_stuff => 'yep',
    };

    my $attachment = {
        "created" => "2016-04-23T12:46:41Z",
        "external_id" => "tx_0000...",
        "file_type" => "image/jpeg",
        "file_url" => "https://...",
        "id" => "attach_0000...",
        "type" => "image/jpeg",
        "url" => "https://...",
        "user_id" => "user_0000..."
    };

    return [
        {
            "currency" => "GBP",
            "merchant" => undef,
            "counterparty" => {},
            "local_amount" => 10000,
            "id" => "1",
            "created" => "2016-04-22T12:35:55.563Z",
            "is_load" => Mojo::JSON::true,
            "updated" => "2016-04-28T20:15:35.043Z",
            "notes" => "",
            "dedupe_id" => "5529515640563",
            "description" => "Initial top up",
            "attachments" => [],
            "metadata" => $metadata,
            "account_balance" => 10000,
            "originator" => Mojo::JSON::false,
            "scheme" => "gps_mastercard",
            "amount" => 10000,
            "settled" => "2016-04-22T12:35:55.563Z",
            "account_id" => "acc_0000000000000000000001",
            "local_currency" => "GBP",
            "category" => "mondo"
        },
        {
            "amount" => -1433,
            "settled" => "2016-04-24T23:00:00.5Z",
            "originator" => Mojo::JSON::false,
            "account_balance" => 8565,
            "scheme" => "gps_mastercard",
            "category" => "cash",
            "account_id" => "acc_0000000000000000000001",
            "local_currency" => "CHF",
            "id" => "2",
            "created" => "2016-04-23T09:22:44.12Z",
            "currency" => "GBP",
            "counterparty" => {},
            "merchant" => $expand eq 'merchant'
                ? _merchant()
                : "merch_0000000000000000000001",
            "local_amount" => -2000,
            "description" => "BCV VILLARS/OLL. 2     Villars-sur-O CHE",
            "dedupe_id" => "565726953219015109",
            "attachments" => [ $attachment,$attachment ],
            "metadata" => $metadata,
            "is_load" => Mojo::JSON::false,
            "updated" => "2016-04-25T09:50:56.605Z",
            "notes" => ""
        },
    ];
}

sub _merchant {

    return {
        "merchant" => {
            "emoji" => "💵",
            "updated" => "2016-04-23T09:22:45.005Z",
            "online" => Mojo::JSON::false,
            "category" => "cash",
            "metadata" => {
                "suggested_tags" => "#money #ATM #cashpoint #cash ",
                "google_places_id" => "ChIJzXdG2omVjkcRqXc-9o1QxZI",
                "foursquare_category" => "ATM",
                "foursquare_id" => "",
                "foursquare_website" => "",
                "suggested_name" => "Caixa 24 Horas",
                "foursquare_category_icon" => "https://ss3.4sqi.net/img/categories_v2/shops/financial_88.png",
                "google_places_icon" => "https://maps.gstatic.com/mapfiles/place_api/icons/bank_dollar-71.png",
                "google_places_name" => "UBS",
                "created_for_merchant" => "merch_0000000000000000000001",
                "created_for_transaction" => "1",
                "twitter_id" => "",
                "website" => ""
            },
            "disable_feedback" => Mojo::JSON::false,
            "atm" => Mojo::JSON::true,
            "logo" => "",
            "group_id" => "grp_0000000000000000000001",
            "id" => "merch_0000000000000000000001",
            "name" => "ATM",
            "created" => "2016-04-23T09:22:45.005Z",
            "address" => {
                "country" => "CHE",
                "city" => "Villars-sur-o",
                "longitude" => 7.076864,
                "address" => "",
                "region" => "",
                "formatted" => "Villars-sur-o, 1884, Switzerland",
                "latitude" => 46.3118929,
                "approximate" => Mojo::JSON::false,
                "zoom_level" => 17,
                "short_formatted" => "Villars-sur-o, 1884, Switzerland",
                "postcode" => "1884"
            }
        },
    };
}

sub _webhooks {
    my ( $account_id ) = @_;

    $account_id //= "acc_000091yf79yMwNaZHhHGzp";

    return [
        {
            "account_id" => $account_id,
            "id" => "webhook_000091yhhOmrXQaVZ1Irsv",
            "url" => "http://example.com/callback"
        },
        {
            "account_id" => $account_id,
            "id" => "webhook_000091yhhzvJSxLYGAceC9",
            "url" => "http://example2.com/anothercallback"
        },
    ];
}

app->start;

# vim: ts=4:sw=4:et
