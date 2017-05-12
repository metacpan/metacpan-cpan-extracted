use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::AnyEvent::WebService::Tracks tests => 60;
use Test::Exception;

clear_tracks;
my $tracks = get_tracks;

my @project_names = map { "Project $_" } 1..4;
my @todo_names = map { "Todo $_" } 1..8;

my @projects;
my @todos;
my ( $ctx, $ctx2 );

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_context('Test Context', sub {
        ( $ctx ) = @_;

        ok($ctx);

        $tracks->create_context('Test Context 2', sub {
            ( $ctx2 ) = @_;

            ok($ctx2);

            my $create_todos;
            my $create_projects;

            $create_todos = sub {
                my ( $index ) = @_;

                my $name    = $todo_names[$index];
                my $project = $projects[int($index / 2)];

                $tracks->create_todo(
                    description => $name,
                    project     => $project, sub {

                    my ( $t ) = @_;

                    ok($t);
                    push @todos, $t;

                    $t->project(sub {
                        my ( $p ) = @_;

                        is($p->id, $project->id);

                        if($index + 1 < @todo_names) {
                            $create_todos->($index + 1);
                        } else {
                            $cond->send;
                        }
                    });
                });
            };

            $create_projects = sub {
                my ( $index ) = @_;

                my $name = $project_names[$index];

                $tracks->create_project(
                    name            => $name,
                    default_context => ($index % 2) ? $ctx : $ctx2, sub {

                    my ( $p ) = @_;

                    ok($p);
                    $p->default_context(sub {
                        my ( $c ) = @_;

                        if($index % 2) {
                            is($c->id, $ctx->id);
                        } else {
                            is($c->id, $ctx2->id);
                        }

                        push @projects, $p;

                        if($index + 1 < @project_names) {
                            $create_projects->($index + 1);
                        } else {
                            $create_todos->(0);
                        }
                    });
                });
            };

            $create_projects->(0);
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    my $run;

    $run = sub {
        my ( $index ) = @_;

        my $project        = $projects[$index];
        my $expected_ctx   = ($index % 2) ? $ctx : $ctx2;
        my @expected_todos = @todos[2 * $index, 2 * $index + 1];

        $project->todos(sub {
            my ( $todos, $error ) = @_;

            ok($todos) || diag($error);
            is(2, scalar(@$todos));
            is($todos->[0]->id, $expected_todos[0]->id);
            is($todos->[1]->id, $expected_todos[1]->id);

            $todos->[0]->context(sub {
                my ( $c ) = @_;

                is($c->id, $expected_ctx->id);

                $todos->[1]->context(sub {
                    my ( $c2 ) = @_;

                    is($c2->id, $expected_ctx->id);

                    $todos->[0]->project(sub {
                        my ( $p ) = @_;

                        is($p->id, $project->id);
                        
                        $todos->[1]->project(sub {
                            my ( $p2 ) = @_;

                            is($p2->id, $project->id);

                            if($index + 1 < @projects) {
                                $run->($index + 1);
                            } else {
                                $cond->send;
                            }
                        });
                    });
                });
            });
        });
    };

    $run->(0);
};
