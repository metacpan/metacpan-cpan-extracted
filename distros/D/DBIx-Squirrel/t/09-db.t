use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

use DBI;
use DBIx::Squirrel;
use experimental qw(builtin);
use builtin      qw(weaken);

use DBIx::Squirrel::Util qw(iterator_going);

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);

# A database handle of each kind, each with the same table and rows.
sub connect_both {
    my %dbh = (
        dbi      => DBI->connect(@source),
        squirrel => DBIx::Squirrel->connect(@source),
    );
    for my $dbh (values %dbh) {
        $dbh->do('CREATE TABLE artist (id INTEGER, name TEXT)');
        $dbh->do('INSERT INTO artist VALUES (1, ?), (2, ?)', undef, 'AC/DC', 'Accept');
    }
    return \%dbh;
}

subtest "iterate and results prepare with a subclass's prepare" => sub {

    package Counted {    ## no critic (Modules::ProhibitMultiplePackages)
        our @ISA = 'DBIx::Squirrel';
    }

    package Counted::db {    ## no critic (Modules::ProhibitMultiplePackages)
        our @ISA      = 'DBIx::Squirrel::db';
        our $PREPARED = 0;


        sub prepare ($self, @args) {
            $PREPARED++;
            return $self->SUPER::prepare(@args);
        }
    }

    package Counted::st {    ## no critic (Modules::ProhibitMultiplePackages)
        our @ISA = 'DBIx::Squirrel::st';
    }

    my $dbh = Counted->connect(@source);
    $dbh->iterate('SELECT 1')->all;
    $dbh->results('SELECT 1 AS one')->all;
    is $Counted::db::PREPARED, 2, 'both call it';
    $dbh->iterate('SELECT 1 WHERE 1 IN (...?)', [1])->all;
    is $Counted::db::PREPARED, 2,
        'except for a statement taking a list, prepared for its values';
};

subtest 'prepare rewrites each placeholder style as ?' => sub {
    my $dbh = connect_both()->{squirrel};
    for my $p (qw(? ?1 :1 $1 :id)) {
        my $sth = $dbh->prepare("SELECT name FROM artist WHERE id = $p");
        isa_ok $sth, ['DBIx::Squirrel::st'], "$p: a statement handle";
        is $sth->{Statement}, 'SELECT name FROM artist WHERE id = ?',
            "$p: the DBI sees ?";
        $sth->execute($p eq ':id' ? (id => 2) : 2);
        is $sth->fetchrow_arrayref, ['Accept'], "$p: binds the value";
    }
};

subtest 'the statement handle keeps what was studied' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare(" SELECT :a, :b -- two\n ");
    like $sth->{private_ekorn}, {
        Placeholders      => {1 => ':a', 2 => ':b'},
        OriginalStatement => 'SELECT :a, :b -- two',
        Options           => {ekorn_dialect => 'SQLite'},
        },
        'placeholders, the original statement, and the options';
};

subtest 'the forms a statement can take' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $want = 'SELECT name FROM artist WHERE id = ?';
    is $dbh->prepare(['SELECT name', 'FROM artist', 'WHERE id = :id'])
        ->{Statement}, $want, 'lines in an array reference';
    is $dbh->prepare(sub { 'SELECT name FROM artist WHERE id = $1' })
        ->{Statement}, $want, 'a code reference returning a string';
    is $dbh->prepare(sub { ['SELECT name FROM artist', 'WHERE id = ?'] })
        ->{Statement}, $want, 'a code reference returning lines';

    my $sth = $dbh->prepare('SELECT name FROM artist WHERE id = :id');
    is $dbh->prepare($sth)->{private_ekorn}{OriginalStatement},
        'SELECT name FROM artist WHERE id = :id',
        "a DBIx::Squirrel statement handle's original statement";
    my $dbi_sth = DBI->connect(@source)->prepare('SELECT 1');
    is $dbh->prepare($dbi_sth)->{Statement}, 'SELECT 1',
        "a DBI statement handle's statement";
};

subtest 'prepare croaks at the caller' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $line = __LINE__ + 2;
    for my $bad ('', " \n\t", undef, {}, \'SELECT 1') {
        is dies { $dbh->prepare($bad) },
            "Expected a statement at ${\__FILE__} line $line.\n",
            'Expected a statement';
    }
};

