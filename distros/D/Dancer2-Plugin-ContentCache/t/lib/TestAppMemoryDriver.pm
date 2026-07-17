package TestAppMemoryDriver;
use Dancer2;

BEGIN {
    set logger  => 'null';
    set plugins => {
        ContentCache => {
            driver                => 'MemoryDriver',
            create_redirect_route => 0,
        },
    };
}

use Dancer2::Plugin::ContentCache;

get '/set_html' => sub {
    return set_cache( '<p>hi there</p>', {} );
};

get '/get/:uuid' => sub {
    my $cache = retrieve_cache( route_parameters->get('uuid') );
    return send_error( 'Not Found', 404 ) unless $cache;
    return $cache->data;
};

1;
