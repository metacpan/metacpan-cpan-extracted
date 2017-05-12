#!/usr/bin/env perl

use strict;
use warnings;

use Data::Dumper;
use Test::Most;

use t::lib::TestApp;

use Dancer::Test;
use Dancer::Config;

subtest "Ensure legacy_post directs to correct controller" => sub {
    route_exists [ POST => '/legacy/post' ], "POST /legacy/post is handled";
    response_content_is [ POST => '/legacy/post' ], "Testing Post",
      "got expected response content for /legacy/post";

    route_exists        [ POST => '/good/post' ], "POST /good/post is handled";
    response_content_is [ POST => '/good/post' ], "Testing Post",
      "got expected response content for /good/post";
};

subtest "Legacy Route Called Logged when Logging Enabled" => sub {
    read_logs;    # Post Rid of Anything already in the loger

    route_exists [ POST => '/legacy/post' ], "POST /legacy/post is handled";
    response_content_is [ POST => '/legacy/post' ], "Testing Post",
      "got expected response content for /legacy/post";
    is_deeply( read_logs,
        [
            {
                level => 'info',
                message =>
                  "Legacy Route POST '/legacy/post' referred from '(none)'"
            }
        ],
        "Logged Call to Legacy Route"
    );

    route_exists        [ POST => '/good/post' ], "POST /good/post is handled";
    response_content_is [ POST => '/good/post' ], "Testing Post",
      "got expected response content for /good/post";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );
};

subtest "Legacy Route Called NOT Logged when Logging NOT Enabled" => sub {
    read_logs;    # Post Rid of Anything already in the loger
    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 0;

    route_exists [ POST => '/legacy/post' ], "POST /legacy/post is handled";
    response_content_is [ POST => '/legacy/post' ], "Testing Post",
      "got expected response content for /legacy/post";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    route_exists        [ POST => '/good/post' ], "POST /good/post is handled";
    response_content_is [ POST => '/good/post' ], "Testing Post",
      "got expected response content for /good/post";
    is_deeply( read_logs, [], "No Additional Log Entries Generated" );

    Dancer::Config::setting('plugins')->{'Legacy::Routing'}->{'log'} = 1;
};

subtest "Legacy Route with URI Parameter" => sub {
    route_exists [ POST => '/legacy/post/123' ],
      "POST /legacy/post/:var is handled";
    response_content_is [ POST => '/legacy/post/123' ],
      "Testing Post, Var Value is = 123",
      "got expected response content for /legacy/post/:var";

    route_exists [ POST => '/good/post/123' ],
      "POST /good/post/:var is handled";
    response_content_is [ POST => '/good/post/123' ],
      "Testing Post, Var Value is = 123",
      "got expected response content for /good/post/:var";
};

subtest "Legacy Route with POST Args" => sub {
    my $legacy_response = dancer_response(
        POST => '/legacy/post/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $legacy_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $legacy_response->{content},
        'eq',
        "Testing Post, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );

    my $standard_response = dancer_response(
        POST => '/good/post/123/params',
        {
            params => { var1 => 123, var2 => 456 }
        }
    );

    cmp_ok( $standard_response->{status}, '==', 200, "200 Response" );
    cmp_ok(
        $standard_response->{content},
        'eq',
        "Testing Post, Var1 Value is = 123 Var2 Value is = 456",
        "Properly Processed Parameters"
    );
};

done_testing;
