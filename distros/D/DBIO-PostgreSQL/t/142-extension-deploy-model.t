use strict;
use warnings;
use Test::More;
use Test::Exception;
use Storable ();

use DBIO::Extension::Protocol;
use DBIO::PostgreSQL::Deploy;

# The deploy and the diff read every model entry they are given: a warning is
# a place that reads a key the entry lacks. None is allowed (karr k152).
my @warnings;
BEGIN { $SIG{__WARN__} = sub { push @warnings, @_ } }

# OFFLINE test: what the PostgreSQL deploy does with the answers of the
# extensions (ADR 0066, phases 0 to 2): claims with their cascade,
# annotations, states, and the helpers an extension builds its addresses with.
#
# WHY: an extension names an object by an address and the driver owns the
# model. A claimed schema that leaves its tables behind, a claim that takes a
# neighbour, an annotation that silently rewrites what the introspection read,
# or a state an extension can change would each be a diff that drops or
# creates something it must not.
#
# What this file claims:
#   1. [schema], [table], [column], [type] claims remove the object with the
#      cascade the POD documents, and nothing else;
#   2. a claim of an object the model does not hold is passed over; an address
#      of an unknown kind is refused;
#   3. annotations set the attribute on the entry of the object, pass over an
#      absent object, refuse to rewrite an attribute with another value;
#   4. states are put under extension_states, read-only, and the model's own
#      extensions section is untouched;
#   5. through the protocol and Deploy::diff all of this runs on both sides,
#      the verdict reaches the statement, two extensions annotating one
#      attribute differently are refused, an undeclared extension's rules do
#      not run.

my $deploy = DBIO::PostgreSQL::Deploy->new;

sub fixture {
  return {
    schemas => { public => {}, g1 => {}, app => {} },
    tables  => {
      'g1.v'      => { schema_name => 'g1',  table_name => 'v',      kind => 'r' },
      'g1.e'      => { schema_name => 'g1',  table_name => 'e',      kind => 'r' },
      'app.users' => { schema_name => 'app', table_name => 'users',  kind => 'r' },
      'app.posts' => { schema_name => 'app', table_name => 'posts',  kind => 'r' },
    },
    columns => {
      'g1.v'      => [ { column_name => 'id', data_type => 'integer' }, { column_name => 'props', data_type => 'jsonb' } ],
      'g1.e'      => [ { column_name => 'id', data_type => 'integer' } ],
      'app.users' => [ { column_name => 'id', data_type => 'integer' }, { column_name => 'geom', data_type => 'geometry' } ],
      'app.posts' => [ { column_name => 'id', data_type => 'integer' } ],
    },
    indexes  => { 'g1.v' => { v_pkey => {} }, 'app.users' => { users_pkey => {} } },
    triggers => { 'g1.v' => { t => {} },      'app.users' => { u => {} } },
    policies => { 'g1.v' => { p => {} },      'app.users' => { q => {} } },
    foreign_keys      => {
      'g1.e'      => [ { constraint_name => 'e_fk', remote_schema => 'app', remote_table => 'users' } ],
      'app.posts' => [ { constraint_name => 'to_users', remote_schema => 'app', remote_table => 'users' } ],
    },
    check_constraints => { 'g1.v' => { c => {} }, 'app.users' => { c => {} } },
    sequences => {
      'g1.v_id_seq'      => { schema_name => 'g1',  owned_by_table => 'g1.v',      owned_by_table_name => 'v',     owned_by_column => 'id' },
      'g1.lonely'        => { schema_name => 'g1' },
      'app.users_id_seq' => { schema_name => 'app', owned_by_table => 'app.users', owned_by_table_name => 'users', owned_by_column => 'id' },
      'app.users_x_seq'  => { schema_name => 'app', owned_by_table => 'app.users', owned_by_table_name => 'users', owned_by_column => 'x' },
    },
    types     => {
      'g1.t'     => { schema_name => 'g1',  type_name => 't',    type_kind => 'enum', values => ['a'] },
      'app.role' => { schema_name => 'app', type_name => 'role', type_kind => 'enum', values => ['a'] },
    },
    functions => { 'g1.f()' => { schema_name => 'g1' }, 'app.f()' => { schema_name => 'app' } },
    extensions => { postgis => { extension_name => 'postgis' } },
  };
}

