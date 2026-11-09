use strict;
use warnings;
use Test::More;

use DBIO::Firebird::Storage;
use DBIO::Firebird::Storage::InterBase;
use DBIO::Firebird::Storage::ODBC;

# OFFLINE (karr k60, cases bind-empty-string ... bind-lob-row-operations).
#
# WHY: text and blob columns are BLOBs on Firebird. DBD::Firebird dies on a
# BLOB parameter in a SELECT ("BLOB as an input param for SELECT is not
# allowed") -- so search({ v => 'x' }), find on such a column, the label of a
# document lookup, all die in the DBD -- while the server compares a BLOB with
# a VARCHAR happily. Measured on Firebird 5.0.4 (a UTF8 and a NONE database):
# v = CAST(? AS VARCHAR(8191) CHARACTER SET UTF8) finds the row, also for
# '' and for non-ASCII text up to 8191 characters, and the binary form with
# CHARACTER SET OCTETS for every byte value up to 32765 bytes; UPDATE and
# DELETE take a BLOB parameter and need none. Past the VARCHAR limit nothing
# can be compared, and the storage refuses before the DBD does.
#
# THE STAND-IN: the SQL maker answers a canned statement and bind, the source
# answers its column infos; the storage resolves the binds as it always does.

{
  package T::Source;
  sub new  { bless {}, shift }
  sub name { 'val' }
  sub from { 'val' }
  sub columns_info {
    return {
      id => { data_type => 'integer' },
      v  => { data_type => 'text' },
      b  => { data_type => 'blob' },
      c  => { data_type => 'varchar', size => 20 },
      s  => { data_type => 'string' },
    };
  }
}

{
  package T::Maker;
  sub new { my ($c, $sql, @bind) = @_; bless { sql => $sql, bind => \@bind }, $c }
  sub select { my $s = shift; return ($s->{sql}, @{ $s->{bind} }) }
  sub update { my $s = shift; return ($s->{sql}, @{ $s->{bind} }) }
}

my %SUB;
sub gen {
  my ($class, $op, $sql, @bind) = @_;
  my $sub = $SUB{$class} ||= do {
    (my $name = "T::Storage::$class") =~ s/::/_/g;
    $name = "T::$name";
    eval qq{package $name; use mro 'c3'; our \@ISA = ('$class'); sub sql_maker { \$_[0]{_sql_maker} } 1 }
      or die $@;
    $name;
  };
  my $storage = bless { _sql_maker => T::Maker->new($sql, @bind) }, $sub;
  return $storage->_gen_sql_bind($op, T::Source->new, [ undef, undef, {} ]);
}

my $TEXT = 'CAST(? AS VARCHAR(8191) CHARACTER SET UTF8)';
my $BIN  = 'CAST(? AS VARCHAR(32765) CHARACTER SET OCTETS)';

