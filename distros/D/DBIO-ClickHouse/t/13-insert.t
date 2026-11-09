use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/13-insert.t — the ClickHouse insert path: the multi-row INSERT that
# populate() collapses into, and the primary-key semantics of a database with
# no auto-increment, no last_insert_id and no RETURNING.
#
# Entirely offline. Two levels, deliberately:
#
#   1. DBIO::ClickHouse::SQLMaker::insert_multi poked directly, with
#      is_same_sql_bind — the rendering contract (one statement, N value
#      tuples, binds in statement order) and the shapes it refuses.
#   2. The same code reached through $rs->populate / $rs->create on a storage
#      whose _execute only records. Only that path proves core actually routes
#      a bulk insert into our _insert_bulk, and that $row->id afterwards is the
#      UUID this process generated rather than something read back.
#
# The recording storage subclasses DBIO::ClickHouse::Storage rather than using
# DBIO::Test::Storage: core's fake storage brings its own _insert_bulk and
# last_insert_id, and DBIO::Test's hybrid puts it *ahead* of the driver in the
# mro — which would shadow exactly the two methods under test here.

use DBIO::ClickHouse::Test ':DiffSQL';
use DBIO::ClickHouse::Storage;
use DBIO::ClickHouse::SQLMaker;
use DBIO::ClickHouse::DDL;

