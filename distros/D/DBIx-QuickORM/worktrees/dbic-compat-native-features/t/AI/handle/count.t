use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;

# count() must select ONLY the count expression (omit reconciliation used to
# prepend pk fields and produce invalid SQL), and must not over-count when
# the handle queries a one-to-many join or has the distinct flag set.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/count.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE foo (foo_id INTEGER PRIMARY KEY AUTOINCREMENT, name TEXT NOT NULL)');
    $dbh->do('CREATE TABLE bar (bar_id INTEGER PRIMARY KEY AUTOINCREMENT, foo_id INTEGER REFERENCES foo(foo_id), name TEXT NOT NULL)');
    $dbh->disconnect;
}

my $con = DBIx::QuickORM->quick(credentials => {dsn => $dsn});

my $foo_a = $con->handle('foo')->insert({name => 'a'});
my $foo_b = $con->handle('foo')->insert({name => 'b'});
my $foo_c = $con->handle('foo')->insert({name => 'c'});

$con->handle('bar')->insert({foo_id => $foo_a->field('foo_id'), name => 'a1'});
$con->handle('bar')->insert({foo_id => $foo_a->field('foo_id'), name => 'a2'});
$con->handle('bar')->insert({foo_id => $foo_a->field('foo_id'), name => 'a3'});
$con->handle('bar')->insert({foo_id => $foo_b->field('foo_id'), name => 'b1'});

subtest plain_count => sub {
    is($con->handle('foo')->count, 3, "plain count");
    is($con->handle('bar')->count, 4, "plain count on the many side");
    is($con->handle('bar')->count({name => 'a1'}), 1, "count with a where");
};

subtest count_with_omit => sub {
    is($con->handle('foo')->omit(['name'])->count, 3, "count works on a handle with omit set");
};

subtest joined_count => sub {
    my $joined = $con->handle('foo')->left_join('bar');
    is($joined->count, 3, "left-joined count counts distinct primary rows, not join rows");

    my $inner = $con->handle('foo')->inner_join('bar');
    is($inner->count, 2, "inner-joined count counts distinct primary rows with a match");
};

subtest distinct_count => sub {
    is($con->handle('bar')->distinct->count, 4, "distinct count over the primary key");
};

subtest distinct_count_no_pk => sub {
    {
        my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE nopk (name TEXT NOT NULL)');
        $dbh->disconnect;
    }

    my $con2 = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
    like(
        dies { $con2->handle('nopk')->distinct->count },
        qr/Cannot count distinct rows on a source without a primary key/,
        "distinct count on a pk-less source croaks"
    );
};

done_testing;
