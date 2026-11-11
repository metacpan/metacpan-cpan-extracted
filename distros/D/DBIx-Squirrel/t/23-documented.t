use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# Claims the reference makes that no other test checks, each subtest
# named for the reference's section (roadmap 2026-0007).

use DBI;
use DBIx::Squirrel;
use DBIx::Squirrel::Context qw(result_number result_original);
use DBIx::Squirrel::Pipeline;
use DBIx::Squirrel::Stages::Rows;
use DBIx::Squirrel::Stop;
use DBIx::Squirrel::Sugar qw(database statement);

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# Sugar's databases below are all defined with @source, so they share
# one in-memory database, as connect_cached gives them one handle: each
# makes a table of its own name.

# A pattern for where an error was reported: at this file's line, at
# the end of the message.
sub at_line ($line) {
    return qr( \ at\ \Q${\ __FILE__ }\E\ line\ $line\. \n \z )x;
}

# A handle with the examples' artists.
sub music () {
    my $dbh = DBIx::Squirrel->connect(@source);
    $dbh->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    $dbh->do('INSERT INTO artist (name) VALUES (?)', undef, $_)
        for qw(Abba Blur Cream);
    return $dbh;
}

# A subclass of DBIx::Squirrel without handle classes of its own.
package My::Bare {
    our @ISA = 'DBIx::Squirrel';
}

