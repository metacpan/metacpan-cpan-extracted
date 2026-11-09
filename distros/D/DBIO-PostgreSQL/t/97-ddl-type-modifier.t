use strict;
use warnings;

use Test::More;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::DDL;
use DBIO::PostgreSQL::Diff ();
use DBIO::PostgreSQL::Diff::Column ();
use DBIO::PostgreSQL::Introspect::Normalize ();
use DBIO::PostgreSQL::Util ();
use FindBin;
use lib "$FindBin::Bin/lib";
use TypeModifierCases;

# OFFLINE test for karr k116: a declared size is written for every type that
# takes a type modifier, and where the server's grammar wants it.
#
# WHY it exists: install_ddl knew the types with a modifier from a list of
# four names. Every other one lost its size without a word -- data_type =>
# 'character', size => 10 became a column of ONE character, on which every
# insert of two failed; 'bit'/8 became one bit; 'decimal'/[10,2], Cake's own
# decimal(10, 2), a numeric without bound or scale; time, timestamp and
# interval columns the default precision. Which types take a modifier, and
# how it is written, is now one rule (DBIO::PostgreSQL::Util), and everything
# that writes a type asks it: install_ddl, the adapter, the column diff, the
# target model of a compiled schema. The introspector reads the same forms
# back.
#
# The rule cuts both ways, and the second half protects schemas that deploy
# today: a type WITHOUT a modifier never gets one. integer(11) is a syntax
# error.
#
# What the server makes of each type written here is t/98's business; both
# files share t/lib/TypeModifierCases.pm.

# install_ddl for one table with one nullable column per case; returns the
# type written for each, in order.
my $class_seq = 0;
sub written_types {
  my @cases = @_;
  my $n      = ++$class_seq;
  my $schema = "T97::S$n";
  my $result = "T97::S${n}::Result::T";
  {
    no strict 'refs';
    @{"${schema}::ISA"} = ('DBIO::Schema');
    @{"${result}::ISA"} = ('DBIO::Core');
  }
  $schema->load_components('PostgreSQL');
  $result->load_components('PostgreSQL::Result');
  $result->table('k116');
  my $i = 0;
  $result->add_columns(map {
    my ($data_type, $size) = @$_;
    sprintf('c%03d', $i++) => {
      data_type   => $data_type,
      is_nullable => 1,
      ( defined $size ? ( size => $size ) : () ),
    };
  } @cases);
  $schema->register_class(T => $result);

  my $ddl = DBIO::PostgreSQL::DDL->install_ddl($schema);
  my %type = $ddl =~ /^  (c\d{3}) (.*?),?$/mg;
  return map { $type{$_} } sort keys %type;
}

sub size_text {
  my ($size) = @_;
  return 'no size' unless defined $size;
  return 'size ' . ( ref $size ? '[' . join(', ', @$size) . ']' : $size );
}

sub ddl_cases_ok {
  my ($title, @cases) = @_;
  subtest $title => sub {
    my @written = written_types(@cases);
    is scalar @written, scalar @cases, 'every column is in the statement';
    for my $i (0 .. $#cases) {
      my ($data_type, $size, $expected) = @{ $cases[$i] };
      is $written[$i], $expected,
        sprintf '%s, %s is written %s', $data_type, size_text($size), $expected;
    }
  };
}

# ---------------------------------------------------------------------------
# 1. install_ddl
# ---------------------------------------------------------------------------
ddl_cases_ok('the table of karr k116, row for row',                TypeModifierCases->card);
ddl_cases_ok('every other name of a type with a modifier',         TypeModifierCases->synonyms);
ddl_cases_ok('pgvector keeps its dimensions',                      TypeModifierCases->pgvector);
ddl_cases_ok('without a size nothing is added',                    TypeModifierCases->unsized);
ddl_cases_ok('a type without a modifier never gets one',           TypeModifierCases->without_modifier);
ddl_cases_ok('a type nobody here knows: its size is left out, as it was', TypeModifierCases->unknown);

# A size that is neither a number nor a list of them would reach the
# statement as HASH(0x...). The portable types refuse it in core
# (DBIO::Schema::Type); the others refuse it here.
for my $data_type (qw(varchar character bit interval)) {
  ok !eval { written_types([ $data_type, { length => 10 } ]); 1 },
    "$data_type with a hash for a size is refused";
  like $@, qr/size.*scalar or an arrayref/, '... naming what a size may be';
}

