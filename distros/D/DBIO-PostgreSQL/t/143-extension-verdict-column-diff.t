use strict;
use warnings;
use Test::More;

use DBIO::Extension::Protocol;
use DBIO::PostgreSQL::Diff;
use DBIO::PostgreSQL::Diff::Column;

# OFFLINE test: the extensions of a schema are asked about each change of a
# column's type (ADR 0066, phase 3), and the diff writes or refuses the change
# as they answer.
#
# WHY: PostGIS converts another SRID with ST_Transform and refuses another
# geometry type; the diff cannot know that, the extension does. The answer has
# to reach the statement ({ using }) or stop the diff for good ({ refuse }, with
# every message), and a schema without the extension is not affected.
#
# What this file claims:
#   1. without a protocol nothing is asked and the statement is as before;
#   2. { using => $expr } is the USING of the ALTER, in place of the cast --
#      also for an enum target, whose default is still taken out of the way;
#      it goes before the class-wide hooks;
#   3. the change handed over has the documented form, with the annotations in
#      old_info/new_info, and only a change of the type is asked about;
#   4. { refuse } refuses the diff: all columns, all messages, no statement;
#   5. two extensions that answer with different USING expressions refuse;
#   6. the diff object passes its protocol on, from Deploy::Base's argument.

my $C = 'DBIO::PostgreSQL::Diff::Column';
my $tables = { 'public.t' => { schema_name => 'public', table_name => 't' } };

