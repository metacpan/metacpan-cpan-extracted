use strict;
use warnings;
use Cache::KyotoTycoon;
use Benchmark ':all';

my $kt = Cache::KyotoTycoon->new();
$kt->set('foo' => 'bar');
for (1..1000) {
    $kt->get('foo' => 'bar');
}