subtest 'a statement of only a comment goes to the database' => sub {
    my $dbh = connect_both();
    for my $kind (sort keys %$dbh) {
        my $sth = $dbh->{$kind}->prepare(" -- nothing\n");
        ok $sth->execute, "$kind: executes";
        is $sth->{NUM_OF_FIELDS}, 0, "$kind: with no columns";
    }
};

subtest 'prepare croaks at the caller on mixed placeholder styles' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->prepare('SELECT ?, :x') };
    is $err,
        "Expected one placeholder style, not several (?, :name)"
        . " at ${\__FILE__} line $line.\n",
        'Expected one placeholder style';
};

subtest 'prepare croaks without RaiseError' => sub {
    my $dbh = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:', '', '',
        {RaiseError => 0, PrintError => 0},
    );
    like dies { $dbh->prepare('SELEC 1') }, qr( syntax\ error )x,
        'a bad statement';
    like dies { $dbh->prepare_cached('SELEC 1') },
        qr( \A DBD::SQLite::db\ prepare_cached\ failed: .* syntax\ error )xs,
        'and prepare_cached, naming itself';
};

subtest 'connect takes the attributes without a username or password' => sub {
    my $dbh = DBIx::Squirrel->connect(
        'dbi:SQLite:dbname=:memory:',
        {RaiseError => 1, PrintError => 0, ekorn_slice => {}},
    );
    isa_ok $dbh, ['DBIx::Squirrel::db'], 'a handle';
    is $dbh->{RaiseError}, T(), 'with the attributes for the DBI';
    is $dbh->{private_ekorn}{Options}{ekorn_slice}, {}, 'and its own';
};

subtest 'connect clones a plain DBI handle' => sub {
    my $plain = DBI->connect(@source);
    my $dbh   = DBIx::Squirrel->connect($plain);
    isa_ok $dbh, ['DBIx::Squirrel::db'], "DBIx::Squirrel's handle";
    ref_is_not $dbh, $plain, 'a new one';
    is $dbh->{private_ekorn}{Options}, {ekorn_dialect => 'SQLite'},
        'with the dialect discerned';
    is $dbh->selectrow_array('SELECT :x', undef, x => 1), 1,
        'reading placeholders in any style';
};

subtest 'prepare_cached' => sub {
    my $dbh = connect_both()->{squirrel};
    my @sth = map { $dbh->prepare_cached('SELECT :x') } 1 .. 2;
    ref_is $sth[0], $sth[1], 'caches the statement handle';
    isa_ok $sth[0], ['DBIx::Squirrel::st'], 'a statement handle';
    is $sth[0]{private_ekorn}{Placeholders}, {1 => ':x'},
        'keeps what was studied';
};

subtest 'do gives the same result as the DBI' => sub {
    my $dbh = connect_both();
    for my $kind (sort keys %$dbh) {
        my $h = $dbh->{$kind};
        is $h->do('UPDATE artist SET name = name'), 2, "$kind: no binds";
        is $h->do('UPDATE artist SET name = ? WHERE id = ?', undef, 'x', 1),
            1, "$kind: undef attributes";
        is $h->do('UPDATE artist SET name = ? WHERE id = ?', {}, 'y', 1),
            1, "$kind: a hash of attributes";
        is $h->do('DELETE FROM artist WHERE id = 99'), '0E0',
            "$kind: no rows";
        is [$h->do('UPDATE artist SET name = name')], [2],
            "$kind: one value in list context";
    }
};

subtest "do runs a statement it doesn't rewrite as the driver's do does" =>
    sub {
        my $dbh = connect_both();
        my %got;
        for my $kind (sort keys %$dbh) {
            my $h = $dbh->{$kind};
            $got{$kind} = [
                [$h->do('SELECT * FROM artist')],
                [$h->do('UPDATE artist SET name = name RETURNING id')],
                [$h->do('UPDATE artist SET name = :n RETURNING id', undef, n => 'z')],
            ];
            my $many = $h->clone({sqlite_allow_multiple_statements => 1});
            $many->do('CREATE TABLE a (x); CREATE TABLE b (y)');
            push @{ $got{$kind} }, $many->selectcol_arrayref(
            q{SELECT name FROM sqlite_master WHERE name IN ('a', 'b') ORDER BY name},
            );
        }
        is $got{squirrel}[0], $got{dbi}[0], 'a SELECT, counting its rows';
        is $got{squirrel}[1], $got{dbi}[1], 'an UPDATE ... RETURNING';
        is $got{squirrel}[3], ['a', 'b'],
        'several statements, as DBD::SQLite allows';
        is $got{squirrel}[2], ['0E0'],
        "one rewritten, prepared and executed, counting rows as they're fetched";
    };