sub claimed { my ($model, @addresses) = @_; $deploy->_apply_extension_claims($model, \@addresses); return $model }

sub keys_of { [ sort keys %{ $_[0] } ] }

# --- 1. claims -----------------------------------------------------------------
{
  my $m = claimed(fixture(), [ schema => 'g1' ]);
  is_deeply keys_of($m->{schemas}), [qw( app public )], 'a claimed schema leaves the model';
  is_deeply keys_of($m->{tables}), [qw( app.posts app.users )], '... with its tables';
  is_deeply keys_of($m->{columns}), [qw( app.posts app.users )], '... their columns';
  is_deeply keys_of($m->{indexes}), ['app.users'], '... indexes';
  is_deeply keys_of($m->{triggers}), ['app.users'], '... triggers';
  is_deeply keys_of($m->{policies}), ['app.users'], '... policies';
  is_deeply keys_of($m->{foreign_keys}), ['app.posts'], '... foreign keys';
  is_deeply keys_of($m->{check_constraints}), ['app.users'], '... CHECK constraints';
  is_deeply keys_of($m->{sequences}), [qw( app.users_id_seq app.users_x_seq )], '... sequences, also one of its own';
  is_deeply keys_of($m->{types}), ['app.role'], '... types';
  is_deeply keys_of($m->{functions}), ['app.f()'], '... functions';
  is_deeply keys_of($m->{extensions}), ['postgis'], 'the extensions section is not touched';
}
{
  my $m = claimed(fixture(), [ table => 'app.users' ]);
  is_deeply keys_of($m->{tables}), [qw( app.posts g1.e g1.v )], 'a claimed table leaves the model';
  is_deeply keys_of($m->{columns}), [qw( app.posts g1.e g1.v )], '... with its columns';
  is_deeply keys_of($m->{indexes}), ['g1.v'], '... indexes';
  is_deeply keys_of($m->{triggers}), ['g1.v'], '... triggers';
  is_deeply keys_of($m->{policies}), ['g1.v'], '... policies';
  is_deeply keys_of($m->{check_constraints}), ['g1.v'], '... CHECK constraints';
  is_deeply keys_of($m->{sequences}), [qw( g1.lonely g1.v_id_seq )], '... and the sequences that belong to its columns';
  is_deeply keys_of($m->{foreign_keys}), [qw( app.posts g1.e )],
    '... foreign keys of its own; the foreign key of another table that points at it stays';
  is_deeply keys_of($m->{schemas}), [qw( app g1 public )], 'the schema stays';
}
{
  my $m = claimed(fixture(), [ column => 'app.users', 'geom' ]);
  is_deeply [ map { $_->{column_name} } @{ $m->{columns}{'app.users'} } ], ['id'], 'a claimed column leaves its table';
  is_deeply keys_of($m->{tables}), [qw( app.posts app.users g1.e g1.v )], '... the table stays';
  is scalar keys %{ $m->{sequences} }, 4, '... no sequence belonged to it';

  $m = claimed(fixture(), [ column => 'app.users', 'x' ]);
  is_deeply keys_of($m->{sequences}), [qw( app.users_id_seq g1.lonely g1.v_id_seq )],
    'a claimed column takes the sequence that belongs to it';
}
{
  my $m = claimed(fixture(), [ type => 'g1.t' ]);
  is_deeply keys_of($m->{types}), ['app.role'], 'a claimed type leaves the model';
  is_deeply keys_of($m->{tables}), [qw( app.posts app.users g1.e g1.v )], '... and nothing else';
}
{
  my $m = claimed(fixture(), [ schema => 'g1' ], [ table => 'g1.v' ], [ table => 'app.posts' ]);
  my $n = claimed(fixture(), [ table => 'app.posts' ], [ table => 'g1.v' ], [ schema => 'g1' ]);
  is_deeply $m, $n, 'claims in any order give the same model';
  is_deeply claimed(claimed(fixture(), [ schema => 'g1' ]), [ schema => 'g1' ]),
    claimed(fixture(), [ schema => 'g1' ]), 'claiming twice is claiming once';
}

