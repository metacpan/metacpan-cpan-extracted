use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use Test::AnyEvent::WebService::Tracks tests => 8;
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

                $ctx->destroy(sub {
                    my ( $ok ) = @_;

                    ok($ok);

                    $project->destroy(sub {
                        my ( $ok2 ) = @_;

                        ok($ok2);

                        $todo->context(sub {
                            my ( $c ) = @_;

                            ok(! $c);

                            $todo->project(sub {
                                my ( $p ) = @_;

                                ok(! $p);
                                
                                $cond->send;
                            });
                        });
                    });
                });
            });
        });
    });
};