subtest 'do returns undef without RaiseError, as the DBI does' => sub {
    my %h = map {
        ($_ => $_->connect(@source[0 .. 2], {RaiseError => 0, PrintError => 0}))
    } qw(DBI DBIx::Squirrel);
    is $h{'DBIx::Squirrel'}->do('SELEC 1'), $h{DBI}->do('SELEC 1'),
        "a statement it doesn't rewrite";
    is $h{'DBIx::Squirrel'}->do('SELEC :x', undef, x => 1), undef,
        'and one it does';
    like $h{'DBIx::Squirrel'}->errstr, qr( syntax\ error )x, 'with the error';
};

subtest 'so do the select methods' => sub {
    my %h = map {
        ($_ => $_->connect(@source[0 .. 2], {RaiseError => 0, PrintError => 0}))
    } qw(DBI DBIx::Squirrel);
    for my $method (qw(
        selectrow_array    selectrow_arrayref selectrow_hashref
        selectall_arrayref selectcol_arrayref))
    {
        my $dbi = $h{DBI};
        my $sq  = $h{'DBIx::Squirrel'};
        is [$sq->$method('SELEC :x', undef, x => 1)],
            [$dbi->$method('SELEC ?', undef, 1)],
            "$method, in list context";
        is scalar($sq->$method('SELEC :x', undef, x => 1)),
            scalar($dbi->$method('SELEC ?', undef, 1)), 'and in scalar context';
    }
    is [$h{'DBIx::Squirrel'}->selectall_hashref('SELEC :x', 'id', undef, x => 1)
        ],
        [$h{DBI}->selectall_hashref('SELEC ?', 'id', undef, 1)],
        'selectall_hashref';
};

subtest 'do takes bind values without attributes' => sub {
    my $dbh = connect_both()->{squirrel};
    is $dbh->do(
        'UPDATE artist SET name = :name WHERE id = :id', name => 'z',
        id => 2,
        ),
        1, 'rows affected';
    is $dbh->selectrow_array(
        'SELECT name FROM artist WHERE id = $1',
        undef, 2,
        ),
        'z', 'and the row changed';
};

subtest 'the select methods take bind values without attributes' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sql = 'SELECT id, name FROM artist WHERE id = :id';
    for my $method (
        qw(selectrow_array    selectrow_arrayref selectrow_hashref),
        qw(selectall_arrayref selectcol_arrayref selectall_array),
    ) {
        is [$dbh->$method($sql, id => 2)], [$dbh->$method($sql, undef, id => 2)],
            "$method, with named values";
    }
    is $dbh->selectall_hashref($sql, 'id', id => 2),
        {2 => {id => 2, name => 'Accept'}},
        'selectall_hashref, after its key field';
    is [$dbh->selectrow_array('SELECT name FROM artist WHERE id = $1', 1)],
        ['AC/DC'], 'with numbered values';
    is [$dbh->selectrow_array('SELECT name FROM artist WHERE id = $1', [1])],
        ['AC/DC'], 'from an array reference';
    is $dbh->selectall_arrayref($sql, {Slice => {}}, id => 1),
        [{id => 1, name => 'AC/DC'}], 'and with attributes, as before';
    is [$dbh->selectrow_array('SELECT ?', undef, undef)], [undef],
        'an undef value first, after undef attributes';
    is [$dbh->selectrow_array($sql, undef, {id => 1})], [1, 'AC/DC'],
        'and values in a hash reference, after undef attributes';
    my $line = __LINE__ + 1;
    is dies { $dbh->selectrow_array($sql, {id => 1}) },
        "Expected a value for each placeholder (none for id) at ${\ __FILE__ } line $line.\n",
        'which are otherwise the attributes, leaving :id with no value';
};

