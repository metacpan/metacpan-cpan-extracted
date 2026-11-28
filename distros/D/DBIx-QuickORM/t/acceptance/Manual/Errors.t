# Test origin: AI
# This test runs copies of the code examples in lib/DBIx/QuickORM/Manual/Errors.pm. Whenever an
# example there changes, change its copy here to match: t/acceptance/Examples.t fails while any
# example has no copy in an example test.
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test::Examples;

do_for_pg {
    my ($db) = @_;
    $db->connect->do($SCHEMA);
    my $orm = DBIx::QuickORM->new(connect => sub { $db->connect });
    my $dbh = $orm->connection->dbh;

    # CATCHING A DATABASE ERROR
    use Scalar::Util qw/blessed/;

    my $ann = $orm->insert(
        users => {
            name  => 'Ann',
            email => 'ann@example.com',
        }
    );

    my $ok = eval {
        $orm->insert(
            users => {
                name  => 'Ann Again',
                email => 'ann@example.com',    # the address is taken
            }
        );
        1;
    };
    my $err = $@;
    unless ($ok) {
        die $err unless blessed($err) && $err->isa('DBIx::QuickORM::Exception::DB');
        die $err unless ($err->kind // '') eq 'unique_violation';
        # tell the user the address is taken
    }

    ok(!$ok, "the duplicate email fails");
    isa_ok($err, ['DBIx::QuickORM::Exception::DB'], "with a database exception");

    # WHAT AN ERROR CARRIES
    my $kind    = $err->kind;         # 'unique_violation'
    my $state   = $err->state;        # '23505': the SQLSTATE, when the driver reports one
    my $native  = $err->native;       # the driver's own code
    my $text    = $err->errstr;       # the driver's message
    my $sql     = $err->statement;    # the INSERT that failed
    my $message = "$err";             # DBI's message: matching $@ against DBI's text still works

    # 0 here, 1 for a deadlock, serialization failure, or lock timeout,
    # and undef when the kind is unknown
    my $retriable = $err->retriable;

    is($kind,  'unique_violation', "the kind");
    is($state, '23505',            "the SQLSTATE");
    ok(defined $native, "the native code");
    like($text, qr/duplicate key/,        "the driver's message");
    like($sql,  qr/^INSERT INTO "users"/, "the statement");
    is($retriable, 0, "a constraint violation is not retriable");
    like($message, qr/duplicate key/, "the exception stringifies to DBI's message");
    like(dies { $orm->insert(posts => {user_id => 999, title => 'x'}) }, object { call kind => 'foreign_key_violation'; call retriable => 0 }, "a foreign key violation");
    like(dies { $orm->insert(users => {name    => undef}) },             object { call kind => 'not_null_violation' },                         "a NOT NULL violation");

    # THE ORM'S OWN ERRORS
    my $croaked = !eval { $orm->insert(users => {nope => 1}); 1 };
    my $plain   = !ref($@);                                          # true: a complaint about how the ORM was called is a plain string

    ok($croaked, "an unknown field croaks");
    ok($plain,   "with a plain string");
    like($@, qr/^The table 'users' has no field 'nope'/, "saying what was wrong");
    my $stale = $orm->find(users => $ann);
    $orm->clear_cache;
    ok(!eval { $stale->update({name => 'Ann B'}); 1 }, "a refused write");
    ok(!ref($@),                                       "is a plain string too");
    like($@, qr/is not canon/, "naming the problem");

    # UNKNOWN ERRORS
    # a scalar reference: a handle over SQL you write
    my $failed = !eval { $orm->handle(\'SELECT * FROM no_such_table')->all; 1 };
    # true: a syntax error, a missing table, a lost connection (retriable is undef too)
    my $unknown = blessed($@) && !defined $@->kind;

    ok($failed,  "a missing table is a database error");
    ok($unknown, "of no kind");
    is($@->retriable, undef, "and unknown retriability");

    # DEADLOCKS AND SERIALIZATION FAILURES
    my $other   = $db->connect;
    my $updates = 0;

    # The first run reads the row, then another session changes it before the update: under SERIALIZABLE a serialization failure.
    my $conflict = sub { $other->do("UPDATE posts SET views = $_[0] WHERE title = 'Hello'") if $_[1] =~ m/^UPDATE/ && !$updates++; return };
    my $watch    = on_execute { $conflict->(100, $_[0]) };

    my $post_id = $orm->insert(
        posts => {
            user_id => $ann->field('id'),
            title   => 'Hello',
        }
    )->field('id');

    $orm->txn(
        sub {
            my $post = $orm->find(posts => $post_id);
            $post->update({views => $post->field('views') + 1});
        },
        isolation => 'serializable',    # a conflicting write is then a serialization failure

        # the whole block runs again, in a new transaction, up to 3 more times
        retry => 3,
    );

    undef $watch;
    is($updates,                                                  2,   "the first run hit a serialization failure, and the block ran again");
    is($orm->find(posts => $post_id, cache => 0)->field('views'), 101, "the second run saw the other session's value");

    $updates = 0;
    {
        my $watch = on_execute { $conflict->(200, $_[0]) };
        my $err   = dies {
            $orm->txn(
                sub {
                    my $post = $orm->find(posts => $post_id);
                    $post->update({views => $post->field('views') + 1});
                },
                isolation => 'serializable',
            );
        };
        is($err->kind,      'serialization_failure', "the conflict is a serialization failure");
        is($err->retriable, 1,                       "which is retriable");
    }

    {
        my $watch = on_execute { $other->do("UPDATE posts SET views = views + 1 WHERE id = $post_id") if $_[0] =~ m/^UPDATE/ };
        my $tries = 0;
        my $err   = dies {
            $orm->txn(
                sub {
                    $tries++;
                    my $post = $orm->find(posts => $post_id);
                    $post->update({views => $post->field('views') + 1});
                },
                isolation => 'serializable',
                retry     => 3,
            );
        };
        is($tries,     4,                       "retry => 3 allows four attempts");
        is($err->kind, 'serialization_failure', "then the last failure is rethrown");
        $tries = 0;
        like(
            dies {
                $orm->txn(sub { $tries++; die "plain\n" }, retry => 3)
            },
            qr/^plain$/,
            "an error that is not retriable is rethrown at once"
        );
        is($tries, 1, "without another attempt");
    }

    $updates = 0;
    {
        my $views = $orm->find(posts => $post_id, cache => 0)->field('views');
        my $watch = on_execute { $conflict->(300, $_[0]) };
        $orm->txn(sub {
            my $post = $orm->find(posts => $post_id);
            $post->update({views => $post->field('views') + 1});
        });
        is($orm->find(posts => $post_id, cache => 0)->field('views'), $views + 1, "at the default level the read-then-write overwrites the other session's 300 without an error");
    }

    # AFTER AN ERROR IN A TRANSACTION
    my $txn = $orm->txn;
    my $dup = !eval {
        $orm->insert(
            users => {
                name  => 'Dup',
                email => 'ann@example.com',
            }
        );
        1;
    };
    # after an error every statement croaks until the transaction is rolled back
    $txn->rollback;

    $orm->txn(sub {
        my $ok = eval {
            $orm->txn(sub {    # a savepoint: the error rolls back only this insert
                $orm->insert(
                    users => {
                        name  => 'Dup',
                        email => 'ann@example.com',
                    }
                );
            });
            1;
        };
        unless ($ok) {
            my $err = $@;
            # rethrow anything unexpected
            die $err unless blessed($err) && $err->isa('DBIx::QuickORM::Exception::DB');
            die $err unless ($err->kind // '') eq 'unique_violation';
        }
        $orm->insert(users => {name => 'Bob'});    # the transaction goes on
    });

    ok($dup, "the duplicate fails inside the transaction");
    is([map { $_->field('name') } $orm->handle('users')->order_by('id')->all], ['Ann', 'Bob'], "a savepoint takes the error and the transaction commits the rest");
    {
        my $txn = $orm->txn;
        ok(!eval { $orm->insert(users => {name => 'Dup', email => 'ann@example.com'}); 1 }, "an error inside a transaction");
        like(dies { $orm->handle('users')->count }, qr/^A statement in the transaction opened at .* failed, so the transaction can only be rolled back/, "leaves every statement croaking until the transaction ends");
        $txn->rollback;
        is($orm->handle('users')->count, 2, "after which the connection works again");
    }
    like(
        dies {
            $orm->txn(sub {
                my $ok = eval {
                    $orm->txn(sub { $orm->insert(users => {nope => 1}) });
                    1;
                };
                unless ($ok) {
                    my $err = $@;
                    die $err unless blessed($err) && ($err->kind // '') eq 'unique_violation';
                }
            });
        },
        qr/has no field 'nope'/,
        "an unexpected error is rethrown and rolls the whole transaction back"
    );
    is($orm->handle('users')->count, 2, "leaving the table as it was");
};

done_testing;
