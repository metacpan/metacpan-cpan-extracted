use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::AnyEvent::WebService::Tracks tests => 39;
use Test::Exception;

my @contexts = qw(
    One
    Two
    Three
    Four
);

my @todos = map { "Todo $_" } 1..8;

clear_tracks;
my $tracks = get_tracks;

my @context_objects;
my @todo_objects;

run_tests_in_loop {
    my ( $cond ) = @_;

    my $run;
    $run = sub {
        my $name = shift @contexts;

        $tracks->create_context($name, sub {
            my ( $ctx ) = @_;

            ok($ctx);
            push @context_objects, $ctx;
            
            if(@contexts) {
                $run->();
            } else {
                $cond->send;
            }
        });
    };
    $run->();
};

run_tests_in_loop {
    my ( $cond ) = @_;

    my $i = 0;
    my $run;
    $run = sub {
        my $desc    = $todos[$i];
        my $context = $context_objects[int($i / 2)];
        $i++;

        $tracks->create_todo($desc, $context, sub {
            my ( $todo ) = @_;

            ok($todo);
            push @todo_objects, $todo;

            $todo->context(sub {
                my ( $c ) = @_;

                is($c->id, $context->id);

                if($i < @todos) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        });
    };

    $run->();
};

run_tests_in_loop {
    my ( $cond ) = @_;

    my $run;
    my $i = 0;

    $run = sub {
        my $context        = $context_objects[$i];
        my @expected_todos = @todo_objects[2 * $i, 2 * $i + 1];
        $i++;

        $context->todos(sub {
            my ( $todos, $error ) = @_;

            ok($todos) || diag($error);
            is(2, scalar(@$todos));
            is($todos->[0]->id, $expected_todos[0]->id);
            is($todos->[1]->id, $expected_todos[1]->id);

            if($i < @context_objects) {
                $run->();
            } else {
                $cond->send;
            }
        });
    };

    $run->();
};