# --- a storage that renders but never executes ------------------------------
{
  package MyTest::CH::Recorder;
  use strict;
  use warnings;
  use base 'DBIO::ClickHouse::Storage';
  use mro 'c3';

  our @LOG;

  sub new {
    my $self = shift->next::method(@_);
    # Nothing to detect (the concrete driver was instantiated directly) and
    # nothing to detect it from, so short-circuit core's determine-driver
    # wrapper and hand the sql_maker the ClickHouse quoting it would otherwise
    # pick up from the connection.
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

# --- schema: one UUID-keyed source, one integer-keyed source ----------------
{
  package My::CH::Insert::Result::Hit;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('hit');
  __PACKAGE__->add_columns(
    id   => { data_type => 'uuid',    is_auto_increment => 1, is_nullable => 0 },
    url  => { data_type => 'varchar', size => 2048, is_nullable => 0 },
    hits => { data_type => 'integer', is_nullable => 1 }
  );
  __PACKAGE__->set_primary_key('id');
}
{
  # is_auto_increment on a non-UUID type: the DDL layer refuses it (there is no
  # server-side generator to call; the recorder skips the DDL), so an unset key cannot be recovered.
  package My::CH::Insert::Result::Counter;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('counter');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1, is_nullable => 0 },
    n  => { data_type => 'integer', is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Insert::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Hit     => 'My::CH::Insert::Result::Hit');
  __PACKAGE__->register_class(Counter => 'My::CH::Insert::Result::Counter');
}

my $schema = My::CH::Insert::Schema->connect(sub { });
$schema->storage(MyTest::CH::Recorder->new($schema));

my $sqlmaker = DBIO::ClickHouse::SQLMaker->new(
  bindtype => 'columns', quote_char => '`', name_sep => '.',
);

my $UUID_RE = qr/\A[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}\z/;

my $ID   = { dbic_colname => 'id',   sqlt_datatype => 'uuid' };
my $URL  = { dbic_colname => 'url',  sqlt_datatype => 'varchar', sqlt_size => 2048 };
my $HITS = { dbic_colname => 'hits', sqlt_datatype => 'integer' };

sub recorded {
  my @log = @MyTest::CH::Recorder::LOG;
  @MyTest::CH::Recorder::LOG = ();
  return @log;
}

#############################################################################
# 1. insert_multi: the rendering contract
#############################################################################

# The whole point: N rows are ONE statement with N value tuples, not one
# statement executed N times. On a MergeTree table the difference is N parts
# versus one.
{
  is_same_sql_bind(
    \[ $sqlmaker->insert_multi('hit', [qw( id url )], [
      [ 'u1', '/a' ],
      [ 'u2', '/b' ],
      [ 'u3', '/c' ]
    ]) ],
    'INSERT INTO `hit` (`id`, `url`) VALUES (?, ?), (?, ?), (?, ?)',
    [ [ id => 'u1' ], [ url => '/a' ],
      [ id => 'u2' ], [ url => '/b' ],
      [ id => 'u3' ], [ url => '/c' ] ],
    'three rows render as one statement with three value tuples',
  );

  my ($sql) = $sqlmaker->insert_multi('hit', [qw( id url )], [ ['u1','/a'], ['u2','/b'] ]);
  is scalar(() = $sql =~ /\bINSERT\b/gi), 1, 'exactly one INSERT keyword';
  is scalar(() = $sql =~ /\bVALUES\b/gi), 1, '... and exactly one VALUES clause';
}

# Binds are row-major and in placeholder order: the storage hands the flat list
# straight to execute(), so a per-column grouping would bind the wrong values.
{
  my (undef, @bind) = $sqlmaker->insert_multi('hit', [qw( id url hits )], [
    [ 'u1', '/a', 1 ],
    [ 'u2', '/b', 2 ]
  ]);
  is_deeply \@bind,
    [ [ id => 'u1' ], [ url => '/a' ], [ hits => 1 ],
      [ id => 'u2' ], [ url => '/b' ], [ hits => 2 ] ],
    'binds run row by row, left to right, tagged with their column name';
}

# One row is not a special case.
{
  is_same_sql_bind(
    \[ $sqlmaker->insert_multi('hit', [qw( id url )], [ [ 'u1', '/a' ] ]) ],
    'INSERT INTO `hit` (`id`, `url`) VALUES (?, ?)',
    [ [ id => 'u1' ], [ url => '/a' ] ],
    'a single-row dataset renders as an ordinary one-tuple INSERT',
  );
}

# undef is a bind, not a rendered NULL: the DBD decides how to send it, and the
# column still gets its bind attributes.
{
  is_same_sql_bind(
    \[ $sqlmaker->insert_multi('hit', [qw( id hits )], [ [ 'u1', undef ], [ 'u2', 7 ] ]) ],
    'INSERT INTO `hit` (`id`, `hits`) VALUES (?, ?), (?, ?)',
    [ [ id => 'u1' ], [ hits => undef ], [ id => 'u2' ], [ hits => 7 ] ],
    'an undef value stays a placeholder',
  );
}

# Because every row is rendered on its own -- unlike core's single prepared
# statement -- rows may differ in which cells are literal SQL. This is the
# capability that makes generateUUIDv4() usable per row.
{
  is_same_sql_bind(
    \[ $sqlmaker->insert_multi('hit', [qw( id url )], [
      [ \'generateUUIDv4()', '/a' ],
      [ 'u2',                '/b' ]
    ]) ],
    'INSERT INTO `hit` (`id`, `url`) VALUES (generateUUIDv4(), ?), (?, ?)',
    [ [ url => '/a' ], [ id => 'u2' ], [ url => '/b' ] ],
    'literal SQL in one row and a plain value in the next both render',
  );

  is_same_sql_bind(
    \[ $sqlmaker->insert_multi('hit', [qw( id hits )], [
      [ 'u1', \[ 'toUInt32(?)', [ $HITS => 1 ] ] ],
      [ 'u2', \[ 'toUInt32(?)', [ $HITS => 2 ] ] ]
    ]) ],
    'INSERT INTO `hit` (`id`, `hits`) VALUES (?, toUInt32(?)), (?, toUInt32(?))',
    [ [ id => 'u1' ], [ $HITS => 1 ], [ id => 'u2' ], [ $HITS => 2 ] ],
    'literal SQL with its own binds keeps them in statement position',
  );
}

#############################################################################
# 2. insert_multi: the shapes it refuses
#############################################################################

# One statement means one column list. A short or long row cannot be rendered
# into it, and padding it silently would write wrong data into real columns.
{
  throws_ok {
    $sqlmaker->insert_multi('hit', [qw( id url )], [ ['u1','/a'], ['u2'] ])
  } qr/row 1 has 1 value\(s\) but there are 2 columns \(id, url\)/,
    'a short row throws, naming the row index and the column list';

  throws_ok {
    $sqlmaker->insert_multi('hit', [qw( id url )], [ ['u1','/a','x'] ])
  } qr/row 0 has 3 value\(s\) but there are 2 columns/,
    'a long row throws too';

  throws_ok {
    $sqlmaker->insert_multi('hit', [qw( id url )], [ { id => 'u1' } ])
  } qr/row 0 is not an arrayref/,
    'rows are positional: a hashref row throws';

  throws_ok { $sqlmaker->insert_multi('hit', [], [ [] ]) }
    qr/non-empty arrayref of column names/,
    'no columns throws';

  throws_ok { $sqlmaker->insert_multi('hit', [qw( id )], []) }
    qr/non-empty arrayref of rows/,
    'no rows throws';

  throws_ok { $sqlmaker->insert_multi('hit', [qw( id )], 'nope') }
    qr/non-empty arrayref of rows/,
    'a non-arrayref dataset throws';
}

# ClickHouse has real Array(T) columns, so reaching for a Perl arrayref is a
# likely mistake rather than an exotic one -- and no MySQL-wire DBD can bind a
# list. Say what to write instead rather than letting the DBD complain.
{
  throws_ok {
    $sqlmaker->insert_multi('hit', [qw( id tags )], [ [ 'u1', [qw( a b )] ] ])
  } qr/column 'tags' was given a plain arrayref/,
    'a bare arrayref value throws, naming the column';

  throws_ok {
    $sqlmaker->insert_multi('hit', [qw( id tags )], [ [ 'u1', [qw( a b )] ] ])
  } qr/literal SQL with binds/,
    '... and points at the literal-SQL form that does work';
}

#############################################################################
# 3. populate() really goes through _insert_bulk, as one statement
#############################################################################

{
  recorded();
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, $_[0] };
    $schema->resultset('Hit')->populate([
      { id => 'u1', url => '/a', hits => 1 },
      { id => 'u2', url => '/b', hits => 2 }
    ]);
  }

  my @log = recorded();
  is scalar(@log), 1, 'a void-context populate() issues exactly one statement';
  is $log[0]{op}, 'insert_multi', '... rendered through insert_multi';

  # populate() sorts the column names it collects from the row hashes.
  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'INSERT INTO `hit` (`hits`, `id`, `url`) VALUES (?, ?, ?), (?, ?, ?)',
    [ [ $HITS => 1 ], [ $ID => 'u1' ], [ $URL => '/a' ],
      [ $HITS => 2 ], [ $ID => 'u2' ], [ $URL => '/b' ] ],
    '... with every row in one VALUES list and per-column bind attributes',
  );

  # The guard core wraps its per-row loop in is gone with the loop: one
  # statement has nothing to be made atomic across, so nothing here can trip
  # the no-transactions warning or the txn_rollback refusal.
  is scalar(@warnings), 0,
    'a bulk insert raises no transaction warning -- it takes no scope guard';
}

