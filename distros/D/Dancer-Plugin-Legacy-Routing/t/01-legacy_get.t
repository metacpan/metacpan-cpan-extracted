#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most;

use t::lib::TestApp;

use Dancer::Test;
use Dancer::Config;

subtest "Ensure legacy_get directs to correct controller" => sub {
    route_exists        [ GET => '/legacy/get' ], "GET /legacy/get is handled";
    response_content_is [ GET => '/legacy/get' ], "Testing Get",
      "got expected response content for /legacy/get";

    route_exists        [ GET => '/good/get' ], "GET /good/get is handled";
    response_content_is [ GET => '/good/get' ], "Testing Get",
      "got expected response content for /good/get";
};

subtest "Legacy Route Called Logged when Logging Enabled" => sub {
    read_logs;    # Get Rid of Anything already in the loger

    route_exists        [ GET => '/legacy/get' ], "GET /legacy/get is handled";
    response_content_is [ GET => '/legacy/get' ], "Testing Get",
      "got expected response content for /legacy/get";
    is_deeply( read_logs,
        [
            {
                level => 'info',
                message =>
                  "Legacy Route GET '/legacy/get' referred from '(none)'"
            }
        ],
        "Logged Call to Legacy Route"
    );

    route_exists        [ GET => '/good/get' ], "GET /good/get is handled";
    response_content_is [ GET => '/good/get' ], "Testing Get",
      "got expected response content for /good/get";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );
};

subtest "Legacy Route Called NOT Logged when Logging NOT Enabled" => sub {
    read_logs;    # Get Rid of Anything already in the loger
    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 0;

    route_exists        [ GET => '/legacy/get' ], "GET /legacy/get is handled";
    response_content_is [ GET => '/legacy/get' ], "Testing Get",
      "got expected response content for /legacy/get";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    route_exists        [ GET => '/good/get' ], "GET /good/get is handled";
    response_content_is [ GET => '/good/get' ], "Testing Get",
      "got expected response content for /good/get";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 1;
};

subtest "Legacy Route with URI Parameter" => sub {
    route_exists [ GET => '/legacy/get/123' ],
      "GET /legacy/get/:var is handled";
    response_content_is [ GET => '/legacy/get/123' ],
      "Testing Get, Var Value is = 123",
      "got expected response content for /legacy/get/:var";

    route_exists [ GET => '/good/get/123' ], "GET /good/get/:var is handled";
    response_content_is [ GET => '/good/get/123' ],
      "Testing Get, Var Value is = 123",
      "got expected response content for /good/get/:var";
};

subtest "Legacy Route with GET Args" => sub {
    my $legacy_response = dancer_response(
        GET => '/legacy/get/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $legacy_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $legacy_response->{content},
        'eq',
        "Testing Get, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );

    my $standard_response = dancer_response(
        GET => '/good/get/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $standard_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $standard_response->{content},
        'eq',
        "Testing Get, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );
};

done_testing;
