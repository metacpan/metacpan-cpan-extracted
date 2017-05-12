use Test::More;
use DataDog::DogStatsd;

my $statsd = DataDog::DogStatsd->new;
ok($statsd);

$statsd->increment( 'test.stats' );
$statsd->decrement( 'test.stats' );
$statsd->timing('test.timing', 1);
$statsd->gauge('test.gauge', 10);
$statsd->histogram('test.histogram', 1);
$statsd->set('test.set', 1);

$statsd->increment( 'test.stats', { tags => ['tag1', 'tag2'] } );
$statsd->decrement( 'test.stats', { tags => ['tag1', 'tag2'] } );
$statsd->timing( 'test.timing', 1, { tags => ['tag1', 'tag2'] } );
$statsd->gauge('test.gauge', 10, { tags => ['tag1', 'tag2'] } );

done_testing;
