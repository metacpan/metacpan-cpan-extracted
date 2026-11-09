use strict;
use warnings;
use Test::More;
use Test::Exception;

# t/50-native.t — DBIO::ClickHouse::Native, the export bridge to
# ClickHouse::Encoder. Offline, no server, and — the point of the whole slot —
# NO ClickHouse::Encoder: this file asserts at the end that the module was
# never loaded. The bridge produces data structures, so its correctness is a
# property of those structures, and testing it against expected structures is
# what proves the encoder is not a dependency.
#
# The intent this locks down, in order of how badly it hurts when it breaks:
#
#   1. The column list is DDL's type renderer, not a second type table. If the
#      two ever diverge, a table this dist deployed can no longer be fed by
#      this dist — and the Native format is typed, so the mismatch surfaces as
#      a wrong-width binary block, not as a readable error.
#   2. Values are deflated. get_column() IS DBIO's deflation path; going round
#      it (raw hash access, an accessor) hands the encoder an inflated object,
#      which encodes via string overloading and is silently wrong.
#   3. Every case the bridge cannot translate truthfully throws. A binary
#      column-typed format punishes a misinterpreted value with a server error
#      at best and wrong data at worst, so silence is never the right answer:
#      not for a column that was never fetched, not for a NULL in a
#      non-Nullable type, not for an undeflated object, and not for a
#      composite column read back over the MySQL wire (which yields
#      ClickHouse's *text* rendering of the array, never a Perl arrayref).

use DBIO::ClickHouse::Native;
use DBIO::ClickHouse::DDL;

# --- fixture ----------------------------------------------------------------
# One result class covering the shapes that matter: a plain key, a nullable
# column, a LowCardinality one, an Array (the one-way street), and a column
# with a custom inflator/deflator so the deflation path is exercised without
# depending on DateTime.

{
  package My::Native::Event;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('native_event');
  __PACKAGE__->add_columns(
    id     => { data_type => 'uuid',    is_nullable => 0 },
    kind   => { data_type => 'varchar', size => 32, is_nullable => 0,
                extra => { low_cardinality => 1 } },
    hits   => { data_type => 'integer', is_nullable => 0,
                extra => { unsigned => 1 } },
    score  => { data_type => 'double precision', is_nullable => 1 },
    tags   => { data_type => 'text[]',  is_nullable => 0 },
    stamp  => { data_type => 'datetime', is_nullable => 0 }
  );
  __PACKAGE__->set_primary_key('id');

  # A hand-rolled inflator/deflator: the deflated form is what the database
  # stores, the inflated form is an object the application sees. Deliberately
  # NOT InflateColumn::DateTime — the seam under test is DBIO's deflation
  # dispatch, not any one formatter.
  __PACKAGE__->inflate_column(stamp => {
    inflate => sub { My::Native::Stamp->new($_[0]) },
    deflate => sub { $_[0]->as_string }
  });

  package My::Native::Stamp;
  use strict;
  use warnings;
  use overload '""' => sub { 'STRINGIFIED-' . $_[0]->{s} }, fallback => 1;
  sub new { my ($c, $s) = @_; return bless { s => $s }, $c }
  sub as_string { return $_[0]->{s} }

  package My::Native::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';
  # A schema always declares its driver (core ADR 0067), and the driver
  # brings its storage along. Both stay inside the %INC claim at the end: the
  # whole driver is loaded, and still nothing loads the encoder.
  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Event => 'My::Native::Event');
}

# A coderef "DSN": nothing in this file reaches the server, and a coderef
# keeps core from trying to resolve a DBD driver if anything ever did.
my $schema = My::Native::Schema->connect(sub { });
my $source = $schema->source('Event');

my @expected_columns = (
  ['id',    'UUID'],
  ['kind',  'LowCardinality(String)'],
  ['hits',  'UInt32'],
  ['score', 'Nullable(Float64)'],
  ['tags',  'Array(String)'],
  ['stamp', 'DateTime64(3)']
);

# --- columns_for: the shape ClickHouse::Encoder->new takes ------------------

