use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

if (! $ENV{CI_TESTING}) {
    plan skip_all => "Not on a valid CI testing platform..."
}

my $mod = 'Async::Event::Interval';

my $e = $mod->new(1, \&perform, 10);

{ # warn on start() if started

    my $w;
    local $SIG{__WARN__} = sub { $w = shift };
    $e->start;
    $e->start;
    $e->stop;

    like $w, qr/already running/, "start() if called after started warns";
}
{ # warn on restart() if started

    my $w;
    local $SIG{__WARN__} = sub { $w = shift };

    is $w, undef, "the warning is clear";
    $e->start;
    $e->restart;
    $e->stop;

    like $w, qr/already running/, "restart() if called after started warns";

}
sub perform {
    return;
}

done_testing();
