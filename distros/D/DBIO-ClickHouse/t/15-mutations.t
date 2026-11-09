use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/15-mutations.t — the ClickHouse UPDATE/DELETE path. ClickHouse has neither
# statement: changing stored rows is an asynchronous mutation, spelled
# ALTER TABLE t UPDATE/DELETE, and this file pins that rendering plus the two
# things that follow from it — the mutations_sync policy (ADR 0005) and the
# fact that nothing here can report a row count.
#
# Entirely offline. Three levels, deliberately:
#
#   1. DBIO::ClickHouse::SQLMaker::update/delete poked directly, with
#      is_same_sql_bind — the statement shape and the bind order.
#   2. The same code reached through $rs->update / $rs->delete and through
#      $row->update / $row->delete on a storage whose _execute only records.
#      Only that path proves core actually routes both levels here, that the
#      row level addresses its row by primary key, and — the load-bearing bit —
#      that the -1 return value keeps DBIO::Row::_update_body from throwing.
#   3. connect_info, for the mutations_sync override.
#
# The recording storage subclasses DBIO::ClickHouse::Storage for the same
# reason t/13-insert.t does: DBIO::Test's hybrid storage would sit *ahead* of
# the driver in the mro and shadow the very methods under test.

use DBIO::ClickHouse::Test ':DiffSQL';
use DBIO::ClickHouse::Storage;
use DBIO::ClickHouse::SQLMaker;

# --- a storage that renders but never executes ------------------------------
{
  package MyTest::CH::MutRecorder;
  use strict;
  use warnings;
  use base 'DBIO::ClickHouse::Storage';
  use mro 'c3';

  our @LOG;

  sub new {
    my $self = shift->next::method(@_);
    # Nothing to detect (the concrete driver was instantiated directly), so
    # short-circuit core's determine-driver wrapper and hand the sql_maker the
    # ClickHouse quoting it would otherwise pick up from the connection.
    $self->{_driver_determined} = 1;
    $self->{_sql_maker_opts} = { quote_char => '`', name_sep => '.' };
    return $self;
  }

  sub _execute {
    my ($self, $op, $ident, @args) = @_;
    my ($sql, $bind) = $self->_prep_for_execute($op, $ident, \@args);
    push @LOG, { op => $op, sql => $sql, bind => $bind };
    return 1;
  }

  sub _populate_dbh    { }
  sub connected        { 1 }
  sub _seems_connected { 1 }
}

