#!perl
use strict;
use warnings;
use English qw( -no_match_vars );

# $data follows the Dancer2::Core::Role::SessionFactory contract.
## no critic (Bangs::ProhibitVagueNames)

# What happens when more than one worker writes the same session.
#
# This is the claim that justifies INSERT ... ON CONFLICT DO UPDATE over a
# SELECT-then-UPDATE, and until now it was only a claim. Everything here uses
# REAL PROCESSES, because that is the only arrangement that exercises the
# database's own locking: two DBI handles in one process cannot block on each
# other without deadlocking the test.
#
# Nothing here measures elapsed time or sleeps to create a race. Each subtest
# asserts an outcome that is true however the processes happen to interleave:
# one row, no errors, an expiry that no later write moved, and a payload that
# decrypts. The one thing that is NOT deterministic -- WHICH worker's data
# survives -- is asserted as "one of them", because last-writer-wins is what a
# blob session store can promise and the POD now says so.
#
# A FORKED CHILD HERE MUST CALL POSIX::_exit. SessionPgTest::PgDB registers an
# END block that drops the test database; a child exiting normally would run it
# and pull the database out from under the parent. _exit skips END blocks and
# destructors, which also stops the child from closing the libpq socket it
# inherited and corrupting the parent's connection.

use Test2::V1 qw( -utf8 -x ), -include => [ [ 'Test2::Tools::Subtest', 'subtest_streamed' ] ];

use Config      qw( %Config );
use Time::HiRes qw( time );
use List::Util  qw( max min );
use File::Temp  qw( tempfile );
use Carp        qw( croak );
use POSIX       ();

use FindBin qw( $Bin );    ## no critic (Community::DiscouragedModules) -- how a test finds t/lib; the warning is for applications
use lib "$Bin/lib";
use SessionPgTest::PgDB   ();
use SessionPgTest::Ddl    ();
use Dancer2::Session::Pg  ();
use Crypt::Digest::SHA256 qw( sha256_hex );

# The id column holds SHA-256 of the session id, so a test reaching into the
# table by id has to hash it the same way the engine does.
sub rid { my ($id) = @_; return sha256_hex($id) }

use DBI ();

T2->skip_all('this platform cannot fork, so real concurrency cannot be tested')
  if !$Config{'d_fork'};

my ($dbh) = SessionPgTest::PgDB::provision() or T2->skip_all($SessionPgTest::PgDB::REASON);

my $SCHEMA = 'conc';
SessionPgTest::Ddl::apply( $dbh, $SCHEMA, 'DDL without the principal column' )
  or T2->skip_all("could not apply the documented DDL: $SessionPgTest::Ddl::REASON");

my $DSN    = 'dbi:Pg:' . $dbh->{'Name'};
my $DBUSER = $dbh->{'Username'};
my $KEY32  = 'a' x 64;
my $CAP    = 900;

# Turn these up in CI to lean on it harder; the assertions do not depend on the
# numbers. Each worker opens ONE connection, so keep the count below the
# server max_connections -- 32 has been exercised here against a default 100.
my $WORKERS = $ENV{'SESSION_PG_TEST_WORKERS'} || 8;
my $WRITES  = $ENV{'SESSION_PG_TEST_WRITES'}  || 25;

sub engine {
    my (%args) = @_;
    return Dancer2::Session::Pg->new(
        dsn              => $DSN,
        dbuser           => $DBUSER,
        dbschema         => $SCHEMA,
        dbtable          => 'sessions',
        encryption_keys  => { 0 => { key => $KEY32, alg => q{AES-256-GCM}, active => 1 } },
        session_duration => $CAP,
        %args,
    );
}

# Run $code in a forked child. The child reports only through its exit status
# and, on failure, one line in a file -- it makes no assertions, so Test2 needs
# no IPC and a crashing child cannot corrupt the parent's plan.
sub in_child {    ## no critic (Subroutines::RequireFinalReturn) -- the child branch ends in POSIX::_exit, which never returns
    my ( $code, $error_file ) = @_;

    my $pid = fork;
    croak "fork failed: $OS_ERROR" if !defined $pid;
    return $pid                    if $pid;

    my $ok = eval { $code->(); 1 };
    if ( !$ok && defined $error_file ) {
        my $error = $EVAL_ERROR;
        $error =~ s/\n.*//msx;
        if ( open my $out, '>>', $error_file ) {
            print {$out} "$error\n" or POSIX::_exit(1);
            close $out              or POSIX::_exit(1);
        }
    }
    POSIX::_exit( $ok ? 0 : 1 );
}

