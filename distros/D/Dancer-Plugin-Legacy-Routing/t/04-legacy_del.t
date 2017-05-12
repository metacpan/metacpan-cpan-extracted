#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most;

use t::lib::TestApp;

use Dancer::Test;
use Dancer::Config;

subtest "Ensure legacy_del directs to correct controller" => sub {
    route_exists [ DELETE => '/legacy/delete' ],
      "DELETE /legacy/delete is handled";
    response_content_is [ DELETE => '/legacy/delete' ], "Testing Delete",
      "got expected response content for /legacy/delete";

    route_exists [ DELETE => '/good/delete' ], "DELETE /good/delete is handled";
    response_content_is [ DELETE => '/good/delete' ], "Testing Delete",
      "got expected response content for /good/delete";
};

subtest "Legacy Route Called Logged when Logging Enabled" => sub {
    read_logs;    # Delete Rid of Anything already in the loger

    route_exists [ DELETE => '/legacy/delete' ],
      "DELETE /legacy/delete is handled";
    response_content_is [ DELETE => '/legacy/delete' ], "Testing Delete",
      "got expected response content for /legacy/delete";
    is_deeply( read_logs,
        [
            {
                level => 'info',
                message =>
                  "Legacy Route DELETE '/legacy/delete' referred from '(none)'"
            }
        ],
        "Logged Call to Legacy Route"
    );

    route_exists [ DELETE => '/good/delete' ], "DELETE /good/delete is handled";
    response_content_is [ DELETE => '/good/delete' ], "Testing Delete",
      "got expected response content for /good/delete";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );
};

subtest "Legacy Route Called NOT Logged when Logging NOT Enabled" => sub {
    read_logs;    # Delete Rid of Anything already in the loger
    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 0;

    route_exists [ DELETE => '/legacy/delete' ],
      "DELETE /legacy/delete is handled";
    response_content_is [ DELETE => '/legacy/delete' ], "Testing Delete",
      "got expected response content for /legacy/delete";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    route_exists [ DELETE => '/good/delete' ], "DELETE /good/delete is handled";
    response_content_is [ DELETE => '/good/delete' ], "Testing Delete",
      "got expected response content for /good/delete";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 1;
};

subtest "Legacy Route with URI Parameter" => sub {
    route_exists [ DELETE => '/legacy/delete/123' ],
      "DELETE /legacy/delete/:var is handled";
    response_content_is [ DELETE => '/legacy/delete/123' ],
      "Testing Delete, Var Value is = 123",
      "got expected response content for /legacy/delete/:var";

    route_exists [ DELETE => '/good/delete/123' ],
      "DELETE /good/delete/:var is handled";
    response_content_is [ DELETE => '/good/delete/123' ],
      "Testing Delete, Var Value is = 123",
      "got expected response content for /good/delete/:var";
};

subtest "Legacy Route with DELETE Args" => sub {
    my $legacy_response = dancer_response(
        DELETE => '/legacy/delete/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $legacy_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $legacy_response->{content},
        'eq',
        "Testing Delete, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );

    my $standard_response = dancer_response(
        DELETE => '/good/delete/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $standard_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $standard_response->{content},
        'eq',
        "Testing Delete, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );
};

done_testing;
