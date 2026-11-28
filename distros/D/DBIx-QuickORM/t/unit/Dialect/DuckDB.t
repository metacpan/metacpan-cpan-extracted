# Test origin: AI
use Test2::V0;

use DBIx::QuickORM::Dialect::DuckDB;

my $D = 'DBIx::QuickORM::Dialect::DuckDB';

isa_ok($D, ['DBIx::QuickORM::Dialect'], "Inherits the defaults");
is($D->supports_savepoints,                                                                            0,         "No savepoints");
is($D->bind_limit,                                                                                     7000,      "Bind limit");
is($D->supports_second_connection(undef),                                                              0,         "No second connection (exclusive file lock)");
is([map { $D->$_ } qw/supports_returning_insert supports_returning_update supports_returning_delete/], [1, 1, 1], "RETURNING everywhere");

like(dies { $D->begin_sql('SERIALIZABLE') }, qr/^The DuckDB dialect cannot set a transaction isolation level/, "No isolation level");
is($D->supports_isolation, 0, "and supports_isolation says so");

my @sql;
my $dbh = mock {} => (add => [do => sub { push @sql => $_[1]; 1 }, quote => sub { "'$_[1]'" }]);
$D->init_session($dbh, 'Asia/Tokyo');
is(\@sql, ["SET TimeZone = 'Asia/Tokyo'"], "The time zone is passed through as given");

$dbh = mock {} => (add => [selectall_arrayref => sub { [["caf\xc3\xa9", undef, 1], ['plain', "\xe2\x98\xba", 2]] }]);
is($D->_rows($dbh, 'SQL'), [["caf\x{e9}", undef, 1], ['plain', "\x{263a}", 2]], "Scan rows are decoded from UTF-8");
my %messages = (
    'Constraint Error: Duplicate key "id: 1" violates primary key constraint.'                                     => 'unique_violation',
    'Constraint Error: Duplicate key "u: 1" violates unique constraint.'                                           => 'unique_violation',
    'Constraint Error: PRIMARY KEY or UNIQUE constraint violation: duplicate key "1"'                              => 'unique_violation',
    'Constraint Error: NOT NULL constraint failed: t.n'                                                            => 'not_null_violation',
    'Constraint Error: CHECK constraint failed on table t with expression CHECK((c > 0))'                          => 'check_violation',
    'Constraint Error: Violates foreign key constraint because key "id: 9" does not exist in the referenced table' => 'foreign_key_violation',
    'TransactionContext Error: Catalog write-write conflict on alter with "t"'                                     => 'serialization_failure',
    'TransactionContext Error: Conflict on tuple deletion!'                                                        => 'serialization_failure',
    'Catalog Error: Table with name nope does not exist!'                                                          => undef,
);
is($D->error_kind(1, 'S1000', $_),    $messages{$_}, "Kind from the message: $_") for sort keys %messages;
is($D->error_kind(1, 'S1000', undef), undef,         "No message, no kind");

my @values = ("caf\xc3\xa9", undef, 1, [1], 'plain');
$D->text_from_db(@values);
is(\@values, ["caf\x{e9}", undef, 1, [1], 'plain'], "text_from_db decodes in place");

my $latin = "caf\xe9";
ok(!utf8::is_utf8($latin), "A Latin-1 string that was never upgraded");
$D->text_to_db($latin);
ok(utf8::is_utf8($latin), "is upgraded in place");
is($latin, "caf\x{e9}", "without changing its characters");

require DBIx::QuickORM::Dialect;
my ($in, $out) = ("caf\xc3\xa9", "caf\xe9");
DBIx::QuickORM::Dialect->text_from_db($in);
DBIx::QuickORM::Dialect->text_to_db($out);
is([$in, utf8::is_utf8($out) ? 1 : 0], ["caf\xc3\xa9", 0], "The base dialect leaves text alone");

done_testing;
