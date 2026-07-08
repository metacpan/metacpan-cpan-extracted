use Test2::V0 '!meta', '!pass';
use DBI;
use File::Temp qw/tempdir/;

# The dialect auto-detects volatile columns during introspection: generated,
# identity/auto-increment, and server-default columns are flagged volatile
# (only the existence of a default matters, not its value). A plain NOT NULL
# column with no default is not.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $dsn  = "dbi:SQLite:dbname=$dir/vol.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do(<<'    SQL');
        CREATE TABLE widgets (
            id         INTEGER PRIMARY KEY AUTOINCREMENT,
            name       TEXT NOT NULL,
            status     TEXT NOT NULL DEFAULT 'new',
            full_label TEXT GENERATED ALWAYS AS (name || ':' || status) VIRTUAL
        )
    SQL
    $dbh->disconnect;
}

my $con    = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $table  = $con->schema->table('widgets');

ok($table->column('id')->volatile,         "AUTOINCREMENT identity column is auto-volatile");
ok($table->column('full_label')->volatile, "generated column is auto-volatile");
ok($table->column('status')->volatile,     "a server-default column is auto-volatile");
ok(!$table->column('name')->volatile,      "a plain NOT NULL column with no default is not volatile");

# The MySQL 'NULL'-string quirk: a nullable column with no default must not be
# mistaken for having one. SQLite reports SQL NULL here, but assert the shape
# directly against the helper so the intent is explicit and engine-independent.
require DBIx::QuickORM::Dialect;
my $dia = $con->dialect;
ok(!$dia->_has_real_default(undef),  "undef default is not a real default");
ok(!$dia->_has_real_default('NULL'), "a bare 'NULL' string default is not a real default (MySQL quirk)");
ok($dia->_has_real_default(q{'x'}),  "a quoted literal default is a real default");
ok($dia->_has_real_default('5'),     "a numeric default is a real default");

done_testing;
