package DBIx::QuickORM::Manual::Errors;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Errors - Database errors, their kinds, and retrying, by example.

=head1 DESCRIPTION

A DBI error on the ORM's connected handle is thrown as a
L<DBIx::QuickORM::Exception::DB> object that says what kind of error it was
and whether trying again may help. The ORM's own complaints (a misused
method, a refused write) are plain strings. A C<forked> query reports its
child's error as text (L<DBIx::QuickORM::Manual::Background>).

=head1 SCHEMA

The examples use PostgreSQL and this schema:

=for highlighter language=sql

    CREATE TABLE users (
        id          SERIAL PRIMARY KEY,
        name        TEXT NOT NULL,
        email       TEXT UNIQUE,
        prefs       JSON,
        referred_by INTEGER REFERENCES users (id),
        created     TIMESTAMP NOT NULL DEFAULT now()
    );

    CREATE TABLE posts (
        id      SERIAL PRIMARY KEY,
        user_id INTEGER NOT NULL REFERENCES users (id),
        title   TEXT NOT NULL,
        views   INTEGER NOT NULL DEFAULT 0
    );

=head1 CATCHING A DATABASE ERROR

=for highlighter language=perl

    use Scalar::Util qw/blessed/;

    my $ann = $orm->insert(users => {
        name  => 'Ann',
        email => 'ann@example.com',
    });

    my $ok = eval {
        $orm->insert(users => {
            name  => 'Ann Again',
            email => 'ann@example.com',    # the address is taken
        });
        1;
    };
    my $err = $@;
    unless ($ok) {
        die $err unless blessed($err) && $err->isa('DBIx::QuickORM::Exception::DB');
        die $err unless ($err->kind // '') eq 'unique_violation';
        # tell the user the address is taken
    }

=head1 WHAT AN ERROR CARRIES

    my $kind    = $err->kind;         # 'unique_violation'
    my $state   = $err->state;        # '23505': the SQLSTATE, when the driver reports one
    my $native  = $err->native;       # the driver's own code
    my $text    = $err->errstr;       # the driver's message
    my $sql     = $err->statement;    # the INSERT that failed
    my $message = "$err";             # DBI's message: matching $@ against DBI's text still works

    # 0 here, 1 for a deadlock, serialization failure, or lock timeout,
    # and undef when the kind is unknown
    my $retriable = $err->retriable;

The kinds, the same on every database: C<unique_violation>,
C<foreign_key_violation>, C<not_null_violation>, C<check_violation>,
C<deadlock>, C<serialization_failure>, C<lock_timeout>, or undef when the
dialect cannot tell.

SQLite and the MySQL family report native codes rather than useful SQLSTATEs.
DuckDB reports the same code and SQLSTATE for every error, so the ORM
classifies its message (L<DBIx::QuickORM::Manual::Dialects/ERRORS>).

=head1 THE ORM'S OWN ERRORS

    my $croaked = !eval { $orm->insert(users => {nope => 1}); 1 };
    my $plain   = !ref($@);    # true: a complaint about how the ORM was called is a plain string

=head1 UNKNOWN ERRORS

    # a scalar reference: a handle over SQL you write
    my $failed = !eval { $orm->handle(\'SELECT * FROM no_such_table')->all; 1 };

    # true: a syntax error, a missing table, a lost connection (retriable is undef too)
    my $unknown = blessed($@) && !defined $@->kind;

=head1 DEADLOCKS AND SERIALIZATION FAILURES

    my $post_id = $orm->insert(posts => {
        user_id => $ann->field('id'),
        title   => 'Hello',
    })->field('id');

    $orm->txn(
        sub {
            my $post = $orm->find(posts => $post_id);
            $post->update({views => $post->field('views') + 1});
        },
        isolation => 'serializable',    # a conflicting write is then a serialization failure
        # the whole block runs again, in a new transaction, up to 3 more times
        retry     => 3,
    );

These errors mean the database gave up on the transaction, and running it
again usually succeeds, so C<retry> is the answer. C<< retry => 3 >> allows
four attempts. The last failure is rethrown, as is any error that is not
retriable.

The block must be safe to run again: anything it did outside the database
happens again too.

At the default C<read committed> level a read-then-write like this does not
fail at all: it silently overwrites.
L<DBIx::QuickORM::Manual::Transactions/RETRY> shows the alternatives.

=head1 AFTER AN ERROR IN A TRANSACTION

    my $txn = $orm->txn;
    my $dup = !eval {
        $orm->insert(users => {
            name  => 'Dup',
            email => 'ann@example.com',
        });
        1;
    };

    # after an error every statement croaks until the transaction is rolled back
    $txn->rollback;

    $orm->txn(sub {
        my $ok = eval {
            $orm->txn(sub {    # a savepoint: the error rolls back only this insert
                $orm->insert(users => {
                    name  => 'Dup',
                    email => 'ann@example.com',
                });
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

A failed statement marks its transaction failed, on every database, even
when the error is caught: then only a rollback may follow, and a commit rolls
back and croaks. See
L<DBIx::QuickORM::Manual::Transactions/"A FAILED STATEMENT">.

A block's exception rolls its transaction back by itself and is rethrown.
With the object form, roll back yourself. The inner block above rolls back to
its savepoint and rethrows. A bare C<eval> would swallow every error, so keep
only the one you expect.

DuckDB has no savepoints, so the nested form croaks there: roll the whole
transaction back instead. See L<DBIx::QuickORM::Manual::Transactions>.

=cut

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