# WITHOUT THIS THE SUBTESTS BELOW PROVE NOTHING. Forking N workers in a loop
# does not make them run at once: the parent forks them one at a time, and
# worker 1 can finish all its writes before worker N is created. Every
# assertion here would still hold -- one row, the cap intact, a payload that
# decrypts -- because those are true of serial writes too. The test would pass
# while never once exercising the contention it is named for.
#
# So: every child blocks on a pipe until the parent closes the write end, which
# releases all of them at the same instant. A pipe rather than a sleep, because
# a sleep is a guess about scheduling and this is not.
sub _wait_at_gate {
    my ( $reader, $writer ) = @_;

    # The child inherits the write end too, and while ANY copy is open there is
    # no EOF -- so the child closing its own copy is what makes the gate work.
    close $writer or POSIX::_exit(1);
    my $ignored = q{};

    # 0 at EOF IS the signal here, so there is no return value worth checking.
    read $reader, $ignored, 1;
    return;
}

# Fork $count workers that all start at the same instant, and hand each one its
# own number. The pipe, the gate and the release live here rather than in every
# subtest that needs them -- the plumbing is identical and saying it twice
# invites the two copies to drift.
sub fork_at_gate {
    my ( $count, $error_file, $code ) = @_;

    pipe my $gate_r, my $gate_w or croak "pipe failed: $OS_ERROR";

    my @pids;
    for my $worker ( 1 .. $count ) {
        push @pids, in_child(
            sub {
                _wait_at_gate( $gate_r, $gate_w );
                $code->($worker);
            },
            $error_file,
        );
    }

    # Every worker is now blocked on the gate. This opens it, for all at once.
    close $gate_w or croak "cannot close the gate: $OS_ERROR";
    return @pids;
}

# Each worker reports the wall-clock span it was busy for, so the parent can
# show that the workers really overlapped rather than taking turns.
sub _note_span {
    my ( $path, $started ) = @_;
    open my $out, '>>', $path or POSIX::_exit(1);
    printf {$out} "%.6f %.6f\n", $started, time or POSIX::_exit(1);
    close $out or POSIX::_exit(1);
    return;
}

sub _spans {
    my ($path) = @_;
    my @spans;
    open my $in, '<', $path or croak "cannot read $path: $OS_ERROR";
    while ( my $line = <$in> ) {
        chomp $line;
        push @spans, [ $1, $2 ] if $line =~ m/\A([0-9.]+)[ ]([0-9.]+)\z/msx;    ## no critic (RegularExpressions::ProhibitEnumeratedClasses) -- [0-9.] is an ASCII float, not a Unicode digit class
    }
    close $in or croak "cannot close $path: $OS_ERROR";
    return @spans;
}

# Collective busy time over wall-clock time. Workers taking turns give ~1;
# workers running together give ~N. This does not measure the scheduler -- the
# point is only to notice if this subtest ever stops being concurrent.
sub _overlap {
    my (@spans) = @_;
    return ( 0, 0, 0 ) if !@spans;

    my $busy = 0;
    $busy += $_->[1] - $_->[0] for @spans;
    my $wall = max( map { $_->[1] } @spans ) - min( map { $_->[0] } @spans );

    return ( $wall > 0 ? $busy / $wall : 0, $busy, $wall );
}

sub _slurp {
    my ($path) = @_;
    open my $in, '<', $path or croak "cannot read $path: $OS_ERROR";
    local $INPUT_RECORD_SEPARATOR = undef;
    my $content = <$in>;
    close $in or croak "cannot close $path: $OS_ERROR";
    return defined $content ? $content : q{};
}

sub reap_children {
    my (@pids) = @_;
    my $failed = 0;
    for my $pid (@pids) {
        waitpid $pid, 0;
        $failed++ if $CHILD_ERROR != 0;
    }
    return $failed;
}

