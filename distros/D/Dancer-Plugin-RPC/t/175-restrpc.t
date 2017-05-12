#! perl -w
use strict;
use lib 't/lib';

use Test::More;

use Dancer qw/:syntax !pass/;
use Dancer::Plugin::RPC::RESTRPC;
use TestProject;
use Dancer::Test;

route_exists([POST => '/rest/system/ping'], "system/ping exsits");

{
    my $response = dancer_response(
        POST => '/rest/system/version',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    my $version = from_json($response->content);
    is_deeply(
        $version,
        {software_version => '1.0'},
        "system.version"
    );
}

{
    my $response = dancer_response(
        POST => '/rest/system/four_o_four',
        {
            headers => [
                'Content-Type' => 'application/json',
            ],
        }
    );

    is($response->status, 404, "Check endpoint");
}

{
    my $response = dancer_response(
        POST => '/rest/system/ping',
        {
            headers => [
                'Content-Type' => 'form',
            ],
        }
    );

    is($response->status, 404, "Check content-type restrpc");
}

done_testing();
