use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stop;

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

subtest 'tap returns the database handle' => sub {
    ref_is $dbh->tap(sub { 'something else' }), $dbh, 'whatever comes out';
    ref_is $dbh->tap(sub { () }),               $dbh, 'when nothing does';
    ref_is $dbh->tap,                           $dbh, 'with no stages';

    my @all = $dbh->tap(sub { (1, 2, 3) });
    is scalar(@all), 1, 'and only the handle, in list context';
    ref_is $all[0], $dbh, 'the handle';
};

subtest 'the stages run for their side effects' => sub {
    my @seen;
    $dbh->tap(
        sub ($x) { push @seen, ref $x; (1, 2, 3) },
        sub { $_ % 2 ? $_ : () },
        sub { push @seen, "last($_)"; $_ },
    );
    is \@seen, ['DBIx::Squirrel::db', 'last(1)', 'last(3)'];
};

subtest 'tap carries on a chain of method calls' => sub {
    my $n;
    $dbh->tap(sub { $_->do('CREATE TABLE t (n INTEGER)') })
        ->do('INSERT INTO t VALUES (1)');
    ($n) = $dbh->selectrow_array('SELECT COUNT(*) FROM t');
    is $n, 1;
};

subtest 'Stop ends the stages, and tap still returns the handle' => sub {
    my @seen;
    my $handle = $dbh->tap(
        sub { (1, 2, 3) },
        sub { $_ == 2 ? Stop('two') : $_ },
        sub { push @seen, $_ },
    );
    ref_is $handle, $dbh, 'the handle';
    is \@seen, [1, 'two'], 'the stages ran until the Stop';
};

subtest 'a stage that dies is reported where tap was called' => sub {
    my @stages = (sub { $_ }, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { $dbh->tap(@stages) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n";
};

subtest 'a stage that is neither a code reference nor a pipeline' => sub {
    my @stages = (sub { $_ }, 'x');
    my $line   = __LINE__ + 1;
    my $err    = dies { $dbh->tap(@stages) };
    is $err,
        "Expected stage #2 to be a code reference or a pipeline at ${\ __FILE__ } line $line.\n";
};

subtest 'a statement handle has tap too' => sub {
    my $sth = $dbh->prepare('SELECT 6 * 7');
    my $n;
    ref_is $sth->tap(sub { $_->execute }), $sth, 'returning the handle';
    ($n) = $sth->fetchrow_array;
    is $n, 42, 'after running the stages';

    my @stages = (sub { die "boom\n" });        ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { $sth->tap(@stages) };
    is $err,
        "Pipeline stage #1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'reporting errors where tap was called';
};

done_testing;
