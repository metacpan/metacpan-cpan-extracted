#!/usr/bin/env perl

use strict;
use warnings;

my $dirname;

BEGIN {
    use File::Spec;
    use File::Basename;
    $dirname = dirname(File::Spec->rel2abs(__FILE__));
}

use lib $dirname;
use MockServer;

use Test::More;
use DataDog::DogStatsd;

my $PORT = MockServer::start();

my $statsd = DataDog::DogStatsd->new(port => $PORT);

$statsd->increment( 'test.stats' );
my ($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:1|c';

$statsd->decrement( 'test.stats' );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:-1|c';

$statsd->timing('test.timing', 1);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.timing:1|ms';

$statsd->gauge('test.gauge', 10);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.gauge:10|g';

## test tags
$statsd->increment( 'test.stats', { tags => ['tag1', 'tag2'] } );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:1|c|#tag1,tag2';

$statsd->decrement( 'test.stats', { tags => ['tag1', 'tag2'] } );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:-1|c|#tag1,tag2';

$statsd->timing( 'test.timing', 1, { tags => ['tag1', 'tag2'] } );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.timing:1|ms|#tag1,tag2';

$statsd->gauge('test.gauge', 10, { tags => ['tag1', 'tag2'] } );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.gauge:10|g|#tag1,tag2';

## test namespace
$statsd->namespace('test2.');
$statsd->increment( 'stats' );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.stats:1|c';

$statsd->decrement( 'stats' );
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.stats:-1|c';

$statsd->timing('timing', 1);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.timing:1|ms';

$statsd->gauge('gauge', 10);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.gauge:10|g';

done_testing;
