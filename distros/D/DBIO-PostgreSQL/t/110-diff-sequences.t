use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Column;
use DBIO::PostgreSQL::Diff::Sequence;
use DBIO::PostgreSQL::Diff::SequenceOwner;

# karr k121 (9) -- a default that calls a sequence finds the sequence there.
#
# WHY it exists: a serial column is, in the catalog, a column with the default
# nextval('t_id_seq'::regclass) and a sequence the column owns. The model has
# both. The diff wrote the column as the catalog has it and read the sequence
# not at all, so every statement of an upgrade that named a sequence the
# database lacked was one the server refuses:
#
#   CREATE TABLE public.late (id integer NOT NULL DEFAULT nextval('late_id_seq'::regclass));
#   ALTER TABLE public.grow ADD COLUMN n integer NOT NULL DEFAULT nextval('grow_n_seq'::regclass);
#   ALTER TABLE public.grow ALTER COLUMN n SET DEFAULT nextval('grow_n_seq'::regclass);
#       relation "late_id_seq" does not exist
#
# Adding a result class with a serial primary key to a deployed schema and
# calling upgrade is all it took.
#
# What is held here, without a database (t/110-...-live.t holds each against
# a server, through Deploy, with "the row gets its number" and "after apply
# the diff is empty"):
#
#  1. a sequence the target has and the source lacks is created, as the
#     target has it, ahead of the table, the column and the function that
#     call it, and given to its column behind them;
#  2. the sequence of an identity column is none to create: it is a part of
#     its column;
#  3. a sequence only the source has is left, and one both have is touched
#     only where it belongs to another column;
#  4. the one order of two things that cannot be written: a sequence under
#     the name the database's identity column holds is refused;
#  5. an identity goes ahead of the default that takes its place;
#  6. an operation built by hand without what its statement needs dies.

sub table {
  my ($schema, $name, %more) = @_;
  return ("$schema.$name" => { schema_name => $schema, table_name => $name, kind => 'r', %more });
}
sub col {
  my ($name, $type, %more) = @_;
  return { column_name => $name, data_type => $type, not_null => 0, identity => '', generated => '', %more };
}

# A sequence as Introspect::Sequences has it: what serial makes for
# $table.$column unless told otherwise.
sub sequence {
  my ($schema, $name, %more) = @_;
  return ("$schema.$name" => {
    schema_name => $schema, sequence_name => $name,
    owned_by_table => undef, owned_by_table_name => undef, owned_by_column => undef,
    is_identity => 0,
    data_type => 'integer', start_value => 1, increment => 1,
    min_value => 1, max_value => 2147483647, cache_size => 1, is_cycle => 0,
    %more,
  });
}
sub owned_by {
  my ($table, $column) = @_;
  return (owned_by_table => $table, owned_by_table_name => $table, owned_by_column => $column);
}

sub diff_of {
  my ($source, $target) = @_;
  return DBIO::PostgreSQL::Diff->new(source => $source, target => $target);
}
sub statements { [ map { split /\n/, $_->as_sql } @{ diff_of(@_)->operations } ] }

my $SERIAL = 'AS integer INCREMENT BY 1 MINVALUE 1 MAXVALUE 2147483647 START WITH 1 CACHE 1 NO CYCLE';

# --- 1. created ahead, owned behind -----------------------------------------

# The reported case: a table with a serial column that only the target has.
{
  my %base = ( schemas => { public => {} } );
  my $source = { %base, tables => {}, columns => {}, sequences => {} };
  my $target = {
    %base,
    tables    => { table(public => 'late') },
    columns   => { 'public.late' => [
      col(id => 'integer', not_null => 1, default_value => q{nextval('late_id_seq'::regclass)}),
      col(v  => 'text'),
    ] },
    sequences => { sequence(public => 'late_id_seq', owned_by(late => 'id')) },
  };

  is_deeply statements($source, $target), [
    "CREATE SEQUENCE public.late_id_seq $SERIAL;",
    q{CREATE TABLE public.late (id integer NOT NULL DEFAULT nextval('late_id_seq'::regclass), v text);},
    'ALTER SEQUENCE public.late_id_seq OWNED BY public.late.id;',
  ], 'a new table with a serial column: the sequence, the table whose default calls it, then whose it is';

  is diff_of($source, $target)->summary, join("\n",
    '  +sequence: public.late_id_seq',
    '  +table: public.late',
    '  ~sequence: public.late_id_seq (owned by public.late.id)',
  ), 'and the summary says the same three things';

  ok !diff_of($target, $target)->has_changes, 'a sequence both sides have alike asks for nothing';
}