is_deeply(DBIO::ClickHouse::Native->columns_for($source), \@expected_columns,
  'columns_for renders [name, type] pairs in source order');

# The claim that matters: this is the DDL's renderer, not a copy of it. If
# someone adds a second type table, these two stop agreeing.
for my $pair (@expected_columns) {
  my ($name, $type) = @$pair;
  is(DBIO::ClickHouse::DDL->column_type($source->column_info($name)), $type,
    "$name: columns_for agrees with DDL->column_type ('$type')");
}

# ...and column_type is what install_ddl actually emits, so the column list
# describes the table this distribution would deploy.
my $ddl = DBIO::ClickHouse::DDL->install_ddl($schema);
for my $pair (@expected_columns) {
  my ($name, $type) = @$pair;
  like $ddl, qr/\Q`$name` $type\E/,
    "$name: install_ddl emits the same type the column list carries";
}

# --- columns_for: what it accepts as its first argument ---------------------

is_deeply(DBIO::ClickHouse::Native->columns_for($schema->resultset('Event')),
  \@expected_columns, 'a ResultSet resolves to its source');
is_deeply(DBIO::ClickHouse::Native->columns_for(
    $schema->resultset('Event')->new_result({})),
  \@expected_columns, 'a result object resolves to its source');
is_deeply(DBIO::ClickHouse::Native->columns_for('My::Native::Event'),
  \@expected_columns, 'a result class name resolves to its source');

throws_ok { DBIO::ClickHouse::Native->columns_for($schema) }
  qr/cannot get a ResultSource out of a My::Native::Schema object/,
  'a Schema is refused rather than guessed at (which source would it mean?)';
throws_ok { DBIO::ClickHouse::Native->columns_for(undef) }
  qr/needs a ResultSource/, 'undef is refused';
throws_ok { DBIO::ClickHouse::Native->columns_for('No::Such::Class::Here') }
  qr/cannot load 'No::Such::Class::Here'/, 'an unloadable class name is refused';
throws_ok { DBIO::ClickHouse::Native->columns_for('DBIO::ClickHouse::Native') }
  qr/is not a DBIO result class/, 'a loadable non-result class is refused';

# --- columns_for: restricting the column set --------------------------------

is_deeply(DBIO::ClickHouse::Native->columns_for($source, columns => [qw(hits id)]),
  [['hits', 'UInt32'], ['id', 'UUID']],
  'columns restricts the set AND fixes the order — the list is the block layout');

throws_ok { DBIO::ClickHouse::Native->columns_for($source, columns => ['nope']) }
  qr/source 'Event' has no column 'nope'/, 'an unknown column name throws';
throws_ok { DBIO::ClickHouse::Native->columns_for($source, columns => 'hits') }
  qr/'columns' must be an arrayref/, 'columns must be an arrayref';
throws_ok { DBIO::ClickHouse::Native->columns_for($source, columns => []) }
  qr/'columns' must not be empty/, 'an empty column list throws';
throws_ok { DBIO::ClickHouse::Native->columns_for($source, colums => ['id']) }
  qr/unknown option 'colums'/, 'a typo\'d option throws instead of being ignored';

# --- rows_from: order, deflation, pass-through ------------------------------

my $scalar_cols = DBIO::ClickHouse::Native->columns_for($source,
  columns => [qw(id kind hits score stamp)]);

my $stamp = My::Native::Stamp->new('2026-08-11 12:00:00');
my $row = $schema->resultset('Event')->new_result({
  id    => '6ba7b810-9dad-11d1-80b4-00c04fd430c8',
  kind  => 'click',
  hits  => 7,
  score => undef,
  stamp => $stamp
});

is_deeply(DBIO::ClickHouse::Native->rows_from([$row], $scalar_cols), [[
  '6ba7b810-9dad-11d1-80b4-00c04fd430c8', 'click', 7, undef,
  '2026-08-11 12:00:00'
]], 'rows_from emits values in column order, deflated');

