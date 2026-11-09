use strict;
use warnings;

use Test::More;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::Core ();
use DBIO::Schema ();
use DBIO::Schema::ModelCompiler ();
use DBIO::PostgreSQL::Adapter ();
use DBIO::PostgreSQL::Diff ();
use DBIO::PostgreSQL::Introspect ();
use DBIO::PostgreSQL::Util qw(type_takes_modifier type_with_modifier);
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;
use TypeModifierCases;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# LIVE test for karr k116: a declared size arrives in the database.
#
# WHY it exists: t/97 pins what is written; only a server says whether it is
# the column that was declared. Four things are held here:
#
#  1. the rule against the catalog -- every built-in type the server gives a
#     type modifier is one for DBIO::PostgreSQL::Util, and the server refuses
#     a modifier on the types the rule leaves without one;
#  2. the round -- declare, install, and the introspector reads back exactly
#     the declared type, for every row of the card's table and every other
#     name of those types; a diff of the freshly installed database is empty;
#     a schema made from what the introspector read installs the same columns
#     again;
#  3. the runtime failure the card started from -- ten characters go into
#     data_type => 'character', size => 10, eight bits into 'bit'/8;
#  4. the compiled target model says a sized portable type the way the
#     catalog does, so its diff against the installed database is empty too.
#
# Everything happens in databases of this file's own (karr k81).

sub connect_to {
  my (@login) = @_;
  return LiveServer->control_dbh(login => \@login, attrs => { PrintWarn => 0 });
}

# One result class with one nullable column per case, named c000, c001, ...
my $class_seq = 0;
sub schema_for {
  my ($extensions, @cases) = @_;
  my $n      = ++$class_seq;
  my $schema = "T98::S$n";
  my $result = "T98::S${n}::Result::Types";
  {
    no strict 'refs';
    @{"${schema}::ISA"} = ('DBIO::Schema');
    @{"${result}::ISA"} = ('DBIO::Core');
  }
  $schema->load_components('PostgreSQL');
  $schema->pg_extensions(@$extensions) if @$extensions;
  $result->load_components('PostgreSQL::Result');
  $result->table('k116_types');
  my $i = 0;
  $result->add_columns(map {
    my ($data_type, $size) = @$_;
    sprintf('c%03d', $i++) => {
      data_type   => $data_type,
      is_nullable => 1,
      ( defined $size ? ( size => $size ) : () ),
    };
  } @cases);
  $schema->register_class(Types => $result);
  return $schema;
}

# The types of k116_types as the introspector's model has them, in order.
sub introspected_types {
  my ($dbh) = @_;
  my $model = DBIO::PostgreSQL::Introspect->new(dbh => $dbh)->model;
  return map { $_->{data_type} } @{ $model->{columns}{'public.k116_types'} // [] };
}

sub size_text {
  my ($size) = @_;
  return 'no size' unless defined $size;
  return 'size ' . ( ref $size ? '[' . join(', ', @$size) . ']' : $size );
}

# The rule (1.) leaves nothing behind in its database, so the rows (3.) go
# into the same one.
my @rule_db = PrivatePgDatabase->create('t98rule');
my $has_vector = do {
  my $dbh = connect_to(@rule_db);
  my ($found) = $dbh->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_available_extensions WHERE name = 'vector'});
  $dbh->disconnect;
  $found;
};
diag 'pgvector is not available on this server: vector, halfvec and sparsevec are not checked'
  unless $has_vector;

# ---------------------------------------------------------------------------
# 1. The rule, against the catalog
# ---------------------------------------------------------------------------
{
  my $dbh = connect_to(@rule_db);
  note 'server ' . $dbh->selectrow_array('SHOW server_version');

  # Every built-in type with a typmodin, under its catalog name and under the
  # name format_type gives it. A type the server has grown since is a type
  # whose size would be dropped again.
  my $with_modifier = $dbh->selectall_arrayref(q{
    SELECT t.typname, pg_catalog.format_type(t.oid, NULL)
    FROM pg_catalog.pg_type t
    WHERE t.typnamespace = 'pg_catalog'::regnamespace
      AND t.typmodin <> 0
      AND t.typcategory <> 'A'
    ORDER BY t.typname
  });
  cmp_ok scalar @$with_modifier, '>=', 10,
    'the server names its types with a modifier (' . join(', ', map { $_->[0] } @$with_modifier) . ')';
  my @missing = grep { !type_takes_modifier($_) } map { @$_ } @$with_modifier;
  is_deeply \@missing, [], 'every built-in type the server gives a modifier takes one here, under both its names'
    or diag "the server gives these a modifier, DBIO::PostgreSQL::Util does not: @missing";

  # The other half: what the rule leaves without a modifier, the server
  # refuses with one. Written anyway it would be a statement that fails.
  for my $case (TypeModifierCases->without_modifier) {
    my ($data_type, $size, $written) = @$case;
    my $with = type_with_modifier($written, $size);
    ok !eval { $dbh->do("CREATE TABLE k116_refused (c $with)"); 1 },
      "the server refuses $with -- the size of $data_type is rightly left out";
  }
  is_deeply $dbh->selectcol_arrayref(q{SELECT 1 FROM pg_catalog.pg_class WHERE relname = 'k116_refused'}),
    [], '... and none of them made a table';

  $dbh->disconnect;
}