# A serial column added to a table that is there, and a column that is there
# and gets the default.
{
  my %both = ( schemas => { public => {} }, tables => { table(public => 'grow') } );
  my $default = q{nextval('grow_n_seq'::regclass)};
  my %with = (
    columns   => { 'public.grow' => [ col(v => 'text'), col(n => 'integer', not_null => 1, default_value => $default) ] },
    sequences => { sequence(public => 'grow_n_seq', owned_by(grow => 'n')) },
  );

  is_deeply statements(
    { %both, columns => { 'public.grow' => [ col(v => 'text') ] }, sequences => {} }, { %both, %with },
  ), [
    "CREATE SEQUENCE public.grow_n_seq $SERIAL;",
    "ALTER TABLE public.grow ADD COLUMN n integer NOT NULL DEFAULT $default;",
    'ALTER SEQUENCE public.grow_n_seq OWNED BY public.grow.n;',
  ], 'ADD COLUMN: the sequence ahead of it, whose it is behind it';

  is_deeply statements(
    { %both, columns => { 'public.grow' => [ col(v => 'text'), col(n => 'integer', not_null => 1) ] }, sequences => {} },
    { %both, %with },
  ), [
    "CREATE SEQUENCE public.grow_n_seq $SERIAL;",
    "ALTER TABLE public.grow ALTER COLUMN n SET DEFAULT $default;",
    'ALTER SEQUENCE public.grow_n_seq OWNED BY public.grow.n;',
  ], 'SET DEFAULT on a column that is there: the same';
}

# Every name is written by the server's rule, in the sequence's own schema;
# the default is the catalog's text and is not touched.
{
  my $default = q{nextval('"Auth"."LateTab_Id_seq"'::regclass)};
  my $target = {
    schemas   => { public => {}, Auth => {} },
    tables    => { table(Auth => 'LateTab') },
    columns   => { 'Auth.LateTab' => [ col(Id => 'bigint', not_null => 1, default_value => $default) ] },
    sequences => { sequence(Auth => 'LateTab_Id_seq', owned_by(LateTab => 'Id'),
      # how the session reads the table, which is no name to write
      owned_by_table => '"Auth"."LateTab"',
      data_type => 'bigint', max_value => '9223372036854775807') },
  };
  is_deeply statements({ schemas => { public => {} }, tables => {}, columns => {}, sequences => {} }, $target), [
    'CREATE SCHEMA "Auth";',
    'CREATE SEQUENCE "Auth"."LateTab_Id_seq" AS bigint INCREMENT BY 1 MINVALUE 1 MAXVALUE 9223372036854775807 START WITH 1 CACHE 1 NO CYCLE;',
    qq{CREATE TABLE "Auth"."LateTab" ("Id" bigint NOT NULL DEFAULT $default);},
    'ALTER SEQUENCE "Auth"."LateTab_Id_seq" OWNED BY "Auth"."LateTab"."Id";',
  ], 'a Mixed-Case schema, table, column and sequence: each quoted for itself, behind its schema';
}

# A sequence no column owns, and one that counts otherwise: written with
# every parameter the model has, whatever the server would take by default.
{
  my $target = {
    schemas   => { public => {} },
    tables    => { table(public => 'ticket') },
    columns   => { 'public.ticket' => [ col(no => 'bigint', not_null => 1, default_value => q{nextval('ticket_no_seq'::regclass)}) ] },
    sequences => { sequence(public => 'ticket_no_seq',
      data_type => 'bigint', start_value => 1000, increment => -5,
      min_value => -1000, max_value => 1000, cache_size => 20, is_cycle => 1) },
  };
  is_deeply statements({ schemas => { public => {} }, tables => {}, columns => {}, sequences => {} }, $target), [
    'CREATE SEQUENCE public.ticket_no_seq AS bigint INCREMENT BY -5 MINVALUE -1000 MAXVALUE 1000 START WITH 1000 CACHE 20 CYCLE;',
    q{CREATE TABLE public.ticket (no bigint NOT NULL DEFAULT nextval('ticket_no_seq'::regclass));},
  ], 'a sequence of its own is created as the target has it, and given to nobody';
}

