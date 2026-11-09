use strict; use warnings;
use Test::More;
use DBIO::Schema::Type ();

is DBIO::Schema::Type::normalize('integer'),   'integer',   'integer';
is DBIO::Schema::Type::normalize('INT'),        'integer',   'int alias, case-insensitive';
is DBIO::Schema::Type::normalize('bigint'),     'integer',   'bigint -> integer';
is DBIO::Schema::Type::normalize('varchar'),    'text',      'varchar -> text';
is DBIO::Schema::Type::normalize('varchar(255)'),'text',     'varchar(n) -> text (params stripped)';
is DBIO::Schema::Type::normalize('character'),  'char',      'character -> char';
is DBIO::Schema::Type::normalize('decimal'),    'numeric',   'decimal -> numeric';
is DBIO::Schema::Type::normalize('real'),       'double',    'real -> double';
is DBIO::Schema::Type::normalize('bytea'),      'blob',      'bytea -> blob';
is DBIO::Schema::Type::normalize('datetime'),   'timestamp', 'datetime -> timestamp';

eval { DBIO::Schema::Type::normalize('geometry') };
like $@, qr/unknown data_type/, 'unknown type dies';

my $c = DBIO::Schema::Type::canonical_column('id',
  { data_type => 'integer', is_auto_increment => 1 });
is $c->{base_type}, 'integer', 'canonical base_type';
is $c->{not_null},  1,         'absent is_nullable => not_null';
is $c->{auto_increment}, 1,    'auto_increment carried';

my $v = DBIO::Schema::Type::canonical_column('name',
  { data_type => 'char', size => 32, is_nullable => 1 });
is $v->{base_type}, 'char', 'char base_type';
is $v->{size},      32,     'char size carried';
is $v->{not_null},  0,      'is_nullable => not not_null';

my $n = DBIO::Schema::Type::canonical_column('amount',
  { data_type => 'numeric', size => [10, 2] });
is $n->{precision}, 10, 'numeric precision';
is $n->{scale},      2, 'numeric scale';

# The FORM of size is part of the canonical contract. Where the
# family already has a reading, canonical_column normalizes to it silently;
# where it has none, it refuses instead of handing a stringified reference to
# a driver that interpolates it into DDL.

# char: the width. An arrayref names it in its first element; the surplus is
# not a second char parameter and is dropped, not stringified.
{
  my $one = DBIO::Schema::Type::canonical_column('c',
    { data_type => 'char', size => [10] });
  is $one->{size}, 10, 'char size [10] means width 10';
  ok !ref $one->{size}, 'char size never leaves canonical_column as a reference';

  my $two = DBIO::Schema::Type::canonical_column('c',
    { data_type => 'char', size => [10, 2] });
  is $two->{size}, 10, 'char size [10,2]: first element is the width, rest dropped';

  my $none = DBIO::Schema::Type::canonical_column('c',
    { data_type => 'char', size => [] });
  ok !defined $none->{size}, 'char size [] names nothing and counts as absent';

  my $missing = DBIO::Schema::Type::canonical_column('c', { data_type => 'char' });
  ok !defined $missing->{size}, 'char without size has no width';
}

# numeric: [precision, scale]. A scalar names the precision only -- it used to
# be dropped here, which deployed the column at the engine's default scale.
{
  my $scalar = DBIO::Schema::Type::canonical_column('amount',
    { data_type => 'numeric', size => 8 });
  is $scalar->{precision}, 8, 'numeric scalar size is the precision, not dropped';
  ok !defined $scalar->{scale}, 'numeric scalar size leaves the scale undetermined';

  my $one = DBIO::Schema::Type::canonical_column('amount',
    { data_type => 'numeric', size => [10] });
  is $one->{precision}, 10, 'numeric size [10] is precision only';
  ok !defined $one->{scale}, 'numeric size [10] leaves the scale undetermined';

  my $three = DBIO::Schema::Type::canonical_column('amount',
    { data_type => 'numeric', size => [10, 2, 4] });
  is $three->{precision}, 10, 'numeric size surplus: precision from element 0';
  is $three->{scale},      2, 'numeric size surplus: scale from element 1, rest dropped';

  my $none = DBIO::Schema::Type::canonical_column('amount',
    { data_type => 'numeric', size => [] });
  ok !defined $none->{precision}, 'numeric size [] names no precision';
  ok !defined $none->{scale},     'numeric size [] names no scale';
}