# --- schema: a single-key table, a composite-key table, a virtual view ------
{
  package My::CH::Mut::Result::Hit;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('hit');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid',    is_nullable => 0 },
    url  => { data_type => 'varchar', size => 2048, is_nullable => 0 },
    hits => { data_type => 'integer', is_nullable => 1 }
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Mut::Result::Daily;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('daily');
  __PACKAGE__->add_columns(
    day   => { data_type => 'date',    is_nullable => 0 },
    url   => { data_type => 'varchar', size => 2048, is_nullable => 0 },
    total => { data_type => 'integer', is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key(qw( day url ));
}
{
  # A virtual view: its from() is literal SQL, which ALTER TABLE cannot name.
  package My::CH::Mut::Result::HotHit;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table_class('DBIO::ResultSource::View');
  __PACKAGE__->table('hot_hit');
  __PACKAGE__->result_source_instance->is_virtual(1);
  __PACKAGE__->result_source_instance->view_definition(
    'SELECT id, url FROM hit WHERE hits > 100'
  );
  __PACKAGE__->add_columns(
    id  => { data_type => 'uuid',    is_nullable => 0 },
    url => { data_type => 'varchar', size => 2048, is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Mut::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Hit    => 'My::CH::Mut::Result::Hit');
  __PACKAGE__->register_class(Daily  => 'My::CH::Mut::Result::Daily');
  __PACKAGE__->register_class(HotHit => 'My::CH::Mut::Result::HotHit');
}

my $schema = My::CH::Mut::Schema->connect(sub { });
$schema->storage(MyTest::CH::MutRecorder->new($schema));

my $sqlmaker = DBIO::ClickHouse::SQLMaker->new(
  bindtype => 'columns', quote_char => '`', name_sep => '.',
);

my $ID    = { dbic_colname => 'id',    sqlt_datatype => 'uuid' };
my $URL   = { dbic_colname => 'url',   sqlt_datatype => 'varchar', sqlt_size => 2048 };
my $HITS  = { dbic_colname => 'hits',  sqlt_datatype => 'integer' };
my $DAY   = { dbic_colname => 'day',   sqlt_datatype => 'date' };
my $TOTAL = { dbic_colname => 'total', sqlt_datatype => 'integer' };

sub recorded {
  my @log = @MyTest::CH::MutRecorder::LOG;
  @MyTest::CH::MutRecorder::LOG = ();
  return @log;
}

#############################################################################
# 1. the rendering contract
#############################################################################

# The whole point: neither statement is DML. An UPDATE becomes an ALTER whose
# assignment list follows UPDATE *without* a SET keyword, a DELETE becomes an
# ALTER whose only clause is the filter.
{
  is_same_sql_bind(
    \[ $sqlmaker->update('hit', { hits => 9 }, { id => 'u1' }) ],
    'ALTER TABLE `hit` UPDATE `hits` = ? WHERE `id` = ? SETTINGS mutations_sync = 1',
    [ [ hits => 9 ], [ id => 'u1' ] ],
    'an UPDATE renders as ALTER TABLE ... UPDATE',
  );

  is_same_sql_bind(
    \[ $sqlmaker->delete('hit', { id => 'u1' }) ],
    'ALTER TABLE `hit` DELETE WHERE `id` = ? SETTINGS mutations_sync = 1',
    [ [ id => 'u1' ] ],
    'a DELETE renders as ALTER TABLE ... DELETE',
  );

  # ClickHouse writes 'ALTER TABLE t UPDATE a = 1', not '... UPDATE SET a = 1'.
  # SQL::Abstract's generic clause renderer would prepend the keyword, so this
  # is the assertion that the update.set renderer is still wired up. (\bSET\b
  # does not match the SETTINGS clause -- the word boundary fails on the T.)
  my ($sql) = $sqlmaker->update('hit', { hits => 9 }, { id => 'u1' });
  unlike $sql, qr/\bSET\b/, 'no SET keyword: the assignment list follows UPDATE directly';
  unlike $sql, qr/\bDELETE\s+FROM\b/, '... and nothing renders as DELETE FROM';
}

# Binds run in statement order: every assignment, then the condition. Getting
# this backwards is invisible in the SQL and would silently write the WHERE
# value into a column.
{
  my (undef, @bind) = $sqlmaker->update(
    'hit', { hits => 9, url => '/new' }, { id => 'u1', hits => 3 }
  );
  is_deeply \@bind,
    [ [ hits => 9 ], [ url => '/new' ], [ hits => 3 ], [ id => 'u1' ] ],
    'SET binds come first, in column order, then the WHERE binds';
}

# The assignment list is rendered by the inherited machinery, so literal SQL
# (the read-modify-write a mutation is actually good at) still works.
{
  is_same_sql_bind(
    \[ $sqlmaker->update('hit', { hits => \'hits + 1' }, { id => 'u1' }) ],
    'ALTER TABLE `hit` UPDATE `hits` = hits + 1 WHERE `id` = ? SETTINGS mutations_sync = 1',
    [ [ id => 'u1' ] ],
    'literal SQL in an assignment is passed through untouched',
  );

  is_same_sql_bind(
    \[ $sqlmaker->update('hit', { hits => \[ 'hits + ?', [ $HITS => 5 ] ] }, { id => 'u1' }) ],
    'ALTER TABLE `hit` UPDATE `hits` = hits + ? WHERE `id` = ? SETTINGS mutations_sync = 1',
    [ [ $HITS => 5 ], [ id => 'u1' ] ],
    '... and literal SQL with its own binds keeps them ahead of the WHERE binds',
  );
}

# A mutation must carry a filter expression -- 'ALTER TABLE t DELETE' is a
# syntax error, not a delete-everything. WHERE 1 is how ClickHouse spells the
# "every row" that an unrestricted DELETE FROM t means elsewhere.
{
  for my $case (
    [ 'undef'                 => undef      ],
    [ 'an empty hashref'      => {}         ],
    [ 'an empty arrayref'     => []         ],
    [ 'empty literal SQL'     => \[ '' ]    ],
  ) {
    my ($what, $where) = @$case;
    is_same_sql_bind(
      \[ $sqlmaker->delete('hit', $where) ],
      'ALTER TABLE `hit` DELETE WHERE 1 SETTINGS mutations_sync = 1',
      [],
      "$what as the condition renders WHERE 1, never a bare ALTER",
    );
  }
}

#############################################################################
# 2. mutations_sync (ADR 0005)
#############################################################################

# Synchronous by default: without this clause the statement returns before the
# rows have changed, and every read-after-write in the ORM is a coin toss.
{
  my ($sql) = $sqlmaker->delete('hit', { id => 'u1' });
  like $sql, qr/SETTINGS mutations_sync = 1\z/,
    'every mutation ends in SETTINGS mutations_sync = 1 by default';

  # ClickHouse setting names are case-sensitive: MUTATIONS_SYNC is not a
  # setting. Only the keyword may go through _sqlcase.
  like $sql, qr/\bmutations_sync\b/,
    '... with the setting name in lower case, as ClickHouse requires';
}

{
  for my $sync (0, 2) {
    my $m = DBIO::ClickHouse::SQLMaker->new(
      bindtype => 'columns', quote_char => '`', mutations_sync => $sync,
    );
    my ($sql) = $m->delete('hit', { id => 'u1' });
    like $sql, qr/SETTINGS mutations_sync = $sync\z/,
      "mutations_sync => $sync is rendered as asked";
  }
}

# undef is the escape hatch for deployments that set the value per session or
# in the server profile: an explicit clause on every statement would override
# theirs, so undef emits none at all.
{
  my $m = DBIO::ClickHouse::SQLMaker->new(
    bindtype => 'columns', quote_char => '`', mutations_sync => undef,
  );

  is_same_sql_bind(
    \[ $m->delete('hit', { id => 'u1' }) ],
    'ALTER TABLE `hit` DELETE WHERE `id` = ?',
    [ [ id => 'u1' ] ],
    'mutations_sync => undef emits no SETTINGS clause at all',
  );

  my ($sql) = $m->update('hit', { hits => 1 }, { id => 'u1' });
  unlike $sql, qr/SETTINGS/, '... for UPDATE either';
}

# A bad value must not reach the server as SQL.
{
  throws_ok {
    DBIO::ClickHouse::SQLMaker->new(bindtype => 'columns', mutations_sync => 3)
  } qr/Invalid mutations_sync value '3'/,
    'an out-of-range mutations_sync throws when the SQL maker is built';

  throws_ok {
    DBIO::ClickHouse::SQLMaker->new(bindtype => 'columns', mutations_sync => 'yes')
  } qr/Invalid mutations_sync value 'yes'/,
    '... and so does a non-numeric one';

  throws_ok {
    DBIO::ClickHouse::SQLMaker->new(bindtype => 'columns', mutations_sync => 3)
  } qr/Pass undef/,
    '... naming the undef escape hatch rather than only the legal numbers';
}

#############################################################################
# 3. resultset level: core really routes update/delete through here
#############################################################################

{
  recorded();
  my $rv = $schema->resultset('Hit')->search({ url => '/a' })->update({ hits => 9 });

  my @log = recorded();
  is scalar(@log), 1, 'a resultset update() issues exactly one statement';
  is $log[0]{op}, 'update', '... through the update op';

  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `hit` UPDATE `hits` = ? WHERE `url` = ? SETTINGS mutations_sync = 1',
    [ [ $HITS => 9 ], [ $URL => '/a' ] ],
    '... as a mutation, with per-column bind attributes',
  );

  is $rv, -1, 'the return value is -1, not a row count';
}

{
  recorded();
  my $rv = $schema->resultset('Hit')->search({ hits => { '<' => 5 } })->delete;

  my @log = recorded();
  is scalar(@log), 1, 'a resultset delete() issues exactly one statement';
  is $log[0]{op}, 'delete', '... through the delete op';

  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `hit` DELETE WHERE `hits` < ? SETTINGS mutations_sync = 1',
    [ [ $HITS => 5 ] ],
    '... as a mutation',
  );

  is $rv, -1, 'the return value is -1 here too';
}

# An unrestricted delete really does mean everything, and must not degenerate
# into a bare ALTER on the way through core.
{
  recorded();
  $schema->resultset('Hit')->delete({ all => 1 });
  my @log = recorded();

  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `hit` DELETE WHERE 1 SETTINGS mutations_sync = 1',
    [],
    'an unrestricted $rs->delete renders WHERE 1',
  );
}

