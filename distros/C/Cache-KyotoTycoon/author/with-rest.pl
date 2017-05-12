use strict;
use warnings;
use Cache::KyotoTycoon;
use Cache::KyotoTycoon::REST;
use Benchmark ':all';

my $kt = Cache::KyotoTycoon->new();
my $rest = Cache::KyotoTycoon::REST->new();
$kt->set('foo' => 'bar');
die unless $kt->get('foo') eq 'bar';
$rest->put('foo' => 'baz');
die unless $rest->get('foo') eq 'baz';

timethese(
    10000 => +{
        get => sub {
            $kt->get('foo');
        },
        get_rest => sub {
            $rest->get('foo');
        },
        set => sub {
            $kt->set('foo' => 'bar');
        },
        set_rest => sub {
            $rest->put('foo' => 'bar');
        },
    }
);
