use strict;
use warnings;
use Test::More;

use DBIO::Oracle::Type;

# ---------------------------------------------------------------------------
# map_dbio_type_to_oracle must honour the size argument (offline, pure).
# Regression: VARCHAR2/NUMBER/CHAR previously ignored size and emitted a
# hardcoded VARCHAR2(255) / NUMBER, causing phantom diffs on every compare.
# ---------------------------------------------------------------------------
{
  no warnings 'qw';
  my @cases = (
    ['varchar', 128,      'VARCHAR2(128)'],
    ['varchar', undef,    'VARCHAR2(255)'],   # default preserved
    ['nvarchar', 64,      'VARCHAR2(64)'],
    ['char', 3,           'CHAR(3)'],
    ['char', undef,       'CHAR(1)'],
    ['nchar', 2,          'NCHAR(2)'],
    ['numeric', [10, 2],  'NUMBER(10,2)'],
    ['numeric', 8,        'NUMBER(8)'],
    ['numeric', undef,    'NUMBER'],
    ['integer', 99,       'NUMBER'],          # size irrelevant for integer
  );
  for my $c (@cases) {
    my ($type, $size, $want) = @$c;
    my $got = DBIO::Oracle::Type::map_dbio_type_to_oracle($type, size => $size);
    is($got, $want, "map $type" . (defined $size ? " size @{[ ref $size ? join(',',@$size) : $size ]}" : '') . " => $want");
  }
}

# ---------------------------------------------------------------------------
# Round-trip stability: a sized Oracle type introspected to DBIO and mapped
# back must not drift (no phantom diff).
# ---------------------------------------------------------------------------
{
  my $dbio = DBIO::Oracle::Type::map_dbd_type_to_dbio('VARCHAR2', data_length => 128);
  is($dbio->{data_type}, 'varchar2', 'introspect VARCHAR2 data_type');
  is($dbio->{size}, 128, 'introspect VARCHAR2 size');

  my $num = DBIO::Oracle::Type::map_dbd_type_to_dbio('NUMBER', data_precision => 10, data_scale => 2);
  is_deeply($num->{size}, [10, 2], 'introspect NUMBER(10,2) size');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle($num->{data_type}, size => $num->{size}),
     'NUMBER(10,2)', 'NUMBER(10,2) round-trips');
}

# ---------------------------------------------------------------------------
# Identifier shortening (offline) — shared seam used by SQLMaker and DDL.
# ---------------------------------------------------------------------------
SKIP: {
  eval { require DBIO::Oracle::Identifier; 1 }
    or skip 'DBIO::Oracle::Identifier unavailable (Math::Base36?)', 4;

  my $short = 'short_name';
  is(DBIO::Oracle::Identifier::shorten($short), $short, 'short identifier passes through');

  my $long = 'a_very_long_table_name_for_testing_v2_created_timestamp_idx';
  my $s = DBIO::Oracle::Identifier::shorten($long);
  cmp_ok(length($s), '<=', 30, 'long identifier shortened to <= 30 chars');
  is(DBIO::Oracle::Identifier::shorten($long), $s, 'shortening is deterministic');

  isnt(
    DBIO::Oracle::Identifier::shorten($long),
    DBIO::Oracle::Identifier::shorten($long . '_other'),
    'distinct long names get distinct shortened forms',
  );
}

done_testing;
