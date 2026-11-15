use v5.36;
use Test2::V0;
use Test2::Plugin::NoWarnings;

# An object given as a bind value is a value, as plain DBI binds it,
# whatever it's made of: a blessed hash is never taken for the
# attributes, nor a blessed array for a list of values.

use DBI;
use DBIx::Squirrel;
use DBIx::Squirrel::Sugar qw(database);

# Objects of each kind, each a value that prints as itself.
package Obj::Hash {
    use overload q("") => sub { $_[0]{v} }, fallback => 1;
    sub new ($class, $v) { bless {v => $v}, $class }
}

# Its contents aren't its value, so unwrapping it as a list shows.
package Obj::Array {
    use overload q("") => sub { $_[0][0] - 100 }, fallback => 1;
    sub new ($class, $v) { bless [$v + 100], $class }
}

package Obj::Scalar {
    use overload q("") => sub { ${ $_[0] } }, fallback => 1;
    sub new ($class, $v) { bless \$v, $class }
}

package main;

my @source = (
    'dbi:SQLite:dbname=:memory:', '', '',
    {RaiseError => 1, PrintError => 0},
);
my $dbi = DBI->connect(@source);
my $dbh = DBIx::Squirrel->connect(@source);
$_->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)')
    for $dbi, $dbh;
$_->do(q{INSERT INTO artist (name) VALUES ('Abba'), ('Blur'), ('Cream')})
    for $dbi, $dbh;

my %objects = (
    'a blessed hash'   => Obj::Hash->new(2),
    'a blessed array'  => Obj::Array->new(2),
    'a blessed scalar' => Obj::Scalar->new(2),
);
my $sql = 'SELECT name FROM artist WHERE id = ?';

for my $kind (sort keys %objects) {
    my $obj = $objects{$kind};
    subtest "$kind, as plain DBI binds it" => sub {
        my $want = $dbi->selectrow_array($sql, undef, $obj);
        is $want, 'Blur', 'plain DBI binds it as itself';

        is $dbh->selectrow_array($sql, $obj),        $want,   'selectrow_array';
        is $dbh->selectrow_array($sql, undef, $obj), $want,   'after undef';
        is $dbh->selectcol_arrayref($sql, $obj),     [$want], 'selectcol_arrayref';
        is [map { $_->[0] } $dbh->selectall_array($sql, $obj)], [$want],
            'selectall_array';
        is [map { $_->[0] } $dbh->iterate($sql, $obj)->all], [$want],
            'iterate';
        is [map { $_->[0] } $dbh->iterate($sql, $obj, sub { $_ })->all],
            [$want], 'iterate, with a stage';

        my $sth = $dbh->prepare($sql);
        $sth->execute($obj);
        is $sth->fetchrow_arrayref->[0], $want, 'execute';
        $sth->finish;
        is $sth->bind($obj)->execute && $sth->fetchrow_arrayref->[0], $want,
            'bind';
        $sth->finish;

        $dbh->begin_work;
        is $dbh->do('UPDATE artist SET name = name WHERE id = ?', $obj), 1,
            'do';
        $dbh->rollback;
    };
}

subtest 'numbered and named placeholders take objects too' => sub {
    my $obj = Obj::Hash->new(3);
    is $dbh->selectrow_array('SELECT name FROM artist WHERE id = $1', $obj),
        'Cream', 'numbered';
    is $dbh->selectrow_array(
        'SELECT name FROM artist WHERE id = :id',
        id => $obj,
        ),
        'Cream', 'named';
    like dies {
        $dbh->selectrow_array(
            'SELECT name FROM artist WHERE id = :id',
            undef, $obj,
        )
    },
        qr( \A Expected\ names\ and\ values\ in\ pairs )x,
        'an object alone is no hash of named values';
};

subtest "a Sugar database's function takes an object first" => sub {
    database(objects => @source);
    objects()->do('CREATE TABLE artist (id INTEGER PRIMARY KEY, name TEXT)');
    objects()->do(q{INSERT INTO artist (name) VALUES ('Abba')});
    my $sth = objects($sql, Obj::Hash->new(1));
    is $sth->fetchrow_arrayref->[0], 'Abba';
    $sth->finish;
};

subtest 'attributes and lists of values are still plain' => sub {
    is $dbh->selectrow_array($sql, {}, 2), 'Blur', 'a hash, the attributes';
    is $dbh->selectrow_array($sql, [2]), 'Blur', 'an array, the values';
    like dies { $dbh->selectrow_array($sql, \2) },
        qr( \A Expected\ a\ reference\ to\ a\ HASH\ or\ ARRAY )x,
        'any other plain reference croaks';
};

done_testing;
