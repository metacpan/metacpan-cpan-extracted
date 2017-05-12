
use Test::More tests => 44;

use_ok('Beanstalk::Stats');
use_ok('Beanstalk::Job');
use_ok('Beanstalk::Client');

my $client = Beanstalk::Client->new;

ok($client,"Create client");

unless ($client->connect) {
SKIP: {
    skip("Need local beanstalkd server running", 40);
  }
  exit(0);
}

my $job = $client->put({ priority => 12, ttr => 123, data => 'foobar'});
ok($job);

isa_ok($job->peek, 'Beanstalk::Job','peek');
isa_ok($job->stats, 'Beanstalk::Stats','stats');
is($job->priority, 12, 'priority');
is($job->ttr, 123, 'ttr');
is($job->data, 'foobar', 'data');
is($job->reserved, undef, 'reserved');
my $tube = $client->list_tube_used;
$client->watch_only($tube);

$job = $client->reserve;
is($job->touch, 1, 'touch');
is($job->reserved, 1, 'reserved');
is($job->release, 1, 'release');
is($job->tube, $tube,'tube');

$job = $client->reserve;
is($job->bury, 1, 'bury');
is($job->delete, 1, 'delete');

$job = Beanstalk::Job->new({id => 0, client => $client});

is($job->stats, undef, 'stats error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->delete, undef, 'delete error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->touch, undef, 'touch error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->peek, undef, 'peek error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->release, undef, 'release error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->tube, undef, 'tube error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->bury, undef, 'bury error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->ttr, undef, 'ttr error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");

is($job->priority, undef, 'priority error');
is($job->error,'NOT_FOUND');
is($job->error(""),"");
