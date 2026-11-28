# Test origin: AI
use Test2::V0;
use lib 't/lib';

use DBIx::QuickORM;
use DBIx::QuickORM::Test;
use DBIx::QuickORM::Value qw/raw inflated binary sql/;

my %BIN16 = (PostgreSQL => 'BYTEA', SQLite => 'BLOB', DuckDB => 'BLOB', MariaDB => 'BINARY(16)', MySQL => 'BINARY(16)');

# NUL, backslash, and high bytes: binding these as text breaks on backends that need binary binds.
my $UUID  = '005c00ff-fe00-4a5c-8000-00000000005c';
my $BYTES = pack('H*', '005c00fffe004a5c800000000000005c');
my $OTHER = '11111111-2222-4333-8444-555555555555';

do_for_all_dbs {
    my ($db, $set) = @_;

    my $dbh = $db->connect;
    $dbh->do("CREATE TABLE bin_ids (id $BIN16{$set->{family}} NOT NULL PRIMARY KEY, name VARCHAR(32))");
    $dbh->do("CREATE TABLE docs (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(32), data VARCHAR(255))");
    $dbh->do("CREATE TABLE nums (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(32), n INTEGER)");
    $dbh->do("CREATE TABLE texts (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(32))");
    $dbh->do("CREATE TABLE text_keys (k VARCHAR(32) NOT NULL PRIMARY KEY, n INTEGER)");
    $dbh->do("CREATE TABLE nullables (id INTEGER NOT NULL PRIMARY KEY, name VARCHAR(32), n INTEGER)");

    my $orm   = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, types => {bin_ids => {id => 'UUID'}, docs => {data => 'JSON'}});
    my $names = sub { [sort map { $_->{name} } $_[0]->all] };

    subtest where_markers => sub {
        my $h = $orm->handle('bin_ids');
        $h->insert({id => $UUID,  name => 'a'});
        $h->insert({id => $OTHER, name => 'b'});

        is($names->($h->where({id => inflated($UUID)})),                                      ['a'],      "inflated() in where is deflated through the field's type");
        is($names->($h->where({id => inflated(uc $UUID)})),                                   ['a'],      "an uppercase UUID the same way");
        is($names->($h->where({-or => [{id => inflated($UUID)}, {id => inflated($OTHER)}]})), ['a', 'b'], "under -or");
        is($names->($h->where({id => {-in => [inflated($UUID), inflated($OTHER)]}})),         ['a', 'b'], "inside -in");
        is($names->($h->where({id => {'!=' => inflated($UUID)}})),                            ['b'],      "under an operator");
        is($names->($h->where({id => $UUID})),                                                [],         "An unmarked where value is sent as given, so a UUID string does not match bytes");
        is($names->($h->where({id => raw($BYTES)})),                                          ['a'],      "raw() bytes do");
        is($names->($h->where({id => binary($BYTES)})),                                       ['a'],      "and binary() bytes");
        is($names->($h->where(\['id = ?', [token => binary($BYTES)]])),                       ['a'],      "binary() inside literal SQL under a name that is not a field");
        is($h->find(inflated($UUID))->{name},                                                 'a',        "A primary key lookup takes markers");
    };

    subtest undef_markers => sub {
        my $h = $orm->handle('nullables');
        $h->insert({id => 1, name => 'null', n => undef});
        $h->insert({id => 2, name => 'one',  n => 1});

        is($names->($h->where({n => raw(undef)})),                ['null'], "raw(undef) in where gives IS NULL");
        is($names->($h->where({n => inflated(undef)})),           ['null'], "and inflated(undef)");
        is($names->($h->where({n => binary(undef)})),             ['null'], "and binary(undef)");
        is($names->($h->where({n => {'!=' => raw(undef)}})),      ['one'],  "under != it gives IS NOT NULL");
        is($names->($h->where({n => {'!=' => inflated(undef)}})), ['one'],  "for inflated(undef) too");
    };

    subtest json => sub {
        my $h = $orm->handle('docs');
        $h->insert({id => 1, name => 'one', data => raw('{"a":1}')});
        $h->insert({id => 2, name => 'two', data => [2]});
        is($dbh->selectrow_array('SELECT data FROM docs WHERE id = 1'), '{"a":1}', "raw() is stored as given");
        is($names->($h->where({data => raw('{"a":1}')})), ['one'], "raw JSON text in where");
        is($names->($h->where({data => inflated([2])})),  ['two'], "an inflated structure is encoded through the field's type");
        is($names->($h->where({data => '[2]'})),          ['two'], "unmarked text is sent as given");
    };

    subtest sql => sub {
        my $h   = $orm->handle('nums');
        my $row = $h->insert({id => 1, name => sql('lower(?)', 'ABC'), n => sql('1 + 1')});
        is($dbh->selectrow_array('SELECT name FROM nums WHERE id = 1'), 'abc', "sql() is inlined in an insert with its binds");
        is($h->find(1, cache => 0)->{n},                                2,     "and without binds");
        ok(!exists $row->{n} || $row->{n} == 2, "the inserted row holds the database's value or leaves it unfetched");

        my $new = $h->update_row({id => 1}, {n => sql('n + ?', 5)}, enforce_canon => 0);
        is($h->find(1, cache => 0)->{n}, 7, "sql() in update_row changes");

        is($names->($h->where({n => sql('= 3 + ?', 4)})),     ['abc'], "sql() in where supplies its own operator under a field");
        is($h->where({id => 1})->update({n => sql('n * 2')}), 1,       "and works in bulk updates");
        is($h->find(1, cache => 0)->{n},                      14,      "which change the row");

        like(dies { $h->update_row({id => 1, n => sql('14')}, {n => 1}, cas => ['n'], enforce_canon => 0) }, qr/^sql\(\) cannot be used in a primary key or compare-and-swap value/, "sql() in a cas value croaks");
    };

    # A binary() bind on a text field must not leave its bind type on a reused prepared statement.
    subtest binary_on_text_not_reused => sub {
        my $h       = $orm->handle('texts');
        my $is_text = sub {
            my ($id) = @_;
            return 1 unless $set->{family} eq 'SQLite';
            return $dbh->selectrow_array('SELECT typeof(name) FROM texts WHERE id = ?', undef, $id) eq 'text';
        };

        $h->insert({id => 1, name => binary('xyz')});
        $h->insert({id => 2, name => 'abc'});
        is($h->find(2, cache => 0)->{name},                                  'abc', "A plain insert after a binary() one round-trips");
        is($dbh->selectrow_array("SELECT id FROM texts WHERE name = 'abc'"), 2,     "and matches its text");
        ok($is_text->(2), "and is stored as text");

        $h->update_row({id => 1}, {name => binary('xyz')}, enforce_canon => 0);
        $h->update_row({id => 2}, {name => 'def'},         enforce_canon => 0);
        is($h->find(2, cache => 0)->{name},                                  'def', "A plain update_row after a binary() one round-trips");
        is($dbh->selectrow_array("SELECT id FROM texts WHERE name = 'def'"), 2,     "and matches its text");
        ok($is_text->(2), "and is stored as text");

        my $keys = $orm->handle('text_keys');
        $keys->insert({k => $_, n => 1}) for qw/a b c d/;

        # A binary key on a text key column croaks on PostgreSQL and matches nothing on SQLite, so only the
        # plain call after it is checked: it must not reuse the binary call's statement.
        eval { $keys->find(binary('a'), cache => 0) };    # may croak, so only the next call is checked
        is($keys->find('b', cache => 0)->{k}, 'b', "A plain-key find after a binary() one finds its row");
        eval { $keys->delete_row({k => binary('c')}, enforce_canon => 0) };    # may croak, so only the next call is checked
        is($keys->delete_row({k => 'd'}, enforce_canon => 0), 1, "and a plain-key delete_row deletes its row");
        ok(!$dbh->selectrow_array("SELECT k FROM text_keys WHERE k = 'd'"), "which is gone");
    };
};

done_testing;
