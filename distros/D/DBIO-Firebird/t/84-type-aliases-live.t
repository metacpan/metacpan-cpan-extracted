use strict;
use warnings;
use Test::More;

# Live: the type aliases of DBIO::Schema::Type that ddl_type_from_info maps
# to a Firebird type (karr k55): tinyint, bool, string, mediumtext, longtext,
# real, int, binary(n), varbinary(n) (Firebird 4 and later: skipped below),
# character(n), character varying(n), double. The time zone types are not here:
# install_ddl refuses them (t/81), t/88 measures why. Each alias gets a table of its own written by
# install_ddl, so one the server refuses does not hide the others; the
# introspected data_type and size are the base type the alias stands for, and
# where a value means something (bool, string, text) it goes in and comes out.
#
# Skipped unless a DSN is provided (as t/15, t/17):
#
#   DBIO_TEST_FIREBIRD_DSN
#   DBIO_TEST_FIREBIRD_USER
#   DBIO_TEST_FIREBIRD_PASS
#
# WARNING: creates and drops the tables "dbio_t84_tinyint", "dbio_t84_bool",
# "dbio_t84_string", "dbio_t84_stringn", "dbio_t84_real", "dbio_t84_mediumtext",
# "dbio_t84_longtext", "dbio_t84_int", "dbio_t84_binary",
# "dbio_t84_varbinary", "dbio_t84_character", "dbio_t84_charvarying" and
# "dbio_t84_double".

my $dsn  = $ENV{DBIO_TEST_FIREBIRD_DSN};
my $user = $ENV{DBIO_TEST_FIREBIRD_USER};
my $pass = $ENV{DBIO_TEST_FIREBIRD_PASS};

plan skip_all => 'Set DBIO_TEST_FIREBIRD_DSN, _USER, _PASS to run the live type alias test'
  unless $dsn;

eval { require DBI; require DBD::Firebird; 1 }
  or plan skip_all => 'DBI / DBD::Firebird not installed';

use DBIO::Core;
use DBIO::Schema;
use DBIO::Firebird::DDL;
use DBIO::Firebird::Introspect;

my $dbh = DBI->connect($dsn, $user, $pass,
  { RaiseError => 1, AutoCommit => 1, PrintError => 0, ib_dialect => 3 })
  or plan skip_all => 'Cannot connect: ' . DBI->errstr;

$dbh->{LongReadLen} = 65536;    # the text blobs below are read whole

my $ver = $dbh->selectrow_array(
  q{SELECT rdb$get_context('SYSTEM','ENGINE_VERSION') FROM rdb$database});
