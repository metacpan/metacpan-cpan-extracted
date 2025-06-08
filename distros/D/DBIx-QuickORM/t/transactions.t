package My::ORM;
use lib 't/lib';
use Test2::V0 -target => 'DBIx::QuickORM', '!meta', '!pass';
use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use Carp::Always;

do_for_all_dbs {
    my $db = shift;

    db mydb => sub {
        dialect curdialect();
        db_name 'quickdb';
        connect sub { $db->connect };
    };

    orm my_orm => sub {
        db 'mydb';
        autofill;
    };

    package main;
    use DBIx::QuickORM::Test;
    use Test2::V0;
    My::ORM->import('qorm');

    my $con = qorm('my_orm');
    my $s = $con->handle('example');

    subtest no_action => sub {
        subtest commit => sub {
            my $txn = $con->txn;
            ok($txn, "got txn object");
            $txn->commit;
            ok(lives { $txn = undef }, "Can undef commited txn");
            ok(!$con->in_txn, "Not in a txn anymore");
        };

        subtest rollback => sub {
            my $txn = $con->txn;
            ok($txn, "got txn object");
            $txn->rollback;
            ok(lives { $txn = undef }, "Can undef rollbacked txn");
            ok(!$con->in_txn, "Not in a txn anymore");
        };

        subtest scope_end => sub {
            my $txn = $con->txn;
            ok($txn, "got txn object");
            ok(lives { $txn = undef }, "Can undef rollbacked txn");
            ok(!$con->in_txn, "Not in a txn anymore");
        };
    };

    subtest external_txns => sub {
        my $dbh = $con->dbh;
        ok(!$con->in_txn, "Not in a transaction");
        $dbh->begin_work;
        ok($con->in_txn, "In transaction");
        is($con->in_txn, 1, "Not a txn object");
        ok(!$con->current_txn, "No current transaction oject to fetch");
        $dbh->commit;
        ok(!$con->in_txn, "Not in a transaction");
    };

    subtest rows => sub {
        my $row_a;
        $con->txn(sub {
            ok($row_a = $s->insert({name => 'a'}), "Inserted a row");
        });
        ok($row_a->is_valid, "Row is valid");
        ok($row_a->is_stored, "Row is in storage");

        my $row_b;
        $con->txn(sub {
            my $txn = shift;

            ok($row_b = $s->insert({name => 'b'}), "Inserted a row");

            ok($row_b->is_valid, "Row is valid");
            ok($row_b->is_stored, "Row is in storage");

            $txn->rollback;
        });

        ok(!$row_b->is_valid,  "Row is not valid anymore");
        ok(!$row_b->is_stored, "Row is not in storage anymore");

        like(
            dies { $row_b->field('name') },
            qr/This row is invalid/,
            "Cannot use an invalid row"
        );

        $con->txn(sub {
            my $txn = shift;

            ok($row_b = $s->insert({name => 'b'}), "Inserted a row");

            ok($row_b->is_valid, "Row is valid");
            ok($row_b->is_stored, "Row is in storage");
        });

        ok($row_b->is_valid, "Row is valid");
        ok($row_b->is_stored, "Row is in storage");

        my $row_c;
        $con->txn(sub {
            $con->txn(sub {
                $con->txn(sub {
                    $con->txn(sub {
                        ok($row_c = $s->insert({name => 'c'}), "Inserted a row");

                        ok($row_c->is_valid,  "Row is valid");
                        ok($row_c->is_stored, "Row is in storage");
                    });

                    ok($row_c->is_valid,  "Row is valid");
                    ok($row_c->is_stored, "Row is in storage");
                });

                $con->txn(sub {
                    ok($row_c->is_valid,  "Row is valid");
                    ok($row_c->is_stored, "Row is in storage");
                    ok($row_c->row_data->{transaction} != $_[0], "It did not shift up to the new txn");
                });

                ok($row_c->row_data->{transaction} == $_[0], "It shifted down to this txn");

                ok($row_c->is_valid,  "Row is valid");
                ok($row_c->is_stored, "Row is in storage");

                $_[0]->rollback;
            });

            ok(!$row_c->is_valid,  "Row is not valid anymore");
            ok(!$row_c->is_stored, "Row is not in storage anymore");
        });

        ok(!$row_c->is_valid,  "Row is not valid anymore");
        ok(!$row_c->is_stored, "Row is not in storage anymore");

        like(
            dies { $row_c->field('name') },
            qr/This row is invalid/,
            "Cannot use an invalid row"
        );
    };

    subtest rollback => sub {
        my $line;
        my $row_d;
        my $txn;

        my $warns = warnings {
            $con->txn(sub {
                $txn = shift;
                $txn->set_verbose('will fail');
                ok($row_d = $s->insert({name => 'd'}), "Inserted a row");
                ok($row_d->is_valid,  "Row is valid");
                ok($row_d->is_stored, "Row is in storage");

                $line = __LINE__ + 1;
                $txn->rollback();
            });
        };

        is($warns, ["Transaction 'will fail' rolled back in ${ \__FILE__ } line $line.\n"], "Got verbose warning");

        ok(!$row_d->is_valid,  "Row is not valid anymore");
        ok(!$row_d->is_stored, "Row is not in storage anymore");

        ok(defined($txn->result), "Result is defined");
        ok(!$txn->result, "Result is false");
        ok($txn->complete, "txn is complete");
        is($txn->rolled_back, "${ \__FILE__ } line $line", "Recorded where the rollback happened");

        $warns = warnings {
            $con->txn(sub {
                $txn = shift;
                $txn->set_verbose('will fail 2');

                $line = __LINE__ + 1;
                $txn->rollback("Cause I said so");
            });
        };

        is($warns, ["Transaction 'will fail 2' rolled back in ${ \__FILE__ } line $line (Cause I said so)\n"], "Got verbose warning");
        is($txn->rolled_back, "Cause I said so in ${ \__FILE__ } line $line", "Recorded where the rollback happened");
    };

    subtest commit => sub {
        my $line;
        my $row_d;
        my $txn;

        my $warns = warnings {
            $con->txn(sub {
                $txn = shift;
                $txn->set_verbose('will work');
                ok($row_d = $s->insert({name => 'd'}), "Inserted a row");
                ok($row_d->is_valid,  "Row is valid");
                ok($row_d->is_stored, "Row is in storage");

                $line = __LINE__ + 1;
                $txn->commit;
            });
        };

        is($warns, ["Transaction 'will work' committed in ${ \__FILE__ } line $line.\n"], "Got verbose warning");

        ok($row_d->is_valid,  "Row is valid");
        ok($row_d->is_stored, "Row is in storage");

        ok(defined($txn->result), "Result is defined");
        ok($txn->result, "Result is true");
        ok($txn->complete, "txn is complete");
        is($txn->committed, "${ \__FILE__ } line $line", "Recorded where the commit happened");

        $warns = warnings {
            $con->txn(sub {
                $txn = shift;
                $txn->set_verbose('will work 2');

                $line = __LINE__ + 1;
                $txn->commit("Cause I said so");
            });
        };

        is($warns, ["Transaction 'will work 2' committed in ${ \__FILE__ } line $line (Cause I said so)\n"], "Got verbose warning");
        is($txn->committed, "Cause I said so in ${ \__FILE__ } line $line", "Recorded where the commit happened");

    };

    subtest exception => sub {
        my $line;
        my $row_e;
        my $txn;

        my $exception = dies {
            $con->txn(sub {
                $txn = shift;
                $txn->set_verbose('will fail');
                ok($row_e = $s->insert({name => 'e'}), "Inserted a row");
                ok($row_e->is_valid,  "Row is valid");
                ok($row_e->is_stored, "Row is in storage");

                $line = __LINE__ + 1;
                die "oops I did it again";
            });
        };

        like($exception, qr{oops I did it again}, "Propogated exception");
        like($txn->errors, [qr{oops I did it again}], "Stored error");

        ok(!$row_e->is_valid,  "Row is not valid anymore");
        ok(!$row_e->is_stored, "Row is not in storage anymore");

        ok(defined($txn->result), "Result is defined");
        ok(!$txn->result, "Result is false");
        ok($txn->complete, "txn is complete");

        $exception = dies {
            $con->txn(sub {
                $txn = shift;
                $txn->set_verbose('will fail 2');

                $line = __LINE__ + 1;
                die "oops I did it again";
            });
        };

        like($exception, qr{oops I did it again}, "Propogated exception");
        like($txn->errors, [qr{oops I did it again}], "Stored error");
    };

    subtest on_XYZ => sub {
        my $seen = {};
        $con->txn(
            action        => sub { $seen->{action}++ },
            on_success    => sub { $seen->{success}++ },
            on_fail       => sub { $seen->{fail}++ },
            on_completion => sub { $seen->{comp}++ },
        );
        is($seen, {action => 1, success => 1, comp => 1}, "Saw everything but fail");

        $seen = {};
        $con->txn(
            action        => sub { $seen->{action}++; $_[0]->rollback },
            on_success    => sub { $seen->{success}++ },
            on_fail       => sub { $seen->{fail}++ },
            on_completion => sub { $seen->{comp}++ },
        );
        is($seen, {action => 1, fail => 1, comp => 1}, "Saw everything but success");

        $seen = {};
        $con->txn(sub {
            $seen->{action}++;
            $_[0]->add_success_callback(sub { $seen->{success}++ });
            $_[0]->add_fail_callback(sub { $seen->{fail}++ });
            $_[0]->add_completion_callback(sub { $seen->{comp}++ });
        });
        is($seen, {action => 1, success => 1, comp => 1}, "Saw everything but fail");

        $seen = {};
        ok(
            !eval {
                $con->txn(
                    action        => sub { $seen->{action}++; die "oops" },
                    on_success    => sub { $seen->{success}++ },
                    on_fail       => sub { $seen->{fail}++ },
                    on_completion => sub { $seen->{comp}++ },
                );
                1;
            },
            "Exception"
        );
        is($seen, {action => 1, fail => 1, comp => 1}, "Saw everything but success");
    };

    subtest cross_txn => sub {
        my $row;
        $con->txn(sub {
            $row = $s->insert({name => 'f'});
            $row->update({name => 'F'});
            is($row->field('name'), 'F', "Updated Row");
        });

        $con->txn(sub {
            like(
                dies { $row->update({name => 'FF'}) },
                qr/This row was fetched outside of the current transaction stack/,
                "Did not refresh row after its txn was done, new txn needs a refresh"
            );
        });
    };

    subtest after_txn => sub {
        my $row;
        $con->txn(sub {
            $row = $s->insert({name => 'g'});
            $row->update({name => 'G'});
            is($row->field('name'), 'G', "Updated Row");
        });

        ok(lives { $row->update({name => 'GG'}) }, "Not in a transaction, no issue");
    };

    subtest before_txn => sub {
        my $row = $s->insert({name => 'g'});
        $row->update({name => 'G'});
        is($row->field('name'), 'G', "Updated Row");

        $con->txn(sub {
            like(
                dies { $row->update({name => 'GG'}) },
                qr/This row was fetched outside of the current transaction stack/,
                "Did not refresh row after its txn was done, new txn needs a refresh"
            );
        });
    };

    return unless My::ORM::curqdb() =~ m/PostgreSQL/;

    subtest disconnect => sub {
        my $db = My::ORM::curdb();

        my ($e, $w);
        $w = warnings {
            $e = dies {
                $con->txn(sub {
                    my $row = $s->insert({name => 'h'});

                    my $sth = $con->dbh->prepare('select pg_backend_pid()');
                    $sth->execute;
                    my ($pid) = $sth->fetchrow_array;
                    kill(TERM => $pid);
                });
            };
        };

        like($e, qr/server closed the connection unexpectedly/, "Simulated remote disconnect");

        ok(!@{$con->transactions}, "No active transactions");

        $con->reconnect;

        ok($con->all('example'), "Connected");
    };
};

done_testing;
