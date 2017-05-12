#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Warn;

use Data::Riak::HTTP;
use Test::Data::Riak ();

my $fake_host = 'notreal';
my $fake_port = '800000';
my $fake_timeout = '4000';

{ # deprecated defaults in Data::Riak::HTTP
    local $ENV{'DATA_RIAK_HTTP_HOST'} = $fake_host;
    local $ENV{'DATA_RIAK_HTTP_PORT'} = $fake_port;
    local $ENV{'DATA_RIAK_HTTP_TIMEOUT'} = $fake_timeout;

    my $riak;
    # FIXME: hash order dependency
    warnings_like sub {
        $riak = Data::Riak::HTTP->new;
    }, [qr/Environment variable DATA_RIAK_HTTP_HOST is deprecated/,
        qr/Environment variable DATA_RIAK_HTTP_PORT is deprecated/,
        qr/Environment variable DATA_RIAK_HTTP_TIMEOUT is deprecated/];

    is($riak->host, $fake_host, 'ENV override for host');
    is($riak->port, $fake_port, 'ENV override for port');
    is($riak->timeout, $fake_timeout, 'ENV override for timeout');
}

{ # Test::Data::Riak env based defaults
    local $ENV{'TEST_DATA_RIAK_HTTP_HOST'} = $fake_host;
    local $ENV{'TEST_DATA_RIAK_HTTP_PORT'} = $fake_port;
    local $ENV{'TEST_DATA_RIAK_HTTP_TIMEOUT'} = $fake_timeout;

    Test::Data::Riak->import({
        host    => $fake_host,
        port    => $fake_port,
        timeout => $fake_timeout,
    });

    my $riak = riak_transport()->transport;

    is($riak->host, $fake_host, 'ENV override for host');
    is($riak->port, $fake_port, 'ENV override for port');
    is($riak->timeout, $fake_timeout, 'ENV override for timeout');
}

{ # Test::Data::Riak import based defaults
    Test::Data::Riak->import({
        host    => $fake_host,
        port    => $fake_port,
        timeout => $fake_timeout,
    });

    my $riak = riak_transport()->transport;

    is($riak->host, $fake_host, 'ENV override for host');
    is($riak->port, $fake_port, 'ENV override for port');
    is($riak->timeout, $fake_timeout, 'ENV override for timeout');
}

done_testing;
