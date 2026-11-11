use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use Ref::Util qw(is_coderef);

use DBIx::Squirrel;
use DBIx::Squirrel::Context qw(result_number result_original);
use DBIx::Squirrel::Gather;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stop;
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

# A stage gathering its values into batches of $size, the last batch
# given at the end.
sub batches_of ($size) {
    return gather {
        my @batch;
        my $stage = sub ($x) {
            push @batch, $x;
            return @batch == $size ? [splice @batch] : ();
        };
        my $end = sub () { @batch ? [@batch] : () };
        return ($stage, $end);
    };
}

# A stage holding every value, and giving them, joined, at the end.
sub joined ($separator = ',') {
    return gather {
        my @all;
        return (
            sub ($x) { push @all, $x; () },
            sub () { join $separator, @all },
        );
    };
}

subtest 'gather is exported by default' => sub {
    ok __PACKAGE__->can('gather'), 'exported';

    package Without::Gather {    ## no critic (Modules::ProhibitMultiplePackages)
        use DBIx::Squirrel::Gather ();
        ::ok !__PACKAGE__->can('gather'), 'unless the import list is empty';
    }
};

subtest 'gather checks it was given a code reference' => sub {
    my $line = __LINE__ + 1;
    is dies { &DBIx::Squirrel::Gather::gather('x') },    # past the prototype
        "Expected a code reference at ${\ __FILE__ } line $line.\n";
};

subtest 'a stage made with gather is a code reference' => sub {
    my $stage = gather {
        sub { $_ }
    };
    isa_ok $stage, ['Ekorn::Pipeline::Gather'], 'an Ekorn::Pipeline::Gather';
    ok is_coderef($stage),            'and a code reference';
    ok lives { $class->new($stage) }, 'which a pipeline takes';
};

subtest 'without an end, it is an ordinary stage, made for each run' => sub {
    my $made = 0;
    my $p    = $class->new(gather {
        $made++;
        my $count = 0;
        sub { ++$count <= 2 ? $_ : () };
    });
    is [$p->(qw(a b c))], [qw(a b)], 'the first run';
    is [$p->(qw(d e f))], [qw(d e)], 'the second, starting afresh';
    is $made, 2, 'made once for each run';

    my($src) = source(qw(g h i));
    is drain($p->iterator($src)), [qw(g h)], 'an iterator is a run of its own';
    is $made,                     3,         'made for it';
};

subtest 'the values an end returns go through the rest of the stages' => sub {
    my $p = $class->new(batches_of(2), sub { join '', @$_ });
    is [$p->(1 .. 5)], [qw(12 34 5)], 'the last batch, at the end';
    is [$p->(1 .. 4)], [qw(12 34)], 'an end returning nothing adds nothing';
};

subtest 'an end is called even without values' => sub {
    is [$class->new(joined)->()], [''], 'pushed';
    my($src) = source();
    is drain($class->new(joined)->iterator($src)), [''], 'pulled';
};

subtest 'an end gets no arguments, and $_ is undef' => sub {
    my @seen;
    my $p = $class->new(gather {
        (sub { $_ }, sub (@args) { push @seen, [scalar(@args), $_]; () });
    });
    local $_ = 'mine';
    $p->(1, 2);
    is \@seen, [[0, undef]], 'called once, with nothing';
    is $_,     'mine',       'and $_ is left as it was';
};

subtest 'ends are called in order, each feeding those after it' => sub {
    my @log;
    my $p = $class->new(
        batches_of(2),
        sub { push @log, 'map'; join '', @$_ },
        joined('+'),
        sub { push @log, 'last'; "<$_>" },
    );
    is [$p->(1 .. 5)], ['<12+34+5>'],          'the first end, then the second';
    is \@log,          [qw(map map map last)], 'each value going on in turn';
};

subtest 'an end can give several values' => sub {
    my $p = $class->new(
        gather { (sub { () }, sub { qw(x y z) }) },
        sub { uc },
    );
    is [$p->(1)], [qw(X Y Z)];
};

subtest 'after a Stop, ends after the stage that stopped are called' => sub {
    my $p = $class->new(
        sub { Stop() if $_ == 4; $_ },
        joined,
    );
    is [$p->(1 .. 9)], ['1,2,3'], 'and given the values before it';

    my $q = $class->new(
        sub { $_ == 3 ? Stop($_, 'last') : $_ },
        joined,
    );
    is [$q->(1 .. 9)], ['1,2,3,last'], 'and the values the Stop carries';
};

