use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Batch;
use DBIx::Squirrel::Stop;

my $class = 'DBIx::Squirrel::Pipeline';

subtest 'what is exported' => sub {

    package Defaults {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Batch;
        ::ok __PACKAGE__->can($_), "$_ by default" for qw(batch collect);
    }

    package None {        ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Batch ();
        ::ok !__PACKAGE__->can($_), "not $_ with ()" for qw(batch collect);
    }
};

subtest 'batch' => sub {
    is [$class->new(batch(2))->(1 .. 5)], [[1, 2], [3, 4], [5]],
        'full batches, then the last, at the end';
    is [$class->new(batch(2))->(1 .. 4)], [[1, 2], [3, 4]],
        'and no empty one';
    is [$class->new(batch(1))->(1, 2)], [[1], [2]], 'of one';
    is [$class->new(batch(3))->()],     [],         'none, without values';
};

subtest 'batch starts afresh on each run' => sub {
    my $p = $class->new(batch(2), sub { Stop($_) });
    is [$p->(1 .. 3)], [[1, 2]], 'a run stopped with a batch held';
    is [$p->(4 .. 5)], [[4, 5]], 'and the next, without what it held';
};

subtest 'collect' => sub {
    is [$class->new(collect)->(1 .. 3)], [[1, 2, 3]],
        'every value, in one array';
    is [$class->new(collect)->()], [[]], 'an empty one, without values';

    my @args;
    my $p = $class->new(collect { @args = @_; scalar @_ });
    is [$p->(qw(a b c))], [3],         'made into what the block returns';
    is \@args,            [qw(a b c)], 'given the values as its arguments';
    is [$p->()],          [0],         'called even without values';

    is [$class->new(collect { reverse @_ }, sub { uc })->(qw(a b))], [qw(B A)],
        'several values, going on through the stages after it';
    is [$class->new(collect sub (@xs) { "@xs" })->(1, 2)], ['1 2'],
        'or a sub';
};

subtest 'collect starts afresh on each run' => sub {
    my $p = $class->new(collect);
    is [$p->(1, 2)], [[1, 2]], 'the first run';
    is [$p->(3)],    [[3]],    'the second';
};

subtest 'mistakes' => sub {
    for my $bad (0, -1, 1.5, 'x', '', undef) {
        my $shown = $bad // 'undef';
        my $line  = __LINE__ + 1;
        is dies { batch($bad) },
            "Expected a batch size of 1 or more at ${\ __FILE__ } line $line.\n",
            "batch($shown)";
    }
    my $line = __LINE__ + 1;
    is dies { &DBIx::Squirrel::Stages::Batch::collect('x') },    # past the prototype
        "Expected a code reference at ${\ __FILE__ } line $line.\n",
        'collect, given something else';
};

# With a database, through an iterator.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO artist (name) VALUES (?)', $_) for qw(Abba Blur Cream);
my $names = 'SELECT name FROM artist ORDER BY id';

subtest 'from an iterator' => sub {
    my $it = $dbh->iterate($names, sub { $_->[0] }, batch(2));
    is [$it->next], [[qw(Abba Blur)]], 'a batch';
    is [$it->next], [['Cream']],       'the last';
    is [$it->next], [],                'then none';

    my $all = $dbh->iterate($names, sub { $_->[0] }, collect);
    is $all->single, [qw(Abba Blur Cream)], 'every row, as one result';
    is $all->single, [qw(Abba Blur Cream)], 'and again';
};

done_testing;