subtest 'do croaks on a reference other than a HASH or ARRAY' => sub {
    my $dbh  = connect_both()->{squirrel};
    my $code = sub { 1 };
    my $line = __LINE__ + 1;
    my $err  = dies { $dbh->do('SELECT ?', $code) };
    is $err,
        "Expected a reference to a HASH or ARRAY at ${\__FILE__} line $line.\n",
        'a code reference';
};

subtest "prepare reads a statement by its driver's rules" => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare(q{SELECT 'C:\', :x});
    $sth->execute(x => 'y');
    is $sth->fetchrow_arrayref, ['C:\\', 'y'],
        "SQLite: a backslash doesn't escape the quote";

    # No MySQL server here, so give _study a handle naming its driver.
    my $mysql = {Driver => {Name => 'mysql'}};
    my($normalised, $state)
        = DBIx::Squirrel::db::_study($mysql, q{SELECT 'it\'s :no', :x}, undef);    ## no critic (Subroutines::ProtectPrivateSubs)
    is $normalised, q{SELECT 'it\'s :no', ?}, 'MySQL: it does';
    is $state->{Placeholders}, {1 => ':x'}, 'MySQL: one placeholder';
};

## no critic (Subroutines::ProtectPrivateSubs)
# No PostgreSQL or MySQL server here, so give _study handles naming their
# drivers.
subtest 'the options a statement is studied with' => sub {
    my $sql         = q{SELECT :x, :y};
    my $pg          = {Driver => {Name => 'Pg'}, pg_placeholder_dollaronly => 1};
    my($normalised) = DBIx::Squirrel::db::_study($pg, $sql, undef);
    is $normalised, $sql, "DBD::Pg's options are read from the handle";
    ($normalised) = DBIx::Squirrel::db::_study(
        $pg, $sql,
        {pg_placeholder_dollaronly => 0},
    );
    is $normalised, 'SELECT ?, ?', "and prepare's attributes override them";

    my $sqlite = {Driver => {Name => 'SQLite'}, pg_placeholder_dollaronly => 1};
    ($normalised) = DBIx::Squirrel::db::_study($sqlite, $sql, undef);
    is $normalised, 'SELECT ?, ?', "they're not read from another driver";

    my($state, $dbi_attrs);
    ($normalised, $state, $dbi_attrs) = DBIx::Squirrel::db::_study(
        $sqlite, q{SELECT 'it\'s :no', :x},
        {ekorn_dialect => 'mysql', RaiseError => 1},
    );
    is $normalised, q{SELECT 'it\'s :no', ?},
        'ekorn_dialect overrides the driver, as for MySQL through ODBC';
    is $dbi_attrs, {RaiseError => 1}, "and doesn't reach the DBI";
    is +(DBIx::Squirrel::db::_study($sqlite, $sql, undef))[2], undef,
        'no attributes in, none out';
};

subtest 'a statement is studied once for each handle' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sql = 'SELECT name FROM artist WHERE id = :id';
    my $one = $dbh->prepare($sql);
    my $two = $dbh->prepare($sql);
    ok $dbh->{private_ekorn_studied}{Statements}{$sql}, 'kept by the handle';
    is $two->{private_ekorn}, $one->{private_ekorn}, 'each handle the same';
    ref_is_not $two->{private_ekorn}, $one->{private_ekorn}, 'but its own';
    my @names = $one->iterate(id => 1)->all;
    ok !$two->{private_ekorn}{Iterator}, "so an iterator isn't another's";
    my $other = 'SELECT id FROM artist WHERE name = :name';
    $dbh->prepare($other, {ekorn_slice => {}});
    ok !$dbh->{private_ekorn_studied}{Statements}{$other},
        'not kept with attributes';

    my $pg = {
        Driver                    => {Name => 'Pg'},
        pg_placeholder_dollaronly => 1,
    };
    my($normalised) = DBIx::Squirrel::db::_study($pg, 'SELECT :x', undef);
    is $normalised, 'SELECT :x', "with DBD::Pg's options on the handle";
    $pg->{pg_placeholder_dollaronly} = 0;
    ($normalised) = DBIx::Squirrel::db::_study($pg, 'SELECT :x', undef);
    is $normalised, 'SELECT ?', 'kept apart when they change';

    my $sqlite = {Driver => {Name => 'SQLite'}};
    DBIx::Squirrel::db::_study($sqlite, "SELECT $_", undef) for 1 .. 1000;
    is scalar(keys %{ $sqlite->{private_ekorn_studied}{Statements} }), 1000,
        'up to 1000';
    DBIx::Squirrel::db::_study($sqlite, 'SELECT 1001', undef);
    is [keys %{ $sqlite->{private_ekorn_studied}{Statements} }],
        ['SELECT 1001'],
        'then started again';
};
## use critic