# ---------------------------------------------------------------------------
# 2. The adapter: the portable base types
# ---------------------------------------------------------------------------
#
# char and numeric took their size before; a numeric with a precision alone
# and a timestamp with one did not.
{
  my $adapter = DBIO::PostgreSQL::Adapter->new;
  my @cases = (
    [ { base_type => 'char', size => 10 },                    'character(10)' ],
    [ { base_type => 'numeric', precision => 10, scale => 2 }, 'numeric(10,2)' ],
    [ { base_type => 'numeric', precision => 10 },             'numeric(10)' ],
    [ { base_type => 'numeric' },                              'numeric' ],
    [ { base_type => 'numeric', scale => 2 },                  'numeric' ],
    [ { base_type => 'timestamp', size => 3 },                 'timestamptz(3)' ],
    [ { base_type => 'timestamp', size => 0 },                 'timestamptz(0)' ],
    [ { base_type => 'timestamp' },                            'timestamptz' ],
    # a native type without a modifier ignores a size here as well
    [ { base_type => 'integer', size => 11 },                  'bigint' ],
    [ { base_type => 'text', size => 255 },                    'text' ],
    [ { base_type => 'boolean', size => 1 },                   'boolean' ],
    [ { base_type => 'double', size => 53 },                   'double precision' ],
    [ { base_type => 'blob', size => 255 },                    'bytea' ],
  );
  for my $case (@cases) {
    my ($col, $expected) = @$case;
    my $given = join ', ', map { "$_ => $col->{$_}" } sort keys %$col;
    is $adapter->to_native($col), $expected, "adapter: { $given } is $expected";
  }
}

