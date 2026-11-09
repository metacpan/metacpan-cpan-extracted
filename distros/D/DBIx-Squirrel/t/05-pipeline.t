use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stop;

package My::Stop {
    our @ISA = 'DBIx::Squirrel::Stop';
}

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

subtest 'new checks its stages' => sub {
    my $p = $class->new(sub { $_ });
    isa_ok $p, [$class], 'a pipeline';
    ok ref($p) && $p->can('iterator'), 'with an iterator method';
    my $msg = qr( Expected\ stage\ \#2\ to\ be\ a\ code\ reference )x;
    my $at  = qr( at\ \Q${\ __FILE__ }\E\ line\ \d+ )x;
    like dies {
        $class->new(sub { $_ }, 'x')
    }, qr( \A $msg \ $at \. \n \z )x,
        'croaks on a stage that is not a code reference, naming it';
};

subtest 'a stage sees one value, in $_ and as its argument' => sub {
    my @seen;
    my $p = $class->new(sub ($x) {
        push @seen, [$_, $x];
        $x;
    });
    $p->(1, 2);
    is \@seen, [[1, 1], [2, 2]];
};

subtest 'stages map, filter and flatMap' => sub {
    is [$class->new(sub { $_ * 10 })->(1, 2, 3)],         [10, 20, 30], 'map';
    is [$class->new(sub { $_ % 2 ? () : $_ })->(1 .. 6)], [2,  4,  6],  'filter';
    is [$class->new(sub { ($_, $_ + 1) }, sub { $_ * 10 })->(1)], [10, 20],
        'flatMap, then map';
    is [$class->new(sub { $_ })->(1, undef, 3)], [1, undef, 3],
        'undef is a value';
};

subtest 'each value goes through every stage before the next starts' => sub {
    my @log;
    my $p = $class->new(
        sub { push @log, "s1($_)"; ("${_}a", "${_}b") },
        sub { push @log, "s2($_)"; $_ },
        sub { push @log, "s3($_)"; $_ },
    );
    is [$p->('x')], ['xa', 'xb'], 'values come out in order';
    is \@log,       [qw(s1(x) s2(xa) s3(xa) s2(xb) s3(xb))], 'depth-first';
};

subtest 'with no stages, values come back as they are' => sub {
    my $p = $class->new;
    is [$p->(1, undef, 3)], [1, undef, 3], 'pushed';
    my($src) = source(1, 2);
    is drain($p->iterator($src)), [1, 2], 'pulled';
};

subtest 'Stop keeps the values already out' => sub {
    my $p = $class->new(
        sub { ($_ * 10, $_ * 10 + 5) },
        sub { Stop() if $_ == 15; $_ + 1 },
    );
    is [$p->(1, 2)], [11], 'Stop';

    my $q = $class->new(sub { My::Stop->throw if $_ == 2; $_ });
    is [$q->(1, 2, 3)], [1], 'a subclass of Stop';
};

subtest 'the values a Stop carries go through the rest of the stages' => sub {
    my $p = $class->new(
        sub { $_ == 3 ? Stop("found $_", undef) : $_ },
        sub { defined ? "<$_>"                  : 'none' },
    );
    is [$p->(1 .. 9)], ['<1>', '<2>', '<found 3>', 'none'], 'pushed';

    my($src, $calls) = source(1 .. 9);
    my $next = $p->iterator($src);
    is drain($next), ['<1>', '<2>', '<found 3>', 'none'], 'pulled';
    is $$calls,      3,  'without calling the source again';
    is [$next->()],  [], 'and stays done';

    my $q = $class->new(
        sub { $_ == 2  ? Stop($_, 99) : $_ },
        sub { $_ == 99 ? Stop('last') : $_ },
    );
    is [$q->(1 .. 4)], [1, 2, 'last'], 'a later stage can stop them in turn';
};

subtest 'iterator hands out one value per call' => sub {
    my @log;
    my $p = $class->new(
        sub { push @log, "s1($_)"; ("${_}a", "${_}b") },
        sub { push @log, "s2($_)"; $_ },
    );
    my($src, $calls) = source(qw(x y));
    my $next = $p->iterator($src);

    is [$next->()], ['xa'],             'the first value';
    is \@log,       [qw(s1(x) s2(xa))], 'running only the stages it needed';
    is $$calls,     1,                  'after one call of the source';

    is drain($next), [qw(xb ya yb)], 'then the rest, in order';
    is [$next->()],  [],             'then nothing';
};

subtest 'iterator takes several values from one call of the source' => sub {
    my $once = 0;
    my $next
        = $class->new(sub { $_ * 2 })->iterator(sub { $once++ ? () : (1, 2, 3) });
    is drain($next), [2, 4, 6];
};

subtest 'iterator stops calling the source after Stop' => sub {
    my($src, $calls) = source(1 .. 6);
    my $next = $class->new(sub { Stop() if $_ == 3; $_ })->iterator($src);
    is drain($next), [1, 2], 'the values before the Stop';
    is $$calls,      3,      'the source was called no more';
    is [$next->()],  [],     'and stays done';
    is $$calls,      3,      'without calling it again';
};

subtest 'iterator checks its source' => sub {
    my $line = __LINE__ + 1;
    is dies { $class->new->iterator('x') },
        "Expected a code reference at ${\ __FILE__ } line $line.\n";
};

subtest 'a stage that dies says which it was' => sub {
    my $p    = $class->new(sub { $_ }, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line = __LINE__ + 1;
    my $err  = dies { $p->(1) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'pushed';

    my $next = $p->iterator(sub { 1 });
    $line = __LINE__ + 1;
    $err  = dies { $next->() };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'pulled';

    my $obj  = bless {}, 'My::Error';
    my $dies = $class->new(sub { die $obj });    ## no critic (ErrorHandling::RequireCarping)
    ref_is dies { $dies->(1) }, $obj, 'an exception object is passed on';
};

subtest 'iterator over a statement handle' => sub {
    my $dbh = DBI->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 1, PrintError => 0},
    );
    $dbh->do('CREATE TABLE t (n INTEGER, tags TEXT)');
    $dbh->do('INSERT INTO t VALUES (?, ?)', undef, @$_)
        for [1, 'a,b'], [2, ''], [3, 'c'], [4, 'd,e'], [5, 'f'];

    my $sth     = $dbh->prepare('SELECT n, tags FROM t ORDER BY n');
    my $fetches = 0;
    my $next    = $class->new(
        sub { length $_->{tags} ? $_ : () },
        sub ($row) {
            map { "$row->{n}$_" } split m( , )x, $row->{tags};
        },
        sub { Stop() if $_ eq '4e'; $_ },
    )->iterator(sub { $fetches += 1; $sth->fetchrow_hashref // () });

    $sth->execute;
    is drain($next), [qw(1a 1b 3c 4d)], 'filtered, fanned out and stopped';
    is $fetches,     4,                 'without fetching the row after';
    $sth->finish;
};

done_testing;
