use strict;
use warnings;

use Async::Event::Interval;
use Data::Dumper;
use Test::More;

my $mod = 'Async::Event::Interval';

# runs()
{
    my $e = $mod->new(0.1, sub {});

    $e->start;
    select(undef, undef, undef, 0.7);
    $e->stop;

    my $method_runs = $e->runs;
    my $info_runs = $e->info->{runs};

    is $method_runs, $info_runs, "run() returns same data for runs as info()";
    is $method_runs > 5, 1, "Number of runs appears to be correct";

    my $event_runs = $e->events->{$e->id}{runs};
    is $method_runs, $event_runs, "events(id) returns same data as runs() ok";
}

# errors()
{
    my $e = $mod->new(0.1, sub { die("some failure"); });

    $e->start;
    select(undef, undef, undef, 0.3);
    $e->stop;

    is $e->errors, 1, "errors() shared data ok";

}
done_testing();