subtest 'after a Stop, ends before the stage that stopped are not' => sub {
    my $ended = 0;
    my $p     = $class->new(
        gather { (sub { $_ }, sub { $ended++; 'end' }) },
        sub { Stop() if $_ == 2; $_ },
    );
    is [$p->(1 .. 5)], [1], 'nothing after the Stop';
    is $ended,         0,   'the end before it dropped';
};

subtest 'an end can Stop, its values going on' => sub {
    my $p = $class->new(
        gather { (sub { $_ }, sub { Stop('stopped') }) },
        joined,
    );
    is [$p->(1, 2)], ['1,2,stopped'], 'to the ends after it';
};

subtest 'an iterator calls the ends once, after the source runs out' => sub {
    my($src, $calls) = source(1 .. 3);
    my $next = $class->new(batches_of(2))->iterator($src);
    is [$next->()],  [[1, 2]], 'a full batch';
    is $$calls,      2,        'from two calls of the source';
    is drain($next), [[3]],    'then the last, at the end';
    is $$calls,      4,        'after the source ran out';
    is [$next->()],  [],       'and then nothing';
    is $$calls,      4,        'without calling the source again';
};

subtest 'a block giving the wrong things croaks, naming the stage' => sub {
    my $msg
        = 'Expected stage #2, made with gather, to return a code reference or a pipeline, and optionally an end function';
    my @bad = ([], [sub { }, sub { }, sub { }], ['x'], [sub { }, 'x']);
    for my $returns (@bad) {
        my $p    = $class->new(sub { $_ }, gather { @$returns });
        my $line = __LINE__ + 1;
        is dies { $p->(1) }, "$msg at ${\ __FILE__ } line $line.\n",
            scalar(@$returns) . ' values';
    }
};

subtest 'an end that dies says which stage it was' => sub {
    my $p = $class->new(
        sub { $_ },
        gather { (sub { $_ }, sub { die "boom\n" }) },    ## no critic (ErrorHandling::RequireCarping)
    );
    my $line = __LINE__ + 1;
    is dies { $p->(1) },
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n";
};

# Iterators and result sets run a pipeline for each execution.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
$dbh->do('INSERT INTO artist (name) VALUES (?)', $_)
    for qw(Abba Blur Cream Dido Enya);

subtest 'an iterator runs its gathers afresh on each execution' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist WHERE id <= ? ORDER BY id',
        3,
        sub { $_->[0] },
        joined,
    );
    is $it->single,          'Abba,Blur,Cream', 'single';
    is [$it->reset(2)->all], ['Abba,Blur'],     'reset, with other values';
    is [$it->reset->next],   ['Abba,Blur'],     'and again';
};

subtest 'a gathered result is counted' => sub {
    my $it = $dbh->iterate(
        'SELECT name FROM artist ORDER BY id', sub { $_->[0] },
        joined,
    );
    is [$it->all], ['Abba,Blur,Cream,Dido,Enya'];
    is $it->count, 1;
};

subtest 'what an end can ask' => sub {
    my @seen;
    my $it = $dbh->iterate(
        'SELECT name FROM artist WHERE id <= 2 ORDER BY id',
        gather {
            (sub { () }, sub { push @seen, [result_number, result_original]; 'end' });
        },
        sub { push @seen, [result_number, result_original]; $_ },
    );
    is [$it->all], ['end'];
    is \@seen, [[1, undef], [1, undef]],
        'the result it makes, but no original: it comes from every row';
};

subtest 'an iterator run while an end gives its values has originals' => sub {
    my @seen;
    my $it = $dbh->iterate(
        'SELECT id FROM artist WHERE id <= 2 ORDER BY id',
        gather { (sub { () }, sub { 'end' }) },
        sub {
            my $inner = $dbh->iterate(
                'SELECT name FROM artist WHERE id = 1',
                sub { push @seen, result_original; $_ },
            );
            $inner->all;
            push @seen, result_original;
            $_;
        },
    );
    is [$it->all], ['end'];
    is \@seen, [['Abba'], undef], 'the inner one has its own, the outer none';
};

subtest 'a Sugar statement runs its gathers afresh on each call' => sub {
    database(
        bands => 'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    );
    bands('CREATE TABLE band (id INTEGER PRIMARY KEY, name TEXT)');
    bands('INSERT INTO band (name) VALUES (?)', $_) for qw(Abba Blur Cream);
    statement(
        band_names => bands => 'SELECT name FROM band WHERE id <= ? ORDER BY id',
        sub { $_->[0] },
        joined,
    );
    is [band_names(2)], ['Abba,Blur'],       'the first call';
    is [band_names(3)], ['Abba,Blur,Cream'], 'the second, starting afresh';
};

done_testing;