# --- 2. absent, unknown ----------------------------------------------------------------
{
  my $m = claimed(fixture(), [ schema => 'nowhere' ], [ table => 'x.y' ], [ column => 'x.y', 'z' ],
    [ column => 'app.users', 'nope' ], [ type => 'x.t' ]);
  is_deeply $m, fixture(), 'an address the model does not hold changes nothing';
  throws_ok { claimed(fixture(), [ function => 'g1.f()' ]) }
    qr/extension claim: the address \[function, g1\.f\(\)\] is of a kind this deploy does not know/,
    'an address of another kind is refused, naming it';
  throws_ok { $deploy->_apply_extension_annotations(fixture(), [ [ [ index => 'x' ], 'a', 1 ] ]) }
    qr/extension annotation: the address \[index, x\] is of a kind/, '... also in an annotation';
}

# --- 3. annotations -----------------------------------------------------------------------
{
  my $m = fixture();
  $deploy->_apply_extension_annotations($m, [
    [ [ column => 'app.users', 'geom' ], srid => 4326 ],
    [ [ column => 'app.users', 'geom' ], base_type => 'geometry' ],
    [ [ table  => 'app.users' ], spatial => { cols => ['geom'] } ],
    [ [ type   => 'app.role' ], flavour => 'x' ],
    [ [ schema => 'app' ], graph => 0 ],
    [ [ column => 'app.users', 'gone' ], srid => 1 ],
    [ [ table  => 'x.y' ], a => 1 ],
  ]);
  my ($geom) = grep { $_->{column_name} eq 'geom' } @{ $m->{columns}{'app.users'} };
  is $geom->{srid}, 4326, 'an annotation is an attribute of the column';
  is $geom->{base_type}, 'geometry', '... several';
  is_deeply $m->{tables}{'app.users'}{spatial}, { cols => ['geom'] }, 'of a table, a structure';
  is $m->{types}{'app.role'}{flavour}, 'x', 'of a type';
  is $m->{schemas}{app}{graph}, 0, 'of a schema, a false value too';
  ok !exists $m->{columns}{'app.users'}[0]{srid}, 'not of another column';

  my $copy = Storable::dclone($m);
  $deploy->_apply_extension_annotations($m, [ [ [ column => 'app.users', 'geom' ], srid => 4326 ] ]);
  is_deeply $m, $copy, 'the same value again changes nothing';

  throws_ok { $deploy->_apply_extension_annotations($m, [ [ [ column => 'app.users', 'geom' ], srid => 3857 ] ]) }
    qr/column 'app\.users\.geom' already has the attribute 'srid' with another value/,
    'another value for an attribute is refused';
  throws_ok { $deploy->_apply_extension_annotations($m, [ [ [ column => 'app.users', 'geom' ], data_type => 'geography' ] ]) }
    qr/already has the attribute 'data_type' with another value/,
    '... also for what the introspection read';
}

# --- 4. states -------------------------------------------------------------------------------
{
  my $m = fixture();
  $deploy->_apply_extension_states($m, { age => { graphs => [ { name => 'g', namespace => 'g1' } ] } });
  is $m->{extension_states}{age}{graphs}[0]{namespace}, 'g1', 'the state is under the extension\'s name';
  is_deeply keys_of($m->{extensions}), ['postgis'], '... the extensions section is untouched';
  throws_ok { $m->{extension_states}{age}{graphs}[0]{namespace} = 'x' } qr/read-only|restricted/,
    'the state is read-only';
  throws_ok { $m->{extension_states}{new} = 1 } qr/disallowed|restricted/, '... also against a new key';
}

