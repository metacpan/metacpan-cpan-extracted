use Test2::V0 '!meta', '!pass';

# Regression tests for DBIx::QuickORM::DB::new_dbh failure modes: a connect
# callback or DBI->connect that returns undef without throwing must croak
# with a useful message instead of crashing on the undef handle.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

use File::Temp qw/tempdir/;
use DBIx::QuickORM::DB;
use DBIx::QuickORM::Dialect::SQLite;

my $dir = tempdir(CLEANUP => 1);

subtest happy_paths => sub {
    my $db = DBIx::QuickORM::DB->new(
        dialect => 'DBIx::QuickORM::Dialect::SQLite',
        dsn     => "dbi:SQLite:dbname=$dir/a.sqlite",
        name    => 'a',
    );

    my $dbh = $db->new_dbh;
    ok($dbh && $dbh->ping, "new_dbh connects via DSN");
    ok($dbh->{AutoInactiveDestroy}, "AutoInactiveDestroy applied");

    require DBI;
    my $cb_db = DBIx::QuickORM::DB->new(
        dialect => 'DBIx::QuickORM::Dialect::SQLite',
        name    => 'b',
        connect => sub { DBI->connect("dbi:SQLite:dbname=$dir/b.sqlite", '', '', {RaiseError => 1}) },
    );
    ok($cb_db->new_dbh->ping, "new_dbh connects via callback");
};

subtest callback_returns_undef => sub {
    my $db = DBIx::QuickORM::DB->new(
        dialect => 'DBIx::QuickORM::Dialect::SQLite',
        name    => 'c',
        connect => sub { return undef },
    );

    my $err = dies { $db->new_dbh };
    like($err, qr/Could not connect to the database/, "undef from the connect callback croaks instead of crashing");
};

subtest connect_throws => sub {
    my $db = DBIx::QuickORM::DB->new(
        dialect => 'DBIx::QuickORM::Dialect::SQLite',
        name    => 'd',
        connect => sub { die "no database for you\n" },
    );

    my $err = dies { $db->new_dbh };
    like($err, qr/no database for you/, "exceptions from the connect attempt propagate");
};

subtest raiseerror_disabled_connect_failure => sub {
    my $db = DBIx::QuickORM::DB->new(
        dialect    => 'DBIx::QuickORM::Dialect::SQLite',
        dsn        => "dbi:SQLite:dbname=$dir/no/such/dir/x.sqlite",
        name       => 'e',
        attributes => {RaiseError => 0, PrintError => 0},
    );

    my $err = dies { $db->new_dbh };
    like($err, qr/Could not connect to the database/, "a silent DBI->connect failure croaks with context");
};

done_testing;
