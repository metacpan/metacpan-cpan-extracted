use strict;
use warnings;

use FindBin;
use lib "$FindBin::Bin/lib";

use List::MoreUtils qw(all);
use Scalar::Util qw(looks_like_number);
use Storable qw(dclone);
use Test::AnyEvent::WebService::Tracks;
use Test::Exception;
use UNIVERSAL ();

my @orig_contexts = qw(One Two Three Four);
my @contexts      = @orig_contexts;

plan tests => 47 * @contexts + 34;

my $tracks = get_tracks;

run_tests_in_loop {
    my ( $cond ) = @_;
    
    my $run;
    $run = sub {
        my $name = shift @contexts;

        $tracks->create_context($name, sub {
            my ( $ctx ) = @_;

            ok($ctx);
            isa_ok($ctx, 'AnyEvent::WebService::Tracks::Context');
            is($ctx->name, $name);
            ok(looks_like_number $ctx->id);
            isa_ok($ctx->created_at, 'DateTime');
            isa_ok($ctx->updated_at, 'DateTime');
            ok(looks_like_number $ctx->position);
            ok(! $ctx->is_hidden);

            dies_ok {
                $ctx->id(0);
            };
            lives_ok {
                $ctx->name('New Name');
            };
            dies_ok {
                $ctx->created_at(DateTime->now);
            };
            dies_ok {
                $ctx->updated_at(DateTime->now);
            };
            lives_ok {
                $ctx->position(1);
            };
            lives_ok {
                $ctx->hide;
            };
            lives_ok {
                $ctx->unhide;
            };

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

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        is(scalar(@$contexts), scalar(@orig_contexts));
        ok(all { UNIVERSAL::isa($_, 'AnyEvent::WebService::Tracks::Context') } @$contexts);

        my $run;

        $run = sub {
            my $ctx = shift @$contexts;

            $ctx->destroy(sub {
                my ( $ok ) = @_;

                ok($ok);

                if(@$contexts) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

@contexts = @orig_contexts;
run_tests_in_loop {
    my ( $cond ) = @_;
    
    my $run;
    $run = sub {
        my $name = shift @contexts;

        $tracks->create_context(name => $name, sub {
            my ( $ctx ) = @_;

            ok($ctx);
            isa_ok($ctx, 'AnyEvent::WebService::Tracks::Context');
            is($ctx->name, $name);
            ok(looks_like_number $ctx->id);
            isa_ok($ctx->created_at, 'DateTime');
            isa_ok($ctx->updated_at, 'DateTime');
            ok(looks_like_number $ctx->position);
            ok(! $ctx->is_hidden);

            dies_ok {
                $ctx->id(0);
            };
            lives_ok {
                $ctx->name('New Name');
            };
            dies_ok {
                $ctx->created_at(DateTime->now);
            };
            dies_ok {
                $ctx->updated_at(DateTime->now);
            };
            lives_ok {
                $ctx->position(1);
            };
            lives_ok {
                $ctx->hide;
            };
            lives_ok {
                $ctx->unhide;
            };

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

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        my $run;

        $run = sub {
            my $ctx = shift @$contexts;

            $ctx->destroy(sub {
                my ( $ok ) = @_;

                ok($ok);

                if(@$contexts) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

@contexts = @orig_contexts;
run_tests_in_loop {
    my ( $cond ) = @_;
    
    my $run;
    $run = sub {
        my $name = shift @contexts;

        $tracks->create_context(name => $name, hide => 1, sub {
            my ( $ctx ) = @_;

            ok($ctx);
            isa_ok($ctx, 'AnyEvent::WebService::Tracks::Context');
            is($ctx->name, $name);
            ok(looks_like_number $ctx->id);
            isa_ok($ctx->created_at, 'DateTime');
            isa_ok($ctx->updated_at, 'DateTime');
            ok(looks_like_number $ctx->position);
            ok($ctx->is_hidden);

            dies_ok {
                $ctx->id(0);
            };
            lives_ok {
                $ctx->name('New Name');
            };
            dies_ok {
                $ctx->created_at(DateTime->now);
            };
            dies_ok {
                $ctx->updated_at(DateTime->now);
            };
            lives_ok {
                $ctx->position(1);
            };
            lives_ok {
                $ctx->hide;
            };
            lives_ok {
                $ctx->unhide;
            };

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

    $tracks->create_context('One', sub {
        my ( $ctx, $error ) = @_;

        ok(! $ctx);
        ok($error);
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        my ( $one ) = @$contexts;

        $one->name('Not one');
        $one->position(4);
        $one->unhide;
        my $updated_at = $one->updated_at;

        my $timer;
        $timer = AnyEvent->timer(
            after => 2,
            cb    => sub {
                undef $timer;
                $one->update(sub {
                    my ( $ctx ) = @_;

                    ok($ctx);
                    is($ctx->name, 'Not one');
                    is($ctx->position, 4);
                    ok(! $ctx->is_hidden);
                    ok($ctx->updated_at > $updated_at);

                    $cond->send;
                });
            },
        );
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        my ( $one, $two ) = @$contexts;

        $one->name($two->name);

        $one->update(sub {
            my ( $ctx, $error ) = @_;

            ok(! $ctx);
            ok($error);

            $cond->send;
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        my ( $one ) = @$contexts;
        my $copy = dclone($one);

        $one->update(sub {
            my ( $c ) = @_;

            is_deeply($c, $copy);
            $cond->send;
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        my ( $one ) = @$contexts;

        $one->destroy(sub {
            dies_ok {
                $one->name;
            };
            dies_ok {
                $one->id;
            };
            dies_ok {
                $one->created_at;
            };
            dies_ok {
                $one->updated_at;
            };
            dies_ok {
                $one->position;
            };
            dies_ok {
                $one->is_hidden;
            };

            dies_ok {
                $one->name('New Name');
            };
            dies_ok {
                $one->position(1);
            };
            dies_ok {
                $one->hide;
            };
            dies_ok {
                $one->unhide;
            };

            dies_ok {
                $one->update(sub {
                    fail("I shouldn't get called!");
                });;
            };

            dies_ok {
                $one->destroy(sub {
                    fail("I shouldn't get called!");
                });;
            };

            $cond->send;
        });
    });
};
