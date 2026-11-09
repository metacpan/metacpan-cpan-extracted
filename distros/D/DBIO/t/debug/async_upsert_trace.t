use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;
use DBIO::Future::Immediate;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::Statistics;

# Every rendering of a statement gets its own copy of the options (karr k405).
# A driver SQL maker consumes on_conflict (and insert_or) from the options it
# receives, so the statement on the wire and the rendering that resolves the
# bind attributes of a level 2 trace each see the complete options: the
# attribute list lines up with the binds, an encode_column value is masked, the
# redact_bind_value hook sees the column name, and the options of the caller
# keep what they were given.

{
  package T405::SQLMaker;
  use base 'DBIO::SQLMaker';
  use mro 'c3';

  # the shape of the driver makers: consume the keys, append a conflict tail
  # with a bind of its own
  sub insert {
    my ($self, $table, $data, $options) = @_;
    my $or          = ref $options eq 'HASH' ? delete $options->{insert_or}   : undef;
    my $on_conflict = ref $options eq 'HASH' ? delete $options->{on_conflict} : undef;

    my ($sql, @bind) = $self->next::method($table, $data, $options);
    $sql =~ s/^INSERT/INSERT OR $or/ if defined $or;
    if ($on_conflict) {
      $sql .= ' ON CONFLICT (id) DO UPDATE SET name = ?';
      push @bind, $self->{bindtype} eq 'columns'
        ? [ { dbic_colname => 'name' } => 'tail-value' ]
        : 'tail-value';
    }
    return ($sql, @bind);
  }

  # update and delete: a key of the options is consumed
  sub update {
    my ($self, $table, $set, $where, $options) = @_;
    delete $options->{marker} if ref $options eq 'HASH';
    return $self->next::method($table, $set, $where);
  }

  sub delete {
    my ($self, $table, $where, $options) = @_;
    delete $options->{marker} if ref $options eq 'HASH';
    return $self->next::method($table, $where);
  }
}

{
  package T405::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 64, is_nullable => 1 },
    password => { data_type => 'varchar', size => 255, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T405::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(User => 'T405::Schema::Result::User');
}

{
  package T405::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Future::Immediate' }
  sub sql_maker_class  { 'T405::SQLMaker' }
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

T405::Schema->storage_type('+DBIO::Test::Storage');
my $schema = T405::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $owner = $schema->storage;

my $out = '';
open my $fh, '>', \$out or die;
my $stats = DBIO::Storage::Statistics->new;
$stats->debugfh($fh);
$owner->debugobj($stats);

my @hook_calls;
my $default_hook = $owner->redact_bind_value;
$owner->redact_bind_value(sub {
  my ($name, $value, $attrs) = @_;
  push @hook_calls, $name;
  return $default_hook->($name, $value, $attrs);
});

my $backend = T405::Backend->new($schema);
$backend->_owner_storage($owner);
$owner->_async_context_owner_token($backend->_context_owner_token);

my $source = $schema->source('User');

sub run_crud {
  my ($op, @args) = @_;
  $backend->{debug} = 2;
  $backend->{seen}  = [];
  $out = '';
  @hook_calls = ();
  $backend->_run_crud($op, $backend->_pool_runner, @args);
  return $backend->{seen}[0];
}

for my $case (
  [ 'on_conflict'             => { on_conflict => { target => 'id' } } ],
  [ 'on_conflict + insert_or' => { on_conflict => { target => 'id' }, insert_or => 'IGNORE' } ],
  [ 'insert_or'               => { insert_or => 'REPLACE' } ],
) {
  my ($label, $opts) = @$case;
  my %given = %$opts;
  my $seen = run_crud(insert => $source, { name => 'alice', password => 'hunter2-secret' }, $opts);

  ok ref $seen->{attrs} eq 'ARRAY', "$label: the bind attributes are resolved";
  is scalar(@{ $seen->{attrs} || [] }), scalar(@{ $seen->{bind} }),
    "$label: one attribute per wire bind";
  unlike $out, qr/hunter2/, "$label: the encode_column value is not traced";
  like $out, qr/'\*\*\*'/, "$label: the encode_column value is traced as ***";
  ok scalar(grep { defined $_ && $_ eq 'password' } @hook_calls),
    "$label: the redact_bind_value hook sees the column name";
  is_deeply $opts, \%given, "$label: the options of the caller are as given";
  like $seen->{sql}, qr/^INSERT OR /, "$label: the wire statement carries insert_or"
    if exists $given{insert_or};
  like $seen->{sql}, qr/ON CONFLICT/, "$label: the wire statement carries the conflict tail"
    if exists $given{on_conflict};
}

# update and delete leave the options of the caller as given.
{
  my $opts = { marker => 1 };
  my $seen = run_crud(update => $source, { name => 'b' }, { id => 1 }, $opts);
  is_deeply $opts, { marker => 1 }, 'update: the options of the caller are as given';
  is scalar(@{ $seen->{attrs} || [] }), scalar(@{ $seen->{bind} }), 'update: attributes line up';

  $opts = { marker => 1 };
  $seen = run_crud(delete => $source, { id => 1 }, $opts);
  is_deeply $opts, { marker => 1 }, 'delete: the options of the caller are as given';
  is scalar(@{ $seen->{attrs} || [] }), scalar(@{ $seen->{bind} }), 'delete: attributes line up';
}

done_testing;
