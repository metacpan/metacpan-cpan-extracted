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

my @orig_projects = qw(P1 P2 P3 P4);
my @projects      = @orig_projects;

plan tests => 62 * @projects + 78;

my $tracks = get_tracks;

run_tests_in_loop {
    my ( $cond ) = @_;

    my $pos = 1;
    
    my $run;
    $run = sub {
        my $name = shift @projects;

        $tracks->create_project($name, sub {
            my ( $proj ) = @_;

            ok($proj);
            isa_ok($proj, 'AnyEvent::WebService::Tracks::Project');
            is($proj->name, $name);
            ok(! defined($proj->description));

            ok(looks_like_number $proj->position);
            ok(! defined($proj->completed_at));
            ok(! $proj->is_complete);
            ok(! $proj->is_hidden);
            ok($proj->is_active);
            isa_ok($proj->created_at, 'DateTime');
            isa_ok($proj->updated_at, 'DateTime');

            dies_ok {
                $proj->completed_at(DateTime->now);
            };
            dies_ok {
                $proj->created_at(DateTime->now);
            };
            dies_ok {
                $proj->id(0);
            };
            dies_ok {
                $proj->updated_at(DateTime->now);
            };

            lives_ok {
                $proj->description('Phony description');
            };
            lives_ok {
                $proj->name('Another name');
            };
            lives_ok {
                $proj->position(4);
            };

            $proj->default_context(sub {
                my ( $ctx ) = @_;

                ok(! defined($ctx));

                if(@projects) {
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

    $tracks->projects(sub {
        my ( $projects ) = @_;

        is(scalar(@$projects), scalar(@orig_projects));
        ok(all { UNIVERSAL::isa($_, 'AnyEvent::WebService::Tracks::Project') } @$projects);

        my $run;

        $run = sub {
            my $proj = shift @$projects;

            $proj->destroy(sub {
                my ( $ok ) = @_;

                ok($ok);

                if(@$projects) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

@projects = @orig_projects;
run_tests_in_loop {
    my ( $cond ) = @_;
    
    my $run;
    $run = sub {
        my $name = shift @projects;

        $tracks->create_project(name => $name, sub {
            my ( $proj ) = @_;

            ok($proj);
            isa_ok($proj, 'AnyEvent::WebService::Tracks::Project');
            is($proj->name, $name);
            ok(! defined($proj->description));
            ok(looks_like_number $proj->id);
            ok(looks_like_number $proj->position);
            ok(! defined($proj->completed_at));
            ok(! $proj->is_complete);
            ok(! $proj->is_hidden);
            ok($proj->is_active);
            isa_ok($proj->created_at, 'DateTime');
            isa_ok($proj->updated_at, 'DateTime');

            dies_ok {
                $proj->completed_at(DateTime->now);
            };
            dies_ok {
                $proj->created_at(DateTime->now);
            };
            dies_ok {
                $proj->id(0);
            };
            dies_ok {
                $proj->updated_at(DateTime->now);
            };

            lives_ok {
                $proj->description('Phony description');
            };
            lives_ok {
                $proj->name('Another name');
            };
            lives_ok {
                $proj->position(4);
            };

            $proj->default_context(sub {
                my ( $ctx, $err ) = @_;

                ok(! defined($ctx));
                ok(! defined($err));

                if(@projects) {
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

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my $run;

        $run = sub {
            my $proj = shift @$projects;

            $proj->destroy(sub {
                my ( $ok ) = @_;

                ok($ok);

                if(@$projects) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

@projects = @orig_projects;
run_tests_in_loop {
    my ( $cond ) = @_;

    my $i = 1;
    
    my $run;
    $run = sub {
        my $name = shift @projects;

        my $desc = "desc$i";

        $tracks->create_project(name => $name, description => $desc, sub {
            my ( $proj ) = @_;

            ok($proj);
            isa_ok($proj, 'AnyEvent::WebService::Tracks::Project');
            is($proj->name, $name);
            is($proj->description, $desc);
            ok(looks_like_number $proj->position);
            ok(! defined($proj->completed_at));
            ok(! $proj->is_complete);
            ok(! $proj->is_hidden);
            ok($proj->is_active);
            isa_ok($proj->created_at, 'DateTime');
            isa_ok($proj->updated_at, 'DateTime');

            dies_ok {
                $proj->completed_at(DateTime->now);
            };
            dies_ok {
                $proj->created_at(DateTime->now);
            };
            dies_ok {
                $proj->id(0);
            };
            dies_ok {
                $proj->updated_at(DateTime->now);
            };

            lives_ok {
                $proj->description('Phony description');
            };
            lives_ok {
                $proj->description('Another name');
            };
            lives_ok {
                $proj->position(4);
            };

            $proj->default_context(sub {
                my ( $ctx, $e ) = @_;

                ok(! defined($ctx));
                ok(! defined($e));

                if(@projects) {
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

    $tracks->create_project('P1', sub {
        my ( $proj, $error ) = @_;

        ok(! $proj);
        ok($error);
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one ) = @$projects;

        $one->name('Not one');
        $one->description('A different description');
        $one->position(3);
        my $updated_at = $one->updated_at;

        my $timer;
        $timer = AnyEvent->timer(
            after => 2,
            cb    => sub {
                undef $timer;
                $one->update(sub {
                    my ( $proj ) = @_;

                    ok($proj);
                    is($proj->name, 'Not one');
                    is($proj->description, 'A different description');
                    is($proj->position, 3);
                    ok($proj->updated_at > $updated_at);

                    $cond->send;
                });
            },
        );
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one, $two ) = @$projects;

        $one->name($two->name);

        $one->update(sub {
            my ( $proj, $error ) = @_;

            ok(! $proj);
            ok($error);

            $cond->send;
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one ) = @$projects;

        $one->destroy(sub {
            dies_ok {
                $one->completed_at;
            };
            dies_ok {
                $one->created_at;
            };
            dies_ok {
                $one->id;
            };
            dies_ok {
                $one->updated_at;
            };
            dies_ok {
                $one->is_complete;
            };
            dies_ok {
                $one->is_hidden;
            };
            dies_ok {
                $one->is_active;
            };
            dies_ok {
                $one->description;
            };
            dies_ok {
                $one->name;
            };
            dies_ok {
                $one->position;
            };
            dies_ok {
                $one->default_context(sub {
                    fail("I shouldn't get called!");
                });
            };
            dies_ok {
                $one->complete;
            };
            dies_ok {
                $one->activate;
            };
            dies_ok {
                $one->hide;
            };
            dies_ok {
                $one->update(sub {
                    fail("I shouldn't get called!");
                });
            };
            dies_ok {
                $one->destroy(sub {
                    fail("I shouldn't get called!");
                });
            };
            $cond->send;
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_context('Test Context', sub {
        my ( $ctx ) = @_;

        $tracks->projects(sub {
            my ( $projects ) = @_;

            my ( $proj ) = @$projects;

            $proj->default_context($ctx);

            $proj->update(sub {
                my ( $p ) = @_;

                ok($p);

                $p->default_context(sub {
                    my ( $c ) = @_;

                    is($c->id, $ctx->id);

                    $cond->send;
                });
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one, $two ) = @$projects;

        dies_ok {
            $one->default_context($two);
        };
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one ) = @$projects;

        $one->default_context(sub {
            my ( $ctx ) = @_;

            ok($ctx);

            $one->default_context(undef);

            $one->update(sub {
                my ( $p ) = @_;

                $p->default_context(sub {
                    my ( $c ) = @_;

                    ok(! $c);
                    $cond->send;
                });
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        my ( $ctx ) = @$contexts;

        $tracks->create_project(name => 'One final project', default_context => $ctx, sub {
            my ( $proj ) = @_;

            ok($proj);
            $proj->default_context(sub {
                my ( $c ) = @_;

                ok($c);
                is($c->id, $ctx->id);
                $cond->send;
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $p ) = @$projects;

        dies_ok {
            $tracks->create_project(name => 'A new project', default_context => $p, sub {
                fail("I shouldn't get called!");
            });
        };

        dies_ok {
            $p->default_context($p);
        };
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    my @state_changes = (
        'hidden',    # active -> hidden
        'completed', # hidden -> completed
        'active',    # completed -> active
        'completed', # active -> completed
        'hidden',    # completed -> hidden
        'active',    # hidden -> active
    );

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one ) = @$projects;

        my $run;

        $run = sub {
            my $change = shift @state_changes;

            if($change eq 'hidden') {
                $one->hide;
            } elsif($change eq 'active') {
                $one->activate;
            } else {
                $one->complete;
            }

            $one->update(sub {
                my ( $p ) = @_;

                ok($p);

                if($change eq 'hidden') {
                    ok(! $one->is_active);
                    ok($one->is_hidden);
                    ok(! $one->is_complete);
                } elsif($change eq 'active') {
                    ok($one->is_active);
                    ok(! $one->is_hidden);
                    ok(! $one->is_complete);
                } else {
                    ok(! $one->is_active);
                    ok(! $one->is_hidden);
                    ok($one->is_complete);
                }

                if(@state_changes) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $one ) = @$projects;
        my $copy = dclone($one);

        $one->update(sub {
            my ( $p ) = @_;

            is_deeply($p, $copy);
            $cond->send;
        });
    });
};
