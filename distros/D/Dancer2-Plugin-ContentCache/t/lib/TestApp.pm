package TestApp;
use Dancer2;

# Dancer2 core already provides encode_json/decode_json DSL keywords.

BEGIN {
    set logger => 'null';
    set plugins => {
        'DBIx::Class' => {
            default => {
                schema_class => 'TestSchema',
                dsn          => 'dbi:SQLite:dbname=:memory:',
            },
        },
        ContentCache => {
            cache_result_set => 'ContentCache',
        },
    };
}

use Dancer2::Plugin::DBIx::Class;
use Dancer2::Plugin::ContentCache;

schema->deploy;

get '/set_html' => sub {
    return set_cache( '<p>hi there</p>', {} );
};

get '/set_json' => sub {
    return set_cache( { foo => 'bar' }, {} );
};

get '/set_short_life' => sub {
    return set_cache( 'gone soon', { life => 1 } );
};

get '/get/:uuid' => sub {
    my $cache = retrieve_cache( route_parameters->get('uuid') );
    return send_error( 'Not Found', 404 ) unless $cache;

    response_header 'X-Cache-Format' => $cache->data_format;
    response_header 'X-Cache-Life'   => $cache->metadata->{life} // '';

    return $cache->data_format eq 'JSON' ? encode_json( $cache->data ) : $cache->data;
};

get '/send_html' => sub {
    return cache_and_send( '<p>sent</p>', {} );
};

get '/send_json' => sub {
    return cache_and_send( { sent => 1 }, {} );
};

get '/redirect_html' => sub {
    return cache_and_redirect( '<p>redirected</p>', {} );
};

get '/cleanup' => sub {
    return clean_up_cache();
};

1;
