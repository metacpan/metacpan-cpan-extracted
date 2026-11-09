use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;
use DBIx::Squirrel::Gather;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stop;
use DBIx::Squirrel::Context qw(iterator result_number result_original);
use experimental            qw(builtin);
use builtin                 qw(weaken);

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# A handle of each kind, with ten artists.
my %h = (
    dbi      => DBI->connect(@source),
    squirrel => DBIx::Squirrel->connect(@source),
);
for my $h (values %h) {
    $h->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    $h->do('INSERT INTO artist (name) VALUES (?)', undef, $_)
        for qw(Abba Blur Cream Dido Enya Faust Genesis Hole Inxs Japan);
}
my $dbh = $h{squirrel};
my $all = 'SELECT id, name FROM artist ORDER BY id';

# Every result an iterator hands out, read with next.
sub drain ($it) {
    my @results;
    while (my($result) = $it->next) { push @results, $result }
    return \@results;
}

subtest 'the rows are those the DBI fetches' => sub {
    is drain($dbh->iterate($all)), $h{dbi}->selectall_arrayref($all),
        'as arrays';
    is drain($dbh->iterate($all, {ekorn_slice => {}})),
        $h{dbi}->selectall_arrayref($all, {Slice => {}}), 'as hashes';
    is drain($dbh->iterate('SELECT id FROM artist WHERE 0')), [], 'none';
};

subtest 'bind values, in any placeholder style' => sub {
    my $sql  = 'SELECT name FROM artist WHERE id IN (%s) ORDER BY id';
    my @want = (['Abba'], ['Cream']);
    is drain($dbh->iterate(sprintf($sql, '?, ?'), 1, 3)), \@want, '?';
    is drain($dbh->iterate(sprintf($sql, '$1, $2'), [1, 3])), \@want,
        'numbered, in an array reference';
    is drain($dbh->iterate(sprintf($sql, ':a, :b'), a => 1, b => 3)), \@want,
        'named';
    is drain($dbh->iterate(sprintf($sql, ':a, :b'), undef, {a => 1, b => 3})),
        \@want, 'named, in a hash reference after the attributes';
    is drain($dbh->iterate(sprintf($sql, '?, ?'), {}, 1, 3)), \@want,
        'with attributes';
    my $sth = $dbh->prepare(sprintf($sql, ':a, :b'));
    is drain($sth->iterate(a => 1, b => 3)), \@want, 'on a statement handle';
};

subtest 'the stages' => sub {
    my $names = "$all LIMIT 4";
    is drain($dbh->iterate($names, sub ($row) { $row->[1] })),
        [qw(Abba Blur Cream Dido)], 'change a row';
    is drain($dbh->iterate(
        $names, sub ($row) { $row->[0] % 2 ? $row : () },
        sub { $_->[1] },
        )),
        [qw(Abba Cream)], 'drop one';
    is drain($dbh->iterate($names, sub ($row) { ($row->[1]) x $row->[0] })),
        [qw(Abba Blur Blur Cream Cream Cream Dido Dido Dido Dido)],
        'return several';
    is drain($dbh->iterate(
        $all,
        sub ($row) {
            $row->[0] == 3 ? Stop($row->[1]) : $row->[1];
        },
        )),
        [qw(Abba Blur Cream)], 'stop';
    is drain($dbh->iterate("$all LIMIT 2", sub { undef })), [undef, undef],
        'and undef is a result';
    is drain($dbh->iterate(
        'SELECT id FROM artist WHERE id = ?', 2, sub { 'x' },)),
        ['x'], 'after bind values';
};

subtest 'next' => sub {
    my $it = $dbh->iterate("$all LIMIT 1", sub { $_->[1] });
    is $it->next,   'Abba', 'returns the next result';
    is [$it->next], [],     'and nothing at the end';
    is [$it->next], [],     'and after';
    ok !$it->sth->{Active}, 'with the statement finished';
};

subtest 'all and count' => sub {
    my $it = $dbh->iterate($all, sub { $_->[1] });
    is $it->count, 0,      'count, before any';
    is $it->next,  'Abba', 'one';
    is $it->count, 1,      'count, after it';
    is [$it->all], [qw(Blur Cream Dido Enya Faust Genesis Hole Inxs Japan)],
        'all, the rest';
    is $it->count,  10, 'count, after them';
    is [$it->all],  [], 'all, with none left';
    is [$it->next], [], 'and next';

    $it = $dbh->iterate($all);
    is scalar($it->all), 10, 'all, in scalar context, counts them';
    is scalar($dbh->iterate("$all LIMIT 0")->all), 0, 'or that there are none';
};

