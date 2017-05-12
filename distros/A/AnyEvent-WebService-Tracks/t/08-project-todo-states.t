use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::AnyEvent::WebService::Tracks tests => 13;
use Test::Exception;

clear_tracks;
my $tracks = get_tracks;

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_context('Test Context', sub {
        my ( $ctx ) = @_;

        ok($ctx);

        $tracks->create_project('Test Project', sub {
            my ( $project ) = @_;

            ok($project);

            $tracks->create_todo(
                context     => $ctx,
                project     => $project,
                description => 'Test Todo', sub {

                my ( $todo ) = @_;

                ok($todo);

                ok($todo->is_active);
                ok(! $todo->is_project_hidden);
                ok(! $todo->is_complete);
                ok(! $todo->is_deferred);

                $project->hide;

                $project->update(sub {
                    my ( $p ) = @_;

                    ok($p);

                    $tracks->todos(sub {
                        my ( $todos ) = @_;

                        is(scalar(@$todos), 0);

                        $project->complete;

                        $project->update(sub {
                            my ( $p ) = @_;

                            ok($p);

                            $project->todos(sub {
                                my ( $todos ) = @_;

                                is(scalar(@$todos), 1);

                                my ( $todo ) = @$todos;

                                ok(! $todo->is_complete);
                                $cond->send;
                            });
                        });
                    });
                });
            });
        });
    });
};