subtest 'prepare takes ekorn_ attributes' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sth = $dbh->prepare('SELECT :x', {ekorn_dialect => 'SQLite'});
    $sth->execute(x => 1);
    is $sth->fetchrow_arrayref, [1], 'and prepares the statement';
};

subtest 'connect_cached returns the cached handle' => sub {
    my sub cached (%ekorn) {
        return DBIx::Squirrel->connect_cached(
            @source[0 .. 2],
            {%{ $source[3] }, %ekorn},
        );
    }
    ref_is cached(), cached(), 'without ekorn_ attributes';
    my $dbh = cached(ekorn_finish_active => 1);
    ref_is cached(ekorn_finish_active => 1), $dbh, 'and with them';
    is $dbh->{private_ekorn}{Options}{ekorn_finish_active}, 1, 'which it keeps';
    ref_is_not cached(ekorn_finish_active => 0), $dbh, 'but not with others';
};

subtest 'connect takes ekorn_ attributes as defaults' => sub {
    my $dbh = DBIx::Squirrel->connect(
        @source[0 .. 2], {
            %{ $source[3] }, ekorn_dialect => 'mysql',
        },
    );
    is $dbh->{private_ekorn}, {Options => {ekorn_dialect => 'mysql'}},
        'kept in the private_ekorn attribute';
    is $dbh->{ekorn_dialect}, undef, 'not passed on to the DBI';

    my($normalised) = DBIx::Squirrel::db::_study(    ## no critic (Subroutines::ProtectPrivateSubs)
        $dbh, q{SELECT 'it\'s :no', :x}, undef,
    );
    is $normalised, q{SELECT 'it\'s :no', ?}, 'statements are read by them';
    is $dbh->prepare('SELECT :x')->{private_ekorn}{Options}{ekorn_dialect},
        'mysql', 'and keep them';
    is $dbh->prepare('SELECT :x', {ekorn_dialect => 'SQLite'})
        ->{private_ekorn}{Options}{ekorn_dialect},
        'SQLite', "prepare's attributes override them";

    is DBIx::Squirrel->connect($dbh)->{private_ekorn},
        {Options => {ekorn_dialect => 'mysql'}}, 'a clone keeps them';
    is DBIx::Squirrel->connect($dbh, {ekorn_dialect => 'Pg'})->{private_ekorn},
        {Options => {ekorn_dialect => 'Pg'}}, 'unless given others';
    is $dbh->{private_ekorn}, {Options => {ekorn_dialect => 'mysql'}},
        "and the first handle's are unchanged";

    is DBIx::Squirrel->connect(@source)->{private_ekorn},
        {Options => {ekorn_dialect => 'SQLite'}},
        "a handle without them is given its driver's dialect";
    is DBIx::Squirrel->connect(@source)->prepare('SELECT :x')
        ->{private_ekorn}{Options}{ekorn_dialect},
        'SQLite', "and statements are read by the driver's rules";
};

# A database handle, standing in for one whose driver passes the
# connection on to another database, and says what it is, or doesn't.
package Stand::In {
    sub get_info ($self, $type) { return $type == 17 ? $self->{dbms} : undef }
}


sub stand_in ($driver, $dbms = undef) {
    return bless {Driver => {Name => $driver}, dbms => $dbms}, 'Stand::In';
}

subtest 'connect discerns the dialect' => sub {
    my $dialect = \&DBIx::Squirrel::_dialect;    ## no critic (Variables::ProtectPrivateVars)
    is $dialect->(stand_in('mysql', 'PostgreSQL')), 'mysql',
        "a driver's own name, without asking the database";
    is $dialect->(stand_in('ODBC',  'MySQL')),   'mysql',   'MySQL through ODBC';
    is $dialect->(stand_in('ODBC',  'MariaDB')), 'MariaDB', 'MariaDB';
    is $dialect->(stand_in('Proxy', 'PostgreSQL')), 'Pg',
        'PostgreSQL through Proxy';
    is $dialect->(stand_in('ODBC', 'Microsoft SQL Server')), 'ODBC',
        "a database with no rules of its own";
    is $dialect->(stand_in('ODBC')), 'ODBC', "a database that doesn't say";

    my $gofer = DBIx::Squirrel->connect(
        'dbi:Gofer:transport=null;dsn=dbi:SQLite:dbname=:memory:', '', '',
        $source[3],
    );
    is $gofer->{private_ekorn}{Options}{ekorn_dialect}, 'SQLite',
        'SQLite through Gofer, connected';
    is $gofer->{RaiseError}, T(), 'leaving RaiseError as it was';
};

