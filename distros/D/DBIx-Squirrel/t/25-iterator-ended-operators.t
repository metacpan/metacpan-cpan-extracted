use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stages::Flow qw(take);
use Ekorn::Pipeline              qw();
use Ekorn::Pipeline::Sinks       qw(count_items keep_all keep_first);

# An iterator's ended, and its | and @{}, which are Ekorn's, as the
# design's sections 4.4 and 4.5 have them.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE n (id INTEGER PRIMARY KEY)');
$dbh->do('INSERT INTO n VALUES (?)', $_) for 1 .. 5;
my $sql = 'SELECT id FROM n ORDER BY id';

subtest 'ended says how the last run ended' => sub {
    my $it = $dbh->iterate($sql, sub { $_->[0] });
    is [$it->ended], [], 'nothing, before a run';
    $it->next;
    is [$it->ended], [], 'nothing, while one is going';
    1 while $it->next;
    is $it->ended, 'done', 'done, once the rows ran out';

    $it->reset;
    is [$it->ended], [], 'nothing, after reset';
    $it->all;
    is $it->ended, 'done', 'done, after all';

    $it->reset->first;
    is $it->ended, 'stopped', 'stopped, after first';
    ok warnings { $it->reset->single }, 'single, warning of more';
    is $it->ended, 'stopped', 'stopped, after single';

    $it = $dbh->iterate("$sql LIMIT 1");
    $it->single;
    is $it->ended, 'done',
        'done, after single with one row, which looked to the end';

    $it = $dbh->iterate($sql, take(2));
    $it->all;
    is $it->ended, 'stopped', 'stopped, by a stage that stopped';

    $it = $dbh->iterate($sql, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    ok dies { $it->next }, 'a stage dying';
    is $it->ended,          'died', 'died';
    is [$it->next],         [],     'and the run gives nothing more';
    is $it->ended,          'died', 'still died';
    is [$it->reset->ended], [],     'until reset';
};

subtest 'without use Ekorn::Pipeline::Operators, | and @{} croak' => sub {
    my $it   = $dbh->iterate($sql);
    my $line = __LINE__ + 1;
    is dies { my $n = $it | count_items },
        "Expected use Ekorn::Pipeline::Operators in scope, for | at ${\ __FILE__ } line $line.\n",
        '|';
    $line = __LINE__ + 1;
    is dies { my @rows = @$it },
        "Expected use Ekorn::Pipeline::Operators in scope, for \@{} at ${\ __FILE__ } line $line.\n",
        '@{}';
    ok !$it->sth->{Active}, 'executing nothing';
};

subtest '| with a sink gives its result' => sub {
    use Ekorn::Pipeline::Operators;
    my $it = $dbh->iterate($sql, sub { $_->[0] });
    is $it | keep_all,           [1 .. 5], 'keep_all, an array reference';
    is $it | count_items,        5,        'count_items, a number';
    is $it | take(2) | keep_all, [1, 2],   'after a stage';
    is $it | keep_first,         1,        'keep_first';
    is $it->ended, 'stopped', "its run the iterator's last, which ended gives";
    ok !$it->sth->{Active}, 'which finishes the statement';
    my @one = $it | keep_all;
    is \@one, [[1 .. 5]], 'one value, even in a list assignment';
};

subtest '@{} reads every result, and each use is a run of its own' => sub {
    use Ekorn::Pipeline::Operators;
    my $it = $dbh->iterate($sql, sub { $_->[0] });
    is [@$it],               [1 .. 5],  'every result, through the stages';
    is scalar(@$it),         5,         'how many';
    is $it->[0],             1,         'the first, reading them all';
    is [@{ $it | take(3) }], [1, 2, 3], 'a chain, read through';
    $dbh->do('INSERT INTO n VALUES (6)');
    is scalar(@$it), 6, 'running the query again';
    $dbh->do('DELETE FROM n WHERE id = 6');
    is [$it->next],        [],     'next, after, has nothing: the run was @{}\'s';
    is $it->ended,         'done', 'and ended says how it ended';
    is [$it->reset->next], [1],    'until reset';
};

subtest 'a result set through | and a pipeline' => sub {
    use Ekorn::Pipeline::Operators;
    my $rows = $dbh->results($sql) | keep_all;
    is [map { $_->id } @$rows], [1 .. 5], 'objects, read through |';

    my $next = Ekorn::Pipeline->new()->iterator($dbh->results("$sql LIMIT 2"));
    my @ids;
    while (my($row) = $next->()) { push @ids, $row->id }
    is \@ids, [1, 2], 'objects, read on after the result set is let go';
};

done_testing;
