use strict;
use warnings;

use Test::More;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;

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

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();