# That assertion would pass for the wrong reason if the object had merely
# stringified on its way out — so the fixture makes the two forms differ. The
# stored value came back, which means the registered deflator ran, which means
# the value went through get_column().
isnt "$stamp", '2026-08-11 12:00:00',
  'the inflated object stringifies to something else entirely, so the '
  . 'deflated value above can only have come from the deflator';

is_deeply(DBIO::ClickHouse::Native->rows_from([$row], [['hits', 'UInt32']]),
  [[7]], 'a one-column list exports one value');

# A plain hashref row (DBIO::ResultClass::HashRefInflator, or caller-built
# data) is taken as-is: there is no result object to deflate through.
is_deeply(DBIO::ClickHouse::Native->rows_from(
    [{ id => 'x', kind => 'k', hits => 1, score => 0.5, stamp => '2026-01-01 00:00:00' }],
    $scalar_cols),
  [['x', 'k', 1, 0.5, '2026-01-01 00:00:00']], 'a hashref row exports as-is');

# --- rows_from: a ResultSet -------------------------------------------------
# No server, so the rows are pushed onto the resultset's cache and iterated
# from there — the same ->next path a live resultset takes.

sub cached_rs {
  my $rs = $schema->resultset('Event')->search(undef, { cache => 1 });
  $rs->set_cache([
    $schema->resultset('Event')->new_result({ id => 'a', kind => 'x', hits => 1 }),
    $schema->resultset('Event')->new_result({ id => 'b', kind => 'y', hits => 2 })
  ]);
  return $rs;
}

my $rs_cols = DBIO::ClickHouse::Native->columns_for($source, columns => [qw(id hits)]);
is_deeply(DBIO::ClickHouse::Native->rows_from(cached_rs(), $rs_cols),
  [['a', 1], ['b', 2]], 'a ResultSet is iterated with ->next');

throws_ok { DBIO::ClickHouse::Native->rows_from($schema, $rs_cols) }
  qr/needs a DBIO::ResultSet or an arrayref/, 'a non-resultset non-arrayref throws';
throws_ok { DBIO::ClickHouse::Native->rows_from(['not a row'], $rs_cols) }
  qr/must be a DBIO result object or a hashref/, 'a plain scalar row throws';

# --- row_iterator: the shape ClickHouse::Encoder->stream pulls from ---------

my $iter = DBIO::ClickHouse::Native->row_iterator(cached_rs(), $rs_cols);
is ref $iter, 'CODE', 'row_iterator returns a coderef';
is_deeply $iter->(), ['a', 1], 'first row';
is_deeply $iter->(), ['b', 2], 'second row';
is $iter->(), undef, 'undef ends the iteration — the contract $enc->stream expects';

# Laziness is the reason the iterator exists at all: a bad row must surface
# when it is pulled, not when the iterator is built, or a huge export would
# have to be walked twice.
my $bad = DBIO::ClickHouse::Native->row_iterator(['not a row'], $rs_cols);
is ref $bad, 'CODE', 'building an iterator over bad rows does not throw yet';
throws_ok { $bad->() } qr/must be a DBIO result object/, '...the pull does';

throws_ok { DBIO::ClickHouse::Native->row_iterator([], 'nope') }
  qr/must be a non-empty arrayref of \[ name, type \] pairs/,
  'the column list is validated up front';
throws_ok { DBIO::ClickHouse::Native->row_iterator([], [['id']]) }
  qr/must hold \[ name, type \] pairs/, 'a malformed pair throws';

# --- the refusals -----------------------------------------------------------
# Each of these is a value the bridge could pass on and a value the encoder
# would then misread. Every one of them is a loud failure by design.

# 1. A column the row never fetched. get_column() would answer undef, and the
#    export would carry a value the row does not have.
my $partial = $schema->resultset('Event')->new_result({ id => 'a' });
throws_ok { DBIO::ClickHouse::Native->rows_from([$partial], $rs_cols) }
  qr/Column 'hits' was not fetched/,
  'an unfetched column throws instead of exporting a phantom value';

