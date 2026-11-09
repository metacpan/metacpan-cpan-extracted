use strict;
use warnings;
use Test::More;

# t/66-mask-error-values-live.t -- what a failing statement throws names the
# type, the column, the constraint, the code and the number of binds, and none
# of the values bound to it.
#
# ClickHouse writes the offending value into its error text, also a bound one:
# DBD::mysql puts the bind values into the statement on the client, and the
# engine quotes what it received -- in the sentence of the error, in the
# statement after "In scope", in "Column values:", in the plan after "while
# executing". The offline contract for the sentences is t/65; what only a
# server answers is whether the text it really writes is the text t/65 pins,
# and whether the storage routes every statement of this driver through the
# masking. Each form runs with a marker value as a bind and asserts on the
# exception that comes out of the storage.
#
# Two kinds of values: 'geheim42' (long: core's masking of bound values takes
# it out wherever it stands) and short ones ('ab', '7x': below core's threshold
# of four characters, so only the sentence rules of the driver can take them
# out). A form whose engine text carries a short value has a case for both.
#
# The tables are created by hand: columns the driver would refuse client-side
# when declared numeric (it refuses a non-number for an Int column before
# sending) are declared as strings in the result classes, so the statement
# reaches the engine and the engine is the one that fails.

plan skip_all => 'Set DBIO_TEST_CLICKHOUSE_DSN to run live ClickHouse tests'
  unless $ENV{DBIO_TEST_CLICKHOUSE_DSN};

use DBIO::ClickHouse::Test;

{
  package MaskT::Result::M;
  use base 'DBIO::Core';
  __PACKAGE__->table('mask_t');
  __PACKAGE__->add_columns(
    i => { data_type => 'varchar', size => 100 },
    map { $_ => { data_type => 'varchar', size => 100, is_nullable => 1 } }
      qw(d u ip e m a s)
  );
  __PACKAGE__->set_primary_key('i');
}

{
  package MaskT::Result::J;
  use base 'DBIO::Core';
  __PACKAGE__->table('mask_j');
  __PACKAGE__->add_columns(j => { data_type => 'varchar', size => 100 });
  __PACKAGE__->set_primary_key('j');
}

my $schema = DBIO::ClickHouse::Test->init_schema(no_populate => 1);
$schema->register_class(M => 'MaskT::Result::M');
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

$dbh->do(q{
  CREATE TABLE mask_t (
    i Int32, d Date, u UUID, ip IPv4, e Enum8('red' = 1, 'blue' = 2),
    m Map(String, Int32), a Array(Int32), s String,
    CONSTRAINT shortname CHECK length(s) < 5,
    CONSTRAINT notwo CHECK length(s) != 2
  ) ENGINE = MergeTree ORDER BY tuple()
});

my $json_table = eval {
  $dbh->do('CREATE TABLE mask_j (j JSON) ENGINE = MergeTree ORDER BY tuple()');
  $schema->register_class(J => 'MaskT::Result::J');
  1;
};
diag 'no native JSON type on this server, the JSON case is left out' unless $json_table;

my $m = $schema->resultset('M');
$m->populate([ { i => 1, d => '2020-01-01', s => 'row1' } ]);

sub error_of {
  my ($code, $value) = @_;
  my $ok = eval { $code->($value); 1 };
  return $ok ? undef : "$@";
}

# literal SQL with bound values, as the where clause of a select
sub lit { my ($sql) = @_; return sub { $m->search(\[ $sql, $_[0] ])->all } }

my $LONG = 'geheim42';

