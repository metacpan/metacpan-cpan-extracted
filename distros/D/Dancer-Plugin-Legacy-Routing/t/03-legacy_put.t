#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most;

use t::lib::TestApp;

use Dancer::Test;
use Dancer::Config;

subtest "Ensure legacy_put directs to correct controller" => sub {
    route_exists        [ PUT => '/legacy/put' ], "PUT /legacy/put is handled";
    response_content_is [ PUT => '/legacy/put' ], "Testing Put",
      "got expected response content for /legacy/put";

    route_exists        [ PUT => '/good/put' ], "PUT /good/put is handled";
    response_content_is [ PUT => '/good/put' ], "Testing Put",
      "got expected response content for /good/put";
};

subtest "Legacy Route Called Logged when Logging Enabled" => sub {
    read_logs;    # Put Rid of Anything already in the loger

    route_exists        [ PUT => '/legacy/put' ], "PUT /legacy/put is handled";
    response_content_is [ PUT => '/legacy/put' ], "Testing Put",
      "got expected response content for /legacy/put";
    is_deeply( read_logs,
        [
            {
                level => 'info',
                message =>
                  "Legacy Route PUT '/legacy/put' referred from '(none)'"
            }
        ],
        "Logged Call to Legacy Route"
    );

    route_exists        [ PUT => '/good/put' ], "PUT /good/put is handled";
    response_content_is [ PUT => '/good/put' ], "Testing Put",
      "got expected response content for /good/put";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );
};

subtest "Legacy Route Called NOT Logged when Logging NOT Enabled" => sub {
    read_logs;    # Put Rid of Anything already in the loger
    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 0;

    route_exists        [ PUT => '/legacy/put' ], "PUT /legacy/put is handled";
    response_content_is [ PUT => '/legacy/put' ], "Testing Put",
      "got expected response content for /legacy/put";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    route_exists        [ PUT => '/good/put' ], "PUT /good/put is handled";
    response_content_is [ PUT => '/good/put' ], "Testing Put",
      "got expected response content for /good/put";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 1;
};

subtest "Legacy Route with URI Parameter" => sub {
    route_exists [ PUT => '/legacy/put/123' ],
      "PUT /legacy/put/:var is handled";
    response_content_is [ PUT => '/legacy/put/123' ],
      "Testing Put, Var Value is = 123",
      "got expected response content for /legacy/put/:var";

    route_exists [ PUT => '/good/put/123' ], "PUT /good/put/:var is handled";
    response_content_is [ PUT => '/good/put/123' ],
      "Testing Put, Var Value is = 123",
      "got expected response content for /good/put/:var";
};

subtest "Legacy Route with PUT Args" => sub {
    my $legacy_response = dancer_response(
        PUT => '/legacy/put/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $legacy_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $legacy_response->{content},
        'eq',
        "Testing Put, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );

    my $standard_response = dancer_response(
        PUT => '/good/put/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $standard_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $standard_response->{content},
        'eq',
        "Testing Put, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );
};

done_testing;
