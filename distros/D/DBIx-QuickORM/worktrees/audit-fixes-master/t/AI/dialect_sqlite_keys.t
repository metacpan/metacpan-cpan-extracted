use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# SQLite key introspection: a plain (non-unique) CREATE INDEX must not be
# recorded as a unique constraint. Unique constraints drive link cardinality
# in Schema::_resolve_links, so a plain index on a FK column previously turned
# a one-to-many link into a (wrong) one-to-one link.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir  = tempdir(CLEANUP => 1);
my $dsn  = "dbi:SQLite:dbname=$dir/keys.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE foo (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do(<<'    EOT');
        CREATE TABLE bar (
            id     INTEGER PRIMARY KEY,
            foo_id INTEGER NOT NULL REFERENCES foo(id),
            tag    TEXT
        )
    EOT
    $dbh->do('CREATE INDEX bar_foo_idx ON bar(foo_id)');
    $dbh->do('CREATE UNIQUE INDEX bar_tag_idx ON bar(tag)');
    $dbh->disconnect;
}

my $con    = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $schema = $con->schema;
my $bar    = $schema->table('bar');

subtest unique_constraints => sub {
    ok(!$bar->unique->{'foo_id'}, "plain index on foo_id is NOT recorded as a unique constraint");
    ok($bar->unique->{'tag'}, "unique index on tag IS recorded as a unique constraint");
    ok($bar->unique->{'id'}, "primary key is recorded as a unique constraint");
};

subtest link_cardinality => sub {
    my $foo = $schema->table('foo');

    my ($to_bar) = grep { $_->other_table eq 'bar' } @{$foo->links};
    ok($to_bar, "foo has a link to bar");
    ok(!$to_bar->unique, "foo -> bar link is one-to-many (bar.foo_id is not unique)");

    my ($to_foo) = grep { $_->other_table eq 'foo' } @{$bar->links};
    ok($to_foo, "bar has a link to foo");
    ok($to_foo->unique, "bar -> foo link is one-to-one (foo.id is the primary key)");
};

done_testing;
