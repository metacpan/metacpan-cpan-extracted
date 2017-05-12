use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Const::Exporter

    http_ports => [
        'HTTP'     => 80,
        'HTTP_ALT' => 8080,
        'HTTPS'    => 443,
    ];

use Const::Exporter

    http_ports => [
        '@HTTP_PORTS' => [ HTTP, HTTP_ALT, HTTPS ],
    ];

is(HTTP, 80, 'HTTP');
is(HTTP_ALT, 8080, 'HTTP_ALT');
is(HTTPS, 443, 'HTTPS');

is_deeply( \@HTTP_PORTS, [ 80, 8080, 443 ], '@HTTP_PORTS');

done_testing;