# --- the helpers -------------------------------------------------------------------------------
{
  my $h = $deploy->_extension_driver_helpers;
  is_deeply $h->{schema}->('auth'), [ schema => 'auth' ], 'schema()';
  is_deeply $h->{table}->('auth.users'), [ table => 'auth.users' ], 'table($key)';
  is_deeply $h->{table}->('auth', 'users'), [ table => 'auth.users' ], 'table($schema, $name)';
  is_deeply $h->{column}->('auth.users', 'id'), [ column => 'auth.users', 'id' ], 'column($key, $column)';
  is_deeply $h->{column}->('auth', 'users', 'id'), [ column => 'auth.users', 'id' ], 'column($schema, $table, $column)';
  is_deeply $h->{type}->('auth', 'role'), [ type => 'auth.role' ], 'type($schema, $name)';
  is $h->{qualified_key}->('a', 'b'), 'a.b', 'qualified_key';
  is $h->{quote_ident}->('Mixed'), '"Mixed"', 'quote_ident is the driver\'s';
  is $h->{quote_qualified}->('a', 'B'), 'a."B"', 'quote_qualified';
  is $deploy->_extension_connection_schema, undef, 'a deploy without a schema has no connection schema';
  is $deploy->_extension_restricted, 0, '... and is not restricted';
}

# --- 5. through Deploy::diff -----------------------------------------------------------------------
{
  package T142::Claim;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'claimer' }
  sub driver { 'DBIO::PostgreSQL' }
  sub inspect { { graphs => ['g1'] } }
  sub claims {
    my ($class, $model, $ctx) = @_;
    return [ map { $ctx->{driver}{schema}->($_) } @{ $ctx->{self}{state}{graphs} || [] } ];
  }
  sub annotate { [] }
  package T142::Annotate;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'annotator' }
  sub driver { 'DBIO::PostgreSQL' }
  # the SRID of a geometry column, from its type
  sub annotate {
    my ($class, $model, $ctx) = @_;
    my @out;
    for my $table (sort keys %{ $model->{columns} }) {
      for my $column (@{ $model->{columns}{$table} }) {
        next unless ($column->{data_type} // '') =~ /^geometry\(\w+,(\d+)\)$/;
        push @out, [ $ctx->{driver}{column}->($table, $column->{column_name}), srid => $1 + 0 ];
      }
    }
    return \@out;
  }
  sub verdict {
    my ($class, $change, $ctx) = @_;
    return undef unless ($change->{kind} // '') eq 'column_type';
    return { using => "ST_Transform($change->{column_name}, $change->{new_info}{srid})" }
      if defined $change->{old_info}{srid};
    return undef;
  }
  package T142::Clash;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'clash' }
  sub driver { 'DBIO::PostgreSQL' }
  sub annotate { [ [ [ column => 'app.users', 'geom' ], srid => 9999 ] ] }

  package T142::Deploy;
  use base 'DBIO::PostgreSQL::Deploy';
  our ($SOURCE, $TARGET, @DECLARED);
  sub _dbh { {} }
  sub _extension_control_schemas { {} }
  sub _installed_extensions { +{ map { $_ => { installed => 1, version => '1', schema => 'public' } } @{ $_[1] } } }
  sub _introspect_current { Storable::dclone($SOURCE) }
  sub _build_target_model { Storable::dclone($TARGET) }
}
$INC{"T142/$_.pm"} = __FILE__ for qw( Claim Annotate Clash );

my $schemas = 0;
sub schema_for {
  my (@extensions) = @_;
  my $pkg = 'T142::S' . ++$schemas;
  eval "package $pkg; use base q(DBIO::Schema); 1" or die $@;
  $pkg->load_components('PostgreSQL');
  $pkg->pg_extensions(@extensions);
  return $pkg;
}

