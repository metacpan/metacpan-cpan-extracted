use strict;
use warnings;

use Test::More;
use Test::Exception;
use File::Temp ();
use File::Find ();
use DBIO::Optional::Dependencies ();

# LIVE ONLY (karr k44, ADR 0013). One table per type class, on a real Db2:
#
#   1. install them from result classes and introspect (model M1);
#   2. let DBIO::Generate write result classes from that introspection --
#      table_columns_info, the normalized model, is all it reads;
#   3. drop the tables, install from the GENERATED classes, introspect again
#      (model M2): M1 and M2 must be the same column for column, and the
#      follow-up diff must be empty.
#
# A hand-made table with BOOLEAN and BINARY(8) is installed beside them in step 1
# (karr k54: install_ddl writes both natively now, the table of its own tests the
# catalog side); where a column does not come back as it went in, its test is TODO
# with the measured difference (%KNOWN), never left out.

plan skip_all => 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('test_rdbms_db2')
  unless DBIO::Optional::Dependencies->req_ok_for ('test_rdbms_db2');

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_DB2_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_DB2_DSN}, _USER and _PASS to run this test'
  unless ($dsn && $user);

use DBIO::Core ();
use DBIO::Generate;
use DBIO::DB2::Deploy;

# --- the result classes: one table per type class ---------------------------
my %TABLES = (
  int => {
    id    => { data_type => 'integer', is_auto_increment => 1 },
    small => { data_type => 'smallint', is_nullable => 1 },
    big   => { data_type => 'bigint', default_value => 7 },
  },
  dec => {
    id => { data_type => 'integer', is_auto_increment => 1 },
    d1 => { data_type => 'numeric', size => [ 10, 2 ], is_nullable => 1 },
    d2 => { data_type => 'decimal', size => [ 5, 0 ], is_nullable => 1 },
    d3 => { data_type => 'decimal', size => [ 12, 2 ], default_value => 5 },
  },
  chr => {
    id => { data_type => 'integer', is_auto_increment => 1 },
    c  => { data_type => 'char', size => 5, default_value => '00000' },
    v  => { data_type => 'varchar', size => 40, default_value => q{it's} },
    u  => { data_type => 'varchar', size => 30, default_value => \'USER' },
    n  => { data_type => 'varchar', size => 10, default_value => 'NULL' },
    p  => { data_type => 'varchar', size => 10, is_nullable => 1 },
  },
  txt => {
    id   => { data_type => 'integer', is_auto_increment => 1 },
    body => { data_type => 'clob', is_nullable => 1 },
    big  => { data_type => 'clob', size => 100000, is_nullable => 1 },
  },
  tim => {
    id      => { data_type => 'integer', is_auto_increment => 1 },
    d       => { data_type => 'date', is_nullable => 1 },
    t       => { data_type => 'time', is_nullable => 1 },
    ts      => { data_type => 'timestamp', is_nullable => 1 },
    ts3     => { data_type => 'timestamp', size => 3, is_nullable => 1 },
    created => { data_type => 'timestamp', default_value => \'CURRENT TIMESTAMP' },
    today   => { data_type => 'date', default_value => \'CURRENT DATE' },
  },
  bin => {
    id => { data_type => 'integer', is_auto_increment => 1 },
    b  => { data_type => 'blob', size => 1000, is_nullable => 1 },
    vb => { data_type => 'varbinary', size => 16, is_nullable => 1 },
  },
  bol => {
    id     => { data_type => 'integer', is_auto_increment => 1 },
    flag   => { data_type => 'boolean', is_nullable => 1 },
    flag_t => { data_type => 'boolean', default_value => \'TRUE' },
    flag_n => { data_type => 'bool', default_value => 0 },
    bn     => { data_type => 'binary', size => 8, is_nullable => 1 },
  },
  flt => {
    id  => { data_type => 'integer', is_auto_increment => 1 },
    r   => { data_type => 'real', is_nullable => 1 },
    d   => { data_type => 'double precision', is_nullable => 1 },
    f   => { data_type => 'float', is_nullable => 1 },
    df  => { data_type => 'decfloat', is_nullable => 1 },
    d16 => { data_type => 'decfloat', size => 16, is_nullable => 1 },
    d34 => { data_type => 'decfloat', size => 34, is_nullable => 1 },
  },
);

# Made by hand, beside the class table bol: the catalog's own BOOLEAN and BINARY(8).
my $RAW = 'raw';
my %RAW_COLUMNS = (
  flag => 'BOOLEAN',
  flag_d => 'BOOLEAN DEFAULT TRUE',
  bn   => 'BINARY(8)',
);

sub table_name { my ($key) = @_; return "dbio_k44${key}_$$" }

for my $key (keys %TABLES) {
  my $class = "DBIO::Test::K44::Result::\u$key";
  no strict 'refs';
  @{"${class}::ISA"} = ('DBIO::Core');
  $class->table(table_name($key));
  $class->add_columns(map { $_ => { %{ $TABLES{$key}{$_} } } } sort keys %{ $TABLES{$key} });
  $class->set_primary_key('id');
}

{
  package DBIO::Test::K44::Schema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
  __PACKAGE__->register_class(ucfirst($_) => "DBIO::Test::K44::Result::\u$_") for sort keys %TABLES;
}

my $schema = DBIO::Test::K44::Schema->connect($dsn, $user, $pass);
my $dbh = eval { $schema->storage->dbh }
  or plan skip_all => "Cannot reach DB2: $@";

my $COMPARE_SCHEMA = "DBIO_TEST_$$";
my @ALL = ((map { table_name($_) } keys %TABLES), table_name($RAW));

sub drop_tables {
  local $dbh->{PrintError} = 0;
  eval { $dbh->do(qq{DROP TABLE "$_"}) } for @ALL;
}

my $deploy = DBIO::DB2::Deploy->new(schema => $schema);

END {
  if ($dbh && $dbh->{Active}) {
    drop_tables();
    my ($n) = eval { $dbh->selectrow_array(
      'SELECT COUNT(*) FROM syscat.schemata WHERE schemaname = ?', undef, $COMPARE_SCHEMA) };
    $deploy->_drop_test_schema($dbh, $COMPARE_SCHEMA) if $n;
  }
}

drop_tables();

# --- 1. install, add the hand-made table, introspect ------------------------
lives_ok { $deploy->install } 'install: one table per type class';

my $raw_ok = eval {
  $dbh->do(qq{CREATE TABLE "} . table_name($RAW) . q{" ("id" INTEGER NOT NULL PRIMARY KEY, }
    . join(', ', map { qq{"$_" $RAW_COLUMNS{$_}} } sort keys %RAW_COLUMNS) . ')');
  1;
};
diag "hand-made BOOLEAN/BINARY table not created on this server: $@" unless $raw_ok;
@ALL = grep { $raw_ok || $_ ne table_name($RAW) } @ALL;

sub mine {
  my ($model) = @_;
  my %want = map { $_ => 1 } @ALL;
  return { map { $_ => $model->{columns}{$_} } grep { $want{$_} } keys %{ $model->{columns} } };
}

my $intro1 = $deploy->_new_introspect($dbh, $deploy->_current_schema($dbh));
my $m1 = mine($intro1->model);
is scalar(keys %$m1), scalar(@ALL), 'M1: every table is introspected';

# --- 2. generate -------------------------------------------------------------
my $dir = File::Temp->newdir;
my $re  = qr/\Adbio_k44\w+_\Q$$\E\z/;
lives_ok {
  DBIO::Generate->new(
    schema_class => 'K44Gen', dump_directory => "$dir", style => 'vanilla',
    use_namespaces => 1, generate_pod => 0, quiet => 1, constraint => $re,
  )->dump($intro1);
} 'DBIO::Generate writes result classes from the introspection';

my %file;
File::Find::find({ no_chdir => 1, wanted => sub {
  return unless /\.pm\z/;
  (my $moniker = $_) =~ s{.*/}{}; $moniker =~ s/\.pm\z//;
  open my $fh, '<', $_ or die "$_: $!";
  $file{$moniker} = { path => $_, code => do { local $/; <$fh> } };
}}, "$dir");
is scalar(keys %file), scalar(@ALL), 'one class per table';

my $all_code = join "\n", map { $_->{code} } values %file;
unlike $all_code, qr/(?:ARRAY|SCALAR|HASH)\(0x/,
  'no stringified reference in the generated classes (size, default_value)';
diag "generated:\n$all_code" if $ENV{DBIO_TEST_VERBOSE};

# --- 3. install from the generated classes, introspect again ----------------
drop_tables();

my @monikers = sort keys %file;
my $loaded = eval {
  unshift @INC, "$dir";
  for my $m (@monikers) {
    (my $rel = $file{$m}{path}) =~ s{\A\Q$dir\E/}{};
    require $rel;
  }
  1;
};
ok $loaded, 'the generated classes compile' or diag $@;

{
  package DBIO::Test::K44::GenSchema;
  use strict; use warnings;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('DB2');
}
for my $m (@monikers) {
  DBIO::Test::K44::GenSchema->register_class($m => "K44Gen::Result::$m");
}

my $schema2 = DBIO::Test::K44::GenSchema->connect($dsn, $user, $pass);
my $deploy2 = DBIO::DB2::Deploy->new(schema => $schema2);
my $dbh2 = $schema2->storage->dbh;

my $installed = $loaded && eval { $deploy2->install; 1 };
ok $installed, 'install from the generated classes' or diag $@;

my $m2 = mine($deploy2->_new_introspect($dbh2, $deploy2->_current_schema($dbh2))->model);

# --- the roundtrip, column by column -----------------------------------------
my @FIELDS = qw(data_type size default_value not_null is_auto_increment
                catalog_type catalog_size catalog_default);

our %KNOWN = ();    # a column that does not come back as it went in: "table.column" => the measured difference

sub render { my ($v) = @_; return ref $v eq 'SCALAR' ? "\\'$$v'" : ref $v eq 'ARRAY' ? "[@$v]" : defined $v ? "'$v'" : 'undef' }

for my $table (sort @ALL) {
  my %c1 = map { $_->{column_name} => $_ } @{ $m1->{$table} // [] };
  my %c2 = map { $_->{column_name} => $_ } @{ $m2->{$table} // [] };
  for my $col (sort keys %c1) {
    my $one = $c1{$col};
    my $two = $c2{$col};
    my @diff = $two ? (grep { !_same($one->{$_}, $two->{$_}) } @FIELDS) : ('missing');
    my $detail = !$two ? 'column missing after the roundtrip'
      : join '; ', map { "$_: " . render($one->{$_}) . ' became ' . render($two->{$_}) } @diff;
    (my $name = $table) =~ s/_\Q$$\E\z//;
    local $TODO = $KNOWN{"$name.$col"};
    is scalar(@diff), 0, "roundtrip $name.$col ("
      . render($one->{data_type}) . ', size ' . render($one->{size}) . ')'
      or diag $detail;
  }
}

sub _same {
  my ($x, $y) = @_;
  return 1 if !defined $x && !defined $y;
  return 0 if defined $x != defined $y;
  return 0 if ref $x ne ref $y;
  return ref $x eq 'ARRAY' ? "@$x" eq "@$y" : ref $x eq 'SCALAR' ? $$x eq $$y : $x eq $y;
}

{
  my $diff = eval { $deploy2->diff };
  ok $diff, 'diff after the generated install' or diag $@;
  my @ops = $diff ? grep { my $t = $_->can('table_name') ? $_->table_name : ''; $t =~ /_\Q$$\E\z/ }
                         @{ $diff->operations } : (1);
  is scalar(@ops), 0, 'the follow-up diff of the generated classes is empty'
    or diag join "\n", map { ref $_ ? $_->as_sql : $_ } @ops;
}

done_testing;
