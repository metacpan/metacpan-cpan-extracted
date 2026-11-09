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
    ['nvarchar', 64,      'NVARCHAR2(64)'],
    ['char', 3,           'CHAR(3)'],
    ['char', undef,       'CHAR(1)'],
    ['nchar', 2,          'NCHAR(2)'],
    ['numeric', [10, 2],  'NUMBER(10,2)'],
    ['numeric', 8,        'NUMBER(8)'],
    ['numeric', undef,    'NUMBER'],
    ['integer', 99,       'INTEGER'],      # size irrelevant for integer
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
# karr k38: the types the reader names are written with their size again, and
# FLOAT is float with its precision as the size. t/56 pins the same live.
# ---------------------------------------------------------------------------
{
  my @write = (
    ['varchar2',  20,    'VARCHAR2(20)'],
    ['varchar2',  undef, 'VARCHAR2(255)'],
    ['NVARCHAR2', 20,    'NVARCHAR2(20)'],
    ['NVARCHAR2', undef, 'NVARCHAR2(255)'],
    ['NCHAR',     10,    'NCHAR(10)'],
    ['timestamp', 3,     'TIMESTAMP(3)'],
    ['timestamp', undef, 'TIMESTAMP'],
    ['timestamp with time zone', 3,     'TIMESTAMP(3) WITH TIME ZONE'],
    ['timestamp with time zone', undef, 'TIMESTAMP WITH TIME ZONE'],
  );
  for my $c (@write) {
    my ($type, $size, $want) = @$c;
    is(DBIO::Oracle::Type::map_dbio_type_to_oracle($type, size => $size), $want,
      "write $type" . (defined $size ? "($size)" : '') . " => $want");
  }

  my %read = (
    NVARCHAR2 => [ { data_length => 40 }, { data_type => 'NVARCHAR2', size => 40 } ],
    NCHAR     => [ { data_length => 20 }, { data_type => 'NCHAR',     size => 20 } ],
    FLOAT126  => [ { data_precision => 126, data_length => 22 }, { data_type => 'float' } ],
    FLOAT64   => [ { data_precision => 64,  data_length => 22 }, { data_type => 'float', size => 64 } ],
    FLOAT63   => [ { data_precision => 63,  data_length => 22 }, { data_type => 'float', size => 63 } ],
    FLOAT1    => [ { data_precision => 1,   data_length => 22 }, { data_type => 'float', size => 1 } ],
    FLOATNONE => [ { data_length => 22 },                        { data_type => 'float' } ],
    DATE      => [ { data_length => 7 },  { data_type => 'date' } ],
    BINARY_FLOAT  => [ { data_length => 4 }, { data_type => 'binary_float' } ],
    BINARY_DOUBLE => [ { data_length => 8 }, { data_type => 'binary_double' } ],
  );
  for my $k (sort keys %read) {
    (my $type = $k) =~ s/(?:126|64|63|1|NONE)\z// if $k =~ /^FLOAT/;
    $type = $k unless $k =~ /^FLOAT/;
    my ($args, $want) = @{ $read{$k} };
    is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio($type, %$args), $want,
      "read $k");
  }
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('NUMBER', data_scale => 0),
    { data_type => 'integer' }, 'read NUMBER with scale 0 and no precision (INTEGER) as integer');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('NUMBER', data_precision => 38, data_scale => 0),
    { data_type => 'numeric', size => [ 38, 0 ] }, 'read NUMBER(38) as numeric, not integer');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('NUMBER'),
    { data_type => 'numeric' }, 'read a bare NUMBER as numeric');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('numeric', size => 38), 'NUMBER(38)', 'write numeric(38) as NUMBER(38)');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle($_), 'INTEGER', "write $_ as INTEGER") for qw(integer bigint smallint);
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('float'), 'FLOAT', 'write float without size as FLOAT');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('float', size => 63), 'FLOAT(63)', 'write float of size 63 as FLOAT(63)');
  for my $bad ([8, 2], 0, 127, -1, 'x', '1.5', '63 CHAR', '') {
    my $shown = ref $bad ? 'an array' : "'$bad'";
    eval { DBIO::Oracle::Type::map_dbio_type_to_oracle('float', size => $bad) };
    like($@, qr/float takes a binary precision/, "float of size $shown is refused");
  }
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('float', size => $_), "FLOAT($_)", "float of size $_ is FLOAT($_)")
    for 1, 126;
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('NCHAR', size => '5 CHAR'), 'NCHAR(5)', 'NCHAR of "5 CHAR" is NCHAR(5)');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('NVARCHAR2', size => '5 char'), 'NVARCHAR2(5)', 'NVARCHAR2 of "5 char" is NVARCHAR2(5)');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('varchar2', size => '20 byte'), 'VARCHAR2(20 BYTE)', 'a length semantics is written in capitals');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('raw', size => 16), 'RAW(16)', 'RAW keeps its size');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('RAW', data_length => 16),
    { data_type => 'raw', size => 16 }, 'read RAW(16): data_length is bytes');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('INTERVAL YEAR(3) TO MONTH', data_precision => 3),
    { data_type => 'interval year to month', size => 3 }, 'read INTERVAL YEAR(3) TO MONTH');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('INTERVAL YEAR(2) TO MONTH', data_precision => 2),
    { data_type => 'interval year to month' }, '... the default precision has no size');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('INTERVAL DAY(3) TO SECOND(4)'),
    { data_type => 'interval day to second', size => [ 3, 4 ] }, 'read INTERVAL DAY(3) TO SECOND(4)');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('interval year to month', size => 3), 'INTERVAL YEAR(3) TO MONTH', 'write the year precision');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('interval year to month'), 'INTERVAL YEAR TO MONTH', '... none');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('interval day to second', size => [ 3, 4 ]), 'INTERVAL DAY(3) TO SECOND(4)', 'write day and second precision');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('interval day to second'), 'INTERVAL DAY TO SECOND', '... none');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('numeric', size => [ 10, undef ]), 'NUMBER(10)', 'numeric [10, undef] has no trailing comma');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('real'), 'BINARY_FLOAT', 'real stays BINARY_FLOAT');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('double precision'), 'BINARY_DOUBLE', 'double precision stays BINARY_DOUBLE');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('double'), 'BINARY_DOUBLE', 'double is BINARY_DOUBLE too; DOUBLE is no Oracle type (ORA-02000)');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('NVARCHAR2', data_length => 40, char_length => 20),
    { data_type => 'NVARCHAR2', size => 20 }, 'read NVARCHAR2: the characters, not the bytes of the dictionary');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('NVARCHAR2', data_length => 40, nchar_size_factor => 2),
    { data_type => 'NVARCHAR2', size => 20 }, 'read NVARCHAR2 with the UTF-16 factor');

  # Length semantics (karr k38): data_length is the bytes, 80 for 20 CHAR.
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('VARCHAR2', data_length => 80, char_length => 20, char_used => 'C'),
    { data_type => 'varchar2', size => '20 CHAR' }, 'read VARCHAR2(20 CHAR) as "20 CHAR"');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('CHAR', data_length => 20, char_length => 5, char_used => 'C'),
    { data_type => 'char', size => '5 CHAR' }, 'read CHAR(5 CHAR) as "5 CHAR"');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('VARCHAR2', data_length => 20, char_length => 20, char_used => 'B'),
    { data_type => 'varchar2', size => 20 }, 'a BYTE column keeps the plain size');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('VARCHAR2', data_length => 20),
    { data_type => 'varchar2', size => 20 }, '... and so does one read without char_used');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('TIMESTAMP(6) WITH LOCAL TIME ZONE'),
    { data_type => 'timestamp with local time zone' }, 'read TIMESTAMP(6) WITH LOCAL TIME ZONE, no size for the default');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('TIMESTAMP(3) WITH LOCAL TIME ZONE'),
    { data_type => 'timestamp with local time zone', size => 3 }, 'read TIMESTAMP(3) WITH LOCAL TIME ZONE with its precision');
  is_deeply(DBIO::Oracle::Type::map_dbd_type_to_dbio('TIMESTAMP(3) WITH TIME ZONE'),
    { data_type => 'timestamp with time zone', size => 3 }, '... which is not TIMESTAMP WITH TIME ZONE');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('timestamp with local time zone'), 'TIMESTAMP WITH LOCAL TIME ZONE',
    'write timestamp with local time zone');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('timestamp with local time zone', size => 3), 'TIMESTAMP(3) WITH LOCAL TIME ZONE',
    '... with a precision');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('varchar2', size => '20 CHAR'), 'VARCHAR2(20 CHAR)',
    'write "20 CHAR" as VARCHAR2(20 CHAR)');
  is(DBIO::Oracle::Type::map_dbio_type_to_oracle('char', size => '5 CHAR'), 'CHAR(5 CHAR)',
    'write "5 CHAR" as CHAR(5 CHAR)');
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

# ---------------------------------------------------------------------------
# render_default_value: the one renderer of a default (karr k47).
# ---------------------------------------------------------------------------
{
  my $r = \&DBIO::Oracle::Type::render_default_value;

  is($r->(undef), undef, 'no default renders as nothing');
  is($r->("it's"), q{'it''s'}, 'an apostrophe is doubled');
  is($r->("''"), q{''''''}, '... every one of them');
  is($r->(''), q{''}, 'the empty string is an empty literal');
  is($r->('plain'), q{'plain'}, 'a string is a quoted literal');
  is($r->(\'SYSDATE'), 'SYSDATE', 'a scalar ref is written as it stands');
  is($r->(\"'it''s'"), q{'it''s'}, '... doubling is the ref\'s own business');

  is($r->($_), $_, "the number $_ is not quoted")
    for qw(0 7 42 -3 0.5 -12.25 100);

  is($r->($_), "'$_'", "'$_' is a string, it would change as a number")
    for ('007', '1.50', '1.', '.5', '+1', '1e3', '0x10', '1,5', '-0', '00');
}

done_testing;
