use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Context      qw(iterator result_number result_original);
use DBIx::Squirrel::Stages::Rows qw(as_hash  pluck);
use Ekorn::Pipeline              qw();
use Ekorn::Pipeline::Operators;
use Ekorn::Pipeline::Sinks   qw(keep_all keep_first keep_last count_items);
use Ekorn::Pipeline::Sources qw(from_array);
use Ekorn::Pipeline::Stages::Batch qw(collect);

# What a stage may ask, wherever a statement is read: through | and in
# a pipeline of the user's own, as the design's section 5 has it.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO artist (name) VALUES (?)', $_) for qw(Abba Blur Cream);
my $sql   = 'SELECT id, name FROM artist ORDER BY id';
my @names = qw(Abba Blur Cream);

subtest 'pluck and as_hash, through |' => sub {
    is $dbh->iterate($sql) | pluck('name') | keep_all, \@names,
        'pluck, by name';
    is $dbh->iterate($sql) | as_hash | keep_all,
        [map { {id => $_ + 1, name => $names[$_]} } 0 .. 2], 'as_hash';
    is $dbh->results($sql) | pluck('name') | keep_all, \@names,
        'pluck, from a result set';
};

subtest "pluck and as_hash, in a pipeline of the user's own" => sub {
    my $next = Ekorn::Pipeline->new(as_hash, pluck('name'))
        ->iterator($dbh->iterate($sql));
    my @got;
    while (my($name) = $next->()) { push @got, $name }
    is \@got, \@names, 'reading an iterator';
};

subtest 'result_original, through |' => sub {
    my $it    = $dbh->iterate($sql);
    my $pairs = $it | pluck('name') | sub { [$_, result_original] }
        | keep_all;
    is $pairs, [map { [$names[$_], [$_ + 1, $names[$_]]] } 0 .. 2],
        'the row each value came from';

    my $rows = $dbh->results($sql) | sub { result_original }
        | keep_all;
    is [map { $_->name } @$rows], \@names, 'from a result set, the row object';

    my $flushed = collect { scalar @_ };
    my $ending  = $it | $flushed | sub { [$_, result_original] }
        | keep_all;
    is $ending, [[3, undef]], 'undef, for a value a flush gives';
};

subtest "result_number and iterator are only the iterator's" => sub {
    my $asked = sub { [result_number, iterator] };
    is $dbh->iterate($sql) | $asked | keep_all, [([undef, undef]) x 3],
        "undef in a pipeline of the user's own";
    my $it = $dbh->iterate($sql, $asked);
    is [$it->all], [map { [$_, exact_ref($it)] } 1 .. 3],
        "as before, in the iterator's own stages";
};

subtest 'result_number and iterator, with a sink given last' => sub {
    my $numbered = sub { result_number . " $_->[1]" };
    is [$dbh->iterate($sql, $numbered, keep_all)],
        ['1 Abba', '2 Blur', '3 Cream'],
        'keep_all, counting as all does';
    is [$dbh->results($sql, sub { result_number . ' ' . $_->name }, keep_all)],
        ['1 Abba', '2 Blur', '3 Cream'], 'and for a result set';
    is $dbh->iterate($sql, $numbered, keep_first), '1 Abba',  'keep_first';
    is $dbh->iterate($sql, $numbered, keep_last),  '3 Cream', 'keep_last';
    is [$dbh->iterate($sql, sub { $_->[0] == 2 ? () : $_ }, $numbered, keep_all)
        ],
        ['1 Abba', '2 Cream'], 'counting results, not rows';
    my @counted;
    is $dbh->iterate(
        $sql, sub { push @counted, result_number; $_ },
        count_items,
        ),
        3,
        'count_items';
    is \@counted, [1, 2, 3], 'its stages counting too';
    isa_ok $dbh->iterate($sql, sub { iterator }, keep_first),
        ['DBIx::Squirrel::Iterator'],
        'iterator, the one running the stages';
};

subtest "pluck after a reshaping stage reads the statement's columns" => sub {
    my $it  = $dbh->iterate($sql);
    my $got = $it | sub { [reverse @$_] }
        | pluck('id') | keep_all;
    is $got, \@names, 'so it picks the wrong field, silently';
    my @ids = $dbh->iterate(
        $sql, as_hash,
        sub { +{%$_, name => uc $_->{name}} },
        pluck('id'),
    )->all;
    is \@ids, [1 .. 3], "but by name on hashes, it reads each hash's keys";
};

subtest "without a statement's columns, pluck and as_hash croak" => sub {
    my $msg
        = qr( Expected\ a\ statement\ to\ read,\ for\ the\ column\ names\ at\  )x;
    like dies { my $x = from_array([1, 'Abba']) | pluck('name') | keep_all },
        $msg,
        'pluck, over a source that is not a statement';
    like dies { Ekorn::Pipeline->new(as_hash)->([1, 'Abba']) }, $msg,
        'as_hash, in a pushed run';
    is from_array({name => 'Abba'}) | pluck('name') | keep_all, ['Abba'],
        'pluck by name, on a hash row, uses its keys';
};

done_testing;