# ---------------------------------------------------------------------------
# 2. Declare, install, read back, diff, and round again
# ---------------------------------------------------------------------------
SKIP: {
  my @cases = (
    TypeModifierCases->card,
    TypeModifierCases->synonyms,
    ( $has_vector ? TypeModifierCases->pgvector : () ),
    TypeModifierCases->unsized,
    TypeModifierCases->without_modifier,
  );
  my $extensions = [ $has_vector ? 'vector' : () ];

  my @db     = PrivatePgDatabase->create('t98round');
  my $schema = schema_for($extensions, @cases)->connect(@db, { PrintError => 0, PrintWarn => 0 });
  my $deploy = $schema->pg_deploy;

  ok eval { $deploy->install; 1 }, 'a table with a column for every case installs'
    or do { diag $@; skip 'the install failed; nothing of the round can be measured', 1 };

  my $dbh  = $schema->storage->dbh;
  my @read = introspected_types($dbh);
  is scalar @read, scalar @cases, 'the introspector reads every column back';
  for my $i (0 .. $#cases) {
    my ($data_type, $size, $written, $format_type) = @{ $cases[$i] };
    # The introspector reads under an empty search_path (qualified_names): a type
    # of an extension comes with its schema, which is "public" here.
    my $expected = $data_type =~ /\A(?:vector|halfvec|sparsevec)\z/ ? "public.$format_type" : $format_type;
    is $read[$i], $expected,
      sprintf '%s, %s (written %s) is read back as %s', $data_type, size_text($size), $written, $format_type;
  }

  my $diff = $deploy->diff;
  ok !$diff->has_changes, 'a diff of the freshly installed database is empty'
    or diag $diff->as_sql;

  # Round again: the column info a generated schema is made from, declared
  # and installed in a second database, gives the same columns.
  #
  # Three columns are left out, each for a reason that is not a size. What
  # the introspector reads as data_type 'timestamp' (timestamp without time
  # zone) or 'integer' is, declared under that name, a portable base type,
  # and those deploy as timestamptz and bigint. And a character varying
  # without a length is read as 'text'.
  my %not_a_size = map { $_ => 1 }
    'timestamp(3) without time zone', 'integer', 'character varying';
  my $introspect = DBIO::PostgreSQL::Introspect->new(dbh => $dbh);
  my $info       = $introspect->table_columns_info('public.k116_types');
  my (@again, @expected, @left_out);
  for my $i (0 .. $#cases) {
    if ($not_a_size{ $read[$i] }) {
      push @left_out, $read[$i];
      next;
    }
    my $column = $info->{ sprintf 'c%03d', $i };
    push @again,    [ $column->{data_type}, $column->{size} ];
    push @expected, $read[$i];
  }
  is_deeply [ sort @left_out ], [ sort keys %not_a_size ],
    'all but three columns go into the second round';

  my @db2     = PrivatePgDatabase->create('t98again');
  my $schema2 = schema_for($extensions, @again)->connect(@db2, { PrintError => 0, PrintWarn => 0 });
  ok eval { $schema2->pg_deploy->install; 1 }, 'the schema made from what was read back installs'
    or diag $@;
  is_deeply [ introspected_types($schema2->storage->dbh) ], \@expected,
    '... with every column the type it had in the first database';

  $schema2->storage->disconnect;
  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 3. The rows the card could not insert
# ---------------------------------------------------------------------------
{
  package T98::Rows::Result::Row;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('PostgreSQL::Result');
  __PACKAGE__->table('k116_rows');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer',   is_auto_increment => 1 },
    code   => { data_type => 'character', size => 10 },
    flags  => { data_type => 'bit',       size => 8 },
    mask   => { data_type => 'varbit',    size => 8 },
    amount => { data_type => 'decimal',   size => [ 10, 2 ] },
    at     => { data_type => 'time',      size => 0 },
    seen   => { data_type => 'timestamp', size => 3 },
  );
  __PACKAGE__->set_primary_key('id');

  package T98::Rows;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Row => 'T98::Rows::Result::Row');
}
{
  my $schema = T98::Rows->connect(@rule_db, { PrintError => 0, PrintWarn => 0 });
  ok eval { $schema->pg_deploy->install; 1 }, 'the table of the card installs' or diag $@;

  my $rs  = $schema->resultset('Row');
  my $row = eval {
    $rs->create({
      code   => 'abcdefghij',
      flags  => '10101010',
      mask   => '101',
      amount => '12345678.915',
      at     => '12:34:56.789',
      seen   => '2026-10-08 12:34:56.123456+00',
    });
  };
  ok $row, 'ten characters go into character/10, eight bits into bit/8' or diag $@;

  SKIP: {
    skip 'the insert failed', 6 unless $row;
    my ($code, $flags, $mask, $amount, $at, $seconds) = $schema->storage->dbh->selectrow_array(
      q{SELECT code, flags::text, mask::text, amount::text, at::text, to_char(seen, 'SS.US') FROM k116_rows});
    is $code,    'abcdefghij',  '... and all ten characters are there';
    is $flags,   '10101010',    '... and all eight bits';
    is $mask,    '101',         'a bit varying of 8 keeps a value of three bits as it is';
    is $amount,  '12345678.92', 'decimal [10,2] has its scale: the third decimal is rounded away';
    is $at,      '12:34:57',    'time with a size of 0 has no fraction';
    is $seconds, '56.123000',   'timestamp with a size of 3 keeps milliseconds';
  }

  ok !eval { $rs->create({ code => 'abcdefghijk', flags => '10101010', amount => 1, at => '00:00', seen => 'now' }); 1 },
    'eleven characters are refused: the size is the column\'s, not more';
  ok !eval { $rs->create({ code => 'a', flags => '10101010', mask => '101010101', amount => 1, at => '00:00', seen => 'now' }); 1 },
    'nine bits are refused by a bit varying of 8';

  $schema->storage->disconnect;
}