my ($major) = ($ver // '0') =~ /^(\d+)/;
plan skip_all => "Firebird 3 or later needed (server is $ver)" if $major < 3;

# key, column info, expected data_type, expected size
my @aliases = (
  [ tinyint     => { data_type => 'tinyint' },                       'smallint',           undef ],
  [ bool        => { data_type => 'bool' },                          'boolean',            undef ],
  [ string      => { data_type => 'string' },                        'blob sub_type text', undef ],
  [ stringn     => { data_type => 'string', size => 40 },            'varchar',            40 ],
  [ real        => { data_type => 'real' },                          'double precision',   undef ],
  [ mediumtext  => { data_type => 'mediumtext' },                    'blob sub_type text', undef ],
  [ longtext    => { data_type => 'longtext' },                      'blob sub_type text', undef ],
  [ int         => { data_type => 'int' },                           'integer',            undef ],
  [ binary      => { data_type => 'binary', size => 4 },             'binary',             4 ],
  [ varbinary   => { data_type => 'varbinary', size => 6 },          'varbinary',          6 ],
  [ character   => { data_type => 'character', size => 10 },         'char',               10 ],
  [ charvarying => { data_type => 'character varying', size => 12 }, 'varchar',            12 ],
  [ double      => { data_type => 'double' },                        'double precision',   undef ],
);

# BINARY and VARBINARY exist from Firebird 4 on (install_ddl refuses them below)
@aliases = grep { $major >= 4 || $_->[0] !~ /\Abinary\z|\Avarbinary\z/ } @aliases;

my @tables = map { "dbio_t84_$_->[0]" } @aliases;
my $cleanup = sub { for my $t (@tables) { eval { $dbh->do(qq{DROP TABLE "$t"}) } } };
$cleanup->();

my $n = 0;
my %made;
for my $a (@aliases) {
  my ($key, $info) = @$a;
  my $table = "dbio_t84_$key";
  $n++;
  my ($rc, $sc) = ("DBIO::Firebird::Test::T84::Result::T$n", "DBIO::Firebird::Test::T84::S$n");
  {
    no strict 'refs';
    @{"${rc}::ISA"} = ('DBIO::Core');
    @{"${sc}::ISA"} = ('DBIO::Schema');
  }
  $rc->table($table);
  $rc->add_columns(id => { data_type => 'integer' }, val => { %$info, is_nullable => 1 });
  $rc->set_primary_key('id');
  $sc->register_class(T => $rc);

  my $ddl = eval { DBIO::Firebird::DDL->install_ddl($sc) };
  ok(defined $ddl, "$info->{data_type}: install_ddl renders") or diag $@;
  next unless defined $ddl;

  my $ok = eval {
    for my $stmt (split /;\n/, $ddl) {
      $stmt =~ s/;\s*\z//;
      $dbh->do($stmt) if $stmt =~ /\S/;
    }
    1;
  };
  ok($ok, "$info->{data_type}: the server accepts the DDL") or diag "$@\n$ddl";
  $made{$key} = 1 if $ok;
}

my $model = DBIO::Firebird::Introspect->new(dbh => $dbh)->model;

for my $a (@aliases) {
  my ($key, $info, $type, $size) = @$a;
  my $label = $info->{data_type} . (defined $info->{size} ? "($info->{size})" : '');
  SKIP: {
    skip "$label not created", 3 unless $made{$key};
    my ($col) = grep { $_->{column_name} eq 'val' } @{ $model->{columns}{"dbio_t84_$key"} || [] };
    ok($col, "$label: column introspected") or skip 'no column', 2;
    is($col->{data_type}, $type, "$label -> data_type $type");
    is_deeply($col->{size}, $size, "$label -> size " . ($size // 'undef'));
  }
}

# --- round trips -------------------------------------------------------------
SKIP: {
  skip 'dbio_t84_bool not created', 2 unless $made{bool};
  $dbh->do('INSERT INTO "dbio_t84_bool" ("id", "val") VALUES (1, TRUE)');
  $dbh->do('INSERT INTO "dbio_t84_bool" ("id", "val") VALUES (2, FALSE)');
  my %v = map { @$_ } @{ $dbh->selectall_arrayref('SELECT "id", "val" FROM "dbio_t84_bool"') };
  ok($v{1}, 'bool: TRUE reads back true');
  ok(!$v{2}, 'bool: FALSE reads back false');
}

SKIP: {
  skip 'dbio_t84_string not created', 2 unless $made{string};
  # a string without a size is text, as in the core canon
  my $long = 'x' x 5000;
  $dbh->do('INSERT INTO "dbio_t84_string" ("id", "val") VALUES (?, ?)', undef, 1, 'plain text');
  $dbh->do('INSERT INTO "dbio_t84_string" ("id", "val") VALUES (?, ?)', undef, 2, $long);
  my %v = map { @$_ } @{ $dbh->selectall_arrayref('SELECT "id", "val" FROM "dbio_t84_string"') };
  is($v{1}, 'plain text', 'string: value reads back');
  is($v{2}, $long, 'string without a size: 5000 characters fit (text, not VARCHAR(255))');
}

SKIP: {
  skip 'dbio_t84_stringn not created', 1 unless $made{stringn};
  $dbh->do('INSERT INTO "dbio_t84_stringn" ("id", "val") VALUES (?, ?)', undef, 1, 'y' x 40);
  eval { $dbh->do('INSERT INTO "dbio_t84_stringn" ("id", "val") VALUES (?, ?)', undef, 2, 'y' x 41) };
  like($@, qr/truncation/i, 'string with a size: VARCHAR(40) refuses 41 characters');
}

for my $key (qw(mediumtext longtext)) {
  SKIP: {
    skip "dbio_t84_$key not created", 1 unless $made{$key};
    my $text = "line one\nline two " . ('y' x 5000);
    $dbh->do(qq{INSERT INTO "dbio_t84_$key" ("id", "val") VALUES (?, ?)}, undef, 1, $text);
    my ($got) = $dbh->selectrow_array(qq{SELECT "val" FROM "dbio_t84_$key" WHERE "id" = 1});
    is($got, $text, "$key: text longer than a VARCHAR reads back whole");
  }
}

SKIP: {
  skip 'dbio_t84_character not created', 1 unless $made{character};
  $dbh->do(q{INSERT INTO "dbio_t84_character" ("id", "val") VALUES (1, 'abc')});
  my ($got) = $dbh->selectrow_array('SELECT "val" FROM "dbio_t84_character" WHERE "id" = 1');
  is($got, 'abc' . (' ' x 7), 'character(10): padded to its size');
}

# The size of character(10), the case ddl-type-size-char (the bit
# case, ddl-type-size-bit, is refused): the size is
# 10 in the introspected model (above) and the server holds the ORM to it.
{
  package K55T84::Schema;
  use DBIO 'Schema';
  __PACKAGE__->load_components('Firebird');

  package K55T84::Schema::Result::Char;
  use DBIO 'Core';
  __PACKAGE__->table('dbio_t84_character');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer' },
    val => { data_type => 'character', size => 10, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package main;
  K55T84::Schema->register_class(Char => 'K55T84::Schema::Result::Char');
}

SKIP: {
  skip "dbio_t84_character not created", 5 unless $made{character};
  local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /^non-transactional DDL on |problem parsing SQL_/ };
  my $orm = K55T84::Schema->connect($dsn, $user, $pass,
    { quote_names => 1, on_connect_call => 'use_softcommit' });
  is(DBIO::Firebird::DDL->server_major_version($orm), $major,
    'server_major_version asks the server behind the storage');
  my $rs = $orm->resultset('Char');
  my $before = $rs->count;
  ok(eval { $rs->create({ id => 20, val => 'x' x 10 }); 1 }, 'ORM: 10 characters go into character(10)') or diag $@;
  my $ok = eval { $rs->create({ id => 21, val => 'x' x 11 }); 1 };
  ok(!$ok, 'ORM: 11 characters are refused by the server');
  like($@, qr/truncation/i, '... as a string truncation');
  is($rs->count, $before + 1, '... and only the 10-character row was written');
  $orm->storage->disconnect;
}

$cleanup->();
$dbh->disconnect;
done_testing;
