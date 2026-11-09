use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test::Schema;
use DBIO::DB2::Storage;
use DBIO::DB2::Storage::Cursor;

# OFFLINE (karr k57, conformance Bind list; the live counterpart is t/87).
# What the cases showed of DBD::DB2, pinned without a server:
#
#   1. a character LOB is bound with the type of a CLOB (-99 in the CLI of DBD::DB2),
#      so a long value is a LOB parameter and not a VARCHAR one; a BLOB or any
#      other type is bound as before;
#   2. DBD::DB2 returns text as the UTF-8 bytes the server holds, never as
#      characters. The storage's cursor decodes the character columns of a
#      UTF-8 database (and only those: a binary column and a non-UTF-8 database
#      are left alone);
#   3. DBD::DB2 reads an empty BLOB as NULL, so an empty string cannot be stored
#      in a BLOB column and read back. It is refused, loudly, naming table and
#      column, instead of being stored as something else;
#   4. Db2 cannot compare a CLOB with a value longer than 32672 bytes (SQL0433N);
#      a select that does is refused before the server is asked.

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DB2::Storage');
$schema = $schema->connect('dbi:DB2:DATABASE=nonexistent', 'u', 'p');
my $storage = $schema->storage;
my $source  = $schema->resultset('BindType')->result_source;

# --- 1: the bind type -------------------------------------------------------
for my $t (qw(clob text CLOB dbclob mediumtext)) {
  is_deeply $storage->bind_attribute_by_data_type($t), { TYPE => -99 }, "$t is bound as a CLOB";
}
for my $t (qw(blob varchar integer binary)) {
  my $a = $storage->bind_attribute_by_data_type($t);
  ok !(ref $a eq 'HASH' && $a->{TYPE} && $a->{TYPE} == -99), "$t is not bound as a CLOB";
}

# --- 2: the cursor decodes -----------------------------------------------------
is $storage->cursor_class, 'DBIO::DB2::Storage::Cursor', 'the storage reads through the DB2 cursor';
{
  package Fake::Sth;
  sub new { my ($c, %a) = @_; bless { %a, rows => [ @{ $a{rows} } ] }, $c }
  sub FETCH { $_[0]{$_[1]} }
  sub bind_columns { my ($s, @r) = @_; $s->{refs} = \@r; 1 }
  sub fetch { my $s = shift; my $row = shift @{ $s->{rows} } or return; ${ $s->{refs}[$_] } = $row->[$_] for 0 .. $#$row; 1 }
  sub fetchall_arrayref { my $s = shift; my @r = map { [ @$_ ] } @{ $s->{rows} }; $s->{rows} = []; \@r }
  sub finish { 1 }
}
my $euro = "\x{20ac}";
(my $bytes = $euro) =~ s/(.)/utf8::encode(my $b = $1); $b/e;
sub cursor {
  my ($utf8) = @_;
  my $sth = Fake::Sth->new(NUM_OF_FIELDS => 3, TYPE => [ 12, -98, -99 ],
    rows => [ [ $bytes, $bytes, $bytes ], [ undef, 'x', 'y' ] ]);
  my $st = bless { utf8 => $utf8, sth => $sth }, 'Fake::Storage2';
  no strict 'refs';
  *{'Fake::Storage2::_select'}        = sub { (undef, $_[0]{sth}) };
  *{'Fake::Storage2::_utf8_database'} = sub { $_[0]{utf8} };
  *{'Fake::Storage2::throw_exception'} = sub { die $_[1] };
  return bless { storage => $st, args => [], attrs => {} }, 'DBIO::DB2::Storage::Cursor';
}
{
  my $c = cursor(1);
  my @row = $c->next;
  is $row[0], $euro, 'a VARCHAR column of a UTF-8 database is decoded to characters';
  is $row[1], $bytes, '... a BLOB column is left as the bytes it is';
  is $row[2], $euro, '... a CLOB column is decoded';
  @row = $c->next;
  ok !defined $row[0], '... NULL stays NULL';
  my @all = cursor(1)->all;
  is $all[0][0], $euro, 'all: decoded as well';
  is $all[0][1], $bytes, '... the BLOB not';
  @all = cursor(0)->all;
  is $all[0][0], $bytes, 'a database that is not UTF-8 is read as it comes';
  @row = cursor(0)->next;
  is $row[2], $bytes, '... next, too';
}

# select_single (what find and single read through) decodes as well
{
  package Fake::Single;
  sub new { bless { row => [ @{ $_[1] } ], TYPE => $_[2] }, $_[0] }
  sub fetchrow_array { my $s = shift; my $r = delete $s->{row}; $r ? @$r : () }
  sub finish { 1 }
  package main;
  no warnings 'redefine';
  local *DBIO::DB2::Storage::_select = sub { (1, Fake::Single->new([ $bytes, $bytes ], [ 12, -98 ])) };
  local *DBIO::DB2::Storage::_utf8_database = sub { 1 };
  my @row = $storage->select_single($source, ['a', 'b'], {}, {});
  is_deeply \@row, [ $euro, $bytes ], 'select_single: the character column is decoded, the BLOB is not';
}

# --- 3 and 4: refusals ---------------------------------------------------------
throws_ok {
  $storage->_prep_for_execute('insert', $source, [ { blob => '' } ]);
} qr/table "bindtype_test" is refused: column "blob"/,
  'an empty string for a BLOB column is refused, naming table and column';
isa_ok $@, 'DBIO::Exception', '... the refusal';
lives_ok { $storage->_prep_for_execute('insert', $source, [ { clob => '' } ]) }
  'an empty string for a CLOB column is stored (it reads back as it was)';
lives_ok { $storage->_prep_for_execute('insert', $source, [ { blob => 'x' } ]) } 'a BLOB with a value is fine';
lives_ok { $storage->_prep_for_execute('insert', $source, [ { blob => undef } ]) } 'a NULL BLOB is fine';

my $long = 'x' x 40_000;
throws_ok { $storage->_prep_for_execute('select', $source, [ [ 'id' ], { clob => $long }, {} ]) }
  qr/table "bindtype_test" is refused: column "clob".*SQL0433N/s,
  'a select that compares a CLOB with more than 32672 bytes is refused, naming table and column';
isa_ok $@, 'DBIO::Exception', '... the refusal';
throws_ok { $storage->_prep_for_execute('select', [ { -alias => 'me', -rsrc => $source } ], [ [ 'id' ], { clob => $long }, {} ]) }
  qr/table "bindtype_test" is refused/, '... the table is found in the FROM of a real select';
lives_ok { $storage->_prep_for_execute('select', $source, [ [ 'id' ], { clob => 'x' x 32_672 }, {} ]) }
  'a value of 32672 bytes is not';
lives_ok { $storage->_prep_for_execute('insert', $source, [ { clob => $long } ]) }
  'a long value is stored without a question';

done_testing;
