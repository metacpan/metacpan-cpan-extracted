use Test2::V0;
use DBI;
use File::Temp qw/tempdir/;
use Scalar::Util qw/refaddr/;

# OFFSET and DISTINCT support on handles: clone-based builders, the emitted
# SQL shapes (LIMIT ? OFFSET ?, SELECT DISTINCT), and the fetched results.

BEGIN {
    skip_all "DBD::SQLite is required for these tests"
        unless eval { require DBD::SQLite; 1 };
}

require DBIx::QuickORM;

my $dir = tempdir(CLEANUP => 1);
my $dsn = "dbi:SQLite:dbname=$dir/offset_distinct.sqlite";

{
    my $dbh = DBI->connect($dsn, '', '', {RaiseError => 1, PrintError => 0});
    $dbh->do('CREATE TABLE people (id INTEGER PRIMARY KEY, surname TEXT, first_name TEXT)');
    $dbh->do(
        "INSERT INTO people (surname, first_name) VALUES "
        . "('smith', 'al'), ('jones', 'bob'), ('smith', 'cy'), ('smith', 'di'), ('jones', 'ed')"
    );
    $dbh->disconnect;
}

my $con  = DBIx::QuickORM->quick(credentials => {dsn => $dsn});
my $base = $con->handle('people');

subtest offset_builder => sub {
    my $o = $base->limit(2)->offset(1);

    isnt(refaddr($o), refaddr($base), "offset() returns a new handle");
    is($o->offset, 1, "offset is stored");
    is($base->offset, undef, "original handle offset is untouched");

    like(dies { $base->offset(1); 1 },
        qr/Must not be called in void context/, "offset() croaks in void context");

    my $kv = $con->handle('people', limit => 2, offset => 1);
    is($kv->offset, 1, "offset accepted as a constructor key/value pair");
};

subtest offset_results => sub {
    my @names = map { $_->{first_name} } $base->order_by('first_name')->limit(2)->offset(1)->data_only->all;
    is(\@names, ['bob', 'cy'], "limit + offset slice the ordered results");

    @names = map { $_->{first_name} } $base->order_by('first_name')->limit(2)->offset(0)->data_only->all;
    is(\@names, ['al', 'bob'], "offset 0 is honored and matches the unoffset slice");

    @names = map { $_->{first_name} } $base->order_by('first_name')->limit(10)->offset(3)->data_only->all;
    is(\@names, ['di', 'ed'], "offset past most rows returns the tail");
};

subtest offset_requires_limit => sub {
    like(
        dies { $base->offset(1)->data_only->all },
        qr/Cannot use 'offset' without a 'limit'/,
        "an offset without a limit croaks at query time"
    );
};

subtest distinct_builder => sub {
    my $d = $base->distinct;

    isnt(refaddr($d), refaddr($base), "distinct() returns a new handle");
    ref_is($d->distinct, $d, "distinct() on an already-distinct handle returns itself");

    my $off = $d->distinct(0);
    isnt(refaddr($off), refaddr($d), "distinct(0) returns a new handle");

    like(dies { $base->distinct; 1 },
        qr/Must not be called in void context/, "distinct() croaks in void context");

    my $kv = $con->handle('people', distinct => 1);
    ok($kv, "distinct accepted as a constructor key/value pair");
};

subtest distinct_results => sub {
    my @all = map { $_->{surname} } $base->fields(['surname'])->order_by('surname')->data_only->all;
    is(\@all, ['jones', 'jones', 'smith', 'smith', 'smith'], "without distinct, duplicate values come back");

    my @uniq = map { $_->{surname} } $base->fields(['surname'])->distinct->order_by('surname')->data_only->all;
    is(\@uniq, ['jones', 'smith'], "with distinct, duplicate values collapse");
};

subtest unsupported_operations => sub {
    like(dies { $base->offset(1)->update({surname => 'x'}) },
        qr/update\(\) with an 'offset' clause is not currently supported/,
        "update with an offset croaks");

    like(dies { $base->distinct->update({surname => 'x'}) },
        qr/update\(\) with distinct set is not currently supported/,
        "update with distinct croaks");

    like(dies { $base->distinct->insert({surname => 'x', first_name => 'y'}) },
        qr/Cannot insert rows using a handle with distinct set/,
        "insert with distinct croaks");

    like(dies { $base->limit(1)->offset(1)->insert({surname => 'x', first_name => 'y'}) },
        qr/Cannot insert rows using a handle with a limit set/,
        "insert with a limit/offset croaks");
};

done_testing;