for my $class (qw(DBIO::Firebird::Storage DBIO::Firebird::Storage::InterBase)) {
  my ($sql, $bind) = gen($class, 'select', 'SELECT id FROM val WHERE v = ?', [ v => 'abc' ]);
  is $sql, "SELECT id FROM val WHERE v = $TEXT", "$class: a text BLOB is compared with a cast VARCHAR";
  is $bind->[0][1], 'abc', '... the bound value is the one written';

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE b = ?', [ b => "\x00\xff" ]);
  is $sql, "SELECT id FROM val WHERE b = $BIN", "$class: a binary BLOB with an OCTETS cast";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE s = ?', [ s => 'x' ]);
  like $sql, qr/\Q$TEXT\E/, "$class: a string without a size is a text BLOB too";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v = ?', [ v => '' ]);
  like $sql, qr/\Q$TEXT\E/, "$class: the empty string is cast as well";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v LIKE ?', [ v => 'a%' ]);
  like $sql, qr/LIKE \Q$TEXT\E/, "$class: LIKE too";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE c = ? AND id = ? AND v = ?',
    [ c => 'x' ], [ id => 3 ], [ v => 'y' ]);
  is $sql, "SELECT id FROM val WHERE c = ? AND id = ? AND v = $TEXT",
    "$class: only the BLOB comparison is rewritten, among others";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v = ? AND v = ?', [ v => 'a' ], [ v => 'b' ]);
  is $sql, "SELECT id FROM val WHERE v = $TEXT AND v = $TEXT", "$class: every such placeholder";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v IS NULL AND id = ?', [ id => 1 ]);
  is $sql, 'SELECT id FROM val WHERE v IS NULL AND id = ?', "$class: no BLOB bind, no change";

  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v = ?', [ v => undef ]);
  is $sql, 'SELECT id FROM val WHERE v = ?', "$class: an undef is no value to cast";

  # a ? in a literal, an identifier or a comment is not a placeholder
  ($sql) = gen($class, 'select',
    q{SELECT 'a?b', "q?" FROM val /* ? */ WHERE v = ? -- ?
      AND 'it''s ?' = 'x'}, [ v => 'x' ]);
  is $sql, qq{SELECT 'a?b', "q?" FROM val /* ? */ WHERE v = $TEXT -- ?\n      AND 'it''s ?' = 'x'},
    "$class: a ? in a string, an identifier or a comment is left alone";

  # core k388: the shared scanner -- a ? in a comment or literal ahead of the
  # BLOB comparison does not move the cast
  ($sql) = gen($class, 'select',
    q{SELECT '?' FROM val /* ? */ WHERE id = ? -- ?
      AND 'a?' = 'a?' AND v = ?}, [ id => 1 ], [ v => 'x' ]);
  is $sql, qq{SELECT '?' FROM val /* ? */ WHERE id = ? -- ?\n      AND 'a?' = 'a?' AND v = $TEXT},
    "$class: a ? in a literal or comment before the comparison does not move the cast";

  # the placeholders cannot be counted: left to the DBD, not guessed
  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v = ? AND x = ?', [ v => 'x' ]);
  is $sql, 'SELECT id FROM val WHERE v = ? AND x = ?', "$class: placeholders and binds that do not match: unchanged";

  ($sql) = gen($class, 'update', 'UPDATE val SET b = ? WHERE v = ?', [ b => 'x' ], [ v => 'y' ]);
  is $sql, 'UPDATE val SET b = ? WHERE v = ?', "$class: UPDATE is not rewritten (the DBD takes the parameter)";

  # limits
  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v = ?', [ v => 'x' x 8191 ]);
  like $sql, qr/\Q$TEXT\E/, "$class: 8191 characters of text are cast";
  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE v = ?', [ v => do { my $s = "\x{20ac}" x 8191; $s } ]);
  like $sql, qr/\Q$TEXT\E/, "... also of three-byte characters";
  ($sql) = gen($class, 'select', 'SELECT id FROM val WHERE b = ?', [ b => 'x' x 32765 ]);
  like $sql, qr/\Q$BIN\E/, "... and 32765 bytes of a binary BLOB";

  for my $case (
    [ 'text',   v => 'x' x 8192,  qr/8191 characters/ ],
    [ 'binary', b => 'x' x 32766, qr/32765 bytes/ ],
  ) {
    my ($label, $col, $value, $limit) = @$case;
    my $ok = eval { gen($class, 'select', "SELECT id FROM val WHERE $col = ?", [ $col => $value ]); 1 };
    my $err = "$@";
    ok !$ok, "$class: a $label value above the VARCHAR limit is refused";
    like $err, qr/refus/i, '... as a refusal';
    like $err, qr/\bval\b/, '... naming the table';
    like $err, qr/\b\Q$col\E\b/, '... and the column';
    like $err, $limit, '... and the limit';
    isa_ok $@, 'DBIO::Exception';
  }
}

{
  my ($sql) = gen('DBIO::Firebird::Storage::ODBC', 'select', 'SELECT id FROM val WHERE v = ?', [ v => 'abc' ]);
  is $sql, 'SELECT id FROM val WHERE v = ?', 'the ODBC storage does not rewrite';
}

done_testing;