# Anything core cannot express as a flat condition (a limit, a group_by, a
# restricting join) becomes an IN-subquery on the identifying columns. That
# rewrite happens above the storage, so the mutation just has to survive it.
{
  recorded();
  $schema->resultset('Hit')->search({ url => '/a' }, { rows => 3 })->delete;
  my @log = recorded();

  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `hit` DELETE WHERE `id` IN ( '
  . 'SELECT `me`.`id` FROM `hit` `me` WHERE ( `url` = ? ) LIMIT ? '
  . ') SETTINGS mutations_sync = 1',
    [ [ $URL => '/a' ], [ { sqlt_datatype => 'integer' } => 3 ] ],
    'the subquery rewrite core does for a limited resultset still renders as a mutation',
  );
}

#############################################################################
# 4. row level: addressed by primary key
#############################################################################

{
  recorded();
  my $row = $schema->resultset('Hit')->new_result({
    id => 'u1', url => '/a', hits => 1
  });
  $row->in_storage(1);
  $row->update({ hits => 2, url => '/b' });

  my @log = recorded();
  is scalar(@log), 1, 'a row update() issues exactly one statement';

  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `hit` UPDATE `hits` = ?, `url` = ? WHERE `id` = ? '
  . 'SETTINGS mutations_sync = 1',
    [ [ $HITS => 2 ], [ $URL => '/b' ], [ $ID => 'u1' ] ],
    '... addressing the row by its primary key, dirty columns first',
  );
}