# ---------------------------------------------------------------------------
# 3. The column diff
# ---------------------------------------------------------------------------
#
# A model that keeps type and size apart (the shape Introspect::Normalize
# makes) is rendered by the same rule. "timestamp with time zone(6)" is a
# syntax error on the server.
{
  my $tables = { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r' } };
  my @cases = (
    [ 'timestamp with time zone',    6,         'timestamp(6) with time zone' ],
    [ 'timestamp without time zone', 6,         'timestamp(6) without time zone' ],
    [ 'time with time zone',         0,         'time(0) with time zone' ],
    [ 'timestamp',                   6,         'timestamp(6)' ],
    [ 'interval',                    3,         'interval(3)' ],
    [ 'varchar',                     100,       'varchar(100)' ],
    [ 'numeric',                     [ 12, 2 ], 'numeric(12,2)' ],
    [ 'bit',                         8,         'bit(8)' ],
  );
  for my $case (@cases) {
    my ($data_type, $size, $expected) = @$case;
    my ($add) = DBIO::PostgreSQL::Diff::Column->diff(
      { 'public.t' => [] },
      { 'public.t' => [ { column_name => 'c', data_type => $data_type, size => $size, not_null => 0 } ] },
      $tables, $tables,
    );
    is $add->as_sql, "ALTER TABLE public.t ADD COLUMN c $expected;",
      sprintf 'diff: adding %s, %s writes %s', $data_type, size_text($size), $expected;

    my ($alter) = DBIO::PostgreSQL::Diff::Column->diff(
      { 'public.t' => [ { column_name => 'c', data_type => 'text', not_null => 0 } ] },
      { 'public.t' => [ { column_name => 'c', data_type => $data_type, size => $size, not_null => 0 } ] },
      $tables, $tables,
    );
    is $alter->as_sql, "ALTER TABLE public.t ALTER COLUMN c TYPE $expected;",
      '... and so does changing a column to it';
  }
}

# ---------------------------------------------------------------------------
# 4. The target model of a compiled schema
# ---------------------------------------------------------------------------
#
# target_from_compiled has to say a type the way format_type reads it back,
# or the diff against the installed database changes the column on every run.
{
  my @cases = (
    [ 'character(10)',  'character(10)' ],
    [ 'numeric(10,2)',  'numeric(10,2)' ],
    [ 'numeric(10)',    'numeric(10,0)' ],
    [ 'numeric',        'numeric' ],
    [ 'timestamptz',    'timestamp with time zone' ],
    [ 'timestamptz(3)', 'timestamp(3) with time zone' ],
    [ 'timestamptz(0)', 'timestamp(0) with time zone' ],
    [ 'bigint',         'bigint' ],
  );
  my $i = 0;
  my $target = DBIO::PostgreSQL::Diff->target_from_compiled({
    tables => {
      t => {
        table_name => 't',
        columns    => [ map { { column_name => 'c' . $i++, native_type => $_->[0], not_null => 0 } } @cases ],
      },
    },
  });
  my @data_type = map { $_->{data_type} } @{ $target->{columns}{'public.t'} };
  for my $i (0 .. $#cases) {
    is $data_type[$i], $cases[$i][1],
      "compiled: the native type $cases[$i][0] is the catalog's $cases[$i][1]";
  }
}

# ---------------------------------------------------------------------------
# 5. Reading back: Introspect::Normalize, and round again
# ---------------------------------------------------------------------------
#
# format_type's text for a column, taken apart into data_type and size, has
# to make the same column when a schema generated from it is installed. The
# third entry is what install_ddl writes for the pair; t/98 holds that the
# server reads each of these as the first again.
{
  my @cases = (
    # format_type                      data_type, size                         written again
    [ 'character(10)',                  [ 'char', 10 ],                         'character(10)' ],
    [ 'character varying(10)',          [ 'varchar', 10 ],                      'character varying(10)' ],
    [ 'bit(8)',                         [ 'bit', 8 ],                           'bit(8)' ],
    [ 'bit varying(8)',                 [ 'varbit', 8 ],                        'varbit(8)' ],
    [ 'bit varying',                    [ 'varbit', undef ],                    'varbit' ],
    [ 'numeric(10,2)',                  [ 'numeric', [ 10, 2 ] ],               'numeric(10,2)' ],
    [ 'numeric(10,0)',                  [ 'numeric', [ 10, 0 ] ],               'numeric(10,0)' ],
    [ 'numeric',                        [ 'numeric', undef ],                   'numeric' ],
    [ 'time(0) without time zone',      [ 'time', 0 ],                          'time(0)' ],
    [ 'time without time zone',         [ 'time', undef ],                      'time' ],
    [ 'time(3) with time zone',         [ 'time with time zone', 3 ],           'time(3) with time zone' ],
    [ 'time with time zone',            [ 'time with time zone', undef ],       'time with time zone' ],
    [ 'timestamp(3) with time zone',    [ 'timestamp with time zone', 3 ],      'timestamp(3) with time zone' ],
    [ 'timestamp(0) with time zone',    [ 'timestamp with time zone', 0 ],      'timestamp(0) with time zone' ],
    [ 'timestamp with time zone',       [ 'timestamp with time zone', undef ],  'timestamp with time zone' ],
    [ 'interval(3)',                    [ 'interval', 3 ],                      'interval(3)' ],
    [ 'interval',                       [ 'interval', undef ],                  'interval' ],
    [ 'interval day to second(3)',      [ 'interval day to second(3)', undef ], 'interval day to second(3)' ],
    [ 'vector(3)',                      [ 'vector', 3 ],                        'vector(3)' ],
  );

  my @declared;
  for my $case (@cases) {
    my ($format_type, $expected) = @$case;
    my %info;
    DBIO::PostgreSQL::Introspect::Normalize->data_type(\%info, { data_type => $format_type });
    is_deeply [ @info{qw(data_type size)} ], $expected,
      sprintf 'read back: %s is %s, %s', $format_type, $expected->[0], size_text($expected->[1]);
    push @declared, [ @info{qw(data_type size)} ];
  }

  my @written = written_types(@declared);
  for my $i (0 .. $#cases) {
    is $written[$i], $cases[$i][2], "... and a schema generated from $cases[$i][0] writes $cases[$i][2]";
  }
}

# ---------------------------------------------------------------------------
# 6. The rule itself
# ---------------------------------------------------------------------------
{
  my $takes = \&DBIO::PostgreSQL::Util::type_takes_modifier;
  my $with  = \&DBIO::PostgreSQL::Util::type_with_modifier;

  for my $case (TypeModifierCases->card, TypeModifierCases->synonyms, TypeModifierCases->pgvector) {
    ok $takes->($case->[0]), "$case->[0] takes a modifier";
  }
  for my $case (TypeModifierCases->without_modifier, TypeModifierCases->unknown) {
    ok !$takes->($case->[0]), "$case->[0] takes none";
  }
  ok !$takes->($_), "'$_' takes none" for '', 'character(10)', 'varchar[]', '"char"';
  ok !$takes->(undef), 'no type takes none';

  is $with->('character', 10),                'character(10)',               'a modifier follows the name';
  is $with->('numeric', [ 10, 2 ]),           'numeric(10,2)',               'a list is written in its order';
  is $with->('timestamp with time zone', 3),  'timestamp(3) with time zone', '... but stands behind the first word of "with time zone"';
  is $with->('time without time zone', 0),    'time(0) without time zone',   '... and of "without time zone", a 0 included';
  is $with->('character', undef),             'character',                   'no size, no modifier';
  is $with->('character', []),                'character',                   'an empty list is no size';
  is $with->('character', ''),                'character',                   'neither is an empty string';
  ok !eval { $with->('character', { n => 1 }); 1 }, 'a hash is no size';
  like $@, qr/scalar or an arrayref/, '... and the refusal says what is';
}

done_testing;
