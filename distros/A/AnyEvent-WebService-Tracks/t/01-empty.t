use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::AnyEvent::WebService::Tracks tests => 4;

my $tracks = get_tracks;

run_tests_in_loop {
    my ( $cond ) = @_;

    my $count = 3;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        is_deeply($projects, []);
        $cond->send unless --$count;
    });

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        is_deeply($contexts, []);
        $cond->send unless --$count;
    });

    $tracks->todos(sub {
        my ( $todos ) = @_;

        is_deeply($todos, []);
        $cond->send unless --$count;
    });
};