subtest 'connect' => sub {
    my @bad = (
        'dbi:SQLite:dbname=/nonexistent/x.db', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    my $line;
    like dies { $line = __LINE__; DBIx::Squirrel->connect(@bad) },
        at_line($line),
        'croaks at the line that called it, without RaiseError';
};

subtest 'Connecting with an existing handle' => sub {
    my $dbh   = music();
    my $clone = DBIx::Squirrel->connect($dbh);
    is $clone->selectall_arrayref(
        q{SELECT name FROM sqlite_master WHERE type = 'table'}),
        [], 'is a separate connection: in memory, a new, empty database';
    is $clone->{RaiseError}, T(), 'with the same attributes';
};

subtest 'connect_cached' => sub {
    my @bad = (
        'dbi:SQLite:dbname=/nonexistent/x.db', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    my $line;
    my $err = dies { $line = __LINE__; DBIx::Squirrel->connect_cached(@bad) };
    like $err, qr( \A DBIx::Squirrel\ connect\( )x, 'croaks on failure too';
    like $err, at_line($line),                      'at the caller';
};

subtest 'Subclassing' => sub {
    my @warnings;
    local $SIG{__WARN__} = sub ($w) { push @warnings, $w };
    my $dbh = My::Bare->connect(@source);
    like \@warnings, [qr( My::Bare )x], 'without handle classes, the DBI warns';
    is ref($dbh), 'DBI::db', 'and returns its own handles';
};

subtest 'The styles' => sub {
    my $dbh = music();
    is [$dbh->selectrow_array('SELECT $2 + $1, $1', undef, 10, 20)], [30, 10],
        'a numbered placeholder is bound once, wherever it appears';
    my $sth
        = $dbh->prepare('SELECT name FROM artist WHERE id = :id OR id = :id');
    for my $values ([id => 2], [{id => 2}], [{':id' => 2}], [':id' => 2]) {
        $sth->execute(@$values);
        is $sth->fetchall_arrayref, [['Blur']], 'a named one is bound by name, '
            . 'given as pairs or in a hash, with or without the sigil';
    }
    $sth = $dbh->prepare('SELECT name FROM artist WHERE id = $id');
    $sth->execute({'$id' => 3});
    is $sth->fetchall_arrayref, [['Cream']], 'with the sigil of $name too';
    like dies { $sth->execute(id => 1, other => 2) },
        qr( \A \QExpected a placeholder of the statement (other)\E )x,
        'and needs a value for each name, and no other';
};

subtest 'Lists' => sub {
    database(listed => @source);
    database('listed')->do('CREATE TABLE n (id INTEGER)');
    database('listed')->do('INSERT INTO n VALUES (?)', undef, $_) for 1 .. 3;
    statement(
        some => listed => 'SELECT id FROM n WHERE id IN (...:ids) ORDER BY id',
        sub { $_->[0] },
    );
    is [some(ids => [1, 3])], [1, 3], 'a Sugar statement takes a list';
    is [some(ids => [2])],    [2],    'of any length';
    is scalar(keys %{ database('listed')->{CachedKids} // {} }), 0,
        "and isn't cached, as each length makes another statement";
};

subtest 'prepare_cached' => sub {
    my $dbh = music();
    my $sql = 'SELECT name FROM artist ORDER BY id';
    my $sth = $dbh->prepare_cached($sql);
    my $it  = $sth->iterate;
    $it->next;
    ref_is $dbh->prepare_cached($sql, undef, 2), $sth,
        '$if_active of 2 hands out the cached handle, part way through';
    is $it->next, ['Blur'], 'unchanged';
};

subtest 'bind' => sub {
    my $dbh = music();
    my $sth = $dbh->prepare('SELECT :a, :b');
    my $line;
    my $err = dies { $line = __LINE__; $sth->bind(a => 1, 'b') };
    like $err, qr( \A \QExpected names and values in pairs\E )x,
        'croaks on an odd number of named values';
    like $err, at_line($line), 'at the caller';

    my $quiet = DBIx::Squirrel->connect(
        @source[0 .. 2],
        {RaiseError => 0, PrintError => 0},
    );
    $sth = $quiet->prepare('SELECT ?');
    my $mock = mock 'DBI::st' => (override => [bind_param => sub { return }]);
    is [$sth->bind(1)], [], "returns nothing if the DBI couldn't bind a value";
};

subtest 'The select methods' => sub {
    my $dbh = music();
    my $sql = 'SELECT name FROM artist WHERE id = :id';
    is [$dbh->selectrow_array($sql, undef, {id => 2})], ['Blur'],
        'named values in a hash reference, after the attributes';
    like dies { $dbh->selectrow_array($sql, {id => 2}) },
        qr( \A \QExpected a value for each placeholder (none for id)\E )x,
        'without them, the hash reference is the attributes';
    is $dbh->selectall_hashref(
        'SELECT id, name FROM artist WHERE id = :id',
        'id', id => 3,
        ),
        {3 => {id => 3, name => 'Cream'}},
        "selectall_hashref's values follow its key field";
};

subtest 'iterate' => sub {
    my $dbh = music();
    my $it  = $dbh->iterate('SELECT name FROM artist ORDER BY id');
    ok !$it->sth->{Executed},
        "the statement isn't executed until a result is asked for";
    $it->next;
    ok $it->sth->{Executed}, 'and is then';
    $it->all;
    ok !$it->sth->{Active}, "it's finished when the results run out";
};

# A row class with a method named as a column.
package My::Named {    ## no critic (Modules::ProhibitMultiplePackages)
    our @ISA = 'DBIx::Squirrel::Result';
    sub name ($self) { return 'mine' }
}

subtest 'Row objects' => sub {
    my $dbh = music();
    my $row = $dbh->results(
        'SELECT id, name FROM artist WHERE id = 1',
        {ekorn_result_class => 'My::Named'},
    )->single;
    is $row->name, 'mine',
        "a column named as one of your own methods gets no method";
    is $row->get_column('name'), 'Abba', 'get_column reaches it';
    is $row->id,                 1,      'other columns get theirs';
};

subtest 'Pipelines' => sub {
    my @inc = map { "-I$_" } grep { !ref } @INC;
    for my $module (qw(
        Pipeline     Gather Stop Context Stages::Flow Stages::Batch
        Stages::Taps Stages::Rows))
    {
        my $code = qq{use DBIx::Squirrel::$module; print \$INC{'DBI.pm'} ? 1 : 0};
        open my $child, '-|', $^X, @inc, '-e', $code
            or die "Can't run $^X: $!";    ## no critic (ErrorHandling::RequireCarping)
        my $loaded = do { local $/ = undef; <$child> };
        close $child;
        is $loaded, '0', "loading DBIx::Squirrel::$module doesn't load the DBI";
    }
};

subtest "A pipeline's stages" => sub {
    my $dbh   = music();
    my $count = DBIx::Squirrel::Pipeline->new(
        sub ($dbh) { $dbh->selectrow_array('SELECT COUNT(*) FROM artist') },
        sub { $_ * 10 },
    );
    is [$dbh->pipe($count)], [30], 'a pipeline can be given to pipe';
    my $seen;
    my $note = DBIx::Squirrel::Pipeline->new(sub ($dbh) {
        $seen = ref $dbh;
        ();
    });
    ref_is $dbh->tap($note), $dbh, 'and to tap';
    is $seen, 'DBIx::Squirrel::db', 'whose stages see the handle';

    my $names = DBIx::Squirrel::Pipeline->new(sub { $_->[1] }, sub { uc });
    my $all   = 'SELECT id, name FROM artist ORDER BY id';
    my $it    = $dbh->iterate($all);
    is [$it->reset($names)->all], [qw(ABBA BLUR CREAM)], 'and to reset';
    is [$dbh->results($all, $names)->all], [qw(ABBA BLUR CREAM)],
        'and to results, straight after the statement';

    my $until_blur = DBIx::Squirrel::Pipeline->new(
        sub { Stop() if $_->[1] eq 'Blur'; $_ },
        sub { result_number . ". $_->[1]" },
    );
    $it = $dbh->iterate($all, $until_blur);
    is [$it->all], ['1. Abba'],
        'a stop inside it stops the iteration, and result_number counts there';
    ok !$it->sth->{Active}, 'finishing the statement';

    database(piped => @source);
    database('piped')->do('CREATE TABLE p (id INTEGER, name TEXT)');
    database('piped')->do(q{INSERT INTO p VALUES (1, 'x')});
    is [piped('SELECT id, name FROM p', $names)], ['X'],
        "and to a database's function, straight after the statement";
};

package Named::Only {    ## no critic (Modules::ProhibitMultiplePackages)
    use DBIx::Squirrel::Stages::Flow qw(take_while);
}

package Named::And::Defaults {    ## no critic (Modules::ProhibitMultiplePackages)
    use DBIx::Squirrel::Stages::Flow qw(:DEFAULT take_while);
}

subtest 'Canned stages' => sub {
    ok !Named::Only->can('take'),      'naming a stage replaces the defaults';
    ok Named::Only->can('take_while'), 'with the one named';
    ok Named::And::Defaults->can('take')
        && Named::And::Defaults->can('take_while'),
        ':DEFAULT keeps them, with the one named';

    my $expected = 'Expected an iterator, for the column names';
    like dies { DBIx::Squirrel::Pipeline->new(pluck('name'))->([1, 'Abba']) },
        qr( \Q$expected\E )x, 'pluck by name, on an array, needs an iterator';
    like dies { DBIx::Squirrel::Pipeline->new(as_hash)->([1, 'Abba']) },
        qr( \Q$expected\E )x, 'and so does as_hash';
    is [DBIx::Squirrel::Pipeline->new(pluck(1))->([1, 'Abba'])], ['Abba'],
        'pluck by position needs none';
    is [DBIx::Squirrel::Pipeline->new(pluck('name'))->({name => 'Abba'})],
        ['Abba'],
        'nor does pluck by name, on a hash';
};

subtest 'What a stage can ask: Context' => sub {
    my $dbh = music();
    my($original) = $dbh->results(
        'SELECT id, name FROM artist WHERE id = 1',
        sub { result_original },
    )->all;
    isa_ok $original, ['DBIx::Squirrel::Result'],
        "result_original, for a result set, is the row object";
    is $original->name, 'Abba', 'as fetched';
};

# A module of stages of your own, as Writing stages says.
package My::Stages {    ## no critic (Modules::ProhibitMultiplePackages)
    use DBIx::Squirrel::Errors qw(croakf);
    our @CARP_NOT = @DBIx::Squirrel::Errors::INTERNAL;


    sub no_blur () {
        return sub ($row) {
            croakf 'Expected no Blur (%s)', $row->[0] if $row->[0] eq 'Blur';
            return $row;
        };
    }
}

subtest 'Writing stages' => sub {
    my $dbh = music();
    my $it  = $dbh->iterate('SELECT name FROM artist', My::Stages::no_blur());
    my $line;
    my $err = dies { $line = __LINE__; $it->all };
    like $err, qr( \n\ {4}\QExpected no Blur (Blur)\E )x,
        "a module of stages with DBIx::Squirrel's \@CARP_NOT croaks";
    like $err, at_line($line), 'at the line that asked for the result';
};

package Elsewhere {    ## no critic (Modules::ProhibitMultiplePackages)
    use DBIx::Squirrel::Sugar qw(database);
    sub handle ($name) { return database($name) }
}

subtest 'database' => sub {
    database(shared_one => @source);
    database(shared_two => @source);
    ref_is Elsewhere::handle('shared_one'), database('shared_one'),
        'a database is found by name anywhere in the program';
    ref_is database('shared_two'), database('shared_one'),
        'two defined with the same arguments share a handle';

    my $original = DBIx::Squirrel->connect(@source);
    my $clones   = 0;
    my $mock     = mock 'DBI::db' => (around => [
        clone => sub ($orig, @args) {
            $clones++;
            return $orig->(@args);
        },
    ]);
    database(lazy_copy => $original);
    is $clones, 0, 'one defined with a handle is not cloned when defined';
    database('lazy_copy');
    is $clones, 1, 'but when first used';
};

subtest 'The function a statement is given' => sub {
    database(staged => @source);
    database('staged')->do('CREATE TABLE a (name TEXT)');
    database('staged')->do('INSERT INTO a VALUES (?)', undef, $_) for qw(x y);
    statement(
        names_of => staged => 'SELECT name FROM a ORDER BY name',
        sub { $_->[0] },
    );
    is [names_of(sub { uc })], [qw(X Y)], 'stages given go after its own';
    is [names_of()],           [qw(x y)], 'for that call only';
};

done_testing;