sub model {
  my ($srid, %extra) = @_;
  my $m = fixture();
  my ($geom) = grep { $_->{column_name} eq 'geom' } @{ $m->{columns}{'app.users'} };
  $geom->{data_type} = "geometry(Point,$srid)";
  $m->{extensions} = { map { $_ => { extension_name => $_, version => '1', schema_name => 'public', relocatable => 1, requires => [] } } qw( claimer annotator ) };
  return $m;
}

# The target has a table in the g1 schema that the source lacks, and the
# source one the target lacks: neither is the diff's to create or drop once
# the schema is claimed.
sub with_g1_changes {
  my ($model) = @_;
  $model->{tables}{'g1.new'} = { schema_name => 'g1', table_name => 'new', kind => 'r' };
  $model->{columns}{'g1.new'} = [ { column_name => 'id', data_type => 'integer' } ];
  delete $model->{tables}{'g1.e'};
  delete $model->{columns}{'g1.e'};
  return $model;
}

{
  local ($T142::Deploy::SOURCE, $T142::Deploy::TARGET) = (model(4326), with_g1_changes(model(3857)));

  my $schema = schema_for(
    claimer   => { class => 'T142::Claim' },
    annotator => { class => 'T142::Annotate' },
  );
  my $diff = T142::Deploy->new(schema => $schema)->diff;
  my $sql = $diff->as_sql;
  unlike $sql, qr/g1\./, 'the claimed schema is neither created nor dropped in: no statement mentions it';
  like $sql, qr/ALTER TABLE app\.users ALTER COLUMN geom TYPE geometry\(Point,3857\) USING ST_Transform\(geom, 3857\);/,
    'the annotation of the model reaches the verdict, and its using reaches the statement';
  is_deeply $diff->source->{extension_states}{claimer}, { graphs => ['g1'] }, 'the state is in the source model';
  is_deeply $diff->target->{extension_states}{claimer}, { graphs => ['g1'] }, '... and in the target model';
  ok !exists $diff->source->{tables}{'g1.v'}, 'the claim is applied to the source';
  ok !exists $diff->target->{tables}{'g1.new'}, '... and to the target';
  is $diff->source->{columns}{'app.users'}[1]{srid}, 4326, 'the annotation is applied to the source';
  is $diff->target->{columns}{'app.users'}[1]{srid}, 3857, '... and to the target';
}
{
  # an extension that is not declared does not run
  local ($T142::Deploy::SOURCE, $T142::Deploy::TARGET) = (model(4326), with_g1_changes(model(3857)));
  my $schema = schema_for('claimer', 'annotator');   # plain classes
  my $sql = T142::Deploy->new(schema => $schema)->diff->as_sql;
  like $sql, qr/CREATE TABLE g1\.new/, 'with plain classes nothing is claimed: the table in g1 is created';
  like $sql, qr/DROP TABLE g1\.e/, '... and the other dropped';
  like $sql, qr/ALTER COLUMN geom TYPE geometry\(Point,3857\);/, '... and the type change has no USING';
}
{
  local ($T142::Deploy::SOURCE, $T142::Deploy::TARGET) = (model(4326), model(4326));
  my $schema = schema_for(
    annotator => { class => 'T142::Annotate' },
    clash     => { class => 'T142::Clash' },
  );
  throws_ok { T142::Deploy->new(schema => $schema)->diff }
    qr/Extensions annotate the same object differently:.*srid: annotator => "4326"; clash => "9999"/s,
    'two extensions that annotate one attribute differently refuse the diff';
}
{
  local ($T142::Deploy::SOURCE, $T142::Deploy::TARGET) = (model(4326), model(4326));
  my $schema = schema_for(annotator => { class => 'T142::Annotate' });
  my $model = Storable::dclone($T142::Deploy::SOURCE);
  $model->{columns}{'app.users'}[1]{srid} = 1;
  local $T142::Deploy::SOURCE = $model;
  throws_ok { T142::Deploy->new(schema => $schema)->diff }
    qr/already has the attribute 'srid' with another value/,
    'an annotation that would rewrite what the model carries refuses the diff';
}

is_deeply \@warnings, [], 'the whole file ran without a warning';

done_testing;
