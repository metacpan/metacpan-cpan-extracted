use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# Regression: SQLite introspection must not record a PARTIAL unique index
# (CREATE UNIQUE INDEX ... WHERE ...) or an EXPRESSION unique index
# (CREATE UNIQUE INDEX ... (lower(x))) as a table-level unique constraint --
# neither constrains the full column tuple, and an expression part has no
# column name (which produced a garbage unique key).

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;
require DBIx::QuickORM::Util;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/idx.sqlite";
{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE t (id INTEGER PRIMARY KEY, email TEXT, name TEXT, deleted INTEGER)');
    $dbh->do('CREATE UNIQUE INDEX u_email ON t (email)');                      # real unique
    $dbh->do('CREATE UNIQUE INDEX u_name_active ON t (name) WHERE deleted = 0'); # partial unique
    $dbh->do('CREATE UNIQUE INDEX u_lower ON t (lower(email))');               # expression unique
    $dbh->disconnect;
}

my $con    = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $unique = $con->schema->table('t')->unique;

my $email_key = DBIx::QuickORM::Util::column_key('email');
my $name_key  = DBIx::QuickORM::Util::column_key('name');

ok(exists $unique->{$email_key}, "a plain unique index is recorded as a unique constraint");
ok(!exists $unique->{$name_key}, "a partial unique index is NOT recorded as a table unique constraint");

ok(!(grep { !defined($_) || $_ eq '' } keys %$unique), "no garbage/undef unique key from the expression index");
ok(!(grep { !defined } map { @$_ } values %$unique), "no unique key contains an undef column");

done_testing;
