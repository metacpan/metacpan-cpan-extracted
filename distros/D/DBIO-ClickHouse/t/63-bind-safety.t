use strict;
use warnings;
use Test::More;
use Test::Exception;
use Math::BigInt;

# t/63-bind-safety.t -- two things the server does to a bound value without
# saying so, and what the driver does about them (karr k43; conformance cases
# bind-empty-string, bind-binary, bind-lob-empty-and-large). Measured against a
# stock server through DBD::mysql:
#
#   * a string that is not a number, bound to an Int column, is stored as NULL
#     (Float and Decimal columns reject '' and 'abc' loudly but also store ' 5'
#     as NULL). The storage refuses it BEFORE it is sent, naming table and
#     column.
#   * DBD::mysql escapes the byte 0x1A as \Z, which ClickHouse keeps as two
#     characters. The SQL maker binds a string with a 0x1A as
#     replaceAll(?, marker, char(26)) with the 0x1A bytes replaced by the
#     marker, which the server turns back into the bytes.
#
# Offline: a storage that renders and records, never executes.

use DBIO::ClickHouse::Test ':DiffSQL';
use DBIO::ClickHouse::Storage;
use DBIO::ClickHouse::SQLMaker;

{
  package MyTest::CH::BindRecorder;
  use strict;
  use warnings;
  use base 'DBIO::ClickHouse::Storage';
  use mro 'c3';

  our @LOG;

  sub new {
    my $self = shift->next::method(@_);
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

{
  package My::CH::Bind::Result::Val;
  use strict;
  use warnings;
  use base 'DBIO::Core';

  __PACKAGE__->table('val');
  __PACKAGE__->add_columns(
    id  => { data_type => 'uuid' },
    i   => { data_type => 'integer', is_nullable => 1 },
    u   => { data_type => 'UInt8', is_nullable => 1 },
    big => { data_type => 'Nullable(Int64)' },
    m   => { data_type => 'UInt8' },
    t8  => { data_type => 'tinyint', is_nullable => 1 },
    ub  => { data_type => 'bigint', extra => { unsigned => 1 }, is_nullable => 1 },
    w   => { data_type => 'UInt256', is_nullable => 1 },
    lc  => { data_type => 'Int16', extra => { low_cardinality => 1 } },
    f   => { data_type => 'double', is_nullable => 1 },
    d   => { data_type => 'decimal', size => [10, 2], is_nullable => 1 },
    s   => { data_type => 'varchar', size => 20, is_nullable => 1 },
    b   => { data_type => 'blob', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package My::CH::Bind::Schema;
  use strict;
  use warnings;
  use base 'DBIO::Schema';

  __PACKAGE__->load_components('ClickHouse');
  __PACKAGE__->register_class(Val => 'My::CH::Bind::Result::Val');
}

my $schema = My::CH::Bind::Schema->connect(sub { });
$schema->storage(MyTest::CH::BindRecorder->new($schema));
my $rs = $schema->resultset('Val');

sub recorded {
  my @log = @MyTest::CH::BindRecorder::LOG;
  @MyTest::CH::BindRecorder::LOG = ();
  return @log;
}

#############################################################################
# 1. a non-number at a numeric column is refused before it is sent
#############################################################################

# WHY: the server answers '' / 'abc' / '5x' / '1.5' bound to an Int32 with
# success and a NULL in the row. A refusal that names the column is the only
# honest answer; sending it would be falsifying the data.
for my $case (
  [ i => '' ], [ i => 'abc' ], [ i => '5x' ], [ i => '1.5' ], [ i => '1e3' ],
  [ i => ' 5' ], [ i => '5 ' ], [ i => '0x10' ],
  [ u => '' ], [ big => 'abc' ],
  [ f => '' ], [ f => 'abc' ], [ f => ' 5' ],
  [ d => '' ], [ d => 'abc' ], [ d => 'inf' ],
) {
  my ($col, $value) = @$case;
  my $shown = length $value ? "'$value'" : q('');
  throws_ok { $rs->create({ id => 'u', $col => $value }) }
    qr/table val, column \Q$col\E\b.*refused.*Nothing was sent/s,
    "create: $shown at $col is refused, naming table and column";
  is scalar(recorded()), 0, "... and no statement was rendered for it";
}

unlike(
  (eval { $rs->create({ id => 'u', i => 'secret-abc' }); 1 } ? '' : "$@"),
  qr/secret-abc/, 'the message never quotes the value',
);

# the other write paths
throws_ok { $rs->search({ id => 'u' })->update({ i => '' }) }
  qr/table val, column i\b.*refused/s, 'update: the SET value is refused too';
is scalar(recorded()), 0, '... before anything is sent';

throws_ok { $rs->populate([ [qw(id i)], [ 'a', 1 ], [ 'b', 'x' ] ]) }
  qr/table val, column i\b.*refused/s, 'populate (insert_multi): refused';
is scalar(recorded()), 0, '... before anything is sent';

#############################################################################
# 2. what stays allowed
#############################################################################

# WHY: bind-digit-string-leading-zero. A string that the server reads as the
# number it looks like is not a falsification; the check is the server's own
# number format, per type, not "looks like a digit".
for my $case (
  [ i => '007' ], [ i => '-3' ], [ i => '+5' ], [ i => 5 ], [ i => 0 ], [ i => undef ],
  [ u => '255' ], [ big => '9223372036854775807' ],
  [ f => '1e3' ], [ f => '1.50' ], [ f => '.5' ], [ f => '5.' ], [ f => '-inf' ],
  [ f => 'NaN' ], [ f => 1.5 ], [ f => '007' ],
  [ d => '1.50' ], [ d => '007' ], [ d => '1E3' ], [ d => undef ],
  [ s => '' ], [ s => 'abc' ], [ s => '5x' ], [ b => '' ],
) {
  my ($col, $value) = @$case;
  my $shown = defined $value ? (length $value ? "'$value'" : q('')) : 'undef';
  lives_ok { $rs->create({ id => 'u', $col => $value }) }
    "$shown at $col is sent";
  is scalar(recorded()), 1, '... exactly one statement';
}

lives_ok { $rs->create({ id => 'u', i => \'toInt32(1)' }) }
  'literal SQL at an Int column is not looked at';
recorded();

# a read is not a write: the server reports a compare, it does not store
lives_ok {
  my $storage = $schema->storage;
  my $source  = $rs->result_source;
  my $q = $rs->search({ i => q() });
  my $attrs = $q->_resolved_attrs;
  my ($op, $ident, @args) = $storage->_select_args($source, $attrs->{select}, $q->{cond}, $attrs);
  $storage->_prep_for_execute($op, $ident, \@args);
}
  'a search condition is not refused (nothing is stored)';
recorded();

#############################################################################
# 2b. an integer outside the range of its type is refused before it is sent
#############################################################################

# WHY: the server stores NULL for 300 at a Nullable(UInt8) and 44 (300 mod 256)
# at a UInt8, with no error, and no session setting makes it throw (measured,
# karr k43). Writing a different value than the one given is falsifying data,
# so the driver is the only place left to say no. The range is the type's own:
# the edges are in, one past is out, for signed and unsigned, narrow and wide.
my $W = sub { Math::BigInt->new(2)->bpow($_[0]) };
for my $case (
  [ u => 300 ], [ u => '300' ], [ u => '-3' ], [ u => 256 ], [ u => '-1' ],
  [ m => 300 ], [ m => '-1' ],
  [ t8 => 128 ], [ t8 => '-129' ],
  [ i => '2147483648' ], [ i => '-2147483649' ],
  [ big => '9223372036854775808' ], [ big => '-9223372036854775809' ],
  [ ub => '-1' ], [ ub => $W->(64)->bstr ],
  [ w => '-1' ], [ w => $W->(256)->bstr ],
  [ lc => 32768 ],
  [ u => '+256' ], [ u => '0000256' ],
) {
  my ($col, $value) = @$case;
  throws_ok { $rs->create({ id => 'u', m => 1, lc => 1, $col => $value }) }
    qr/table val, column \Q$col\E\b.*outside the range of \w+.*Nothing was sent/s,
    "create: $value at $col is out of range and refused";
  is scalar(recorded()), 0, '... and no statement was rendered for it';
}

like(
  (eval { $rs->create({ id => 'u', m => 1, lc => 1, u => 300 }); 1 } ? '' : "$@"),
  qr/UInt8\b/, 'the message names the type'
);
unlike(
  (eval { $rs->create({ id => 'u', m => 1, lc => 1, u => 987654 }); 1 } ? '' : "$@"),
  qr/987654/, 'the message never quotes the value',
);

throws_ok { $rs->search({ id => 'u' })->update({ u => 300 }) }
  qr/table val, column u\b.*outside the range/s, 'update: refused too';
is scalar(recorded()), 0, '... before anything is sent';

throws_ok { $rs->populate([ [qw(id m)], [ 'a', 1 ], [ 'b', 256 ] ]) }
  qr/table val, column m\b.*outside the range/s, 'populate (insert_multi): refused';
is scalar(recorded()), 0, '... before anything is sent';

for my $case (
  [ u => 0 ], [ u => 255 ], [ u => '-0' ], [ u => '+255' ], [ u => '000255' ],
  [ m => 255 ],
  [ t8 => 127 ], [ t8 => '-128' ],
  [ i => '2147483647' ], [ i => '-2147483648' ],
  [ big => '9223372036854775807' ], [ big => '-9223372036854775808' ],
  [ ub => '18446744073709551615' ], [ ub => 0 ],
  [ w => $W->(256)->bdec->bstr ],
  [ lc => 32767 ], [ lc => -32768 ],
  [ f => '1e30' ], [ d => '99999999999' ],
) {
  my ($col, $value) = @$case;
  lives_ok { $rs->create({ id => 'u', m => 1, lc => 1, $col => $value }) }
    "$value at $col is inside its range and sent";
  is scalar(recorded()), 1, '... exactly one statement';
}

# a read is not a write
lives_ok {
  my $q = $rs->search({ u => 300 });
  my $attrs = $q->_resolved_attrs;
  my ($op, $ident, @args) = $schema->storage->_select_args($rs->result_source, $attrs->{select}, $q->{cond}, $attrs);
  $schema->storage->_prep_for_execute($op, $ident, \@args);
} 'a search condition out of range is not refused (nothing is stored)';
recorded();

#############################################################################
# 3. 0x1A is bound through a marker
#############################################################################

# WHY: DBD::mysql quotes the byte 0x1A as \Z and ClickHouse keeps it as the two
# characters, so a text or blob value grew by one character per 0x1A. The value
# goes with its 0x1A bytes replaced by a marker that the server replaces back
# (char(26)); everything else about the value is untouched, so no hex doubling
# (max_query_size) and no encoding decision.
{
  my $sm = DBIO::ClickHouse::SQLMaker->new(
    bindtype => 'columns', quote_char => '`', name_sep => '.',
  );
  my $R = sub { "replaceAll(?, 'ch1a$_[0]x', char(26))" };

  is_same_sql_bind(
    \[ $sm->insert('val', { b => "a\x1Ab\x1A" }) ],
    'INSERT INTO `val` (`b`) VALUES (' . $R->(0) . ')',
    [ [ b => 'ach1a0xbch1a0x' ] ],
    'a value with 0x1A is bound with the bytes replaced by a marker',
  );

  is_same_sql_bind(
    \[ $sm->insert('val', { id => 'u', b => "a\x00b\\c'd\x{20ac}" }) ],
    'INSERT INTO `val` (`b`, `id`) VALUES (?, ?)',
    [ [ b => "a\x00b\\c'd\x{20ac}" ], [ id => 'u' ] ],
    'a value without 0x1A is bound as it was',
  );

  is_same_sql_bind(
    \[ $sm->insert('val', { b => "x\x1Ach1a0xy" }) ],
    'INSERT INTO `val` (`b`) VALUES (' . $R->(1) . ')',
    [ [ b => 'xch1a1xch1a0xy' ] ],
    'the marker is chosen so that it does not occur in the value',
  );

  is_same_sql_bind(
    \[ $sm->update('val', { s => "\x{20ac}\x1A" }, { id => 'u' }) ],
    'ALTER TABLE `val` UPDATE `s` = ' . $R->(0) . ' WHERE `id` = ? SETTINGS mutations_sync = 1',
    [ [ s => "\x{20ac}ch1a0x" ], [ id => 'u' ] ],
    'a character string keeps its characters, in an update too',
  );

  is_same_sql_bind(
    \[ $sm->update('val', { s => 'x' }, { s => "q\x1A" }) ],
    'ALTER TABLE `val` UPDATE `s` = ? WHERE `s` = ' . $R->(0) . ' SETTINGS mutations_sync = 1',
    [ [ s => 'x' ], [ s => 'qch1a0x' ] ],
    'and in a condition, where the value is compared',
  );

  is_same_sql_bind(
    \[ $sm->insert_multi('val', [qw(id b)], [ [ 'a', "\x1A" ], [ 'b', 'ok' ] ]) ],
    'INSERT INTO `val` (`id`, `b`) VALUES (?, ' . $R->(0) . '), (?, ?)',
    [ [ id => 'a' ], [ b => 'ch1a0x' ], [ id => 'b' ], [ b => 'ok' ] ],
    'insert_multi rewrites the one cell and leaves the next',
  );
}

# end to end through the storage
{
  $rs->create({ id => 'u', b => join '', map { chr } 0 .. 255 });
  my ($stmt) = recorded();
  like $stmt->{sql}, qr/replaceAll\(\?, 'ch1a0x', char\(26\)\)/,
    'create: the statement carries the replacement';
  my ($marked) = grep { $_->[1] =~ /ch1a0x/ } @{ $stmt->{bind} };
  ok $marked, '... and the bind carries the marker in place of the byte';
  is $marked->[0]{dbic_colname}, 'b', '... still attributed to its column';
}

done_testing;
