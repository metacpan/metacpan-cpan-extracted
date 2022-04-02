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

{

    $e->start;
    is $e->status > 0, 1, "started ok";
    is $e->error, 0, "no error ok";

    sleep 3;

    is $e->status, 0, "after a crash, status returns 0";
    is $e->error, 1, "after a crash, error returns 1";

    $e->restart;

    is $e->status > 0, 1, "restarted ok";
    is $e->error, 0, "no error ok";

    sleep 3;

    is $e->status, 0, "after a crash, status returns 0";
    is $e->error, 1, "after a crash, error returns 1";
}

sub perform {
    local $SIG{ALRM} = sub { kill 9, $$; };
    alarm 1;
    sleep 2;
    alarm 0;
}

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();
