#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;

use Data::Riak::Fast::HTTP;

my $fake_host = 'notreal';
my $fake_port = '800000';
my $fake_timeout = '4000';

$ENV{'DATA_RIAK_HTTP_HOST'} = $fake_host;
$ENV{'DATA_RIAK_HTTP_PORT'} = $fake_port;
$ENV{'DATA_RIAK_HTTP_TIMEOUT'} = $fake_timeout;

my $riak = Data::Riak::Fast::HTTP->new;

is($riak->host, $fake_host, 'ENV override for host');
is($riak->port, $fake_port, 'ENV override for port');
is($riak->timeout, $fake_timeout, 'ENV override for timeout');

done_testing;
