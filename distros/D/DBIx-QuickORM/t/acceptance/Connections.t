# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;

our $GLOBAL_ORM;

my %NAMESPACE = (PostgreSQL => 'public', MariaDB => 'quickdb', MySQL => 'quickdb', SQLite => 'main', DuckDB => 'main');

# Runs $code in a forked child and returns its exit status. The child exits normally, as a real program
# would, so the end-of-process cleanup of DBI and the drivers runs there too.
sub in_child {
    my ($code) = @_;
    my $pid = fork // die "Could not fork: $!";
    unless ($pid) {
        my $status = eval { $code->() } // do { print STDERR "child died: $@"; 255 };
        exit $status;
    }
    waitpid($pid, 0);
    return $? >> 8;
}

do_for_all_dbs {
    my ($db, $set) = @_;

    my %creds = (dsn => $db->connect_string, user => $db->username, pass => $db->password);
    my %forms = (
        dbh         => sub { (dbh         => $db->connect) },
        connect     => sub { (connect     => sub { $db->connect }) },
        credentials => sub { (credentials => {%creds}) },
    );

    subtest forms => sub {
        for my $form (sort keys %forms) {
            my $conn = DBIx::QuickORM->new($forms{$form}->())->connection;
            my $dbh  = $conn->dbh;
            is(ref($conn->dialect), "DBIx::QuickORM::Dialect::$set->{family}", "$form: the dialect follows the server");
            like($conn->dialect->server_version, qr/^[1-9][0-9]*$/, "$form: the dialect holds the server version as a number");
            is($conn->dialect->server_version, $dbh->{pg_server_version},  "$form: PostgreSQL's is pg_server_version") if $set->{family} eq 'PostgreSQL';
            is($conn->namespace,               $NAMESPACE{$set->{family}}, "$form: the namespace is the connection's");
            ok($dbh->{RaiseError} && !$dbh->{PrintError} && $dbh->{AutoInactiveDestroy}, "$form: RaiseError on, PrintError off, AutoInactiveDestroy on");
            is($dbh->selectrow_array('SELECT 1'), 1, "$form: the handle works");
        }
    };

    subtest raise_error => sub {
        like(dies { DBIx::QuickORM->new(dbh => $db->connect(undef, RaiseError => 0, AutoCommit => 1)) }, qr/^The database handle must have RaiseError on/, "A dbh with RaiseError off croaks");
        like(
            dies {
                DBIx::QuickORM->new(connect => sub { $db->connect(undef, RaiseError => 0, AutoCommit => 1) })
            },
            qr/^The database handle must have RaiseError on/,
            "A connect sub's handle with RaiseError off croaks"
        );

        my $orm = DBIx::QuickORM->new(credentials => {%creds, attrs => {RaiseError => 0, PrintError => 1}});
        ok($orm->connection->dbh->{RaiseError},  "credentials force RaiseError on");
        ok(!$orm->connection->dbh->{PrintError}, "and PrintError off");
    };

    subtest auto_commit => sub {
        my $off = qr/^The database handle must have AutoCommit on and no transaction open; the ORM manages transactions/;
        like(dies { DBIx::QuickORM->new(dbh => $db->connect(undef, RaiseError => 1, AutoCommit => 0)) }, $off, "A dbh with AutoCommit off croaks");
        like(
            dies {
                DBIx::QuickORM->new(connect => sub { $db->connect(undef, RaiseError => 1, AutoCommit => 0) })
            },
            $off,
            "A connect sub's handle with AutoCommit off croaks"
        );

        my $dbh = $db->connect;
        $dbh->begin_work;
        like(dies { DBIx::QuickORM->new(dbh => $dbh) }, $off, "A dbh with a transaction open croaks");
        $dbh->rollback;

        like(
            dies { DBIx::QuickORM->new(credentials => {%creds, attrs => {AutoCommit => 0}}) },
            qr/^Do not turn AutoCommit off in 'credentials' attrs; the ORM manages transactions/,
            "credentials with AutoCommit off croak",
        );
        ok(DBIx::QuickORM->new(credentials => {%creds, attrs => {AutoCommit => 1}})->connection->dbh->{AutoCommit}, "credentials with AutoCommit on are accepted");
    };

    subtest no_database => sub {
        skip_all "only the MySQL family can connect without a current namespace" unless $set->{family} =~ m/^(?:MySQL|MariaDB)$/;
        (my $dsn = $creds{dsn}) =~ s/dbname=[^;]*;?//;
        like(
            dies { DBIx::QuickORM->new(credentials => {%creds, dsn => $dsn}) },
            qr/^The connection has no current schema or database; select one in the DSN/,
            "A connection with no database selected croaks",
        );
    };

    subtest dbh_form => sub {
        my $orm = DBIx::QuickORM->new(dbh => $db->connect);
        like(dies { $orm->connector->() }, qr/^This ORM was given a 'dbh', so it cannot open another database connection/, "The handle is returned once");

        my $status = in_child(sub {
            my $err = dies { $orm->connection };
            # A database no second connection can open says so first.
            return defined($err) && $err =~ m/^(?:This ORM was given a 'dbh', so it cannot open another database connection|This ORM's database cannot be opened by a second connection)/ ? 0 : 2;
        });
        is($status,                                            0, "A forked child croaks instead of reconnecting");
        is($orm->connection->dbh->selectrow_array('SELECT 1'), 1, "The parent's connection still works");
    };

    subtest fork_reconnect => sub {
        for my $form (qw/connect credentials/) {
            my $orm    = DBIx::QuickORM->new($forms{$form}->());
            my $parent = $orm->connection;
            my $shared = $parent->dialect->supports_second_connection($parent->dbh);

            my $status = in_child(sub {
                my $conn = eval { $orm->connection };
                return $@ =~ m/^This ORM's database cannot be opened by a second connection/ ? 10 : 2 unless $conn;
                return 3 if $conn == $parent;
                return 4 unless $conn->pid == $$;
                return 5 unless $conn->dbh->selectrow_array('SELECT 1') == 1;
                return 6 unless $orm->connection == $conn;
                return 0;
            });

            if ($shared) {
                is($status, 0, "$form: a forked child gets a fresh Connection of its own");
            }
            else {
                is($status, 10, "$form: a forked child cannot open a second connection to the database, and croaks with our message");
            }
            ref_is($orm->connection, $parent, "$form: the parent keeps its Connection");
            is($parent->dbh->selectrow_array('SELECT 1'), 1, "$form: and its session");
        }
    };

    subtest fork_untouched => sub {
        my $orm    = DBIx::QuickORM->new(connect => sub { $db->connect });
        my $parent = $orm->connection;

        is(in_child(sub { 0 }),                       0, "A child that never uses the ORM exits");
        is($parent->dbh->selectrow_array('SELECT 1'), 1, "and the parent's session survives");

        $GLOBAL_ORM = $orm;
        is(in_child(sub { 0 }),                       0, "A child exits with the ORM still alive in a global");
        is($parent->dbh->selectrow_array('SELECT 1'), 1, "and the parent's session survives");
        $GLOBAL_ORM = undef;
    };
};

done_testing;