# timestamp: the fractional-seconds precision, under the key the char width
# travels under -- size. It used to be dropped here, so a schema compiled for
# an engine that writes it (timestamptz(3)) came out without it and differed
# from the table the same column had just been deployed as.
{
  for my $alias (qw/timestamp datetime timestamptz/) {
    my $col = DBIO::Schema::Type::canonical_column('seen',
      { data_type => $alias, size => 3 });
    is_deeply $col, {
      column_name => 'seen', base_type => 'timestamp', not_null => 1,
      default => undef, auto_increment => 0, size => 3,
    }, "$alias size 3: the precision travels as size, and as nothing else";
  }

  # 0 is a precision -- whole seconds -- not the absence of one.
  my $zero = DBIO::Schema::Type::canonical_column('seen',
    { data_type => 'timestamp', size => 0 });
  ok exists $zero->{size},  'timestamp size 0 is carried';
  is $zero->{size}, 0,      'timestamp size 0 arrives as 0';

  my $one = DBIO::Schema::Type::canonical_column('seen',
    { data_type => 'timestamp', size => [6] });
  is $one->{size}, 6, 'timestamp size [6] means precision 6';
  ok !ref $one->{size}, 'timestamp size never leaves canonical_column as a reference';

  my $two = DBIO::Schema::Type::canonical_column('seen',
    { data_type => 'timestamp', size => [6, 9] });
  is $two->{size}, 6, 'timestamp size [6,9]: first element is the precision, rest dropped';

  # No precision declared: the column carries no size key at all, so the
  # canonical column of a plain timestamp is what it always was.
  for my $absent (
    [ 'an empty arrayref' => { data_type => 'timestamp', size => [] } ],
    [ 'undef'             => { data_type => 'timestamp', size => undef } ],
    [ 'no size'           => { data_type => 'timestamp' } ],
  ) {
    my ($what, $info) = @$absent;
    my $col = DBIO::Schema::Type::canonical_column('seen', $info);
    ok !exists $col->{size}, "timestamp with $what carries no size";
  }

  eval { DBIO::Schema::Type::canonical_column('stamped',
    { data_type => 'datetime', size => { fsp => 3 } }) };
  my $err = $@;
  ok $err, 'hashref size is refused for timestamp, not passed on';
  like $err, qr/\bstamped\b/,   'timestamp refusal names the column';
  like $err, qr/\btimestamp\b/, 'timestamp refusal names the base type';
  like $err, qr/\bHASH\b/,      'timestamp refusal names the form found';
}

# Each base type that carries a size carries it under its own keys and under
# no other: the three readings must not leak into each other.
{
  is_deeply DBIO::Schema::Type::canonical_column('name',
    { data_type => 'char', size => 32 }), {
      column_name => 'name', base_type => 'char', not_null => 1,
      default => undef, auto_increment => 0, size => 32,
    }, 'char: size, no precision or scale';

  is_deeply DBIO::Schema::Type::canonical_column('amount',
    { data_type => 'numeric', size => [10, 2] }), {
      column_name => 'amount', base_type => 'numeric', not_null => 1,
      default => undef, auto_increment => 0, precision => 10, scale => 2,
    }, 'numeric: precision and scale, no size';
}

# A reference form that names nothing in either reading is refused loudly. It
# used to be passed through and stringified to an address by the driver.
{
  eval { DBIO::Schema::Type::canonical_column('weird',
    { data_type => 'char', size => { width => 10 } }) };
  my $err = $@;
  ok $err, 'hashref size is refused, not passed on';
  like $err, qr/\bweird\b/, 'refusal names the column';
  like $err, qr/\bchar\b/,  'refusal names the base type';
  like $err, qr/\bHASH\b/,  'refusal names the form found';

  my $n = 10;
  eval { DBIO::Schema::Type::canonical_column('odd',
    { data_type => 'numeric', size => \$n }) };
  like $@, qr/\bSCALAR\b/, 'scalarref size is refused for numeric too';
}

# Scope: only the base types that consume size read its form. A base type that
# ignores size entirely has no reading to violate, so nothing is refused there.
{
  my $col = DBIO::Schema::Type::canonical_column('body',
    { data_type => 'text', size => { junk => 1 } });
  is $col->{base_type}, 'text', 'unread size is not the type layer\'s business';
}

# The other five base types carry no size, whatever was declared. This records
# what canonical_column does today, not a decision that it should: whether a
# varchar(255), a binary(16) or a float(24) ought to keep its size is an open
# question about the portable vocabulary. Whoever answers it changes this
# block on purpose.
{
  for my $case (
    [ integer => { data_type => 'int',     size => 11  } ],
    [ text    => { data_type => 'varchar', size => 255 } ],
    [ blob    => { data_type => 'binary',  size => 16  } ],
    [ double  => { data_type => 'float',   size => 24  } ],
    [ boolean => { data_type => 'boolean', size => 1   } ],
  ) {
    my ($base, $info) = @$case;
    is_deeply DBIO::Schema::Type::canonical_column('c', $info), {
      column_name => 'c', base_type => $base, not_null => 1,
      default => undef, auto_increment => 0,
    }, "$info->{data_type} size $info->{size}: base type $base carries no size today";
  }
}

done_testing;