{
  recorded();
  my $row = $schema->resultset('Hit')->new_result({ id => 'u1', url => '/a' });
  $row->in_storage(1);
  $row->delete;

  my @log = recorded();
  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `hit` DELETE WHERE `id` = ? SETTINGS mutations_sync = 1',
    [ [ $ID => 'u1' ] ],
    'a row delete() is a mutation filtered on the primary key',
  );

  ok !$row->in_storage, '... and the row knows it is gone';
}

# A composite key must put every one of its columns in the filter -- a mutation
# that matched on a prefix would rewrite rows nobody asked about, and there is
# no transaction to take that back.
{
  recorded();
  my $row = $schema->resultset('Daily')->new_result({
    day => '2026-07-26', url => '/a', total => 1
  });
  $row->in_storage(1);
  $row->update({ total => 7 });

  my @log = recorded();
  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'ALTER TABLE `daily` UPDATE `total` = ? WHERE ( `day` = ? AND `url` = ? ) '
  . 'SETTINGS mutations_sync = 1',
    [ [ $TOTAL => 7 ], [ $DAY => '2026-07-26' ], [ $URL => '/a' ] ],
    'a composite primary key contributes every column to the filter',
  );
}

#############################################################################
# 5. the return value, and why it is -1
#############################################################################

# DBIO::Row::_update_body throws "row not found" on a 0 return and "updated
# more than one row" above 1. ClickHouse reports neither -- a mutation
# acknowledges the ALTER, not the row set -- so the storage returns DBI's
# "count unknown". Returning 0 or '0E0' would make every single row update
# throw; this test is what stops someone from "fixing" it that way.
{
  recorded();
  my $row = $schema->resultset('Hit')->new_result({ id => 'u1', hits => 1 });
  $row->in_storage(1);

  lives_ok { $row->update({ hits => 2 }) }
    'a row update() survives core row-count gate';

  is $schema->storage->update($schema->source('Hit'), { hits => 1 }, { id => 'u1' }),
    -1, 'storage update() returns -1 -- DBI for "number of rows unknown"';
  is $schema->storage->delete($schema->source('Hit'), { id => 'u1' }),
    -1, 'storage delete() returns -1 as well';

  cmp_ok -1, '!=', 0, 'the value clears core\'s "row not found" check';
  cmp_ok -1, '<=', 1, '... and its "updated more than one row" check';
  recorded();
}