# ---------------------------------------------------------------------------
# 4. The compiled target model
# ---------------------------------------------------------------------------
#
# install_ddl and the model compiler both ask the adapter. What it answers
# for a sized portable type has to be, in the target model, the text the
# catalog has for the installed column -- numeric(10) is numeric(10,0)
# there -- or the diff alters the column on every run.
{
  package T98::Portable::Result::Thing;
  use base 'DBIO::Core';
  __PACKAGE__->table('k116_portable');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'char',    size => 32 },
    amt  => { data_type => 'numeric', size => [ 10, 2 ] },
    qty  => { data_type => 'numeric', size => 10 },
    cnt  => { data_type => 'numeric', size => [ 5 ] },
    any  => { data_type => 'numeric' },
    seen => { data_type => 'timestamp' },
  );
  __PACKAGE__->set_primary_key('id');

  package T98::Portable;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_class(Thing => 'T98::Portable::Result::Thing');
}
{
  my $schema = T98::Portable->connect(PrivatePgDatabase->create('t98comp'), { PrintError => 0, PrintWarn => 0 });
  ok eval { $schema->pg_deploy->install; 1 }, 'a schema of portable types installs' or diag $@;

  my $source = DBIO::PostgreSQL::Introspect->new(dbh => $schema->storage->dbh)->model;
  my $target = DBIO::PostgreSQL::Diff->target_from_compiled(
    DBIO::Schema::ModelCompiler->new(adapter => DBIO::PostgreSQL::Adapter->new)->compile($schema),
  );

  is_deeply
    [ map { $_->{data_type} } @{ $target->{columns}{'public.k116_portable'} } ],
    [ map { $_->{data_type} } @{ $source->{columns}{'public.k116_portable'} } ],
    'the compiled target has every type as the catalog reads the installed column';
  is_deeply
    [ map { $_->{data_type} } @{ $source->{columns}{'public.k116_portable'} } ],
    [ 'bigint', 'character(32)', 'numeric(10,2)', 'numeric(10,0)', 'numeric(5,0)', 'numeric', 'timestamp with time zone' ],
    '... and the catalog has them as declared';

  my $diff = DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
  ok !$diff->has_changes, 'the diff of the installed database against the compiled target is empty'
    or diag $diff->as_sql;

  $schema->storage->disconnect;
}

done_testing;
