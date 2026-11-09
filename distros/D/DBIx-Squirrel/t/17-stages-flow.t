use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while drop_while);
use DBIx::Squirrel::Sugar qw(database statement);

my $class = 'DBIx::Squirrel::Pipeline';

# Return every value an iterator hands out.
sub drain ($next) {
    my @xs;
    while (my($x) = $next->()) { push @xs, $x }
    return \@xs;
}

# Return a source handing out @xs one per call, and a reference to the
# number of times it was called.
sub source (@xs) {
    my $calls = 0;
    return sub { $calls += 1; @xs ? shift @xs : () }, \$calls;
}

subtest 'what is exported' => sub {

    package Defaults {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Flow;
        ::ok __PACKAGE__->can($_),  "$_ by default" for qw(take       drop);
        ::ok !__PACKAGE__->can($_), "not $_"        for qw(take_while drop_while);
    }

    package All {         ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Flow qw(:all);
        ::ok __PACKAGE__->can($_), "$_ with :all"
            for qw(take drop take_while drop_while);
    }

    package None {        ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Stages::Flow ();
        ::ok !__PACKAGE__->can($_), "not $_ with ()"
            for qw(take drop take_while drop_while);
    }
};

subtest 'take' => sub {
    is [$class->new(take(2))->(qw(a b c d))], [qw(a b)], 'the first values';
    is [$class->new(take(5))->(qw(a b))],     [qw(a b)], 'or all there are';
    is [$class->new(take(0))->(qw(a b))],     [],        'or none';
    is [$class->new(take(2))->()],            [],        'from none';

    my($src, $calls) = source(qw(a b c d));
    my $next = $class->new(take(2))->iterator($src);
    is drain($next), [qw(a b)], 'pulled';
    is $$calls,      2,         'without asking for the value after';
};

subtest 'drop' => sub {
    is [$class->new(drop(2))->(qw(a b c d))], [qw(c d)], 'the values after';
    is [$class->new(drop(5))->(qw(a b))],     [],        'or none';
    is [$class->new(drop(0))->(qw(a b))],     [qw(a b)], 'or all';
    is [$class->new(drop(1), take(2))->(qw(a b c d))], [qw(b c)],
        'and with take, a page';
};

subtest 'take and drop start afresh on each run' => sub {
    my $p = $class->new(drop(1), take(2));
    is [$p->(qw(a b c d))], [qw(b c)], 'the first run';
    is [$p->(qw(e f g h))], [qw(f g)], 'the second';
};

subtest 'take_while' => sub {
    my @seen;
    my $p = $class->new(take_while { push @seen, $_; $_ < 3 });
    is [$p->(1 .. 5, 1)], [1, 2], 'the values until one fails';
    is \@seen, [1, 2, 3],
        'given each in $_, and stopped at the first that fails';

    my($src, $calls) = source(1 .. 5);
    my $next = $class->new(take_while { $_ < 3 })->iterator($src);
    is drain($next), [1, 2], 'pulled';
    is $$calls,      3,      'without asking for the value after';

    is [$class->new(take_while sub ($x) { $x ne 'c' })->(qw(a b c))],
        [qw(a b)], 'as its argument too';
};

subtest 'drop_while' => sub {
    my @seen;
    my $p = $class->new(drop_while { push @seen, $_; $_ < 3 });
    is [$p->(1 .. 5, 1)], [3, 4, 5, 1], 'the values from the first that fails';
    is \@seen,            [1, 2, 3],    'asking no more once one has';
    is [$p->(1, 4, 1)],   [4, 1],       'starting afresh on each run';
};

subtest 'counts are checked when the stage is made' => sub {
    for my $bad (-1, 1.5, 'x', '', undef) {
        my $shown = $bad // 'undef';
        for my $fn (\&take, \&drop) {
            my $line = __LINE__ + 1;
            is dies { $fn->($bad) },
                "Expected a count of 0 or more at ${\ __FILE__ } line $line.\n",
                "$shown";
        }
    }
    # Past the prototype, as nothing else can give them anything but code
    for my $fn (\&take_while, \&drop_while) {
        my $line = __LINE__ + 1;
        is dies { $fn->('x') },
            "Expected a code reference at ${\ __FILE__ } line $line.\n",
            'and tests';
    }
};

# With a database, through iterators and Sugar.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO artist (name) VALUES (?)', $_)
    for qw(Abba Blur Cream Dido Enya);

subtest 'a page of rows, from an iterator' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist ORDER BY id',
        sub { $_->[0] },
        drop(1), take(2),
    );
    is [$it->all], [qw(Blur Cream)], 'the page';
    ok !$it->sth->{Active}, 'and the statement is finished';
    is [$it->reset->all], [qw(Blur Cream)], 'and again, after reset';
};

subtest 'a Sugar statement takes afresh on each call' => sub {
    database(
        bands => 'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    );
    bands('CREATE TABLE band (id INTEGER PRIMARY KEY, name TEXT)');
    bands('INSERT INTO band (name) VALUES (?)', $_) for qw(Abba Blur Cream);
    statement(
        first_two => bands => 'SELECT name FROM band ORDER BY id',
        sub { $_->[0] },
        take(2),
    );
    is [first_two()], [qw(Abba Blur)], 'the first call';
    is [first_two()], [qw(Abba Blur)], 'the second';
};

done_testing;