subtest 'single' => sub {
    my $sql = 'SELECT name FROM artist WHERE id = ?';
    my $it  = $dbh->iterate($sql, 3, sub { $_->[0] });
    is $it->single, 'Cream', 'the one result';
    is $it->single, 'Cream', 'again, executing the statement again';
    is [$dbh->iterate($sql, 99)->single], [], 'or nothing';
    my $expected = qr( \A Expected\ one\ result,\ not\ more )x;
    my $line     = __LINE__ + 1;
    like dies { $dbh->iterate($all)->single },
        qr( $expected \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'croaks at the caller on more than one';
};

subtest 'reset' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist WHERE id <= ?', 2,
        sub { $_->[0] },
    );
    is drain($it),           [qw(Abba Blur)],       'the bind values given';
    is drain($it->reset(3)), [qw(Abba Blur Cream)], 'others';
    is drain($it->reset),    [qw(Abba Blur Cream)], 'kept';
    is drain($it->reset(1, sub { lc })), ['abba'],  'and stages, added';
    is drain($it->reset(1)),             ['abba'],  'and kept';

    $it = $dbh->iterate($all, sub { $_->[1] });
    is $it->next, 'Abba', 'one fetched';
    ref_is $it->reset, $it, 'reset returns the iterator';
    is $it->next, 'Abba', 'starting again, finishing the statement';
};

subtest '$_ is left alone' => sub {
    my $it    = $dbh->iterate($all, sub { $_->[1] });
    my @names = qw(x y);
    for (@names) { $it->next }
    is \@names, [qw(x y)], "a for loop's aliases";
    my @mapped = grep { $it->next } qw(a b);
    is \@mapped, [qw(a b)], "and grep's";
    local $_ = 'kept';
    $it->reset;
    $it->all;
    is $_, 'kept', 'by reset and all';
    $dbh->iterate('SELECT 1', sub { $_ })->single;
    is $_, 'kept', 'and single';
};

subtest 'ekorn_slice' => sub {
    my $hashes = $h{dbi}->selectall_arrayref($all, {Slice => {}});
    my $sth    = $dbh->prepare($all, {ekorn_slice => {}});
    is drain($sth->iterate), $hashes, 'on prepare';
    my $other = DBIx::Squirrel->connect(
        @source[0 .. 2],
        {%{ $source[3] }, ekorn_slice => {}},
    );
    $other->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    $other->do(q{INSERT INTO artist (name) VALUES ('Abba'), ('Blur')});
    is drain($other->iterate($all)),
        [{id => 1, name => 'Abba'}, {id => 2, name => 'Blur'}],
        'or on connect';
    is drain($other->iterate($all, {ekorn_slice => []})),
        [[1, 'Abba'], [2, 'Blur']],
        'which prepare overrides';
    is drain(
        $dbh->iterate('SELECT id FROM artist WHERE id <= 2', {ekorn_slice => [0]})),
        [[1], [2]], 'a slice of columns';
    my $expected = 'Expected ekorn_slice to be a reference to an ARRAY or HASH';
    like dies { $dbh->iterate($all, {ekorn_slice => 'x'}) },
        qr( \A \Q$expected\E )x, 'croaks on anything else';
};

