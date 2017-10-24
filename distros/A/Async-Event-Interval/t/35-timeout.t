use strict;
use warnings;

use Async::Event::Interval;
use Test::More;

my $mod = 'Async::Event::Interval';

my $e = $mod->new(1, \&perform, 10);

{

    $e->start;
    is $e->status > 0, 1, "started ok";

    sleep 3;
    is $e->status, -1, "after a crash, status returns -1";

    $e->restart;
    is $e->status > 0, 1, "restarted ok";

    sleep 3;
    is $e->status, -1, "after a crash, status returns -1";

}

sub perform {
    local $SIG{ALRM} = sub { kill 9, $$; };
    alarm 1;
    sleep 2;
    alarm 0;
}

done_testing();
