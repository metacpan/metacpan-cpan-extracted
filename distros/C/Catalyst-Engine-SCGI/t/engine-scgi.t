#!perl

use strict;
use warnings;

use Test::More tests => 2;

use_ok('Catalyst');

scgi_application_prefix: {
    my $request = Catalyst::Request->new;

    $ENV{HTTP_HOST} = "127.0.0.1";
    $ENV{SERVER_PORT} = 80;
    $ENV{SCRIPT_NAME} = '/MyApp';
    $ENV{PATH_INFO} = '/some/path';

    Catalyst->setup_engine('SCGI');
    my $c = Catalyst->new({
      request => $request,
    });
    $c->prepare_path;

    is (
        Catalyst::uri_for( $c, '/some/path' )->as_string,
        'http://127.0.0.1/MyApp/some/path',
        'uri_for creates url with correct application prefix'
    );
}