# A row that omits a column still fills the shared column list, with undef.
{
  recorded();
  $schema->resultset('Hit')->populate([
    { id => 'u1', url => '/a', hits => 1 },
    { id => 'u2', url => '/b' }
  ]);

  my @log = recorded();
  is scalar(@log), 1, 'a ragged dataset is still one statement';
  is_same_sql_bind(
    \[ $log[0]{sql}, @{ $log[0]{bind} } ],
    'INSERT INTO `hit` (`hits`, `id`, `url`) VALUES (?, ?, ?), (?, ?, ?)',
    [ [ $HITS => 1 ],     [ $ID => 'u1' ], [ $URL => '/a' ],
      [ $HITS => undef ], [ $ID => 'u2' ], [ $URL => '/b' ] ],
    '... the missing cell binds as undef rather than shortening the tuple',
  );
}

# _insert_bulk with nothing to insert is a caller bug, not an empty statement.
{
  throws_ok {
    $schema->storage->_insert_bulk(
      $schema->source('Hit'), [qw( id url )], []
    )
  } qr/without a dataset to process/,
    '_insert_bulk throws on an empty dataset';
}

#############################################################################
# 4. primary key semantics: what you get back is what was sent
#############################################################################

# A UUID auto-increment column is generated client-side and *sent*, so the row
# in the table and the row object agree without any retrieval.
{
  recorded();
  my $row = $schema->resultset('Hit')->create({ url => '/x' });

  like $row->id, $UUID_RE, 'create() on a UUID key returns a v4 UUID';

  my @log = recorded();
  is scalar(@log), 1, '... written with a single INSERT';
  is $log[0]{op}, 'insert', '... the ordinary single-row insert';

  my ($id_bind) = grep { $_->[0]{dbic_colname} eq 'id' } @{ $log[0]{bind} };
  ok $id_bind, 'the id was part of the INSERT, not left to a server default';
  is $id_bind->[1], $row->id,
    'the value bound into the statement is exactly what $row->id returns';

  # No follow-up SELECT, no last_insert_id: one round-trip, and nothing that
  # could disagree with what was written.
  is scalar(grep { $_->{op} ne 'insert' } @log), 0,
    'no identity is read back afterwards';
}

