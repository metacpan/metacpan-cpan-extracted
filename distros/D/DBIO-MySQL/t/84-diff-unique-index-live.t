use strict;
use warnings;
use Test::More;

# LIVE half of karr k70: DBIO::MySQL::Deploy->upgrade brings a unique key to
# the database -- one that was added to the schema, one whose columns changed,
# one that was removed, and the one of a table the upgrade itself creates.
#
# WHY IT MATTERS. The diff used to skip every unique index (t/43 has the
# reason and the offline half). An upgrade therefore said "nothing to do" while
# the schema demanded a unique key the database did not have, and duplicates
# went into a table whose schema forbade them. t/43 pins what the diff says for
# two models; whether a server takes the statements, in that order, and then
# really refuses the duplicate, is what this file shows.
#
# What this file claims, each time through upgrade() of a schema against a
# database that has an earlier version of it:
#   1. a unique key added to a table that is there is created, and the
#      duplicate it forbids is refused by the server afterwards;
#   2. a unique key whose columns changed is dropped and created again over
#      the new columns: what the old one refused goes in, what the new one
#      forbids is refused;
#   3. an index that became unique is rebuilt as a unique one;
#   4. a unique key that left the schema is dropped, and the duplicate goes in;
#   5. a table the upgrade creates gets its unique key, in a statement after
#      the CREATE TABLE, and refuses the duplicate;
#   6. after every one of them the next diff has nothing left to say.
# The duplicates are tried before the upgrade as well, where they must go in:
# the refusal afterwards is then the key's and not the fixture's.
#
# NOT claimed: anything about a unique key a foreign key hangs on, or about one
# that goes together with its column. Neither is this card's.
#
# Gated like the other live tests: needs DBIO_TEST_MYSQL_DSN, _USER and _PASS.
# Works in a database of its own, created and dropped here: upgrade() is a
# statement about a whole database -- it drops every table the schema does not
# name -- and the database the DSN names is shared with the rest of the suite.
# The account has to be allowed CREATE DATABASE, which a diff needs anyway for
# its temporary database (_dbio_tmp_*, probed up front: karr k105).