# The place in the order: behind schemas and types, ahead of functions and
# tables; whose it is behind the columns and ahead of the views.
{
  my $function = sub {
    my ($name) = @_;
    return ("public.$name()" => {
      schema_name => 'public', function_name => $name, kind => 'f',
      definition => "CREATE OR REPLACE FUNCTION public.$name() RETURNS bigint LANGUAGE sql AS \$\$ SELECT nextval('s') \$\$",
    });
  };
  my $source = {
    schemas => { public => {} }, types => {}, functions => {}, sequences => {},
    tables  => { table(public => 'kept') },
    columns => { 'public.kept' => [ col(a => 'integer') ] },
  };
  my $target = {
    schemas   => { public => {}, app => {} },
    types     => { 'app.mood' => { schema_name => 'app', type_name => 'mood', type_kind => 'enum', values => ['ok'] } },
    functions => { $function->('next_s') },
    sequences => { sequence(public => 's', owned_by(kept => 'b')) },
    tables    => {
      table(public => 'kept'), table(public => 'fresh'),
      'public.v' => { schema_name => 'public', table_name => 'v', kind => 'v',
        view_definition => ' SELECT a FROM kept;', depends_on => ['public.kept'] },
    },
    columns   => {
      'public.kept'  => [ col(a => 'integer'), col(b => 'integer', default_value => q{nextval('s'::regclass)}) ],
      'public.fresh' => [ col(a => 'integer') ],
    },
  };
  is_deeply [ map { (ref($_) =~ /::(\w+)\z/)[0] . ' ' . $_->action } @{ diff_of($source, $target)->operations } ], [
    'Schema create', 'Type create', 'Sequence create', 'Function create', 'Table create',
    'Column add', 'SequenceOwner own', 'View create',
  ], 'a sequence comes behind schemas and types and ahead of functions and tables, whose it is behind the columns';
}

# --- 2. the sequence of an identity column ------------------------------------

{
  my $target = {
    schemas   => { public => {} },
    tables    => { table(public => 'ident') },
    columns   => { 'public.ident' => [ col(id => 'bigint', not_null => 1, identity => 'a') ] },
    sequences => { sequence(public => 'ident_id_seq', owned_by(ident => 'id'), is_identity => 1,
      data_type => 'bigint', max_value => '9223372036854775807') },
  };
  is_deeply statements({ schemas => { public => {} }, tables => {}, columns => {}, sequences => {} }, $target), [
    'CREATE TABLE public.ident (id bigint NOT NULL GENERATED ALWAYS AS IDENTITY);',
  ], 'an identity column makes its sequence itself: no CREATE SEQUENCE, no OWNED BY';

  ok(DBIO::PostgreSQL::Diff::Sequence->is_own({ is_identity => 0 }), 'is_own: a sequence a column owns, or none');
  ok(DBIO::PostgreSQL::Diff::Sequence->is_own({}), 'is_own: an entry that does not say');
  ok(!DBIO::PostgreSQL::Diff::Sequence->is_own({ is_identity => 1 }), 'is_own: not the sequence of an identity column');
  ok(!DBIO::PostgreSQL::Diff::Sequence->is_own(undef), 'is_own: not what is not there');
}

# --- 3. what is left alone, and what a sequence belongs to --------------------

