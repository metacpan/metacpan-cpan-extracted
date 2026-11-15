use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBIx::Squirrel;
use DBIx::Squirrel::Stages::Flow qw(take);
use Ekorn::Pipeline              qw();
use File::Temp                   qw(tempfile);
use IPC::Open3                   qw(open3);
use Symbol                       qw(gensym);
use experimental                 qw(builtin);
use builtin                      qw(weaken);

# The statement as a source, as the design's section 4 has it: batches
# that grow, all, first and single over Ekorn's iterator, and what 4.6
# says the build must keep.

my $dbh = DBIx::Squirrel->connect(
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
$dbh->do('CREATE TABLE n (id INTEGER PRIMARY KEY)');
$dbh->do('INSERT INTO n VALUES (?)', $_) for 1 .. 300;
my $sql = 'SELECT id FROM n ORDER BY id';

# Return how many rows each fetch asked for, undef for every row left,
# while the code given runs, and what it returned.
sub fetches ($code) {
    my @asked;
    my $fetch = DBI::st->can('fetchall_arrayref');
    no warnings qw(once redefine);
    local *DBIx::Squirrel::st::fetchall_arrayref = sub ($sth, @args) {
        push @asked, $args[1];
        return $sth->$fetch(@args);
    };
    my @got = $code->();
    return \@asked, @got;
}

subtest 'batches start at 2 rows, and double to 64' => sub {
    my($asked)
        = fetches(sub { my $it = $dbh->iterate($sql); 1 while $it->next });
    is $asked, [2, 4, 8, 16, 32, 64, 64, 64, 64], 'read with next';

    ($asked, my $first) = fetches(sub { $dbh->iterate($sql)->first });
    is $first, [1], 'first';
    is $asked, [2], 'fetching 2 rows';

    my $warnings = warnings {
        ($asked) = fetches(sub { $dbh->iterate($sql)->single });
    };
    is $asked,            [2], 'single, fetching 2 rows to tell there are more';
    is scalar @$warnings, 1,   'and warning';

    ($asked, my $one) = fetches(sub { $dbh->iterate("$sql LIMIT 1")->single });
    is $one,   [1], 'single, with one row';
    is $asked, [2], 'fetching 2 rows to tell there are no more';

    ($asked) = fetches(sub {
        $dbh->iterate($sql, take(1))->all;
    });
    is $asked, [2], 'take(1), fetching 2 rows';
};

subtest 'all, without stages, fetches the rest at once' => sub {
    is [$dbh->iterate('UPDATE n SET id = id WHERE 0')->all], [],
        'nothing, from a statement without columns';
    my $it = $dbh->iterate($sql);
    $it->next for 1 .. 3;
    my($asked, @rest) = fetches(sub { $it->all });
    is [map { $_->[0] } @rest], [4 .. 300], 'every row left';
    is $asked, [undef], 'with one fetch of them all, after the batch';
    ok !$it->sth->{Active}, 'finishing the statement';

    # The run is Ekorn's iterator's: ended says how it ended.
    $it = $dbh->iterate($sql);
    my $run = ($it->next, $it->{run})[1];
    $it->all;
    is $run->ended, 'done', 'which ended done';

    ($asked, @rest) = fetches(sub {
        $dbh->iterate($sql, sub { $_->[0] })->all;
    });
    is \@rest, [1 .. 300], 'with stages, every result';
    ok !grep({ !defined } @$asked), 'fetched in batches, a row at a time';
};

subtest 'first and single end the run' => sub {
    my $it  = $dbh->iterate($sql);
    my $run = ($it->next, $it->{run})[1];
    is $it->first,  [2],       'first, the next row';
    is $run->ended, 'stopped', 'stopping the run';

    $it  = $dbh->iterate($sql);
    $run = ($it->next, $it->{run})[1];
    ok warnings { $it->single }, 'single, warning of more';
    is $run->ended, 'stopped', 'stopping the run';
    ok !$it->sth->{Active}, 'and finishing the statement';
};

subtest "a run's end touches only its own run" => sub {
    my $it    = $dbh->iterate($sql);
    my $outer = Ekorn::Pipeline->new()->iterator($it);
    is [$outer->()], [[1]], 'a run of a pipeline reading the iterator';
    $it->reset;
    is [$it->next], [[1]], 'then a fresh run of its own';
    undef $outer;
    ok $it->sth->{Active}, 'the old run, ended late, leaves the handle alone';
    is [$it->next], [[2]], 'and the new run reads on';

    $outer = Ekorn::Pipeline->new()->iterator($it);
    $it->reset;
    is [$outer->()], [],    'the old run, read after, gives nothing of the new';
    is [$it->next],  [[1]], 'and takes nothing from it';
    $it->all;
    undef $outer;
    is [$it->reset->next], [[1]],
        'nor does it act, ended after the new run ended';
};

subtest 'no cycles keep an iterator alive' => sub {
    for my $class (qw(iterate results)) {
        my $it  = $dbh->$class($sql, sub { $_[0] });
        my $sth = $it->sth;
        $it->next;
        weaken(my $weak = $it);
        undef $it;
        ok !defined $weak,  "$class: let go, it goes";
        ok !$sth->{Active}, "$class: and its statement is finished";
    }
};

subtest 'a fresh run starts clean' => sub {
    my $it = $dbh->iterate($sql);
    $it->next for 1 .. 20;
    my($asked, @first) = fetches(sub { $it->reset->next });
    is \@first, [[1]], 'reset after next, from the first row';
    is $asked,  [2],   'with a batch of 2';

    ok warnings { $it->single }, 'single, warning of more';
    ($asked, @first) = fetches(sub { $it->reset->next });
    is \@first, [[1]], 'reset after single, from the first row';
    is $asked,  [2],   'with a batch of 2';

    $it->next;
    $it->all;
    ($asked, @first) = fetches(sub { $it->reset->next });
    is \@first, [[1]], 'reset after all, from the first row';
    is $asked,  [2],   'with a batch of 2';
};

subtest 'an iterator is a source' => sub {
    my $it   = $dbh->iterate("$sql LIMIT 3", sub { $_->[0] });
    my @rows = Ekorn::Pipeline->new()->iterator($it)->all;
    is \@rows, [1, 2, 3], 'read by a pipeline, through its own stages';

    my $columns
        = Ekorn::Pipeline->new(sub { Ekorn::Pipeline::run_context()->{columns} })
        ->iterator($dbh->iterate("$sql LIMIT 1"))
        ->();
    is $columns, ['id'],
        "passing on the statement's columns as the run's context";

    my $next = Ekorn::Pipeline->new()->iterator($dbh->iterate("$sql LIMIT 3"));
    is [map { $next->() } 1 .. 4], [[1], [2], [3]],
        'read on after the iterator is let go';
};

subtest 'ends at program exit are quiet' => sub {
    my $code = <<~'PERL';
        use v5.36;
        use DBIx::Squirrel;
        my $dbh = DBIx::Squirrel->connect('dbi:SQLite:dbname=:memory:', '', '',
            {RaiseError => 1, PrintError => 0});
        $dbh->do('CREATE TABLE n (id INTEGER)');
        $dbh->do('INSERT INTO n VALUES (?)', $_) for 1 .. 10;
        our $it = $dbh->iterate('SELECT id FROM n');
        $it->next;
        our $handle = $dbh;
        print "ran\n";
        PERL
    # The program goes in a file, not after -e: on Windows, a child's
    # arguments pass through one command line, whose quoting mangled
    # the program's double quotes, on CPAN Testers' v3.0.0 trial.
    my($fh, $file) = tempfile(SUFFIX => '.pl', UNLINK => 1);
    print { $fh } $code;
    close $fh;
    my $pid = open3(
        my $in, my $out, my $err = gensym(), $^X, (map { "-I$_" } @INC),
        $file,
    );
    close $in;
    my $said   = do { local $/ = undef; <$out> };
    my $warned = do { local $/ = undef; <$err> };
    waitpid $pid, 0;
    my $status = $? >> 8;
    # Windows writes the child's text with "\r\n".
    is $said =~ s( \r\n )(\n)gxr, "ran\n",
        'a program leaving an iterator part-read';
    is $warned, '', 'ends without warnings';
    is $status, 0,  'or errors';
};

done_testing;
