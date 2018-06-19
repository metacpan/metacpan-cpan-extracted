#XXX this test is plagued by a *horrific* perl bug, the dread 'Use of uninitialized value in null operation' during die()
#use strict;
#use warnings;

use Test::More tests => 6;
use Test::Fatal;
use App::Prove::Elasticsearch::Queue::Rabbit;
use Capture::Tiny qw{capture_merged};

use POSIX;
#XXX can't do closures because of the insane bug I'm working around

# new

local *App::Prove::Elasticsearch::Queue::Default::new   = sub { my ($class,$conf) = @_; return bless({config => $conf}, $class) };
local *Net::RabbitMQ::new                               = sub { return bless({},shift) };
local *Net::RabbitMQ::connect                           = sub {};

my $out = '';
SKIP: {
    skip("XXX this test will cause the perl interpreter to fail with the message 'Use of uninitialized value in null operation", 1);
    like( exception { App::Prove::Elasticsearch::Queue::Rabbit->new({}) }, qr/must be defined/, "Constructor fatal when queue.server not defined");
}
is( exception { $out = App::Prove::Elasticsearch::Queue::Rabbit->new({'queue.host' => 'zippy.test'}) }, undef, "Constructor non-fatal when queue.server defined");

# queue_jobs

local *Net::RabbitMQ::channel_open     = sub {};
local *Net::RabbitMQ::exchange_declare = sub {};
local *Net::RabbitMQ::queue_declare    = sub {};
local *Net::RabbitMQ::queue_bind       = sub {};
local *Net::RabbitMQ::publish          = sub { my (undef,undef,undef,$t) = @_; print "queued $t\n"; };
local *Net::RabbitMQ::channel_close    = sub {};
local *Net::RabbitMQ::disconnect       = sub {};
local *App::Prove::Elasticsearch::Queue::Default::_get_searcher     = sub { return shift->{'searcher'} = 'App::Prove::Elasticsearch::Searcher::ByName' };
local *App::Prove::Elasticsearch::Planner::Default::find_test_paths = sub { return @_ };
local *App::Prove::Elasticsearch::Searcher::ByName::filter          = sub {};

my $obj = bless({
    config => { 'queue.exchange' => 'zippy' },
    queue_name => 'eep',
    mq => bless({},'Net::RabbitMQ'),
    planner => 'App::Prove::Elasticsearch::Planner::Default',
},'App::Prove::Elasticsearch::Queue::Rabbit');

my @jobs = (
    {
        version => 666,
        platforms => ['a','b','c'],
        tests => ['whee.test', 'zippy.test'],
    },
);

my $out; #XXX WHAT THE HELL!  Removing this obviously *wrong* line triggers the death bug mentioned above!
is(exception { $out = capture_merged { $obj->queue_jobs(@jobs) } } ,undef,"q-jobs can make it all the way through");
like($out,qr/queued whee/i,"Test successfully published");

# get_jobs
my $ctr = 0;
local *Net::RabbitMQ::get = sub { $ctr++; return { body => 'a' } unless $ctr >= 4; return; };

is($obj->get_jobs(),3,"Jobs returned from queue");

$ctr = 0;
$obj->{config}->{'queue.granularity'} = 2;
is($obj->get_jobs(),2,"Jobs returned from queue: limited by granularity");

#XXX work around insanity
POSIX::_exit 0;