{
  my %both = (
    schemas => { public => {} },
    tables  => { table(public => 'a'), table(public => 'b') },
    columns => { 'public.a' => [ col(id => 'integer') ], 'public.b' => [ col(id => 'integer') ] },
  );
  my $with = sub { return { %both, sequences => { @_ } } };

  is_deeply statements($with->(sequence(public => 'gone_seq', owned_by(a => 'id'))), $with->()), [],
    'a sequence only the database has is left where it is';

  is_deeply statements(
    $with->(sequence(public => 's', owned_by(a => 'id'))),
    $with->(sequence(public => 's', owned_by(a => 'id'),
      data_type => 'bigint', max_value => '9223372036854775807', increment => 10, cache_size => 50)),
  ), [], 'a sequence both have is not compared: no ALTER SEQUENCE for its type or how it counts';

  is_deeply statements(
    $with->(sequence(public => 's', owned_by(a => 'id'))), $with->(sequence(public => 's', owned_by(b => 'id'))),
  ), [ 'ALTER SEQUENCE public.s OWNED BY public.b.id;' ], 'but it is given to the column the target has it at';

  is_deeply statements($with->(sequence(public => 's')), $with->(sequence(public => 's', owned_by(b => 'id')))),
    [ 'ALTER SEQUENCE public.s OWNED BY public.b.id;' ], 'also when it belonged to none';

  is_deeply statements($with->(sequence(public => 's', owned_by(a => 'id'))), $with->(sequence(public => 's'))),
    [ 'ALTER SEQUENCE public.s OWNED BY NONE;' ], 'and taken from its column where the target has it with none';
  is diff_of($with->(sequence(public => 's', owned_by(a => 'id'))), $with->(sequence(public => 's')))->summary,
    '  ~sequence: public.s (owned by none)', 'which the summary says';

  # A model built by hand that has no owned_by_table_name says nothing.
  my %hand = ( 'public.s' => { schema_name => 'public', sequence_name => 's' } );
  is_deeply statements($with->(sequence(public => 's', owned_by(a => 'id'))), $with->(%hand)), [],
    'a target entry that does not say what the sequence belongs to asks for nothing';
  is_deeply statements($with->(), $with->(%hand)), [ 'CREATE SEQUENCE public.s;' ],
    'and one without parameters is created with the server\'s';
}

# A sequence that stays while the table it belonged to goes: it is taken from
# the column ahead of DROP TABLE, which would take it along.
{
  my $source = {
    schemas   => { public => {} },
    tables    => { table(public => 'old') },
    columns   => { 'public.old' => [ col(id => 'integer', default_value => q{nextval('s'::regclass)}) ] },
    sequences => { sequence(public => 's', owned_by(old => 'id')) },
  };
  my $target = { schemas => { public => {} }, tables => {}, columns => {}, sequences => { sequence(public => 's') } };
  is_deeply statements($source, $target), [
    'ALTER SEQUENCE public.s OWNED BY NONE;',
    'DROP TABLE public.old;',
  ], 'a sequence the target keeps is taken from its column before the table goes';
}

# --- 4. a name the identity column of the database holds --------------------

{
  my %both = ( schemas => { public => {} }, tables => { table(public => 'Grow') } );
  my $source = {
    %both,
    columns   => { 'public.Grow' => [ col(N => 'integer', not_null => 1, identity => 'a') ] },
    sequences => { sequence(public => 'Grow_N_seq', owned_by(Grow => 'N'), is_identity => 1) },
  };
  my $target = {
    %both,
    columns   => { 'public.Grow' => [ col(N => 'integer', not_null => 1, default_value => q{nextval('"Grow_N_seq"'::regclass)}) ] },
    sequences => { sequence(public => 'Grow_N_seq', owned_by(Grow => 'N')) },
  };

  my $ops = eval { diff_of($source, $target)->operations };
  my $error = $@;
  is $ops, undef, 'identity made serial: no operation is built';
  like $error, qr/\Arefusing to diff: sequence public\.Grow_N_seq is a sequence of its own in the target, and in the database that name is the identity sequence of column public\.Grow\.N\n/,
    'the refusal names the sequence and the column whose identity it is';
  like $error, qr/^  ALTER TABLE public\."Grow" ALTER COLUMN "N" DROP IDENTITY;$/m,
    'and the statement that is the way out, with its names quoted';
  like $error, qr/No statement was generated\./, 'and says that nothing was generated';

  # After the way out the column is a plain one, and the diff runs.
  my $after = {
    %both,
    columns   => { 'public.Grow' => [ col(N => 'integer', not_null => 1) ] },
    sequences => {},
  };
  is_deeply statements($after, $target), [
    qq{CREATE SEQUENCE public."Grow_N_seq" $SERIAL;},
    q{ALTER TABLE public."Grow" ALTER COLUMN "N" SET DEFAULT nextval('"Grow_N_seq"'::regclass);},
    'ALTER SEQUENCE public."Grow_N_seq" OWNED BY public."Grow"."N";',
  ], 'after DROP IDENTITY the diff creates the sequence and sets the default';

  # The other way round is no clash: the identity makes a sequence of its own.
  is_deeply statements($target, $source), [
    'ALTER TABLE public."Grow" ALTER COLUMN "N" DROP DEFAULT;',
    'ALTER TABLE public."Grow" ALTER COLUMN "N" ADD GENERATED ALWAYS AS IDENTITY;',
  ], 'serial made identity: the default goes, the identity comes, the old sequence is left';
}

