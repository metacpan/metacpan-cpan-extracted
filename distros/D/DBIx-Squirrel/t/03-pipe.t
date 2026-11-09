use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stop;

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

subtest 'the first stage is called with the database handle' => sub {
    my $arg = sub ($x) { $x };
    ref_is [$dbh->pipe($arg)]->[0],       $dbh, 'as its argument';
    ref_is [$dbh->pipe(sub { $_ })]->[0], $dbh, 'and in $_';
    is $dbh->pipe(sub { $_->selectrow_array('SELECT 6 * 7') }), 42,
        'which it can use';
};

subtest 'with no stages, pipe returns the database handle' => sub {
    my @results = $dbh->pipe;
    is scalar(@results), 1, 'one value';
    ref_is $results[0], $dbh, 'the database handle';
};

subtest 'each value goes through the rest of the stages on its own' => sub {
    my @results = $dbh->pipe(
        sub { (3, 4, 5) },
        sub { $_ % 2 ? $_ : () },
        sub { $_ * 2 },
    );
    is \@results, [6, 10];
};

subtest 'in scalar context, pipe returns the first value' => sub {
    my $first = $dbh->pipe(sub { (3, 4, 5) });
    is $first, 3, 'of several';

    my $none = $dbh->pipe(sub { () });
    is $none, undef, 'or undef, if there are none';
};

subtest 'Stop ends the pipeline' => sub {
    my @results = $dbh->pipe(
        sub { (1, 2, 3) },
        sub { $_ == 2 ? Stop('two') : $_ },
    );
    is \@results, [1, 'two'];
};

subtest 'a stage that dies is reported where pipe was called' => sub {
    my @stages = (sub { $_ }, sub { die "boom\n" });    ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { $dbh->pipe(@stages) };
    is $err,
        "Pipeline stage #2 failed at ${\ __FILE__ } line $line:\n    boom\n";
};

subtest 'a stage that is not a code reference' => sub {
    my @stages = (sub { $_ }, 'x');
    my $line   = __LINE__ + 1;
    my $err    = dies { $dbh->pipe(@stages) };
    is $err,
        "Expected stage #2 to be a code reference at ${\ __FILE__ } line $line.\n";
};

subtest 'a statement handle has pipe too' => sub {
    my $sth   = $dbh->prepare('SELECT 6 * 7');
    my $first = sub ($x) { ref $x };
    is [$sth->pipe($first)], ['DBIx::Squirrel::st'],
        'called with the statement handle';
    is [$sth->pipe(sub { $_->execute; $_->fetchrow_array })], [42],
        'which it can use';

    my @stages = (sub { die "boom\n" });         ## no critic (ErrorHandling::RequireCarping)
    my $line   = __LINE__ + 1;
    my $err    = dies { $sth->pipe(@stages) };
    is $err,
        "Pipeline stage #1 failed at ${\ __FILE__ } line $line:\n    boom\n",
        'reporting errors where pipe was called';
};

done_testing;