subtest 'one iterator at a time on a statement handle' => sub {
    my $sth = $dbh->prepare($all);
    my $one = $sth->iterate;
    my $two = $sth->iterate;
    $one->next;
    my $expected
        = q(Expected the statement handle's other iterator to be finished);
    my $line = __LINE__ + 1;
    like dies { $two->next },
        qr( \A \Q$expected\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'croaks while another has results left';
    is scalar($one->all), 9, 'and that one is unharmed';
    ok lives { $two->next },        'once it ends';
    ok lives { $two->reset->next }, 'and the one going can reset itself';
    undef $two;
    ok lives { $sth->iterate->next }, 'or once the other goes';
    my $single = $sth->iterate(sub { $_->[1] });
    ok dies { $single->single },      'single, with more than one result';
    ok lives { $sth->iterate->next }, 'is finished, either way';
};

subtest 'what a stage can ask' => sub {
    my $it = $dbh->iterate(
        "$all LIMIT 4",
        sub ($row) { $row->[0] == 2 ? () : $row },
        sub ($row) {
            return {
                iterator => iterator,
                number   => result_number,
                original => result_original,
            };
        },
    );
    my $results = drain($it);
    is $results->[0]{iterator}, exact_ref($it), 'iterator';
    is [map { $_->{number} } @$results], [1, 2, 3],
        'result_number, counting results, not rows';
    is [map { $_->{original}[1] } @$results], [qw(Abba Cream Dido)],
        'result_original';
    is [iterator, result_number, result_original], [undef, undef, undef],
        'and nothing outside a stage';
};

subtest 'what a stage can ask is a term, taking no arguments' => sub {
    my($result) = $dbh->iterate(
        $all,
        sub ($row) {
            return [
                result_number + 1,
                result_original->[1],
                result_original // 'none',
                ref iterator // 'none',
            ];
        },
    )->next;
    is $result->[0], 2,                          'result_number + 1 adds one';
    is $result->[1], 'Abba',                     'result_original->[1]';
    is $result->[2], [1, 'Abba'],                'result_original // ...';
    is $result->[3], 'DBIx::Squirrel::Iterator', 'iterator // ...';
    is result_number // 'none', 'none',          'outside a stage too';
};

subtest 'all, without stages, after next, across batches' => sub {
    $dbh->do('CREATE TABLE m (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do('INSERT INTO m VALUES (?, ?)', $_, "n$_") for 1 .. 250;
    my $sql = 'SELECT id, name FROM m ORDER BY id';

    my $it = $dbh->iterate($sql);
    $it->next for 1 .. 3;
    my @rest = $it->all;
    is [map { $_->[0] } @rest], [4 .. 250],
        'the rest of the batch, then the rows after it';
    is $rest[0],   [4, 'n4'], 'every column';
    is $it->count, 250,       'all counted';
    ok !$it->sth->{Active}, 'and the statement finished';

    my $rs = $dbh->results($sql);
    $rs->next for 1 .. 120;
    my @objects = $rs->all;
    is [map { $_->id } @objects], [121 .. 250],
        'as row objects, in the second batch';
    isa_ok $objects[0], ['DBIx::Squirrel::Result'], 'each';

    is [$dbh->iterate($sql, {ekorn_slice => [1]})->all]->[-1], ['n250'],
        'with a slice of columns';
    is [$dbh->iterate($sql, {ekorn_slice => {}})->all]->[0],
        {id => 1, name => 'n1'},
        'or of hashes';
    is [$dbh->iterate($sql, {ekorn_slice => []})->all]->[0], [1, 'n1'],
        'or of every column';
};

subtest 'column_names' => sub {
    my $it = $dbh->iterate('SELECT id, name AS Who FROM artist ORDER BY id');
    is [$it->column_names], [qw(id Who)], 'executing the statement first';
    $it->all;
    is [$it->column_names], [qw(id Who)], 'and still there after the last row';

    local $dbh->{FetchHashKeyName} = 'NAME_lc';
    is [$dbh->iterate('SELECT name AS Who FROM artist')->column_names],
        ['who'], 'as FetchHashKeyName says, as fetchrow_hashref keys them';
    is [$dbh->iterate('UPDATE artist SET name = name WHERE 0')->column_names],
        [], 'none for a statement without columns';
};

subtest 'an iterator ended early finishes its statement' => sub {
    $dbh->do('CREATE TABLE n (id INTEGER PRIMARY KEY)');
    $dbh->do('INSERT INTO n VALUES (?)', $_) for 1 .. 150;
    my $sql = 'SELECT id FROM n ORDER BY id';

    # More rows than a batch, so the statement is still fetching.
    my $it
        = $dbh->iterate($sql, sub ($row) { Stop() if $row->[0] == 3; $row->[0] });
    is [$it->all], [1, 2], 'by a stop';
    ok !$it->sth->{Active}, 'which finishes it';
    $it = $dbh->iterate($sql);
    like dies { $it->single }, qr( \A Expected\ one\ result,\ not\ more )x,
        'by single, finding more than one';
    ok !$it->sth->{Active}, 'which finishes it too';
};

subtest 'a statement that cannot be executed, without RaiseError' => sub {
    my $quiet = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    $quiet->do('CREATE TABLE u (x INTEGER UNIQUE)');
    $quiet->do('INSERT INTO u VALUES (1)');
    my $it = $quiet->iterate('INSERT INTO u VALUES (?)', 1);
    is [$it->all],    [],  'has no results';
    is $it->sth->err, T(), 'and the handle says why';
};

subtest 'what a stage can ask, with several results from a row' => sub {
    my @stages = (
        sub ($row) { $row->[0] == 2 ? ($row, $row) : $row },
        sub ($row) { [result_number, result_original->[1], $row->[1]] },
    );
    my $expected = [
        [1, 'Abba', 'Abba'], [2, 'Blur',  'Blur'],
        [3, 'Blur', 'Blur'], [4, 'Cream', 'Cream'],
    ];
    is [$dbh->iterate("$all LIMIT 3", @stages)->all], $expected, 'through all';
    is drain($dbh->iterate("$all LIMIT 3", @stages)), $expected, 'and next';
};

subtest 'errors are reported at the caller' => sub {
    my $it   = $dbh->iterate($all, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line = __LINE__ + 1;
    is dies { $it->next },
        "Pipeline stage #1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'from a stage';
    $it = $dbh->iterate('SELECT name FROM artist WHERE id = :id', x => 1);
    my $expected
        = qr( \A Expected\ a\ placeholder\ of\ the\ statement\ \(x\) )x;
    $line = __LINE__ + 1;
    like dies { $it->next },
        qr( $expected \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        'from binding';
    like dies { DBIx::Squirrel::Iterator->new('x') },
        qr( \A Expected\ a\ statement\ handle )x, 'from new';

    # The second row overflows, so the fetch fails after execute succeeds.
    my $failed = 'DBD::SQLite::st fetchall_arrayref failed: integer overflow';
    my $overflow
        = 'SELECT abs(column1) FROM (VALUES (1), (-9223372036854775807 - 1))';
    $line = __LINE__ + 1;
    like dies { $dbh->iterate($overflow)->all },
        qr( \A \Q$failed\E \ at\ \Q${\ __FILE__ }\E\ line\ $line\. )x,
        "from a fetch, with the DBI's message";
};

# Ekorn::Pipeline, from v0.1.1, ends an iterator once a stage dies.
subtest 'once a stage dies, the iterator has ended' => sub {
    $dbh->do('CREATE TABLE number (n INTEGER)');
    $dbh->do('INSERT INTO number VALUES (?)', $_) for 1 .. 250;
    my $numbers = 'SELECT n FROM number ORDER BY n';
    my $dies    = sub ($row) { die "no 2\n" if $row->[0] == 2; $row->[0] };
    my $it      = $dbh->iterate($numbers, $dies);
    is [$it->next], [1], 'a row before the stage dies';
    like dies { $it->next }, qr( no\ 2 )x, 'the stage dies';
    is [$it->next], [], 'then next returns nothing';
    is [$it->next], [], 'on every call';
    is [$it->all],  [], 'and all nothing';
    ok !$it->sth->{Active}, 'the statement finished, part way through';
    is $it->count, 1, 'counting what was handed out';
    $it->reset;
    is [$it->next], [1], 'reset runs it again, from the start';

    my $rs = $dbh->results(
        $numbers,
        sub ($row) { die "no 2\n" if $row->n == 2; $row->n },
    );
    is [$rs->next], [1], 'a result set too';
    ok dies { $rs->next }, 'whose stage dies';
    is [$rs->next], [], 'and has ended';
};

subtest "a pipeline's stages, wherever stages go" => sub {
    my $even = DBIx::Squirrel::Pipeline->new(sub ($row) {
        $row->[0] % 2 ? () : $row;
    });
    my $named = DBIx::Squirrel::Pipeline->new(sub ($row) {
        $row->[1];
    });
    my @spliced = ($even->stages, $named->stages);
    is [$dbh->iterate($all, @spliced)->all], [qw(Blur Dido Faust Hole Japan)],
        'spliced into iterate';
    is [$dbh->iterate("$all LIMIT ?", 4, @spliced)->all], [qw(Blur Dido)],
        'after bind values';
    is [
        $dbh->results($all, sub ($row) { [$row->id, $row->name] }, @spliced)->all
        ],
        [qw(Blur Dido Faust Hole Japan)], 'and into results';
    my $both = DBIx::Squirrel::Pipeline->new(@spliced, sub { lc });
    is [$dbh->iterate($all, $both->stages)->all],
        [qw(blur dido faust hole japan)],
        'from a pipeline made of pipelines';

    my $counted = DBIx::Squirrel::Pipeline->new(gather {
        my $n = 0;
        (sub { ++$n; () }, sub { $n });
    });
    is [$dbh->iterate($all, $counted->stages)->all], [10], 'a gather stage';
    is [$dbh->iterate("$all LIMIT 3", $counted->stages)->all], [3],
        'made afresh for each run';
    is scalar($both->stages), 3, 'how many, in scalar context';
};

subtest 'a statement without rows' => sub {
    my $it = $dbh->iterate('UPDATE artist SET name = name WHERE id <= ?', 2);
    is drain($it),     [], 'has no results';
    is $it->sth->rows, 2,  'and the handle says how many rows it changed';
};

subtest 'an iterator is freed' => sub {
    my $it = $dbh->iterate($all);
    $it->next;
    weaken(my $weak = $it);
    undef $it;
    is $weak, undef, 'when it goes out of scope';
};

done_testing;