#############################################################################
# 6. guardrails: what is refused rather than rendered
#############################################################################

# ALTER TABLE can only name one real table. A virtual view's from() is literal
# SQL, so the statement would reach the server as nonsense.
{
  throws_ok { $schema->resultset('HotHit')->search({ url => '/a' })->delete }
    qr/can only name a single real table/,
    'a mutation against a virtual view throws instead of rendering';

  throws_ok { $schema->resultset('HotHit')->search({ url => '/a' })->delete }
    qr/-in => \$other_rs/,
    '... pointing at the subquery rewrite that does work';

  throws_ok { $schema->resultset('HotHit')->update({ url => '/a' }, { all => 1 }) }
    qr/can only name a single real table/,
    'the same guard covers UPDATE';

  throws_ok { $sqlmaker->delete([ { me => 'hit' }, { url => 'url' } ], { id => 1 }) }
    qr/can only name a single real table/,
    '... and a join list handed straight to the SQL maker';
}

# 'ALTER TABLE t UPDATE WHERE ...' has no valid form.
{
  throws_ok { $schema->resultset('Hit')->search({ url => '/a' })->update({}) }
    qr/needs a non-empty hashref of columns to set/,
    'an UPDATE with nothing to set throws';

  throws_ok { $sqlmaker->update('hit', undef, { id => 1 }) }
    qr/needs a non-empty hashref of columns to set/,
    '... and so does a missing assignment hashref';
}

#############################################################################
# 7. mutations_sync is a connect-time option
#############################################################################

# It has to reach the SQL maker (it is rendered into the statement) and must
# never reach DBI->connect, which would hand a MySQL-wire DBD an attribute it
# has never heard of.
{
  my $storage = MyTest::CH::MutRecorder->new($schema);
  $storage->connect_info([ sub { }, {
    quote_char => '`', name_sep => '.', mutations_sync => 2,
  } ]);

  my ($sql) = $storage->sql_maker->delete('hit', { id => 'u1' });
  like $sql, qr/SETTINGS mutations_sync = 2\z/,
    'connect_info { mutations_sync => 2 } reaches the SQL maker';

  ok !exists $storage->_dbio_connect_attributes->{mutations_sync},
    '... and is stripped from the attributes handed to DBI->connect';

  ok scalar(grep { $_ eq 'mutations_sync' } $storage->_dbio_sql_maker_option_names),
    'the storage advertises mutations_sync as a SQL-maker option';
}

{
  my $storage = MyTest::CH::MutRecorder->new($schema);
  $storage->connect_info([ sub { }, {
    quote_char => '`', name_sep => '.', mutations_sync => undef,
  } ]);

  my ($sql) = $storage->sql_maker->delete('hit', { id => 'u1' });
  unlike $sql, qr/SETTINGS/,
    'an explicit undef survives connect_info and suppresses the clause';
}

done_testing;
