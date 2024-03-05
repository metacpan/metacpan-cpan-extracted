use warnings;
use strict;

use Test::More;
use Test::SharedFork;

BEGIN {
    if (! $ENV{CI_TESTING}) {
        plan skip_all => "Not on a valid CI testing platform...";
    }
    warn "Segs before: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};
}

use Async::Event::Interval;
use Data::Dumper;

my @params = (
    { 0 => 'a' },
    { 1 => 'b' },
    { 2 => 'c' },
);

my $event = Async::Event::Interval->new(
    0,
    \&callback
);

for (0..2) {
    $event->start($_, $params[$_]);
    while (! $event->waiting) {}
}

$event->stop;

warn "Segs after: " . `ipcs -m | wc -l` . "\n" if $ENV{PRINT_SEGS};

done_testing();

sub callback {
    my ($iter, $href) = @_;

    if ($iter == 0) {
        is $href->{$iter}, 'a', "start() param on iter $iter ok";
    }
    elsif ($iter == 1) {
        is $href->{$iter}, 'b', "start() param on iter $iter ok";
    }
    elsif ($iter == 2) {
        is $href->{$iter}, 'c', "start() param on iter $iter ok";
    }
}