package SessionPgTest::PgDB;
use strict;
use warnings;
use English qw( -no_match_vars );

# A throwaway PostgreSQL database for the tests that need one, on a cluster that
# is already running. It is deliberately self-contained: a distribution headed
# for CPAN cannot need anything but its own prerequisites to run its own tests.
#
# Perl 5.12, as the module: no signatures, no s///r.
#
# Usage: provision returns a live handle and the database name, or nothing with
# $SessionPgTest::PgDB::REASON set, which a caller passes to skip_all.
#
# The database is created with `createdb` as the current OS user (PGHOST,
# PGPORT and PGUSER are honoured) and dropped at exit BY ITS EXACT NAME, after
# the handle is disconnected -- dropdb refuses a database that still has a
# session, and a test that leaks one leaves it behind for good.
# SESSION_PG_TEST_KEEP_DB=1 keeps it for inspection.

use DBI ();

our $REASON;
my @CLEANUP;

END { $_->() for @CLEANUP }

sub provision {
    undef $REASON;
    my $name = sprintf 'session_pg_test_%d_%d', $PID, int rand 1_000_000;

    if ( system( 'createdb', $name ) != 0 ) {
        $REASON = 'createdb failed: no reachable PostgreSQL cluster where this user may create databases';
        return ();
    }

    # RaiseError is on, so this THROWS on failure -- and at this point createdb
    # has already succeeded while nothing is registered in @CLEANUP yet. Left
    # bare it turns a skip into a hard failure AND leaks the database, which
    # defeats the whole point of returning a reason instead of dying: a cluster
    # that accepts createdb but refuses a connection (pg_hba, a vanished socket,
    # max_connections) is exactly the case this function exists to skip on.
    my $dbh = eval { DBI->connect( "dbi:Pg:dbname=$name", q{}, q{}, { AutoCommit => 1, RaiseError => 1, PrintError => 0 } ); };

    if ( !$dbh ) {
        my $why = $EVAL_ERROR || 'DBI->connect returned no handle';
        $why =~ s/\s+\z//msx;
        system 'dropdb', '--if-exists', $name;    # nothing is registered yet, so drop it here
        $REASON = "created database '$name' but could not connect to it: $why";
        return ();
    }

    if ( $ENV{'SESSION_PG_TEST_KEEP_DB'} ) {
        push @CLEANUP, sub { warn "SessionPgTest::PgDB: database '$name' KEPT; drop it with: dropdb $name\n" };
    } else {
        push @CLEANUP, sub {
            eval { $dbh->disconnect if $dbh };

            # Disconnecting OUR handle is not enough. Anything else holding a
            # connection to this database -- an engine built with a dsn, which
            # opens its own -- keeps dropdb from working, and dropdb then exits
            # non-zero and leaves the database behind. A file-scoped `my $engine`
            # happens to be released before END runs, which is the only reason
            # this has not been leaking; a package variable would not be.
            #
            # So evict the other backends first, from a connection to another
            # database, and then say so if dropdb still fails.
            _terminate_backends($name);

            if ( system( 'dropdb', '--if-exists', $name ) != 0 ) {
                warn "SessionPgTest::PgDB: could not drop database '$name'; " . "drop it by hand with: dropdb $name\n";
            }
        };
    }
    return ( $dbh, $name );
}

# Ask PostgreSQL to close every other connection to this throwaway database.
# Connects to `postgres`, because a backend cannot terminate the database it is
# itself attached to. Best effort: if this fails there is nothing useful to do
# about it, and the dropdb that follows will report the real problem.
sub _terminate_backends {
    my ($name) = @_;

    my $admin = eval { DBI->connect( 'dbi:Pg:dbname=postgres', q{}, q{}, { AutoCommit => 1, RaiseError => 1, PrintError => 0 } ); };
    return if !$admin;

    eval {
        $admin->do(
            'SELECT pg_terminate_backend(pid) FROM pg_stat_activity
              WHERE datname = ? AND pid <> pg_backend_pid()', undef, $name
        );
        1;
    };
    eval { $admin->disconnect };

    return;
}

1;