# 2. NULL into a type that cannot hold one. Verified against
#    ClickHouse::Encoder 0.02: undef into Int32 encodes as 0, into String as
#    the empty string. Silently, which is the whole problem.
throws_ok {
  DBIO::ClickHouse::Native->rows_from(
    [{ id => 'a', hits => undef }], $rs_cols)
} qr/Column 'hits' is undef but its ClickHouse type is 'UInt32'/,
  'undef in a non-Nullable type throws (the encoder would write a zero)';

lives_ok {
  DBIO::ClickHouse::Native->rows_from([{ score => undef }],
    [['score', 'Nullable(Float64)']])
} 'undef in a Nullable type is fine';
lives_ok {
  DBIO::ClickHouse::Native->rows_from([{ kind => undef }],
    [['kind', 'LowCardinality(Nullable(String))']])
} 'undef under LowCardinality(Nullable(...)) is fine — the wrapper nests outside';

# 3. An undeflated object. It would encode through string/numeric conversion:
#    a DateTime outside UTC silently loses its offset, a numeric column gets
#    the leading digits of the stringification.
throws_ok {
  DBIO::ClickHouse::Native->rows_from(
    [{ stamp => My::Native::Stamp->new('2026-08-11 12:00:00') }],
    [['stamp', 'DateTime64(3)']])
} qr/holds a My::Native::Stamp object, which reached here undeflated/,
  'a blessed value throws rather than being stringified into a binary format';

# 4. A composite column holding a plain scalar — what the MySQL wire hands
#    back for Array/Map/Tuple/JSON. No heuristic splitting.
throws_ok {
  DBIO::ClickHouse::Native->rows_from([{ tags => "['perl','db']" }],
    [['tags', 'Array(String)']])
} qr/Column 'tags' has the composite type 'Array\(String\)'/,
  'a stringified array throws — the MySQL wire cannot round-trip a composite';
throws_ok {
  DBIO::ClickHouse::Native->rows_from([{ tags => "['perl','db']" }],
    [['tags', 'Array(String)']])
} qr/do not survive the MySQL wire protocol/, '...and says why';

# Built by hand, the same column works: that is the supported direction.
is_deeply(DBIO::ClickHouse::Native->rows_from([{ tags => ['perl', 'db'] }],
    [['tags', 'Array(String)']]),
  [[['perl', 'db']]], 'an arrayref into Array(String) passes through');
is_deeply(DBIO::ClickHouse::Native->rows_from([{ m => { a => 1 } }],
    [['m', 'Map(String, UInt8)']]),
  [[{ a => 1 }]], 'a hashref into Map passes through');

# The mirror image: a reference into a scalar type is just as wrong.
throws_ok {
  DBIO::ClickHouse::Native->rows_from([{ kind => ['a'] }],
    [['kind', 'LowCardinality(String)']])
} qr/holds a ARRAY reference, but its ClickHouse type/,
  'an arrayref into a scalar type throws';
throws_ok {
  DBIO::ClickHouse::Native->rows_from([{ kind => \'raw' }], [['kind', 'String']])
} qr/holds a SCALAR reference, which no ClickHouse type accepts/,
  'a scalar ref (literal-SQL spelling elsewhere in DBIO) has no meaning here';
throws_ok { DBIO::ClickHouse::Native->rows_from([{}], [['kind', 'String']]) }
  qr/Row hashref has no key 'kind'/, 'a missing hashref key throws';

# Dynamic is the one type that takes either shape, so it must not be caught by
# either half of the composite rule.
lives_ok {
  DBIO::ClickHouse::Native->rows_from([{ d => 'scalar' }, { d => [1, 2] }, { d => undef }],
    [['d', 'Dynamic']])
} 'Dynamic accepts a scalar, an arrayref and undef alike';

# --- the point of the whole file -------------------------------------------

ok !exists $INC{'ClickHouse/Encoder.pm'},
  'ClickHouse::Encoder was never loaded — the bridge is a data-structure '
  . 'translation, not a dependency';

done_testing;