# Two inserts do not share an id.
{
  recorded();
  my $a = $schema->resultset('Hit')->create({ url => '/a' });
  my $b = $schema->resultset('Hit')->create({ url => '/b' });
  recorded();
  isnt $a->id, $b->id, 'each insert generates its own UUID';
}

# An explicitly supplied key always wins.
{
  recorded();
  my $row = $schema->resultset('Hit')->create({
    id => '11111111-2222-4333-8444-555555555555', url => '/x'
  });
  recorded();
  is $row->id, '11111111-2222-4333-8444-555555555555',
    'a supplied UUID is not replaced by a generated one';
}

# A literal-SQL key asks the *server* to compute the value, which is precisely
# what this driver cannot read back. create() promises a usable row object, so
# it throws rather than handing back the unevaluated literal ref. The statement
# itself is emitted first -- there is no transaction, so the row is written.
{
  recorded();
  my $row = eval {
    $schema->resultset('Hit')->create({ id => \'generateUUIDv7()', url => '/x' })
  };
  my $err = $@;
  my @log = recorded();

  like $log[0]{sql}, qr/generateUUIDv7\(\)/,
    'a literal id is passed through to the server untouched';
  ok !defined $row, '... but create() cannot return a row object for it';
  like $err, qr/computed by the server/,
    '... it throws, naming a server-computed key as the unreadable case';
  like $err, qr/populate/,
    '... and points at populate(), which never needs the key back';
}

# undef counts as "not supplied", the same reading core applies in insert().
{
  recorded();
  my $row = $schema->resultset('Hit')->create({ id => undef, url => '/x' });
  recorded();
  like $row->id, $UUID_RE, 'an explicit undef key is filled in, not sent as NULL';
}

#############################################################################
# 5. the case that cannot be honest: a non-UUID key left unset
#############################################################################

{
  recorded();
  my $row = eval { $schema->resultset('Counter')->create({ n => 5 }) };
  my $err = $@;
  recorded();

  ok !defined $row, 'create() without an integer key produces no row object';
  isa_ok $err, 'DBIO::Exception';

  like $err, qr/no auto-increment and no last_insert_id/,
    'the exception says what the database cannot do';
  like $err, qr/\bCounter\b/,     '... names the result source';
  like $err, qr/column 'id'/,     '... and the column';
  like $err, qr/the row itself was written/,
    '... and warns that the INSERT is not undone -- there is no transaction';
  like $err, qr/is_auto_increment => 1/,
    '... then tells the user how to get a working surrogate key';
  like $err, qr/refused by the DDL layer/,
    '... and why is_auto_increment does nothing on an integer column';
}

# The hook throws on its own too, not only through create().
{
  throws_ok { $schema->storage->last_insert_id($schema->source('Counter'), 'id') }
    qr/no auto-increment and no last_insert_id/,
    'last_insert_id() throws when called directly';
}

#############################################################################
# 6. client generation and the emitted DDL default describe the same columns
#############################################################################

# The storage generates a UUID for exactly the columns the DDL layer gives a
# DEFAULT generateUUIDv4() to. If those two rules ever drift, one of these
# fails: a column with a server default we never let fire, or a column we
# expect a default on that has none.
{
  {
    package My::CH::Insert::HitOnly;
    use base 'DBIO::Schema';
    __PACKAGE__->load_components('ClickHouse');
    __PACKAGE__->register_class(Hit => 'My::CH::Insert::Result::Hit');
  }
  my $ddl = DBIO::ClickHouse::DDL->install_ddl('My::CH::Insert::HitOnly');

  like $ddl, qr/`id`\s+UUID\s+DEFAULT\s+generateUUIDv4\(\)/,
    'the UUID key gets a server-side DEFAULT generateUUIDv4() as a safety net';

  # nothing server-side generates an integer, so the DDL layer refuses the
  # integer is_auto_increment key instead of building a table without a generator
  throws_ok { DBIO::ClickHouse::DDL->install_ddl('My::CH::Insert::Schema') }
    qr/table 'counter' \(columns [^)]*\): column 'id' is auto-increment/,
    'the integer-keyed table is refused, not built without a generator';
}

done_testing;