# values: [ value, secret... ]; a secret is a plain string or a regex. For a
# value of up to three characters the value itself, quoted and bare, is the
# secret.
my @cases = (
  {
    name   => 'Int32 parse of a string, insert',
    run    => sub { $m->create({ i => $_[0] }) },
    values => [ [$LONG, '42'], ['ab'] ],
    keep   => [qr/Cannot parse string '\*\*\*' as Int32/, qr/Code: 6\./, qr/CANNOT_PARSE_TEXT/, qr/with 1 bind value\b/],
  },
  {
    name   => 'Int32 parse of a number with a tail (parsed just)',
    run    => sub { $m->create({ i => $_[0] }) },
    values => [ ['7x', qr/'7'/] ],
    keep   => [qr/as Int32: syntax error at position 1 \(parsed just '\*\*\*'\)/, qr/Code: 6\./],
  },
  {
    name   => 'Date parse of a value the engine cuts off, insert',
    run    => sub { $m->create({ i => 1, d => $_[0] }) },
    values => [ ['31337-99-99', '31337', '99-99'] ],
    keep   => [qr/Cannot parse date here: \*\*\*: Cannot parse Date from String/, qr/Code: 38\./, qr/CANNOT_PARSE_DATE/, qr/with 2 bind values/],
  },
  {
    name   => 'Date parse, insert',
    run    => sub { $m->create({ i => 1, d => $_[0] }) },
    values => [ [$LONG] ],
    keep   => [qr/Cannot parse date/, qr/Code: 38\./, qr/with 2 bind values/],
  },
  {
    name   => 'Date parse, mutation',
    run    => sub { $m->search({ s => 'row1' })->update({ d => $_[0] }) },
    values => [ [$LONG], ['31337-99-99', '31337'] ],
    keep   => [qr/Cannot parse date/, qr/Code: 38\./, qr/ALTER TABLE `mask_t` UPDATE `d` = \? WHERE `s` = \?/, qr/with 2 bind values/],
  },
  {
    name   => 'comparison of an Int32 column with a string, where',
    run    => lit('i = ?'),
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Cannot convert string '\*\*\*' to type Int32/, qr/Code: 53\./, qr/TYPE_MISMATCH/, qr/with 1 bind value\b/],
  },
  {
    name   => 'CAST(? AS INTEGER)',
    run    => lit('i = CAST(? AS INTEGER)'),
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Cannot parse string '\*\*\*' as Int32/, qr/In scope SELECT me\.i, /, qr/FROM mask_t AS me WHERE i = CAST\(\*\*\*, \*\*\*\)/, qr/Code: 6\./, qr/with 1 bind value\b/],
  },
  {
    name   => 'CHECK constraint, column values of the row',
    run    => sub { $m->create({ i => 5, s => $_[0] }) },
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Constraint `(?:shortname|notwo)` for table \S+\.mask_t/, qr/is violated at row 1\./, qr/Expression: \(/,
               qr/Column values: s = \*\*\*\. \(VIOLATED_CONSTRAINT\)/, qr/Code: 469\./, qr/with 2 bind values/],
  },
  {
    name   => 'syntax error in a statement with a bound value',
    run    => lit('i = ? AND AND'),
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Code: \d+\./, qr/in scope SELECT me\.i, /, qr/WHERE \(i = \*\*\*\) AND AND/, qr/with 1 bind value\b/],
  },
  {
    name   => 'multi-row insert, the failing value in a later row',
    run    => sub { $m->populate([ { i => 1, s => 'okay' }, { i => 2, s => 'okay' }, { i => $_[0], s => 'okay' } ]) },
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Cannot parse string '\*\*\*' as Int32/, qr/Code: 6\./, qr/VALUES \(\?, \?\), \(\?, \?\), \(\?, \?\)/, qr/with 6 bind values/],
  },
  {
    name   => 'multi-row insert, a Date in the second row',
    run    => sub { $m->populate([ { i => 1, d => '2020-01-01' }, { i => 2, d => $_[0] } ]) },
    values => [ ['31337-99-99', '31337'] ],
    keep   => [qr/Cannot parse date here: \*\*\*/, qr/Code: 38\./, qr/with 4 bind values/],
  },
  {
    name   => 'UUID parse',
    run    => sub { $m->create({ i => 1, u => $_[0] }) },
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Cannot parse uuid \*\*\*: Cannot parse UUID from String/, qr/Code: 376\./, qr/CANNOT_PARSE_UUID/, qr/with 2 bind values/],
  },
  {
    name   => 'IPv4 parse',
    run    => sub { $m->create({ i => 1, ip => $_[0] }) },
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Invalid IPv4 value/, qr/Code: 675\./, qr/CANNOT_PARSE_IPV4/, qr/with 2 bind values/],
  },
  {
    name   => 'Enum8 unknown element',
    run    => sub { $m->create({ i => 1, e => $_[0] }) },
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/Unknown element '?\*\*\*'? for enum/, qr/Code: 691\./, qr/UNKNOWN_ELEMENT_OF_ENUM/, qr/with 2 bind values/],
  },
  {
    name   => 'Map parse',
    run    => sub { $m->create({ i => 1, m => $_[0] }) },
    values => [ [$LONG], ['ab'] ],
    keep   => [qr/expected '\{' before: '?\*\*\*'?/, qr/Map\(String, Int32\)/, qr/Code: 27\./, qr/with 2 bind values/],
  },
  {
    name   => 'Array parse',
    run    => sub { $m->create({ i => 1, a => "[$_[0]]" }) },
    values => [ [$LONG, qr/found 'g'/], ['ab', qr/found 'a'/] ],
    keep   => [qr/Cannot read array from text, expected comma or end of array, found '\*\*\*'/, qr/Code: 130\./, qr/with 2 bind values/],
  },
  {
    name   => 'a value with a quote, a double quote, a comma and a colon',
    run    => sub { $m->create({ i => $_[0] }) },
    values => [ [q{ge'heim"42, x: y}, 'heim', '42, x', 'x: y'] ],
    keep   => [qr/Cannot parse string '\*\*\*' as Int32: syntax error/, qr/Code: 6\./, qr/with 1 bind value\b/],
  },
  {
    name   => 'a value with a newline',
    run    => sub { $m->create({ i => $_[0] }) },
    values => [ ["geheim42\nzeile2", 'geheim42', 'zeile2'] ],
    keep   => [qr/Cannot parse string '?\*\*\*'? as Int32/, qr/Code: 6\./, qr/with 1 bind value\b/],
  },
);

push @cases, {
  name   => 'JSON parse',
  run    => sub { $schema->resultset('J')->create({ j => "{$_[0]" }) },
  values => [ [$LONG], ['ab'] ],
  keep   => [qr/Cannot parse JSON object here: \*\*\*/, qr/Code: 117\./, qr/INCORRECT_DATA/, qr/with 1 bind value\b/],
} if $json_table;

for my $case (@cases) {
  for my $spec (@{ $case->{values} }) {
    my ($value, @secret) = @$spec;
    my $label = "$case->{name} [" . ($value =~ /\n/ ? 'newline' : $value) . ']';

    unshift @secret, length $value > 3
      ? $value
      : (qr/'\Q$value\E'/, qr/\b\Q$value\E\b/);

    my $msg = error_of($case->{run}, $value);
    diag "$label: $msg" if $ENV{MASK_VERBOSE};

    ok defined $msg, "$label: the statement fails" or next;

    for my $secret (@secret) {
      my $re = ref $secret ? $secret : qr/\Q$secret\E/;
      unlike $msg, $re, "$label: the message does not hold $re";
    }
    like $msg, $_, "$label: the message keeps $_" for @{ $case->{keep} };
  }
}

# The statements that run on the handle of the storage without the storage
# naming their values -- the introspection, the scratch-database deploy, the
# DDL of the diff -- reach the same hook through the error handler of the
# handle; the sentences of the engine are masked there too.
{
  my $msg = error_of(sub { $dbh->selectall_arrayref('SELECT CAST(? AS Int32)', undef, 'ab') });
  ok defined $msg, 'raw handle, a bind: fails';
  unlike $msg // '', qr/'ab'/, '... the short value is not in the message';
  like $msg // '', qr/Cannot parse string '\*\*\*' as Int32/, '... the sentence keeps its type';
  like $msg // '', qr/Code: 6\./, '... and its code';

  $msg = error_of(sub { $dbh->do(q{ALTER TABLE mask_t ADD COLUMN z Int32 DEFAULT 'ab'}) });
  ok defined $msg, 'raw handle, DDL with a literal: fails';
  (my $engine = $msg // '') =~ s/\s*\[for Statement .*//s;
  unlike $engine, qr/'ab'/, '... the literal is not in the text of the engine';
  like $msg // '', qr/Code: \d+\./, '... the code stays';
  like $msg // '', qr/\[for Statement "ALTER TABLE mask_t ADD COLUMN z Int32 DEFAULT 'ab'"/,
    '... the statement as written is named, its literal is the caller\'s own';
}

# A literal in the statement itself, outside the place of the error, is not a
# bound value: the part of the statement the engine does not quote stays.
{
  my $msg = error_of(sub { $m->search(\[ q{s = 'literalmark' AND i = ?}, $LONG ])->all });
  unlike $msg, qr/\Q$LONG\E/, 'literal beside a bound value: the bound value is gone';
  like $msg, qr/Code: \d+\./, '... the code stays';
  like $msg, qr/\[for Statement "SELECT .*s = 'literalmark' AND i = \?/,
    '... the statement of the exception keeps its placeholder form and its literal';
}

# The raw text stays available to whoever asks the handle.
{
  my $raw;
  {
    local $dbh->{HandleError} = undef;
    local $dbh->{RaiseError}  = 0;
    local $dbh->{PrintError}  = 0;
    $dbh->do('INSERT INTO mask_t (i) VALUES (?)', undef, $LONG);
    $raw = $dbh->errstr;
  }
  like $raw // '', qr/Cannot parse string '\Q$LONG\E' as Int32/,
    '$dbh->errstr keeps the raw text of the engine';
}

done_testing;
