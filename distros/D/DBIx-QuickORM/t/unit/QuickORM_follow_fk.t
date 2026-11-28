# Test origin: AI
use Test2::V0;

use DBI;
use DBIx::QuickORM;

my $dbh = DBI->connect('dbi:SQLite::memory:', '', '', {RaiseError => 1});
$dbh->do("CREATE TABLE a (id INTEGER PRIMARY KEY, b1 INTEGER, b2 INTEGER)");
$dbh->do("CREATE TABLE b (id INTEGER PRIMARY KEY, code TEXT UNIQUE)");
$dbh->do("CREATE TABLE lone (id INTEGER PRIMARY KEY)");
$dbh->do("INSERT INTO b (id, code) VALUES (1, 'x'), (2, 'y')");
$dbh->do("INSERT INTO a (id, b1, b2) VALUES (1, 1, 2)");

my $orm = DBIx::QuickORM->new(dbh => $dbh, row_class => undef, fks => {a => {b => [{b1 => 'id'}, {b2 => 'id'}]}});
my $row = $orm->refresh_row('a', {id => 1});

like(dies { $orm->follow_fk(a => $row, 'b') }, qr/^There is more than one foreign key between 'a' and 'b'; choose one with 'link'/, "Two keys without a link croak");
is($orm->follow_fk(a => $row, 'b', link => {b1 => 'id'})->only->{id}, 1, "a link chooses one");
is($orm->follow_fk(a => $row, 'b', link => {b2 => 'id'})->only->{id}, 2, "or the other");
like(dies { $orm->follow_fk(a => $row, 'b', link => {b1 => 'code'}) }, qr/^The link \(b1 => code\) matches no foreign key between 'a' and 'b'/, "A link that matches no key croaks");
like(dies { $orm->follow_fk(a => $row, 'b', link => []) },             qr/^'link' must be a hashref of field => field/,                         "link must be a hashref");
like(dies { $orm->follow_fk(a => $row, 'lone') },                      qr/^There is no foreign key between 'a' and 'lone'/,                     "Tables without a key between them croak");
like(dies { $orm->follow_fk(a => $row, 'nope') },                      qr/^The table 'nope' is not in the database map/,                        "An unknown table croaks");
like(dies { $orm->follow_fk(a => $row, 'b', bogus => 1) },             qr/^Unknown argument\(s\) to follow_fk\(\): bogus/,                      "Unknown arguments croak");
like(dies { $orm->follow_fk(a => 'x', 'b', link => {b1 => 'id'}) },    qr/^follow_fk\(\) needs row data/,                                       "Row data is required");

my $back = $orm->follow_fk(b => {id => 2}, 'a', link => {id => 'b2'});
is($back->state,                  'multi',       "A reverse link to a field that is not unique is multi");
is($back->where,                  {'a.b2' => 2}, "with the row's value in its where, the field qualified");
is([map { $_->{id} } $back->all], [1],           "and finds the rows pointing here");

my $null = $orm->follow_fk(a => {id => 1, b1 => undef}, 'b', link => {b1 => 'id'});
is($null->where, {'b.id' => object { call kind => 'sql'; call value => 'IS NULL AND 1 = 0' }}, "A NULL link value becomes a literal that is never true");
is($null->state, 'single',                                                                     "and keeps the link's state");
is([$null->all], [],                                                                           "so it matches nothing");

my $data = $orm->db_map->tables;
$data->{a}->{fk}->{ghost} = [{b1 => 'id'}];
my $ghostly = DBIx::QuickORM->new(dbh => $dbh, db_map => $data);
like(dies { $ghostly->follow_fk(a => {id => 1}, 'ghost') }, qr/^'a' has a foreign key to 'ghost', which is not in the database map/, "A key to a table outside the map croaks");

subtest caller_line => sub {
    my $file = __FILE__;
    my $line = __LINE__ + 1;
    my $join = dies { $orm->handle('a')->join('b') };
    like($join, qr/^There is more than one foreign key between 'a' and 'b'.* at \Q$file\E line $line\./, "A join's link error reports the caller's line");

    my $obj = DBIx::QuickORM->new(dbh => $dbh, fks => {a => {b => [{b1 => 'id'}, {b2 => 'id'}]}})->handle('a')->find(1);
    $line = __LINE__ + 1;
    my $follow = dies { $obj->follow_fk('lone') };
    like($follow, qr/^There is no foreign key between 'a' and 'lone'.* at \Q$file\E line $line\./, "and so does a row's follow_fk");
};

done_testing;