my ($dsn, $user, $pass) = @ENV{ map { "DBIO_TEST_MYSQL_${_}" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MYSQL_DSN}, _USER and _PASS to run this test'
  unless $dsn && $user;

use DBI;
use DBIO::MySQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use DiffTempDbProbe qw(temp_db_skip_reason);

my $DB = "dbio_k70_$$";

my $raw = DBI->connect($dsn, $user, $pass, { AutoCommit => 1, RaiseError => 1, PrintError => 0 });
my ($dbd) = $dsn =~ /\Adbi:(\w+):/;

sub drop_database { local $raw->{Warn} = 0; $raw->do("DROP DATABASE IF EXISTS `$DB`") }
END {
  if ($raw) {
    local ($@, $?);
    eval { drop_database() };
  }
}

unless (eval { drop_database(); $raw->do("CREATE DATABASE `$DB`"); 1 }) {
  my $why = "$@";
  undef $raw;
  plan skip_all => "this account may not create a database of its own, and a diff needs one too: $why";
}
if (my $why = temp_db_skip_reason($raw)) { plan skip_all => $why }
note sprintf 'server %s, DBD::%s %s, database %s', scalar $raw->selectrow_array('SELECT VERSION()'),
  $dbd, "DBD::$dbd"->VERSION, $DB;

# ---------------------------------------------------------------------------
# The schema, in the versions it goes through
# ---------------------------------------------------------------------------
my @ACCOUNT_COLUMNS = (
  id     => { data_type => 'integer', is_auto_increment => 1 },
  email  => { data_type => 'varchar', size => 190 },
  tenant => { data_type => 'integer' },
  handle => { data_type => 'varchar', size => 64 },
);

# The table an upgrade creates has a text column, and claim 6 is asked of it
# too: its collation is the schema's (karr k82).
my @VOUCHER_COLUMNS = (
  id     => { data_type => 'integer', is_auto_increment => 1 },
  batch  => { data_type => 'integer' },
  serial => { data_type => 'varchar', size => 64 },
);

# One version of the schema, connected to the database of this test:
#   Moniker => { table => ..., columns => [...],
#                unique => { name => [columns] },    # add_unique_constraint
#                index  => { name => [columns] } }   # mysql_index, not unique
my $version = 0;
sub schema_version {
  my (%sources) = @_;
  my $ns = 'K70Live::V' . ++$version;
  eval "package $ns; use DBIO 'Schema'; __PACKAGE__->load_components('MySQL'); 1" or die $@;
  for my $moniker (sort keys %sources) {
    my $def   = $sources{$moniker};
    my $class = "${ns}::Result::$moniker";
    eval "package $class; use DBIO 'Core', -mysql; 1" or die $@;
    $class->table($def->{table});
    $class->add_columns(@{ $def->{columns} });
    $class->set_primary_key('id');
    $class->add_unique_constraint($_ => $def->{unique}{$_}) for sort keys %{ $def->{unique} // {} };
    $class->mysql_index($_ => { columns => $def->{index}{$_} }) for sort keys %{ $def->{index} // {} };
    $ns->register_class($moniker => $class);
  }
  # Every connection of the schema works in this test's database, whatever
  # the DSN names.
  return $ns->connect($dsn, $user, $pass, { on_connect_do => ["USE `$DB`"] });
}

sub account {
  my (%keys) = @_;
  return (Account => { table => 'account', columns => \@ACCOUNT_COLUMNS, %keys });
}
my %VOUCHER = (Voucher => {
  table => 'voucher', columns => \@VOUCHER_COLUMNS,
  unique => { uniq_voucher_serial => ['batch', 'serial'] },
});

# The indexes of a table as the server lists them, the primary key left out:
# name => [ 'unique' or 'plain', columns in their order ].
sub server_keys {
  my ($table) = @_;
  my %got;
  for my $row (@{ $raw->selectall_arrayref(
    'SELECT INDEX_NAME, NON_UNIQUE, COLUMN_NAME FROM information_schema.STATISTICS '
  . 'WHERE TABLE_SCHEMA = ? AND TABLE_NAME = ? ORDER BY INDEX_NAME, SEQ_IN_INDEX', undef, $DB, $table,
  ) }) {
    my ($name, $non_unique, $column) = @$row;
    next if $name eq 'PRIMARY';
    $got{$name} //= [ $non_unique ? 'plain' : 'unique' ];
    push @{ $got{$name} }, $column;
  }
  return \%got;
}

# A row goes in / is refused as a duplicate under the named key.
sub goes_in {
  my ($rs, $row, $name) = @_;
  ok eval { $rs->create($row); 1 }, $name or diag "refused: $@";
}
sub is_refused {
  my ($rs, $row, $key, $name) = @_;
  my $went_in = eval { $rs->create($row); 1 };
  my $error   = "$@";
  # MySQL names the key `table.key`, MariaDB `key`.
  ok !$went_in && $error =~ /Duplicate entry .* for key '(?:\w+\.)?\Q$key\E'/, $name
    or diag $went_in ? 'the row went in' : "refused for another reason: $error";
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, @_ };

# upgrade() of a schema version: the statements it ran, in their order, or
# undef and a diagnostic when it failed.
sub upgrade_to {
  my ($schema, %opts) = @_;
  my $deploy = DBIO::MySQL::Deploy->new(schema => $schema);
  my $diff   = eval { $deploy->upgrade(%opts) };
  if ($@) {
    diag "upgrade failed: $@";
    return;
  }
  return [ $diff ? map { $_->as_sql } @{ $diff->operations } : () ];
}

# Claim 6: the diff of the schema against the database it was just upgraded
# to has nothing left.
sub nothing_left {
  my ($schema, $name) = @_;
  my $diff = eval { DBIO::MySQL::Deploy->new(schema => $schema)->diff };
  ok $diff && !$diff->has_changes, $name
    or diag $diff ? explain [ map { $_->as_sql } @{ $diff->operations } ] : "the diff failed: $@";
}

# ---------------------------------------------------------------------------
# 0. The starting point: one table with a plain index and no unique key,
#    installed.
# ---------------------------------------------------------------------------
my $schema = schema_version(account(index => { key_account_handle => ['handle'] }));

unless (ok eval { DBIO::MySQL::Deploy->new(schema => $schema)->install; 1 }, 'the starting schema installs') {
  diag "the install failed, and nothing below can be asked: $@";
  done_testing;
  exit;   # END drops what was created
}
is_deeply server_keys('account'), { key_account_handle => [ plain => 'handle' ] },
  'to begin with the table has a plain index and no unique key';

my $accounts = $schema->resultset('Account');
goes_in $accounts, { email => 'ann@example.org', tenant => 1, handle => 'ann' }, 'a first row goes in';
goes_in $accounts, { email => 'ann@example.org', tenant => 2, handle => 'ann' },
  'control: with no unique key, a second row with the same email and handle goes in too';
$accounts->search({ tenant => 2 })->delete;

# ---------------------------------------------------------------------------
# 1. A unique key added to the table
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(account(
  index  => { key_account_handle => ['handle'] },
  unique => { uniq_account_email => ['email'] },
));
is_deeply upgrade_to($schema),
  [ 'CREATE UNIQUE INDEX `uniq_account_email` ON `account` (`email`) USING BTREE;' ],
  'added: upgrade creates the unique key, and does nothing else';
is_deeply server_keys('account'), {
  key_account_handle => [ plain  => 'handle' ],
  uniq_account_email => [ unique => 'email' ],
}, '... and the server has it, unique, over that column';

$accounts = $schema->resultset('Account');
is_refused $accounts, { email => 'ann@example.org', tenant => 2, handle => 'bob' }, 'uniq_account_email',
  '... and refuses a second row with the same email';
nothing_left $schema, '... and the next diff has nothing left';

# ---------------------------------------------------------------------------
# 2. The columns of the unique key changed: email -> tenant, email
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(account(
  index  => { key_account_handle => ['handle'] },
  unique => { uniq_account_email => ['tenant', 'email'] },
));
is_deeply upgrade_to($schema), [
  'DROP INDEX `uniq_account_email` ON `account`;',
  'CREATE UNIQUE INDEX `uniq_account_email` ON `account` (`tenant`, `email`) USING BTREE;',
], 'changed: upgrade drops the unique key and creates it over the new columns';
is_deeply server_keys('account'), {
  key_account_handle => [ plain  => 'handle' ],
  uniq_account_email => [ unique => 'tenant', 'email' ],
}, '... and the server has it over those columns, in that order';

$accounts = $schema->resultset('Account');
goes_in $accounts, { email => 'ann@example.org', tenant => 2, handle => 'bob' },
  '... the row the old key refused goes in: same email, another tenant';
is_refused $accounts, { email => 'ann@example.org', tenant => 2, handle => 'cat' }, 'uniq_account_email',
  '... and the same email for the same tenant is refused';
nothing_left $schema, '... and the next diff has nothing left';

# ---------------------------------------------------------------------------
# 3. An index that became unique: same name, same column
# ---------------------------------------------------------------------------
goes_in $accounts, { email => 'dup@example.org', tenant => 1, handle => 'ann' },
  'control: while the index over handle is a plain one, a handle goes in twice';
$accounts->search({ email => 'dup@example.org' })->delete;

$schema->storage->disconnect;
$schema = schema_version(account(unique => {
  key_account_handle => ['handle'],
  uniq_account_email => ['tenant', 'email'],
}));
is_deeply upgrade_to($schema), [
  'DROP INDEX `key_account_handle` ON `account`;',
  'CREATE UNIQUE INDEX `key_account_handle` ON `account` (`handle`) USING BTREE;',
], 'made unique: upgrade drops the plain index and creates it as a unique one';
is_deeply server_keys('account'), {
  key_account_handle => [ unique => 'handle' ],
  uniq_account_email => [ unique => 'tenant', 'email' ],
}, '... and the server has it as a unique one';

$accounts = $schema->resultset('Account');
is_refused $accounts, { email => 'dup@example.org', tenant => 1, handle => 'ann' }, 'key_account_handle',
  '... and refuses a handle a second time';
nothing_left $schema, '... and the next diff has nothing left';

# ---------------------------------------------------------------------------
# 4. A unique key removed from the schema
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(account(unique => { key_account_handle => ['handle'] }));
is_deeply upgrade_to($schema, allow_destructive => 1), [ 'DROP INDEX `uniq_account_email` ON `account`;' ],
  'removed: upgrade drops the unique key that left the schema, and does nothing else';
is_deeply server_keys('account'), { key_account_handle => [ unique => 'handle' ] },
  '... and the server no longer has it, while the other one is still there';

$accounts = $schema->resultset('Account');
goes_in $accounts, { email => 'ann@example.org', tenant => 2, handle => 'cat' },
  '... the row it refused goes in: same email, same tenant';
is_refused $accounts, { email => 'eve@example.org', tenant => 3, handle => 'ann' }, 'key_account_handle',
  '... and the key that stayed still refuses its duplicate';
nothing_left $schema, '... and the next diff has nothing left';

# ---------------------------------------------------------------------------
# 5. A table the upgrade creates, with a unique key
# ---------------------------------------------------------------------------
$schema->storage->disconnect;
$schema = schema_version(account(unique => { key_account_handle => ['handle'] }), %VOUCHER);
my $ran = upgrade_to($schema) // [];
is scalar(@$ran), 2, 'new table: upgrade runs two statements'
  or diag explain $ran;
like $ran->[0] // '', qr/\ACREATE TABLE `voucher` \(/, '... the CREATE TABLE';
is $ran->[1], 'CREATE UNIQUE INDEX `uniq_voucher_serial` ON `voucher` (`batch`, `serial`) USING BTREE;',
  '... and after it the unique key of that table';
is_deeply server_keys('voucher'), { uniq_voucher_serial => [ unique => 'batch', 'serial' ] },
  '... and the server has the table with its unique key';

my $vouchers = $schema->resultset('Voucher');
goes_in $vouchers, { batch => 1, serial => 1 }, '... a row goes in';
is_refused $vouchers, { batch => 1, serial => 1 }, 'uniq_voucher_serial',
  '... and the same batch and serial a second time is refused';
goes_in $vouchers, { batch => 1, serial => 2 }, '... while another serial of the batch goes in';
nothing_left $schema, '... and the next diff has nothing left';

note 'warned during the run: ' . join ' | ', map { s/\s+\z//r } @warnings if @warnings;

$schema->storage->disconnect;
drop_database();
$raw->disconnect;
undef $raw;

done_testing;
