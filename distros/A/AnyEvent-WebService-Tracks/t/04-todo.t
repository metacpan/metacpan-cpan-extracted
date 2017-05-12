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

my @orig_todos = ('Walk the dog', 'Finish TPS report', 'Take out the trash',
    'Install Tracks');
my @todos      = @orig_todos;

plan tests => 83 * @todos + 124;

my $tracks = get_tracks;

my $ctx;

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->contexts(sub {
        my ( $contexts ) = @_;

        unless(@$contexts) {
            $cond->send;
            return;
        }

        my $run;

        $run = sub {
            my $ctx = shift @$contexts;

            $ctx->destroy(sub {
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

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_context(name => 'Test Context', sub {
        ( $ctx ) = @_;

        ok($ctx);
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;
    
    my $run;
    $run = sub {
        my $desc = shift @todos;

        $tracks->create_todo($desc, $ctx, sub {
            my ( $todo ) = @_;

            ok($todo);
            isa_ok($todo, 'AnyEvent::WebService::Tracks::Todo');
            is($todo->description, $desc);
            ok(! defined($todo->due));
            ok(! defined($todo->notes));
            ok(! defined($todo->show_from));
            ok($todo->is_active);
            ok(! $todo->is_project_hidden);
            ok(! $todo->is_complete);
            ok(! $todo->is_deferred);
            ok(looks_like_number $todo->id);
            ok(! $todo->completed_at);
            ok(! $todo->recurring_todo_id);
            isa_ok($todo->created_at, 'DateTime');
            isa_ok($todo->updated_at, 'DateTime');

            dies_ok {
                $todo->completed_at(DateTime->now);
            };
            dies_ok {
                $todo->created_at(DateTime->now);
            };
            dies_ok {
                $todo->updated_at(DateTime->now);
            };
            dies_ok {
                $todo->id(0);
            };
            dies_ok {
                $todo->recurring_todo_id(0);
            };

            lives_ok {
                $todo->description('Test description');
            };
            lives_ok {
                $todo->due(DateTime->now);
            };
            lives_ok {
                $todo->notes('Test notes');
            };
            lives_ok {
                $todo->show_from(DateTime->now);
            };

            $todo->context(sub {
                my ( $c ) = @_;

                is($c->id, $ctx->id);

                $todo->project(sub {
                    my ( $p, $e ) = @_;

                    ok(! defined($p));
                    ok(! defined($e));

                    if(@todos) {
                        $run->();
                    } else {
                        $cond->send;
                    }
                });
            });
        });
    };

    $run->();
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->todos(sub {
        my ( $todos ) = @_;

        is(scalar(@$todos), scalar(@orig_todos));
        ok(all { UNIVERSAL::isa($_, 'AnyEvent::WebService::Tracks::Todo') } @$todos);

        my $run;

        $run = sub {
            my $todo = shift @$todos;

            $todo->destroy(sub {
                my ( $ok ) = @_;

                ok($ok);

                if(@$todos) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

@todos = @orig_todos;
run_tests_in_loop {
    my ( $cond ) = @_;
    
    my $run;
    $run = sub {
        my $desc = shift @todos;

        $tracks->create_todo(description => $desc, context => $ctx, sub {
            my ( $todo ) = @_;

            ok($todo);
            isa_ok($todo, 'AnyEvent::WebService::Tracks::Todo');
            is($todo->description, $desc);
            ok(! defined($todo->due));
            ok(! defined($todo->notes));
            ok(! defined($todo->show_from));
            ok($todo->is_active);
            ok(! $todo->is_project_hidden);
            ok(! $todo->is_complete);
            ok(! $todo->is_deferred);
            ok(looks_like_number $todo->id);
            ok(! $todo->completed_at);
            ok(! $todo->recurring_todo_id);
            isa_ok($todo->created_at, 'DateTime');
            isa_ok($todo->updated_at, 'DateTime');

            dies_ok {
                $todo->completed_at(DateTime->now);
            };
            dies_ok {
                $todo->created_at(DateTime->now);
            };
            dies_ok {
                $todo->updated_at(DateTime->now);
            };
            dies_ok {
                $todo->id(0);
            };
            dies_ok {
                $todo->recurring_todo_id(0);
            };

            lives_ok {
                $todo->description('Test description');
            };
            lives_ok {
                $todo->due(DateTime->now);
            };
            lives_ok {
                $todo->notes('Test notes');
            };
            lives_ok {
                $todo->show_from(DateTime->now);
            };

            $todo->context(sub {
                my ( $c ) = @_;

                is($c->id, $ctx->id);

                $todo->project(sub {
                    my ( $p, $e ) = @_;

                    ok(! defined($p));
                    ok(! defined($e));

                    if(@todos) {
                        $run->();
                    } else {
                        $cond->send;
                    }
                });
            });
        });
    };

    $run->();
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->todos(sub {
        my ( $todos ) = @_;

        my $run;

        $run = sub {
            my $todo = shift @$todos;

            $todo->destroy(sub {
                my ( $ok ) = @_;

                ok($ok);

                if(@$todos) {
                    $run->();
                } else {
                    $cond->send;
                }
            });
        };

        $run->();
    });
};

@todos = @orig_todos;
run_tests_in_loop {
    my ( $cond ) = @_;

    my $i = 1;
    
    my $run;
    $run = sub {
        my $desc = shift @todos;

        my $notes = "notes$i";

        $tracks->create_todo(description => $desc, notes => $notes, context => $ctx, sub {
            my ( $todo ) = @_;

            ok($todo);
            isa_ok($todo, 'AnyEvent::WebService::Tracks::Todo');
            is($todo->description, $desc);
            is($todo->notes, $notes);
            ok(! defined($todo->due));
            ok(! defined($todo->show_from));
            ok($todo->is_active);
            ok(! $todo->is_project_hidden);
            ok(! $todo->is_complete);
            ok(! $todo->is_deferred);
            ok(looks_like_number $todo->id);
            ok(! $todo->completed_at);
            ok(! $todo->recurring_todo_id);
            isa_ok($todo->created_at, 'DateTime');
            isa_ok($todo->updated_at, 'DateTime');

            dies_ok {
                $todo->completed_at(DateTime->now);
            };
            dies_ok {
                $todo->created_at(DateTime->now);
            };
            dies_ok {
                $todo->updated_at(DateTime->now);
            };
            dies_ok {
                $todo->id(0);
            };
            dies_ok {
                $todo->recurring_todo_id(0);
            };

            lives_ok {
                $todo->description('Test description');
            };
            lives_ok {
                $todo->due(DateTime->now);
            };
            lives_ok {
                $todo->notes('Test notes');
            };
            lives_ok {
                $todo->show_from(DateTime->now);
            };

            $todo->context(sub {
                my ( $c ) = @_;

                is($c->id, $ctx->id);

                $todo->project(sub {
                    my ( $p, $e ) = @_;

                    ok(! defined($p));
                    ok(! defined($e));

                    if(@todos) {
                        $run->();
                    } else {
                        $cond->send;
                    }
                });
            });
        });
    };

    $run->();
};

run_tests_in_loop {
    my ( $cond ) = @_;

    dies_ok {
        $tracks->create_todo(description => 'Foobar', sub {
            fail("I should never get called!");
        });
    };

    $cond->send;
};

run_tests_in_loop {
    my ( $cond ) = @_;

    dies_ok {
        $tracks->create_todo(description => 'Foobar', notes => 'Foobar', sub {
            fail("I should never be called!");
        });
    };
    $cond->send;
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_project('Test Project', sub {
        my ( $project ) = @_;

        ok($project);

        dies_ok {
            $tracks->create_todo(
                description => 'Foobar',
                context     => $ctx,
                project     => $ctx, sub {
                fail("I should never get called!");
            });

        };
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $project ) = @$projects;

        $project->default_context($ctx);

        $project->update(sub {
            my ( $p ) = @_;

            ok($p);
            $tracks->create_todo(
                description => 'Foobar',
                project     => $project, sub {
                
                my ( $todo, $err ) = @_;

                ok($todo) || diag($err);

                $todo->project(sub {
                    my ( $p ) = @_;

                    is($p->id, $project->id);

                    $tracks->create_todo('Foobar 2', $project, sub {
                        my ( $todo2 ) = @_;

                        ok($todo2);

                        $todo2->project(sub {
                            my ( $p2 ) = @_;

                            is($p2->id, $project->id);

                            dies_ok {
                                $tracks->create_todo(
                                    description => 'Foobar 3',
                                    project     => $ctx, sub {

                                    fail("I should never get called!");
                                });
                            };

                            $cond->send;
                        });
                    });
                });
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->projects(sub {
        my ( $projects ) = @_;

        my ( $project ) = @$projects;

        $project->default_context(undef);

        $project->update(sub {
            my ( $p ) = @_;

            ok($p);

            $tracks->create_todo(
                description => 'This should fail',
                project     => $project, sub {
                
                my ( $t ) = @_;

                ok(! $t);

                $cond->send;
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->todos(sub {
        my ( $todos ) = @_;

        my ( $one ) = @$todos;

        $one->destroy(sub {
            dies_ok {
                $one->is_complete;
            };
            dies_ok {
                $one->is_active;
            };
            dies_ok {
                $one->is_project_hidden;
            };
            dies_ok {
                $one->is_deferred;
            };
            dies_ok {
                $one->complete;
            };
            dies_ok {
                $one->activate;
            };
            dies_ok {
                $one->defer;
            };
            dies_ok {
                $one->description;
            };
            dies_ok {
                $one->notes;
            };
            dies_ok {
                $one->due;
            };
            dies_ok {
                $one->show_from;
            };
            dies_ok {
                $one->id;
            };
            dies_ok {
                $one->completed_at;
            };
            dies_ok {
                $one->recurring_todo_id;
            };
            dies_ok {
                $one->created_at;
            };
            dies_ok {
                $one->updated_at;
            };
            dies_ok {
                $one->context(sub {
                    fail("I shouldn't get called!");
                });
            };
            dies_ok {
                $one->project(sub {
                    fail("I shouldn't get called!");
                });
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

    $tracks->create_todo('Foobar 2', $ctx, sub {
        my ( $todo ) = @_;

        # we do this to make sure the update time is in the future
        my $timer;
        $timer = AnyEvent->timer(
            after => 1,
            cb => sub {
                undef $timer;
                my $old_updated = $todo->updated_at;

                $todo->description('Foobar 23');
                $todo->notes('Some notes!');

                is($todo->description, 'Foobar 23');
                is($todo->notes, 'Some notes!');

                $todo->update(sub {
                    my ( $todo2 ) = @_;

                    is($todo2, $todo);
                    is($todo2->description, 'Foobar 23');
                    is($todo2->notes, 'Some notes!');
                    isnt($todo2->updated_at, $old_updated);
                    ok($todo2->updated_at > $old_updated);

                    $cond->send;
                });
            },
        );
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_project('One', sub {
        my ( $one ) = @_;

        $tracks->create_project('Two', sub {
            my ( $two ) = @_;

            $tracks->create_todo(context => $ctx, project => $one, description => 'Test todo', sub {
                my ( $todo ) = @_;

                ok($todo);

                $todo->project(sub {
                    my ( $p ) = @_;

                    is($p->id, $one->id);

                    $todo->project($two);

                    $todo->update(sub {
                        my ( $todo ) = @_;

                        $todo->project(sub {
                            my ( $p ) = @_;

                            is($p->id, $two->id);

                            $todo->project(undef);

                            $todo->update(sub {
                                my ( $todo ) = @_;

                                $todo->project(sub {
                                    my ( $p ) = @_;

                                    ok(! $p);

                                    $todo->project($one);

                                    $todo->update(sub {
                                        my ( $todo ) = @_;

                                        $todo->project(sub {
                                            my ( $p ) = @_;

                                            is($p->id, $one->id);
                                            $cond->send;
                                        });
                                    });
                                });
                            });
                        });
                    });
                });
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->create_context('Two', sub {
        my ( $two ) = @_;
        my $one = $ctx;

        ok($one);
        ok($two);

        $tracks->create_todo('Another test todo', $one, sub {
            my ( $todo ) = @_;

            $todo->context(sub {
                my ( $c ) = @_;

                is($c->id, $one->id);

                $todo->context($two);

                $todo->update(sub {
                    my ( $todo ) = @_;

                    $todo->context(sub {
                        my ( $c ) = @_;

                        is($c->id, $two->id);

                        dies_ok {
                            $todo->context(undef);
                        };
                        $cond->send;
                    });
                });
            });
        });
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    my @state_changes = (
        'deferred',  # active -> deferred
        'completed', # deferred -> completed
        'active',    # completed -> active
        'completed', # active -> completed
        'deferred',  # completed -> deferred
        'active',    # deferred -> active
    );

    $tracks->todos(sub {
        my ( $todos ) = @_;

        my ( $one ) = @$todos;

        my $run;

        $run = sub {
            my $change = shift @state_changes;

            if($change eq 'deferred') {
                $one->defer(1);
            } elsif($change eq 'active') {
                $one->activate;
            } else {
                $one->complete;
            }

            $one->update(sub {
                my ( $t ) = @_;

                ok($t);

                if($change eq 'deferred') {
                    ok(! $t->is_active);
                    ok($t->is_deferred);
                    ok(! $t->is_complete);
                    ok($t->show_from);
                } elsif($change eq 'active') {
                    ok($t->is_active);
                    ok(! $t->is_deferred);
                    ok(! $t->is_complete);
                    ok(! $t->show_from);
                } else {
                    ok(! $t->is_active);
                    ok(! $t->is_deferred);
                    ok($t->is_complete);
                    ok(! $t->show_from);
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

    my $now      = DateTime->now;
    my $other    = $now->clone->add(days => 7, hours => 3, minutes => 1);
    my $duration = DateTime::Duration->new(days => 7, hours => 3, minutes => 1);
    my @defer    = (
        1         => $now->clone->add(days => 1),
        $other    => $other,
        $duration => $other,
    );

    $tracks->create_todo(
        description => 'Deferred Task',
        context     => $ctx,
        show_from   => $now->clone->add(days => 1),
    sub {
        my ( $todo ) = @_;

        ok($todo);
        ok($todo->is_deferred);
        ok($todo->show_from);
        my $expected = $now->clone->add(days => 1);
        if($expected->hour || $expected->minute || $expected->second) {
            $expected->set_hour(0);
            $expected->set_minute(0);
            $expected->set_second(0);
        };
        is($todo->show_from, $expected);

        my $run;

        $run = sub {
            my $arg      = shift @defer;
            my $expected = shift @defer;

            $todo->defer($arg);

            $todo->update(sub {
                my ( $t ) = @_;

                ok($t);
                ok($todo->is_deferred);
                ok($todo->show_from);
                if($expected->hour || $expected->minute || $expected->second) {
                    $expected->set_hour(0);
                    $expected->set_minute(0);
                    $expected->set_second(0);
                };
                is($todo->show_from, $expected);

                if(@defer) {
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

    my $time = DateTime->now;
    $time->set_hour(17);
    $time->set_minute(0);
    $time->set_second(0);

    $tracks->create_todo(
        description => 'Another Deferred Task',
        context     => $ctx,
        show_from   => $time->clone->add(days => 1),
    sub {
        my ( $todo ) = @_;

        ok($todo);

        my $expected = $time->clone->add(days => 1);
        if($expected->hour || $expected->minute || $expected->second) {
            $expected->set_hour(0);
            $expected->set_minute(0);
            $expected->set_second(0);
        };
        is($todo->show_from, $expected);
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    my $time = DateTime->now;
    $time->set_hour(20);
    $time->set_minute(0);
    $time->set_second(0);

    $tracks->create_todo(
        description => 'Yet Another Deferred Task',
        context     => $ctx,
        show_from   => $time->clone->add(days => 1),
    sub {
        my ( $todo ) = @_;

        ok($todo);

        my $expected = $time->clone->add(days => 1);
        if($expected->hour || $expected->minute || $expected->second) {
            $expected->set_hour(0);
            $expected->set_minute(0);
            $expected->set_second(0);
        };
        is($todo->show_from, $expected);
        $cond->send;
    });
};

run_tests_in_loop {
    my ( $cond ) = @_;

    $tracks->todos(sub {
        my ( $todos ) = @_;

        my ( $one ) = @$todos;
        my $copy = dclone($one);

        $one->update(sub {
            my ( $t ) = @_;

            is_deeply($t, $copy);
            $cond->send;
        });
    });
};
