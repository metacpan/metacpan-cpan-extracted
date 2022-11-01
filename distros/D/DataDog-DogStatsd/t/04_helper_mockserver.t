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
use DataDog::DogStatsd::Helper qw(stats_inc stats_dec stats_timing stats_gauge stats_histogram stats_event stats_timed);

DataDog::DogStatsd::Helper::set_dogstatsd my $statsd = DataDog::DogStatsd->new(port => MockServer::start());

stats_inc('test.stats');
my ($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:1|c';

# sample_rate
stats_inc('test.stats', 0.99);
foreach (1 .. 10) {
    ($msg) = MockServer::get_and_reset_messages();
    next unless $msg;
    is $msg, 'test.stats:1|c|@0.99';
    last;
}

stats_dec('test.stats');
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:-1|c';

stats_timing('test.timing', 1);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.timing:1|ms';

# sample_rate
stats_timing('connection_time', 1000, 0.99);
foreach (1 .. 10) {
    ($msg) = MockServer::get_and_reset_messages();
    next unless $msg;
    is $msg, 'connection_time:1000|ms|@0.99';
    last;
}

stats_gauge('test.gauge', 10);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.gauge:10|g';

stats_histogram('test.histogram', 100);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.histogram:100|h';

stats_event('event test', 'this is a test event');
($msg) = MockServer::get_and_reset_messages();
is $msg, '_e{10,20}:event test|this is a test event';

## test tags
stats_inc('test.stats', {tags => ['tag1', 'tag2']});
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:1|c|#tag1,tag2';

stats_dec('test.stats', {tags => ['tag1', 'tag2']});
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.stats:-1|c|#tag1,tag2';

stats_timing('test.timing', 1, {tags => ['tag1', 'tag2']});
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.timing:1|ms|#tag1,tag2';

stats_gauge('test.gauge', 10, {tags => ['tag1', 'tag2']});
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test.gauge:10|g|#tag1,tag2';

## test namespace
$statsd->namespace('test2.');
stats_inc('stats');
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.stats:1|c';

stats_dec('stats');
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.stats:-1|c';

stats_timing('timing', 1);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.timing:1|ms';

stats_gauge('gauge', 10);
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.gauge:10|g';

my $ret = stats_timed {    # scalar context: the commas below act as the comma operator
    Time::HiRes::sleep shift;
    19, 20, 21;
}
timed => {tags => ['tag1:1', 'tag2:2']},
    0.1;
($msg) = MockServer::get_and_reset_messages();
like $msg, qr/test2.timed:\d+\|ms\|#tag1:1,tag2:2/, $msg;
is $ret, 21;

($ret) = stats_timed {    # list context: the commas form a list
    Time::HiRes::sleep shift;
    19, 20, 21;
}
timed => {tags => ['tag1:1', 'tag2:2']},
    0.1;
($msg) = MockServer::get_and_reset_messages();
is $ret, 19;

undef $@;
eval {
    stats_timed {
        die "msg\n";
    }
    timed => {tags => ['tag1:1', 'tag2:2']},
        0.1;
};
is $@, "msg\n";
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.timed.failure:1|c|#tag1:1,tag2:2';

undef $@;
eval {
    stats_timed {
        die [1, 2, 3, 4];
    }
    timed => {tags => ['tag1:1', 'tag2:2']},
        0.1;
};
is_deeply $@, [1, 2, 3, 4];
($msg) = MockServer::get_and_reset_messages();
is $msg, 'test2.timed.failure:1|c|#tag1:1,tag2:2';

done_testing;
