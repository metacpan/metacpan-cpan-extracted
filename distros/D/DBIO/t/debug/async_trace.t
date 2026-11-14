use strict;
use warnings;

use Test::More;

use DBIO::Test::Storage;
use DBIO::SQLMaker;
use DBIO::Future::Immediate;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::Statistics;

# The async path carries the one trace rule of the sync path (ADR 0025,
# karr k402): level 1 is the statement, level 2 adds the binds through the
# owner's redact_bind_value with column name and bind attributes, cut to 32
# characters, undef as NULL. The statements core builds hand the seam the bind
# attributes as a second list; the wire binds stay bare values (karr k342).

{
  package T402::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('users');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 64, is_nullable => 1 },
    password => { data_type => 'varchar', size => 255, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package T402::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(User => 'T402::Schema::Result::User');
}

{
  package T402::Stats;
  our @ISA = ('DBIO::Storage::Statistics');
  our (@started, @ended);
  sub query_start { my $s = shift; push @started, [@_]; $s->SUPER::query_start(@_) }
  sub query_end   { my $s = shift; push @ended,   [@_]; $s->SUPER::query_end(@_) }
}

{
  package T402::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Future::Immediate' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub _query_async {
    my ($self, $sql, $bind, $attrs) = @_;
    push @{ $self->{seen} }, { sql => $sql, bind => $bind, attrs => $attrs, argc => scalar(@_) };
    $self->{ended} = $self->_debug_query($sql, $bind, $attrs);
    return $self->future_class->done(1);
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind, $attrs) = @_;
    push @{ $self->{seen} }, { sql => $sql, bind => $bind, attrs => $attrs, pinned => 1 };
    $self->_debug_query($sql, $bind, $attrs);
    return $self->future_class->done(1);
  }
}

T402::Schema->storage_type('+DBIO::Test::Storage');
my $schema = T402::Schema->connect(sub { });
$schema->storage(DBIO::Test::Storage->new($schema));
my $owner = $schema->storage;

my $out = '';
open my $fh, '>', \$out or die;
my $stats = T402::Stats->new;
$stats->debugfh($fh);
$owner->debugobj($stats);

my $backend = T402::Backend->new($schema);
$backend->_owner_storage($owner);
$owner->_async_context_owner_token($backend->_context_owner_token);
$backend->{seen} = [];

my $source = $schema->source('User');

sub run_crud {
  my ($level, $op, @args) = @_;
  $backend->{debug} = $level;
  $backend->{seen}  = [];
  $out = '';
  @T402::Stats::started = @T402::Stats::ended = ();
  $backend->_run_crud($op, $backend->_pool_runner, @args);
  return $backend->{seen}[0];
}

# Level 2, encode_column: the bind shows as ***, the other as it is.
{
  my $seen = run_crud(2, 'insert', $source, { name => 'alice', password => 'hunter2-secret' });
  like $out, qr/'alice'/, 'level 2: a plain column value is traced';
  like $out, qr/'\*\*\*'/, 'level 2: the bind of an encode_column column is traced as ***';
  unlike $out, qr/hunter2/, 'level 2: the encoded column value is not traced';
  is_deeply $seen->{bind}, [ 'alice', 'hunter2-secret' ],
    'the wire binds are bare values';
  is_deeply [ map { $_->{dbic_colname} } @{ $seen->{attrs} } ], [ 'name', 'password' ],
    'the attributes are a second list parallel to the binds, naming the columns';
  ok $seen->{attrs}[1]{redact}, 'the attribute of an encoded column carries redact';
  is $seen->{attrs}[0]{sqlt_datatype}, 'varchar', 'the attribute carries the data type';
  ok !(grep { exists $_->{value} } @{ $seen->{attrs} }), 'the attributes carry no value';
  is scalar(@{ $seen->{bind} }), scalar(@{ $seen->{attrs} }), 'one attribute per bind';
}

# select, update and delete resolve attributes too.
{
  my $ra = $schema->resultset('User')->search({ 'me.name' => 'bob' })->_resolved_attrs;
  my $seen = run_crud(2, 'select', $ra->{from}, $ra->{select}, $ra->{where}, $ra);
  is_deeply $seen->{bind}, [ 'bob' ], 'select: bare wire bind';
  like $seen->{attrs}[0]{dbic_colname}, qr/name$/, 'select: the where bind names its column';
  is $seen->{attrs}[0]{sqlt_datatype}, 'varchar', 'select: the attribute carries the data type';

  my $pa = $schema->resultset('User')->search({ 'me.password' => 'pw-secret' })->_resolved_attrs;
  run_crud(2, 'select', $pa->{from}, $pa->{select}, $pa->{where}, $pa);
  unlike $out, qr/pw-secret/, 'select: an encode_column bind is not traced';
  like $out, qr/'\*\*\*'/, 'select: it is traced as ***';

  $seen = run_crud(2, 'update', $source, { password => 'new-secret' }, { id => 5 });
  is_deeply $seen->{bind}, [ 'new-secret', 5 ], 'update: bare wire binds';
  is_deeply [ map { $_->{dbic_colname} } @{ $seen->{attrs} } ], [ 'password', 'id' ],
    'update: set and where binds name their columns';
  unlike $out, qr/new-secret/, 'update: the encoded value is not traced';

  $seen = run_crud(2, 'delete', $source, { name => 'bob' });
  is $seen->{attrs}[0]{dbic_colname}, 'name', 'delete: the where bind names its column';

  my $sa = $schema->resultset('User')->search({ 'me.id' => 1 })->_resolved_attrs;
  $seen = run_crud(2, 'select_single', $sa->{from}, $sa->{select}, $sa->{where}, $sa);
  like $seen->{attrs}[0]{dbic_colname}, qr/id$/, 'select_single: the where bind names its column';
}

