use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# SQLite key introspection edge cases:
#  * A partial UNIQUE index (WHERE clause) does not constrain the whole table,
#    so it must NOT be recorded as a table-wide unique constraint.
#  * An expression UNIQUE index (e.g. lower(a)) has no plain column name, so it
#    must not produce an undef-column unique key or leak undef into an index's
#    column list.
# In both cases the index itself should still appear under the table's indexes.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/idx.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE t (a INTEGER, b TEXT)');
    $dbh->do('CREATE UNIQUE INDEX u_partial ON t(a) WHERE b IS NOT NULL');
    $dbh->do('CREATE UNIQUE INDEX u_expr    ON t(lower(a))');
    $dbh->do('CREATE UNIQUE INDEX u_plain   ON t(b)');
    $dbh->disconnect;
}

my $warnings = '';
local $SIG{__WARN__} = sub { $warnings .= $_[0] };

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $t   = $con->schema->table('t');

subtest partial_unique_index => sub {
    ok(!$t->unique->{'a'}, "partial unique index on (a) is NOT a table unique constraint");

    my ($partial) = grep { $_->{name} eq 'u_partial' } @{$t->indexes};
    ok($partial, "partial index still appears under indexes");
    is($partial->{columns}, ['a'], "partial index keeps its column");
};

subtest expression_unique_index => sub {
    ok(!exists $t->unique->{''}, "expression unique index produces no empty-key unique constraint");

    for my $key (keys %{$t->unique}) {
        my $cols = $t->unique->{$key};
        ok(!(grep { !defined } @$cols), "unique key '$key' has no undef columns");
    }

    my ($expr) = grep { $_->{name} eq 'u_expr' } @{$t->indexes};
    ok($expr, "expression index still appears under indexes");
    ok(!(grep { !defined } @{$expr->{columns}}), "expression index has no undef in its column list");
};

subtest plain_unique_still_works => sub {
    ok($t->unique->{'b'}, "an ordinary unique index is still recorded as a unique constraint");
};

is($warnings, '', "no uninitialized-value warnings emitted during introspection");

done_testing;
