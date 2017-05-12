package Test::Parameters;

use common::sense;

use Test::Most;
use base 'Test::Class';

use Algorithm::Functional::BFS;

my $func = sub {};

sub undefined_adjacent_nodes_func : Tests(1)
{
    eval
    {
        my $bfs = Algorithm::Functional::BFS->new
        (
            victory_func => $func,
        );
    };

    ok(defined($@), 'constructor died');
}

sub undefined_victory_func : Tests(1)
{
    eval
    {
        my $bfs = Algorithm::Functional::BFS->new
        (
            adjacent_nodes_func => $func,
        );
    };

    ok(defined($@), 'constructor died');
}

sub undefined_start_node : Tests(1)
{
    my $bfs = Algorithm::Functional::BFS->new
    (
        adjacent_nodes_func => $func,
        victory_func        => $func,
    );

    eval
    {
        $bfs->search();
    };

    ok(defined($@), 'search() died');
}

1;