subtest 'do binds an array reference of values' => sub {
    my $dbh = connect_both()->{squirrel};
    is $dbh->do('UPDATE artist SET name = ? WHERE id = ?', ['w', 1]), 1,
        'with ? placeholders';
    is $dbh->do('UPDATE artist SET name = $1 WHERE id = $2', ['x', 1]), 1,
        'and numbered ones';
    is $dbh->selectrow_array('SELECT name FROM artist WHERE id = 1'), 'x',
        'binding each value to its own placeholder';
};

subtest "prepare_cached and DBIx::Squirrel's own attributes" => sub {
    my $dbh = connect_both()->{squirrel};
    my $sql = 'SELECT id, name FROM artist ORDER BY id';
    ref_is_not $dbh->prepare_cached($sql, {ekorn_slice => {}}),
        $dbh->prepare_cached($sql), 'others give another handle';
    ref_is $dbh->prepare_cached($sql, {ekorn_slice => {}}),
        $dbh->prepare_cached($sql, {ekorn_slice => {}}), 'the same, the same';

    my $sth = $dbh->prepare_cached($sql);
    my $it  = $sth->iterate;
    $it->next;
    ref_is $dbh->prepare_cached($sql, undef, 2), $sth,
        'a handle, cached, as it is';
    ref_is iterator_going($sth), $it, 'keeps the iterator using it';
    weaken(my $gone = $it);
    undef $it;
    ok !$gone, 'without keeping it from being freed';
};

subtest 'prepare_cached and a handle an iterator is using' => sub {
    my $dbh = connect_both()->{squirrel};
    my $sql = 'SELECT id, name FROM artist ORDER BY id';
    my $sth = $dbh->prepare_cached($sql);
    my $it  = $sth->iterate(sub ($row) {
        $row->[1];
    });
    is $it->next, 'AC/DC', 'an iterator, part way';
    my $new = $dbh->prepare_cached($sql);
    ref_is_not $new, $sth, 'gives a new handle';
    ref_is $dbh->prepare_cached($sql), $new, 'cached in its place';
    is [$it->all], ['Accept'], 'leaving the iterator its results';

    my $other = $new->iterate;
    $other->next;
    ref_is_not $dbh->prepare_cached($sql, undef, 3), $new,
        'whatever $if_active says, but 2';

    my $plain = $dbh->prepare_cached($sql);
    $plain->execute;
    $plain->fetchrow_arrayref;
    like warning { $dbh->prepare_cached($sql) }, qr( still\ Active )x,
        'a handle active without an iterator warns, as with the DBI';
    ok !$plain->{Active}, 'and is finished';
};

subtest 'prepare_cached keeps statements rewritten the same apart' => sub {
    my $dbh = connect_both()->{squirrel};
    my $ab  = $dbh->prepare_cached('SELECT :a, :b');
    my $ba  = $dbh->prepare_cached('SELECT :b, :a');
    ok $ab != $ba, 'giving each its own handle';
    is $ab->{private_ekorn}{Placeholders}, {1 => ':a', 2 => ':b'},
        'the first keeps its placeholders';
    is $ba->{private_ekorn}{Placeholders}, {1 => ':b', 2 => ':a'},
        'and so does the second';
    $ab->execute(a => 1, b => 2);
    is $ab->fetchrow_arrayref, [1, 2], 'each binding by its own names';
    $ba->execute(a => 1, b => 2);
    is $ba->fetchrow_arrayref, [2, 1], 'in its own order';
    $_->finish for $ab, $ba;
    ref_is $dbh->prepare_cached('SELECT :b, :a'), $ba,
        'and the same statement still gets the cached handle';
};

done_testing;