T2->subtest_streamed(
    "$WORKERS processes writing ONE session id" => sub {
        my ( $fh, $error_file ) = tempfile( UNLINK => 1 );
        close $fh or croak "cannot close the temporary file: $OS_ERROR";

        my ( $sfh, $span_file ) = tempfile( UNLINK => 1 );
        close $sfh or croak "cannot close the temporary file: $OS_ERROR";

        my @pids = fork_at_gate(
            $WORKERS,
            $error_file,
            sub {
                my ($worker) = @_;
                my $engine   = engine();
                my $started  = time;
                $engine->_flush( 'hot', { writer => $worker, n => $_ } ) for 1 .. $WRITES;
                _note_span( $span_file, $started );
            }
        );

        my $failed = reap_children(@pids);

        my $errors = _slurp($error_file);
        T2->is( $failed, 0,   "all $WORKERS workers completed " . $WORKERS * $WRITES . ' writes without error' );
        T2->is( $errors, q{}, 'and nothing was recorded -- no deadlock, no unique violation' )
          or T2->diag($errors);

        # AND THE WORKERS REALLY OVERLAPPED, which is the part a passing
        # assertion above does not establish. If they had taken turns, the time
        # they were collectively busy would equal the wall-clock time the whole
        # thing took; running at once, it is a multiple of it. Stated as a ratio
        # rather than an absolute so it means the same on a fast machine and a
        # loaded one, and loosely (1.5x of a possible 8x) so it is not flaky --
        # this exists to catch a test that has stopped being concurrent, not to
        # measure the scheduler.
        my @spans = _spans($span_file);
        T2->is( scalar @spans, $WORKERS, 'every worker reported the span it was busy for' );

        my ( $ratio, $busy, $wall ) = _overlap(@spans);
        T2->ok(
            $ratio > 1.5,
            sprintf 'and they ran CONCURRENTLY: %.1fx overlap (%.3fs of work in %.3fs of wall clock)',
            $ratio, $busy, $wall
        ) or T2->diag('the workers appear to have run one after another, so this subtest did not test contention');

        my ($rows) = $dbh->selectrow_array( "SELECT count(*) FROM $SCHEMA.sessions WHERE id = ?", undef, rid('hot') );
        T2->is( $rows, 1, 'ON CONFLICT left exactly one row, not one per worker' );

        # THE INVARIANT THAT MATTERS FOR SECURITY. `expires` and `created` are both
        # set from the same now() by the first INSERT and are excluded from the
        # conflict assignment, so this equality holds exactly -- and it holding
        # after N*M concurrent writes is the proof that no race moves the cap.
        my ($cap_intact) = $dbh->selectrow_array(
            "SELECT expires = created + interval '$CAP seconds'
           FROM $SCHEMA.sessions WHERE id = ?", undef, rid('hot')
        );
        T2->ok( $cap_intact, 'and the expiry cap is still the one the FIRST write set' );

        my $data = engine()->_retrieve('hot');
        T2->ok( defined $data, 'the surviving payload decrypts -- no interleaved write tore it' );
        T2->is( $data->{'n'}, $WRITES, 'and it is a LAST write: whichever worker finished last, it finished' );
        T2->ok(
            $data->{'writer'} >= 1 && $data->{'writer'} <= $WORKERS,
            'by one of the workers -- which one is a race, and is not promised'
        );
    }
);

T2->subtest_streamed(
    'concurrent writers to DIFFERENT ids all land' => sub {
        my ( $fh, $error_file ) = tempfile( UNLINK => 1 );
        close $fh or croak "cannot close the temporary file: $OS_ERROR";

        my @pids = fork_at_gate(
            $WORKERS,
            $error_file,
            sub {
                my ($worker) = @_;
                engine()->_flush( "own-$worker", { writer => $worker } );
            }
        );

        T2->is( reap_children(@pids), 0, 'every worker wrote its own session' );

        # No prefix match: the column holds digests, which share no prefix with
        # each other or with the session ids. Ask for the exact set instead.
        my $wanted = join q{,}, map { $dbh->quote( rid("own-$_") ) } 1 .. $WORKERS;
        my ($rows) = $dbh->selectrow_array("SELECT count(*) FROM $SCHEMA.sessions WHERE id IN ($wanted)");
        T2->is( $rows, $WORKERS, "all $WORKERS rows are present" );

        my $engine = engine();
        my @wrong  = grep { ( $engine->_retrieve("own-$_") || {} )->{'writer'} ne $_ } 1 .. $WORKERS;
        T2->is( [@wrong], [], 'and each one holds its own writer, not another worker data' );
    }
);