{
  package T143::Using;
  use base 'DBIO::Extension';
  our @asked;
  sub extension_interface { 1 }
  sub name   { 'using_ext' }
  sub driver { 'DBIO::PostgreSQL' }
  sub verdict {
    my ($class, $change, $ctx) = @_;
    push @asked, $change;
    return undef unless ($change->{new_type} // '') =~ /^geometry/;
    return { using => "ST_Transform($change->{column_name}, 3857)" };
  }
}
{
  package T143::Refuse;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'refuse_ext' }
  sub driver { 'DBIO::PostgreSQL' }
  sub verdict {
    my ($class, $change, $ctx) = @_;
    return undef unless ($change->{old_type} // '') =~ /^geometry/
      && ($change->{new_type} // '') =~ /^geography/;
    return { refuse => "$change->{column_name}: geometry is not converted to geography" };
  }
}
{
  package T143::OtherUsing;
  use base 'DBIO::Extension';
  sub extension_interface { 1 }
  sub name   { 'other_using' }
  sub driver { 'DBIO::PostgreSQL' }
  sub verdict { { using => 'something_else' } }
}

sub protocol {
  my (@classes) = @_;
  return DBIO::Extension::Protocol->new(
    entries => [ map { { name => $_->name, class => $_, options => {}, installed => 1 } } @classes ],
  );
}

sub col {
  my ($name, $type, %extra) = @_;
  return { column_name => $name, data_type => $type, not_null => 0, %extra };
}

# The twelve sections of the columns diff a Diff object hands over.
sub run {
  my ($protocol, $from, $to) = @_;
  return $C->diff(
    { 'public.t' => $from }, { 'public.t' => $to },
    $tables, $tables,
    ({}) x 8,
    $protocol,
  );
}

sub sql { join "\n", map { $_->as_sql } @_ }

# --- 1. no protocol ---------------------------------------------------------
{
  my @ops = run(undef, [ col(v => 'text') ], [ col(v => 'integer') ]);
  is sql(@ops), 'ALTER TABLE public.t ALTER COLUMN v TYPE integer;',
    'without a protocol: no USING, nothing asked';
  ok !defined $ops[0]->using, '... and the operation has no using';
}

# --- 2. using ---------------------------------------------------------------
{
  my @ops = run(protocol('T143::Using'),
    [ col(g => 'geometry(Point,4326)') ], [ col(g => 'geometry(Point,3857)') ]);
  is sql(@ops),
    'ALTER TABLE public.t ALTER COLUMN g TYPE geometry(Point,3857) USING ST_Transform(g, 3857);',
    'a verdict { using }: its expression is the USING of the ALTER';
  is $ops[0]->using, 'ST_Transform(g, 3857)', '... and the operation carries it';

  @ops = run(protocol('T143::Using'), [ col(g => 'text') ], [ col(g => 'text') ]);
  is scalar @ops, 0, 'no change, no operation';

  @ops = run(protocol('T143::Using'), [ col(g => 'text') ], [ col(g => 'integer') ]);
  is sql(@ops), 'ALTER TABLE public.t ALTER COLUMN g TYPE integer;',
    'undef from the extension: the statement stays as the diff writes it';

  # the verdict goes before the class-wide hooks
  $C->register_using_hook(t143 => sub { "$_[0]{column}::via_hook" });
  @ops = run(protocol('T143::Using'),
    [ col(g => 'geometry(Point,4326)') ], [ col(g => 'geometry(Point,3857)') ]);
  like sql(@ops), qr/USING ST_Transform/, 'a verdict goes before the registered hooks';
  @ops = run(protocol('T143::Using'), [ col(g => 'text') ], [ col(g => 'integer') ]);
  like sql(@ops), qr/USING g::via_hook/, '... and the hooks are asked when no extension answers';
  $C->unregister_using_hook('t143');

  # an enum target keeps taking its default out of the way
  my $enum = col(v => 'mood', type_category => 'e', enum_type => 'mood', type_schema => 'public');
  my $old  = col(v => 'text', default_value => "'ok'::text");
  @ops = run(protocol('T143::OtherUsing'), [ $old ], [ $enum ]);
  is sql(@ops), join("\n",
    'ALTER TABLE public.t ALTER COLUMN v DROP DEFAULT;',
    'ALTER TABLE public.t ALTER COLUMN v TYPE mood USING something_else;',
  ), 'an enum target: the USING of the verdict replaces the cast, the default is still dropped';
}

# --- 3. the change ----------------------------------------------------------
{
  @T143::Using::asked = ();
  run(protocol('T143::Using'),
    [ col(g => 'text', srid => 4326, name => 'keep'), col(n => 'integer') ],
    [ col(g => 'integer', srid => 3857, name => 'keep'), col(n => 'integer', not_null => 1) ]);
  is scalar @T143::Using::asked, 1, 'asked for the one change of a type, not for a change of NOT NULL';
  my $change = $T143::Using::asked[0];
  is $change->{kind},        'column_type', 'kind';
  is $change->{table},       'public.t',    'table is the key of the model';
  is $change->{schema_name}, 'public',      'schema_name';
  is $change->{table_name},  't',           'table_name';
  is $change->{column_name}, 'g',           'column_name';
  is $change->{old_info}{srid}, 4326, 'old_info carries the annotations of the model';
  is $change->{new_info}{srid}, 3857, 'new_info too';
  is $change->{old_type}, 'text',    'old_type is the rendered type';
  is $change->{new_type}, 'integer', 'new_type is the rendered type';
}

# --- 4. refuse --------------------------------------------------------------
{
  my $error = do { local $@; eval {
    $C->diff(
      { 'public.t' => [ col(a => 'geometry'), col(b => 'geometry'), col(c => 'text') ] },
      { 'public.t' => [ col(a => 'geography'), col(b => 'geography'), col(c => 'integer') ] },
      $tables, $tables, ({}) x 8, protocol('T143::Refuse'),
    ); 1 } ? '' : "$@" };
  like $error, qr/^refusing to diff: the extensions of the schema refuse/,
    'a verdict { refuse } refuses the diff when it is built';
  like $error, qr/column public\.t\.a: refuse_ext: a: geometry is not converted to geography/,
    '... naming the first column and the extension';
  like $error, qr/column public\.t\.b: refuse_ext: b: geometry is not converted to geography/,
    '... and the second: every message';
  unlike $error, qr/public\.t\.c/, '... not a column nobody refused';
  like $error, qr/No statement was generated/, '... and says that no statement was generated';
}

# --- 5. conflict ------------------------------------------------------------
{
  my $error = do { local $@; eval {
    run(protocol('T143::Using', 'T143::OtherUsing'),
      [ col(g => 'geometry(Point,4326)') ], [ col(g => 'geometry(Point,3857)') ]); 1 } ? '' : "$@" };
  like $error, qr/conflicting answers.*other_using: something_else.*using_ext: ST_Transform/s,
    'two different USING answers refuse, naming both extensions';
}

# --- 6. the diff passes its protocol on --------------------------------------
{
  my $model = sub {
    my ($type) = @_;
    return {
      tables  => { 'public.t' => { schema_name => 'public', table_name => 't', kind => 'r',
                                   depends_on => [], depends_on_columns => {}, inherits => [] } },
      columns => { 'public.t' => [ col(g => $type) ] },
    };
  };
  my $diff = DBIO::PostgreSQL::Diff->new(
    source     => $model->('geometry(Point,4326)'),
    target     => $model->('geometry(Point,3857)'),
    extensions => protocol('T143::Using'),
  );
  like $diff->as_sql, qr/USING ST_Transform\(g, 3857\);/,
    'DBIO::PostgreSQL::Diff hands its extensions to the column diff';

  $diff = DBIO::PostgreSQL::Diff->new(
    source => $model->('geometry(Point,4326)'),
    target => $model->('geometry(Point,3857)'),
  );
  unlike $diff->as_sql, qr/USING/, '... and without them asks nobody';
}

done_testing;
