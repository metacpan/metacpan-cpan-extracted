use strict;
use warnings;
use Test::More;

# Offline coverage for DBIO::Sybase::Introspect::Columns::fetch -- specifically
# that varchar/decimal columns come back with a populated `size` (karr k25).
# Before that fix, `fetch` never queried length/precision/scale at all, so
# `size` was always undef on both sides of a diff and column-size changes
# were silently never detected. No live server: a tiny mock $dbh stands in
# for DBD::Sybase.
#
# CLAIM REPLACED (karr k48): the mock used to serve four rowsets in call order
# -- INFORMATION_SCHEMA.COLUMNS, an INFORMATION_SCHEMA primary-key join, and two
# syscolumns side queries for identity and size. ASE has no INFORMATION_SCHEMA,
# so fetch now reads everything from one syscolumns/systypes query (plus
# syscomments for defaults). The claim this file makes is unchanged -- size is
# populated from syscolumns length/prec/scale and a size change is detected by
# the core comparator -- only the rows it is fed are now the catalog's.
use_ok 'DBIO::Sybase::Introspect::Columns';
use DBIO::Diff::Compare qw(changed_column_fields);

# --- Mock DBI layer -------------------------------------------------------
{
  package Test::Sybase::MockDBH;
  sub new { my ($class, %rows) = @_; bless { %rows }, $class }
  sub selectall_arrayref {
    my ($self, $sql) = @_;
    return [] if $sql =~ /syscomments/i;        # no defaults
    return $self->{columns} if $sql =~ /syscolumns/i;
    die "unexpected SQL: $sql";
  }
}

my $tables = { widget => { table_name => 'widget', kind => 'table', schema => 'dbo' } };

my $dbh = Test::Sybase::MockDBH->new(
  columns => [
    { table_name => 'widget', column_name => 'id', colid => 1, type_name => 'int',
      length => 4, prec => undef, scale => undef, status => 0, cdefault => 0 },
    { table_name => 'widget', column_name => 'name', colid => 2, type_name => 'varchar',
      length => 64, prec => undef, scale => undef, status => 0, cdefault => 0 },
    { table_name => 'widget', column_name => 'price', colid => 3, type_name => 'decimal',
      length => 17, prec => 10, scale => 2, status => 8, cdefault => 0 },
  ],
);

my $columns = DBIO::Sybase::Introspect::Columns->fetch($dbh, 'dbo', $tables);
my %by_name = map { $_->{column_name} => $_ } @{ $columns->{widget} };

is scalar(@{ $columns->{widget} }), 3, 'three columns fetched';

# --- int column: no size (not a char/numeric type) ------------------------
ok !exists $by_name{id}{size}, 'int column has no size key';

# --- varchar column: scalar size -------------------------------------------
is $by_name{name}{size}, 64, 'varchar column size is scalar length';

# --- decimal column: [precision, scale] arrayref ---------------------------
is_deeply $by_name{price}{size}, [10, 2], 'decimal column size is [precision, scale]';

# --- round-trip through the core diff comparator: a size change must now be
#     detected (this is the actual bug: size was always undef on both sides,
#     so this comparison never fired before the fix) --------------------
{
  my $old = { %{ $by_name{name} } };
  my $new = { %{ $by_name{name} }, size => 255 };
  my @changed = changed_column_fields($old, $new);
  ok( (grep { $_ eq 'size' } @changed), 'varchar size change is detected by changed_column_fields' );
}
{
  my $old = { %{ $by_name{price} } };
  my $new = { %{ $by_name{price} }, size => [12, 4] };
  my @changed = changed_column_fields($old, $new);
  ok( (grep { $_ eq 'size' } @changed), 'decimal size change is detected by changed_column_fields' );
}
{
  my $old = { %{ $by_name{name} } };
  my $new = { %{ $by_name{name} } };
  my @changed = changed_column_fields($old, $new);
  ok( !(grep { $_ eq 'size' } @changed), 'identical size is not reported as changed' );
}

# --- nchar/nvarchar: length is size * @@ncharsize (karr k57) ----------------
# syscolumns.length is bytes. An nvarchar(10) on a utf8 server (@@ncharsize 3)
# reports 30, on iso_1 (@@ncharsize 1) 10 -- measured live on ASE 16.0 SP02
# iso_1: nvarchar(10) length 10, nchar(4) length 4, univarchar(10) length 20.
# The declared size is the character count, so it must come back as 10 on
# both, or a diff against the desired nvarchar(10) widens the column to 30.
{
  my $ndbh = Test::Sybase::MockDBH->new(
    columns => [
      map {
        my ($name, $type, $len, $ncs) = @$_;
        +{ table_name => 'widget', column_name => $name, colid => 1,
           type_name => $type, length => $len, prec => undef, scale => undef,
           status => 8, cdefault => 0, ncharsize => $ncs };
      }
      [ nv_utf8 => nvarchar   => 30, 3 ],
      [ nc_utf8 => nchar      => 12, 3 ],
      [ nv_iso  => nvarchar   => 10, 1 ],
      [ uv      => univarchar => 20, 3 ],
      [ v_utf8  => varchar    => 10, 3 ],
    ],
  );
  my %n = map { $_->{column_name} => $_ }
    @{ DBIO::Sybase::Introspect::Columns->fetch($ndbh, 'dbo', $tables)->{widget} };
  is $n{nv_utf8}{size}, 10, 'nvarchar(10) at @@ncharsize 3 (length 30) reads back as 10';
  is $n{nc_utf8}{size}, 4,  'nchar(4) at @@ncharsize 3 (length 12) reads back as 4';
  is $n{nv_iso}{size},  10, 'nvarchar(10) at @@ncharsize 1 reads back as 10';
  is $n{uv}{size},      10, 'univarchar stays halved, independent of @@ncharsize';
  is $n{v_utf8}{size},  10, 'varchar length is its size, @@ncharsize does not apply';
}

# --- binary/varbinary: size is the length (karr k93) --------------------------
# syscolumns.length of a binary(n)/varbinary(n) column is n bytes, no charset
# multiplier. _size returned undef for them, so both sides of a diff read a
# column without a size and a length change was never seen; DDL writes
# VARBINARY(n) with the size (karr k70), so the catalog must say it back.
{
  my $bdbh = Test::Sybase::MockDBH->new(
    columns => [
      map {
        my ($name, $type, $len) = @$_;
        +{ table_name => 'widget', column_name => $name, colid => 1,
           type_name => $type, length => $len, prec => undef, scale => undef,
           status => 8, cdefault => 0, ncharsize => 3 };
      }
      [ vb => varbinary => 16 ],
      [ bn => binary    => 4 ],
      [ vb1 => varbinary => 1 ],
    ],
  );
  my %b = map { $_->{column_name} => $_ }
    @{ DBIO::Sybase::Introspect::Columns->fetch($bdbh, 'dbo', $tables)->{widget} };
  is $b{vb}{size},  16, 'varbinary(16) reads back with size 16';
  is $b{bn}{size},  4,  'binary(4) reads back with size 4, @@ncharsize does not apply';
  is $b{vb1}{size}, 1,  'varbinary(1) reads back with size 1';
  my @changed = changed_column_fields($b{vb}, { %{ $b{vb} }, size => 32 });
  ok( (grep { $_ eq 'size' } @changed), 'varbinary length change is detected by changed_column_fields' );
}

done_testing;
