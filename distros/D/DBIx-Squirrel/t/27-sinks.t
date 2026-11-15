use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stages::Flow qw(take);
use DBIx::Squirrel::Stages::Rows qw(pluck);
use Ekorn::Pipeline::Sinks       qw(
    count_items keep keep_all keep_first keep_last
    keep_single);

# A call taking stages gives a sink's result when its last stage is one,
# as the design's section 6 has it; the select methods push what the DBI
# gives through their stages.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO artist (name) VALUES (?)', $_)
    for qw(Abba Blur Cream Dido Enya);
my $sql   = 'SELECT id, name FROM artist ORDER BY id';
my @names = qw(Abba Blur Cream Dido Enya);

subtest 'iterate, with a sink last' => sub {
    my @rows = $dbh->iterate($sql, keep_all);
    is scalar(@rows), 5, 'keep_all, a list';
    my $rows = $dbh->iterate($sql, keep_all);
    is $rows, [map { [$_ + 1, $names[$_]] } 0 .. 4],
        'or an array reference, for one value';
    is [$dbh->iterate($sql, pluck('name'), take(2), keep_all)], [qw(Abba Blur)],
        'after stages';
    is [$dbh->iterate($sql, pluck('name'), keep(3))], [qw(Abba Blur Cream)],
        'keep(N)';
    is $dbh->iterate($sql, count_items), 5, 'count_items';
    is $dbh->iterate($sql, pluck('name'), keep_first), 'Abba', 'keep_first';
    is $dbh->iterate($sql, pluck('name'), keep_last),  'Enya', 'keep_last';
    is $dbh->iterate("$sql LIMIT 1", pluck('name'), keep_single), 'Abba',
        'keep_single';
    my $first;
    like warnings { $first = $dbh->iterate($sql, pluck('name'), keep_single) },
        [qr( \A Expected\ only\ one\ item,\ but\ there\ were\ more )x],
        'keep_single, warning of a second';
    is $first, 'Abba', 'and giving the first';

    my $none = 'SELECT name FROM artist WHERE 0';
    is [$dbh->iterate($none, keep_single)], [undef],
        'keep_single, undef for none';
    is [$dbh->iterate($none, keep_all)], [], 'keep_all, nothing';
    is scalar($dbh->iterate($none, keep_all)), [],
        'or an empty array reference';
    is $dbh->iterate($none, count_items), 0, 'count_items, 0';
};

subtest 'iterate and results, on either handle' => sub {
    my $sth = $dbh->prepare('SELECT name FROM artist WHERE id > ? ORDER BY id');
    is [$sth->iterate(3, pluck(0), keep_all)], [qw(Dido Enya)],
        "a statement handle's iterate";
    is $sth->iterate(1, count_items), 4, 'with bind values';
    my $artist
        = $dbh->results('SELECT * FROM artist WHERE id = ?', 2, keep_single);
    isa_ok $artist, ['DBIx::Squirrel::Result'], 'results, a row object';
    is $artist->name, 'Blur', 'the one asked for';
    is [map { $_->name } $sth->results(4, keep_all)], ['Enya'],
        "a statement handle's results";
    ok !$sth->{Active}, 'finishing the statement';
};

subtest 'without a sink last, an iterator' => sub {
    isa_ok scalar($dbh->iterate($sql, pluck('name'))),
        ['DBIx::Squirrel::Iterator'], 'in scalar context';
    my @got = $dbh->iterate($sql, pluck('name'));
    is scalar(@got), 1, 'and in list context, one iterator';
    isa_ok $got[0], ['DBIx::Squirrel::Iterator'];
};

subtest 'the select methods push what the DBI gives through stages' => sub {
    my @got = $dbh->selectall_arrayref(
        'SELECT name FROM artist WHERE id > ?', 3,
        sub {
            map { $_->[0] } @$_;
        },
    );
    is \@got, [qw(Dido Enya)], 'its one reference, through the stages';
    is scalar($dbh->selectall_arrayref($sql, sub { @$_ })), 5,
        'how many come out, with no sink, where one value is asked for';
    is scalar($dbh->selectall_arrayref($sql, undef, sub { @$_ }, keep_all)),
        [map { [$_ + 1, $names[$_]] } 0 .. 4],
        "a sink's result, after attributes";
    is [$dbh->selectrow_array("$sql LIMIT 1", sub { uc })], [1, 'ABBA'],
        "selectrow_array, the row's values";
    is $dbh->selectrow_array(
        'SELECT name FROM artist WHERE id = :id', id => 3,
        sub { lc },                               keep_first,
        ),
        'cream', 'with bind values of any style';
    is [$dbh->selectcol_arrayref('SELECT id FROM artist', sub { scalar @$_ })],
        [5], 'selectcol_arrayref';
    is [$dbh->selectall_hashref($sql, 'id', sub { join ',', sort keys %$_ })],
        ['1,2,3,4,5'], 'selectall_hashref';
    is $dbh->selectrow_hashref($sql, sub { $_->{name} }, keep_first), 'Abba',
        'selectrow_hashref';
    is $dbh->selectrow_arrayref($sql, sub { $_->[1] }, keep_first), 'Abba',
        'selectrow_arrayref';
    is scalar($dbh->selectall_arrayref($sql)), D(),
        'and without, what the DBI gives';
    like dies {
        my @x = $dbh->selectall_arrayref($sql, sub { @$_ }, pluck('name'))
    },
        qr( Expected\ a\ statement\ to\ read,\ for\ the\ column\ names )x,
        'a pushed run, with no columns for pluck';
};

subtest 'selectall_array pushes each row through its stages' => sub {
    is [$dbh->selectall_array($sql, sub { $_->[1] })], \@names,
        'each row, a value of its own';
    is [
        $dbh->selectall_array(
            'SELECT name FROM artist WHERE id > ? ORDER BY id', 3, pluck(0), sub { lc },
        ),
        ],
        [qw(dido enya)], 'after its bind values, through several stages';
    is scalar($dbh->selectall_array($sql, sub { $_->[0] > 3 ? $_ : () })), 2,
        'how many come out, with no sink, where one value is asked for';
    is
        scalar(
            $dbh->selectall_array($sql, {Slice => {}}, sub { $_->{name} }, keep_all)),
        \@names, "a sink's result, after attributes";
    is $dbh->selectall_array($sql, count_items), 5, 'count_items';
    is [$dbh->selectall_array($sql, take(2), sub { $_->[1] })], [qw(Abba Blur)],
        'a stop, ending the push';
    is [$dbh->selectall_array('SELECT name FROM artist WHERE 0', sub { uc })],
        [],
        'no rows, nothing through them';
    is [$dbh->selectall_array($sql)], [map { [$_ + 1, $names[$_]] } 0 .. 4],
        'and without stages, the rows, as the DBI gives them';
    is scalar($dbh->selectall_array($sql)), 5, 'or how many, for one value';
};

done_testing;
