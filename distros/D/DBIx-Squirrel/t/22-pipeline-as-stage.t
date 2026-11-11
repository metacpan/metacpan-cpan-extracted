use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Gather;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Flow;
use DBIx::Squirrel::Stages::Rows;

# An in-memory SQLite database lasts as long as its handle, which
# connect_cached keeps, so each use of music sees the same one.
use DBIx::Squirrel::Sugar database => {
    music => [
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    ],
};

my $class = 'DBIx::Squirrel::Pipeline';

# An object standing for a number, as a bind value.
package My::Three {
    use overload '""' => sub ($self, @) { $self->{n} }, fallback => 1;
}

# Names in capitals: a pipeline used as a stage below, made before the
# statements that use it are defined, as they're defined on use.
my $names;


BEGIN {
    $names = DBIx::Squirrel::Pipeline->new(pluck('name'), sub { uc });
}

# Statements taking a pipeline among their stages.
use DBIx::Squirrel::Sugar statement => {
    names_in_capitals => [
        music => 'SELECT id, name FROM artist ORDER BY id',
        {ekorn_slice => {}}, $names,
    ],
    first_two => [
        music => 'SELECT id, name FROM artist ORDER BY id',
        {ekorn_slice => {}}, $names, take(2),
    ],
    named_after => [
        music => 'SELECT id, name FROM artist WHERE id > ? ORDER BY id',
        {ekorn_slice => {}},
    ],
    names_without_attrs => [
        music => 'SELECT id, name FROM artist ORDER BY id', $names,
    ],
};

music 'CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)';
music 'INSERT INTO artist (name) VALUES (?)', $_
    for qw(Abba Blur Cream Dido Enya);

my $dbh   = music;
my $all   = 'SELECT id, name FROM artist ORDER BY id';
my $after = 'SELECT id, name FROM artist WHERE id > ? ORDER BY id';
my @all   = qw(ABBA BLUR CREAM DIDO ENYA);

subtest 'iterate takes a pipeline where a stage goes' => sub {
    is [$dbh->iterate($all, {ekorn_slice => {}}, $names)->all], \@all,
        'alone';
    is [$dbh->iterate($all, {ekorn_slice => {}}, $names, take(2))->all],
        [qw(ABBA BLUR)], 'with a stage after it';
    is [$dbh->iterate($all, {ekorn_slice => {}}, sub { $_ }, $names)->all],
        \@all, 'with a stage before it';
    is [$dbh->iterate($after, {ekorn_slice => {}}, 3, $names)->all],
        [qw(DIDO ENYA)], 'after bind values';
    is [$dbh->iterate($all, $class->new(sub { $_->[1] }))->all],
        [qw(Abba Blur Cream Dido Enya)],
        'first, in place of the attributes';
    is [$dbh->iterate($after, {ekorn_slice => {}}, 3, $names->stages)->all],
        [$dbh->iterate($after, {ekorn_slice => {}}, 3, $names)->all],
        'as its stages would';
};

subtest 'its stages run in the call\'s run' => sub {
    my $two = $class->new($names, take(2));
    is [$dbh->iterate($all, {ekorn_slice => {}}, $two)->all],
        [qw(ABBA BLUR)], 'a take(2) inside gives 2 in all';
    is [$dbh->iterate($all, {ekorn_slice => {}}, $two, take(1))->all],
        ['ABBA'], 'and the stages after it take what it gives';

    my $it = $dbh->iterate($all, {ekorn_slice => {}}, $two);
    is [$it->all],        [qw(ABBA BLUR)], 'run once';
    is [$it->reset->all], [qw(ABBA BLUR)], 'and again, reset';
};

subtest 'results and a statement handle take one too' => sub {
    is [$dbh->results($all, {ekorn_slice => {}}, $names, take(3))->all],
        [qw(ABBA BLUR CREAM)], 'results';
    my $sth = $dbh->prepare($after, {ekorn_slice => {}});
    is [$sth->iterate(1, $names)->all], [qw(BLUR CREAM DIDO ENYA)],
        'a statement handle\'s iterate';
    is [$sth->results(4, $names)->all], ['ENYA'],
        'a statement handle\'s results';
};

subtest 'Sugar takes one where a stage goes' => sub {
    is [names_in_capitals()], \@all, 'in a statement\'s definition';
    is [first_two()], [qw(ABBA BLUR)], 'with a stage after it';
    is [named_after(3, $names)], [qw(DIDO ENYA)],
        'after a statement\'s bind values';
    is [music($all, {ekorn_slice => {}}, $names, take(1))], ['ABBA'],
        'after a database\'s statement';
    is [music($after, {ekorn_slice => {}}, 4, $names)], ['ENYA'],
        'and its bind values';
};

subtest 'a pipeline straight after the statement is a stage' => sub {
    is [names_without_attrs()], \@all, 'defined on use';
    statement(names_as_it_runs => music => $all, $names);
    is [names_as_it_runs()], \@all, 'defined as the program runs';
    is [names_as_it_runs(take(2))], [qw(ABBA BLUR)],
        'with more stages for a call';
};

subtest 'a gather block can return a pipeline' => sub {
    my $made = 0;
    my $it   = $dbh->iterate(
        $all,
        {ekorn_slice => {}},
        gather {
            my $n = 0;    # this run's
            $made++;
            $class->new($names, sub { ++$n . ":$_" }, take(2));
        },
    );
    is [$it->all],        ['1:ABBA', '2:BLUR'], 'its stages run in its place';
    is [$it->reset->all], ['1:ABBA', '2:BLUR'], 'made afresh for each run';
    is $made,             2, 'by calling the block each time';
};

subtest 'a stage inside a pipeline is named by its place' => sub {
    my $boom = $class->new(sub { $_ }, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line;
    like dies {
        $line = __LINE__ + 1;
        $dbh->iterate($all, sub { $_ }, $boom)->all;
    },
        qr( \A Pipeline\ stage\ \#2\.2\ failed\ at\ \S+\ line\ $line: \n \s+ boom )x,
        'as #2.2';
};

subtest 'anything else is still a bind value' => sub {
    my $three = bless {n => 3}, 'My::Three';
    is [$dbh->iterate($after, {ekorn_slice => {}}, $three, $names)->all],
        [qw(DIDO ENYA)], 'an object that isn\'t a pipeline is bound';
    like dies {
        DBIx::Squirrel::Sugar->import(statement => {
            bad => [music => $all, undef, bless {}, 'Not::A::Pipeline'],
        });
    },
        qr( \A \QExpected only code references or pipelines after the statement for bad\E )x,
        'and a statement\'s definition says so';
};

done_testing;
