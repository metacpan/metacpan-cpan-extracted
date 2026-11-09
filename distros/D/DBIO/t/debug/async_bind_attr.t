use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::Future::Immediate;
use DBIO::Storage::Async;

# The async select carries the bind attribute like the sync path
# (_gen_sql_bind): the values of attrs->{bind} (placeholders in a literal
# from, select or where) go in front of the binds of the SQL maker. The bind
# attributes of a level 2 trace cover the same positions, so the count always
# matches (karr k404).

{
  package T404::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 64, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T404::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(User => 'T404::Schema::Result::User');
}

{
  # a driver SQL maker consumes on_conflict from the options it receives and
  # appends a conflict tail with a bind of its own (ADR 0036)
  package T404::SQLMaker;
  use base 'DBIO::SQLMaker';
  use mro 'c3';

  sub insert {
    my ($self, $table, $data, $options) = @_;
    my $on_conflict = ref $options eq 'HASH' ? delete $options->{on_conflict} : undef;
    my ($sql, @bind) = $self->next::method($table, $data, $options);
    if ($on_conflict) {
      $sql .= ' ON CONFLICT (id) DO UPDATE SET name = ?';
      push @bind, $self->{bindtype} eq 'columns'
        ? [ { dbic_colname => 'name' } => 'tail-value' ]
        : 'tail-value';
    }
    return ($sql, @bind);
  }
}

{
  package T404::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Future::Immediate' }
  sub sql_maker_class  { 'T404::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub _query_async {
    my ($self, $sql, $bind, $attrs) = @_;
    push @{ $self->{seen} }, { sql => $sql, bind => $bind, attrs => $attrs };
    $self->_debug_query($sql, $bind, $attrs);
    return $self->future_class->done(1);
  }
}

T404::Schema->storage_type('+DBIO::Test::Storage');
my $schema = T404::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $owner = $schema->storage;

my $backend = T404::Backend->new($schema);
$backend->_owner_storage($owner);
$owner->_async_context_owner_token($backend->_context_owner_token);

open my $fh, '>', \my $out or die;
$owner->debugfh($fh);

sub run_crud {
  my ($op, @args) = @_;
  $backend->{debug} = 2;
  $backend->{seen}  = [];
  $backend->_run_crud($op, $backend->_pool_runner, @args);
  return $backend->{seen}[0];
}

my $source = $schema->source('User');
my $ra = $schema->resultset('User')->search(
  { 'me.id' => 5, -and => [ \'me.name = ?' ] },
  { bind => [ 'zed' ] },
)->_resolved_attrs;

for my $op (qw(select select_single)) {
  my $seen = run_crud($op, $ra->{from}, $ra->{select}, $ra->{where}, $ra);
  is_deeply $seen->{bind}, [ 'zed', 5 ],
    "$op: the values of the bind attribute stand in front of the select binds";
  is scalar(@{ $seen->{attrs} || [] }), 2,
    "$op: one bind attribute per wire bind";
}

# A literal from carries its placeholders first as well, and a bind given as
# a pair is a bare value on the wire.
{
  my $ra = $schema->resultset('User')->search(
    { 'me.id' => 5 },
    { bind => [ [ { sqlt_datatype => 'varchar' } => 'zed' ], 'two' ],
      from => [ { me => \'(SELECT * FROM users WHERE name = ? OR name = ?)' } ] },
  )->_resolved_attrs;
  my $seen = run_crud('select', $ra->{from}, $ra->{select}, $ra->{where}, $ra);
  is_deeply $seen->{bind}, [ 'zed', 'two', 5 ], 'literal from: pair unwrapped, order kept';
  is scalar(@{ $seen->{attrs} || [] }), 3, 'literal from: attribute count matches';
}

# Without a bind attribute nothing changes.
{
  my $pa = $schema->resultset('User')->search({ 'me.id' => 5 })->_resolved_attrs;
  my $seen = run_crud('select', $pa->{from}, $pa->{select}, $pa->{where}, $pa);
  is_deeply $seen->{bind}, [ 5 ], 'no bind attribute: only the select binds';
}

# The count of attributes and binds matches for every statement.
for my $case (
  [ insert => $source, { name => 'a' } ],
  [ insert => $source, { name => 'a' }, { on_conflict => { target => 'id' } } ],
  [ update => $source, { name => 'b' }, { id => 1 } ],
  [ delete => $source, { id => 1, name => 'c' } ],
) {
  my ($op, @args) = @$case;
  my $seen = run_crud($op, @args);
  ok ref $seen->{attrs} eq 'ARRAY', "$op: attributes resolved at level 2";
  is scalar(@{ $seen->{attrs} }), scalar(@{ $seen->{bind} }), "$op: attribute count equals bind count";
}

done_testing;
