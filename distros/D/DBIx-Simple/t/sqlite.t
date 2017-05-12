use Test::More;
use strict;

BEGIN {
    eval { require DBD::SQLite; 1 }
        or plan skip_all => 'DBD::SQLite required';
    eval { DBD::SQLite->VERSION >= 1 }
        or plan skip_all => 'DBD::SQLite >= 1.00 required';

    plan tests => 57;
    use_ok('DBIx::Simple');
}

# In memory database! No file permission troubles, no I/O slowness.
# http://use.perl.org/~tomhukins/journal/31457 ++

my $db = DBIx::Simple->connect('dbi:SQLite:dbname=:memory:');
my $q = 'SELECT * FROM xyzzy ORDER BY foo';

ok($db);

eval { $db->query('SYNTAX ERR0R !@#!@#') };
like($@, qr/prepare failed/);  # test RaiseError

ok($db->query('CREATE TABLE xyzzy (FOO, bar, baz)'));

ok($db->query('INSERT INTO xyzzy (FOO, bar, baz) VALUES (?, ?, ?)', qw(a b c)));

is_deeply([ $db->query($q)->flat ], [ qw(a b c) ]);

ok($db->query('INSERT INTO xyzzy VALUES (??)', qw(d e f)));

is_deeply([ $db->query($q)->flat ], [ qw(a b c d e f) ]);

ok($db->query("INSERT INTO xyzzy VALUES (?, '(??)', ?)", qw(g h)));

is_deeply([ $db->query($q)->flat ], [ qw(a b c d e f g (??) h) ]);

is_deeply(scalar $db->query($q)->list, 'c');

is_deeply([ $db->query($q)->list ], [ qw(a b c) ]);


is_deeply($db->query($q)->array, [ qw(a b c) ]);

is_deeply(scalar $db->query($q)->arrays, [ [ qw(a b c) ], [ qw(d e f) ], [ qw(g (??) h) ] ]);

is_deeply($db->query($q)->hash, { qw(foo a bar b baz c) });

is_deeply(scalar $db->query($q)->hashes, [ { qw(foo a bar b baz c) }, { qw(foo d bar e baz f) }, { qw(foo g bar (??) baz h) } ]);

is_deeply([ $db->query($q)->kv_list ], [ qw(foo a bar b baz c) ]);
is_deeply(scalar
            $db->query($q)->kv_list,   [ qw(foo a bar b baz c) ]);
is_deeply(  $db->query($q)->kv_array , [ qw(foo a bar b baz c) ]);


is_deeply(scalar $db->query($q)->kv_arrays, [ [ qw(foo a bar b baz c) ], [ qw(foo d bar e baz f) ], [ qw(foo g bar (??) baz h) ] ]);
is_deeply(scalar $db->query($q)->kv_flat,   [ qw(  foo a bar b baz c          foo d bar e baz f          foo g bar (??) baz h) ]);

is_deeply(scalar $db->query($q)->columns, [ qw(foo bar baz) ]);

is_deeply([ $db->query($q)->arrays ], scalar $db->query($q)->arrays);
is_deeply([ $db->query($q)->hashes ], scalar $db->query($q)->hashes);
is_deeply([ $db->query($q)->kv_flat ], scalar $db->query($q)->kv_flat);
is_deeply([ $db->query($q)->kv_arrays ], scalar $db->query($q)->kv_arrays);
is_deeply([ $db->query($q)->columns ], scalar $db->query($q)->columns);

is_deeply(scalar $db->query($q)->map_arrays(2), { c => [ qw(a b) ], f => [ qw(d e) ], h => [ qw(g (??)) ] });
is_deeply(scalar $db->query($q)->map_hashes('baz'), { c => { qw(foo a bar b) }, f => { qw(foo d bar e) }, h => { qw(foo g bar (??)) } });
is_deeply(scalar $db->query('SELECT foo, bar FROM xyzzy ORDER BY foo')->map, { qw(a b d e g (??)) });

$db->lc_columns = 0;

is_deeply($db->query($q)->hash, { qw(FOO a bar b baz c) });

is_deeply(scalar $db->query($q)->hashes, [ { qw(FOO a bar b baz c) }, { qw(FOO d bar e baz f) }, { qw(FOO g bar (??) baz h) } ]);

is_deeply(scalar $db->query($q)->columns, [ qw(FOO bar baz) ]);

is_deeply(scalar $db->query($q)->map_hashes('baz'), { c => { qw(FOO a bar b) }, f => { qw(FOO d bar e) }, h => { qw(FOO g bar (??)) } });

$db->lc_columns = 1;

SKIP: {
    eval { require SQL::Interp } or skip "SQL::Interp required", 1;
    my $c = 'c';
    is_deeply(scalar $db->iquery('SELECT * FROM xyzzy WHERE baz =', \$c)->array, [ qw(a b c) ]);
}

SKIP: {
    eval { require Object::Accessor } or skip "Object::Accessor required", 21;

    my $object = $db->query($q)->object;
    isa_ok($object, "DBIx::Simple::Result::RowObject");
    is($object->foo, 'a');
    is($object->bar, 'b', 'bar is b');
    is($object->baz, 'c');

    my @objects = $db->query($q)->objects;
    isa_ok($objects[0], "DBIx::Simple::Result::RowObject");
    is($objects[0]->foo, 'a');
    is($objects[0]->bar, 'b');
    is($objects[0]->baz, 'c');
    isa_ok($objects[1], "DBIx::Simple::Result::RowObject");
    is($objects[1]->foo, 'd');
    is($objects[1]->bar, 'e');
    is($objects[1]->baz, 'f');

    sub Mock::new_from_dbix_simple {
        my ($class, $result, @foo) = @_;
        isa_ok($result, "DBIx::Simple::Result");
        is_deeply(\@foo, [ 42, 21 ]);
        return wantarray;
    }

    ok(! $db->query($q)->object('Mock', 42, 21));  # wantarray false
    is_deeply(     [ $db->query($q)->objects('Mock', 42, 21) ], [ 1 ]);  # wantarray true
    is_deeply(scalar $db->query($q)->objects('Mock', 42, 21),   [ 1 ]);  # wantarray true
}

ok($db->disconnect);