# A session is not worth waiting on: the module sets statement_timeout on every
# connection it opens precisely so that a write which cannot proceed FAILS
# instead of holding a worker open indefinitely. Here a transaction nobody
# commits holds the row, which is the shape of the problem -- an administrative
# query, a migration, a stuck pool connection -- and the writer must give up.
T2->subtest_streamed(
    'a writer blocked on an open transaction is cut off, not hung' => sub {
        my ( $fh, $error_file ) = tempfile( UNLINK => 1 );
        close $fh or croak "cannot close the temporary file: $OS_ERROR";

        my $holder = DBI->connect( $DSN, $DBUSER, undef, { RaiseError => 1, PrintError => 0, AutoCommit => 0 } );

        # The DIGEST, not the session id: the engine writes digests, so an
        # insert of the raw id would take a different row and there would be
        # nothing to block on.
        $holder->do(
            "INSERT INTO $SCHEMA.sessions (id, session_data, expires)
                  VALUES (?, '\\x00', now() + interval '$CAP seconds')",
            undef, rid('blocked')
        );

        # Still uncommitted, so the row is invisible but its id is taken: a second
        # INSERT ... ON CONFLICT has to wait to find out which.
        my $pid    = in_child( sub { engine( statement_timeout => 400 )->_flush( 'blocked', { who => 'child' } ) }, $error_file, );
        my $failed = reap_children($pid);

        $holder->rollback;
        $holder->disconnect;

        my $errors = _slurp($error_file);
        T2->is( $failed, 1, 'the blocked write FAILED rather than waiting for a commit that never came' );
        T2->like(
            $errors,
            qr/statement[ ]timeout/msx,
            'and it was statement_timeout that stopped it, which is the mechanism documented'
        );

        # The rollback removed the holder's row, so the id is free again and an
        # ordinary write works. The failure was transient, not a poisoned session.
        T2->ok(
            eval { engine()->_flush( 'blocked', { who => 'after' } ); 1 },
            'once the transaction ends, the same id writes normally'
        );
        T2->is( engine()->_retrieve('blocked'), { who => 'after' }, 'and reads back' );
    }
);

# Spelled out as a test because it is the one thing concurrency here does NOT
# give you, and a reader who assumes otherwise will be wrong in a way that is
# hard to see: the payload is one encrypted blob, so a writer overwrites all of
# it. Two workers that each read, change one key and write back do not merge --
# the second wins outright. This needs no fork; it is sequential by
# construction, which is exactly how it happens across two requests.
T2->subtest_streamed(
    'last writer wins, which is all a blob store can promise' => sub {
        my $engine = engine();
        $engine->_flush( 'rmw', { cart => ['apple'], step => 'start' } );

        my $as_read_by_a = $engine->_retrieve('rmw');
        my $as_read_by_b = $engine->_retrieve('rmw');

        $as_read_by_a->{'cart'} = [ 'apple', 'pear' ];    # worker A adds to the cart
        $engine->_flush( 'rmw', $as_read_by_a );

        $as_read_by_b->{'step'} = 'address';              # worker B advances the wizard
        $engine->_flush( 'rmw', $as_read_by_b );

        my $final = $engine->_retrieve('rmw');
        T2->is( $final->{'step'}, 'address', 'the second writer change is there' );
        T2->is( $final->{'cart'}, ['apple'], 'and the FIRST writer change is GONE -- the whole payload was replaced' );

        my ($rows) = $dbh->selectrow_array( "SELECT count(*) FROM $SCHEMA.sessions WHERE id = ?", undef, rid('rmw') );
        T2->is( $rows, 1, 'no duplicate row came of it, which is the part ON CONFLICT does promise' );
    }
);

T2->done_testing;