# --- 5. an identity and a default do not stand on one column -----------------

{
  my $alter = sub {
    my ($old, $new) = @_;
    return [ split /\n/, DBIO::PostgreSQL::Diff::Column->new(
      action => 'alter', table_key => 'public.t', schema_name => 'public', table_name => 't',
      column_name => 'n', old_info => $old, new_info => $new,
    )->as_sql ];
  };
  my $default = q{nextval('other_seq'::regclass)};

  is_deeply $alter->(col(n => 'integer', identity => 'd'), col(n => 'integer', default_value => $default)), [
    'ALTER TABLE public.t ALTER COLUMN n DROP IDENTITY;',
    "ALTER TABLE public.t ALTER COLUMN n SET DEFAULT $default;",
  ], 'the identity goes ahead of the default that takes its place';

  is_deeply $alter->(col(n => 'integer', default_value => $default), col(n => 'integer', identity => 'd')), [
    'ALTER TABLE public.t ALTER COLUMN n DROP DEFAULT;',
    'ALTER TABLE public.t ALTER COLUMN n ADD GENERATED BY DEFAULT AS IDENTITY;',
  ], 'the default goes ahead of the identity that takes its place';

  is_deeply $alter->(col(n => 'integer', identity => 'd'), col(n => 'integer', identity => 'a')), [
    'ALTER TABLE public.t ALTER COLUMN n SET GENERATED ALWAYS;',
  ], 'and one kind of identity is made the other as before';
}

# --- 6. operations built by hand ----------------------------------------------

{
  my $create = sub { DBIO::PostgreSQL::Diff::Sequence->new(action => 'create', @_) };
  is $create->(schema_name => 'app', sequence_name => 'Seq', sequence_info => { increment => 2 })->as_sql,
    'CREATE SEQUENCE app."Seq" INCREMENT BY 2;', 'a sequence with one parameter is written with that one';
  throws_ok { $create->(schema_name => 'app')->as_sql }
    qr/\ADBIO::PostgreSQL::Diff::Sequence: no statement for action 'create' on sequence app -- it has no sequence_name\n\z/,
    'a create without a name dies';
  throws_ok { DBIO::PostgreSQL::Diff::Sequence->new(action => 'alter', schema_name => 'app', sequence_name => 's')->as_sql }
    qr/\ADBIO::PostgreSQL::Diff::Sequence: no statement for action 'alter' on sequence app\.s -- the class knows no such action\n\z/,
    'an action the class does not know dies: it has no ALTER SEQUENCE';
  is(DBIO::PostgreSQL::Diff::Sequence->new(action => 'drop', schema_name => 'app', sequence_name => 'Seq')->as_sql,
    'DROP SEQUENCE app."Seq";', 'the drop of a sequence of a dropped schema is written as DROP SEQUENCE');

  my $own = sub { DBIO::PostgreSQL::Diff::SequenceOwner->new(action => 'own', schema_name => 'app', sequence_name => 's', @_) };
  is $own->(table_name => 'T', column_name => 'c')->as_sql,
    'ALTER SEQUENCE app.s OWNED BY app."T".c;', 'own with a table and a column';
  is $own->()->as_sql, 'ALTER SEQUENCE app.s OWNED BY NONE;', 'own with neither';
  throws_ok { $own->(table_name => 'T')->as_sql }
    qr/no statement for action 'own' on sequence app\.s -- it names a table without a column or a column without a table\n\z/,
    'own with a table and no column dies';
  throws_ok { DBIO::PostgreSQL::Diff::SequenceOwner->new(action => 'own', schema_name => 'app')->as_sql }
    qr/no statement for action 'own' on sequence app -- it has no sequence_name\n\z/,
    'own without a sequence dies';
  throws_ok { DBIO::PostgreSQL::Diff::SequenceOwner->new(action => 'create', schema_name => 'app', sequence_name => 's')->as_sql }
    qr/DBIO::PostgreSQL::Diff::SequenceOwner: no statement for action 'create' on sequence app\.s -- the class knows no such action\n\z/,
    'and so does an action the class does not know';
}

done_testing;