# A pinned statement is the same builder.
{
  $backend->{debug} = 2;
  $backend->{seen}  = [];
  $backend->_run_crud_pinned('delete', 'CONN', $source, { name => 'bob' });
  is $backend->{seen}[0]{attrs}[0]{dbic_colname}, 'name', 'pinned runner passes the attributes';
}

# Level 1: the statement alone; no attributes are resolved.
{
  my $seen = run_crud(1, 'insert', $source, { name => 'alice', password => 'hunter2-secret' });
  like $out, qr/INSERT INTO/, 'level 1: the statement is traced';
  unlike $out, qr/alice|hunter2|\*\*\*/, 'level 1: no bind';
  is_deeply \@T402::Stats::started, [[ $seen->{sql}, '' ]],
    'level 1: the statistics object gets one empty element';
  is_deeply \@T402::Stats::ended, [], 'level 1: no end until the returned coderef runs';
  is ref $backend->{ended}, 'CODE', 'level 1: the call returns a coderef for query_end';
  $backend->{ended}->();
  is_deeply \@T402::Stats::ended, [[ $seen->{sql} ]], 'the coderef calls query_end with the statement';
  is_deeply $seen->{bind}, [ 'alice', 'hunter2-secret' ], 'level 1: wire binds are bare';
}

# Level 0: nothing, no coderef.
{
  run_crud(0, 'delete', $source, { name => 'bob' });
  is $out, '', 'level 0: nothing traced';
  is $backend->{ended}, undef, 'level 0: no coderef';
  is $backend->{seen}[0]{attrs}, undef, 'level 0: no attributes resolved';
}

# A hook of the owner sees the column name and the attribute hash.
{
  my $old = DBIO::Storage::DBI->redact_bind_value;
  my @asked;
  DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
  run_crud(2, 'delete', $source, { name => 'bob' });
  DBIO::Storage::DBI->redact_bind_value($old);
  is scalar(@asked), 1, 'the hook is asked once per bind';
  is $asked[0][0], 'name', 'the hook sees the column name';
  is $asked[0][1], 'bob', 'the hook sees the value';
  is ref $asked[0][2], 'HASH', 'the hook sees the attribute hash';
  is $asked[0][2]{dbic_colname}, 'name', 'the attribute hash names the column';
}

# A raw statement has no attributes: the hook gets undef for name and attributes.
{
  my $old = DBIO::Storage::DBI->redact_bind_value;
  my @asked;
  DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
  $backend->{debug} = 2;
  $out = '';
  $backend->_query_async('SELECT ?', ['raw-value']);
  DBIO::Storage::DBI->redact_bind_value($old);
  is_deeply \@asked, [[ undef, 'raw-value', undef ]],
    'a raw statement: the hook gets undef for name and attributes';
  like $out, qr/'raw-value'/, 'a raw statement: the bind is traced';
}

# Cap at 32 characters, '...' at the cut, NULL for undef.
{
  my $long = 'x' x 40;
  $backend->{debug} = 2;
  $out = '';
  @T402::Stats::started = ();
  $backend->_query_async('SELECT ?, ?, ?', [ $long, undef, 'y' x 32 ]);
  is_deeply \@T402::Stats::started,
    [[ 'SELECT ?, ?, ?', "'" . ('x' x 32) . "...'", 'NULL', "'" . ('y' x 32) . "'" ]],
    'binds cut at 32 characters with ..., undef as NULL, exactly 32 left alone';
}

# Without an owner the class-level hook of DBIO::Storage::DBI is used.
{
  my $lone = T402::Backend->new(undef);
  $lone->{debug} = 2;
  my $lonestats = T402::Stats->new;
  my $o = '';
  open my $lfh, '>', \$o or die;
  $lonestats->debugfh($lfh);
  $lone->debugobj($lonestats);
  @T402::Stats::started = ();
  $lone->_debug_query('SELECT ?', ['v'], undef);
  is_deeply \@T402::Stats::started, [[ 'SELECT ?', "'v'" ]], 'without an owner: own debugobj, class hook';
}

done_testing;
