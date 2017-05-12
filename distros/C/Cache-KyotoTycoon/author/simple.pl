use strict;
use warnings;
use Cache::KyotoTycoon;
use Benchmark ':all';

my $kt = Cache::KyotoTycoon->new();
$kt->set('foo' => 'bar');
die unless $kt->get('foo') eq 'bar';
timethese(
    50000 => +{
        echo => sub {
            $kt->echo(+{});
        },
        get => sub {
            $kt->get('foo');
        },
        set => sub {
            $kt->set('foo' => 'bar');
        },
    }
);
