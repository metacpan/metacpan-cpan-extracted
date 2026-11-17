use strict;
use warnings;
use Test::More;

use DBIO::DB2::Storage::Cursor;

# OFFLINE. The Db2 CLI formats a DECIMAL, REAL, DOUBLE or DECFLOAT by the
# LC_CTYPE the process had at connect time: under de_DE it delivers
# '1234567890,12', which Perl reads as 1234567890. The cursor's decode_rows
# gives such a column its decimal point back, UTF-8 database or not, and
# leaves every other value alone. The live counterpart is t/101.

{
  package Fake::Storage;
  sub new { bless { utf8 => $_[1] }, $_[0] }
  sub _utf8_database { $_[0]{utf8} }
}

sub decode {
  my ($utf8, $types, @row) = @_;
  my $row = [ @row ];
  DBIO::DB2::Storage::Cursor->decode_rows(Fake::Storage->new($utf8), { TYPE => $types }, $row);
  return $row;
}

# type codes: DECIMAL 3, NUMERIC 2, REAL 7, FLOAT 6, DOUBLE 8, DECFLOAT -360
my %value = (
  3    => [ '1234567890,12' => '1234567890.12', '-0,50' => '-0.50', ',5' => '.5', '12,' => '12.' ],
  2    => [ '99,99'         => '99.99' ],
  7    => [ '1,500000E+00'  => '1.500000E+00', '-2,5e-03' => '-2.5e-03' ],
  6    => [ '1,5'           => '1.5' ],
  8    => [ '1,50000000000000E+000' => '1.50000000000000E+000' ],
  -360 => [ '1,25' => '1.25', '1234567890123456,7890' => '1234567890123456.7890' ],
);
for my $type (sort { $a <=> $b } keys %value) {
  my @pairs = @{ $value{$type} };
  while (my ($in, $out) = splice @pairs, 0, 2) {
    for my $utf8 (1, 0) {
      is decode($utf8, [ $type ], $in)->[0], $out,
        "type $type: '$in' -> '$out' (" . ($utf8 ? 'UTF-8' : 'not UTF-8') . ' database)';
    }
  }
}

# untouched
is_deeply decode(1, [ 3, 3, 3, 3 ], '1234567890.12', '12', '1.234,56', '1,2,3'),
  [ '1234567890.12', '12', '1.234,56', '1,2,3' ],
  'no comma, no comma-only form (grouping, two commas): unchanged';
is_deeply decode(1, [ 3, 8 ], undef, undef), [ undef, undef ], 'NULL stays undef';
is_deeply decode(0, [ 12, 1, -1, 3 ], 'a,b', '1,5', '2,5', '3,5'),
  [ 'a,b', '1,5', '2,5', '3.5' ],
  'character columns keep their comma, even when they look like a number';
is_deeply decode(1, [ 4, 5, -5, 12 ], '15,5', '1,5', '1,5', '1,5'),
  [ '15,5', '1,5', '1,5', '1,5' ],
  'INTEGER, SMALLINT, BIGINT and VARCHAR are not touched';
is_deeply decode(1, [ -98 ], '1,5'), [ '1,5' ], 'a BLOB is not touched';

# characters still decode, beside a number, in a UTF-8 database only
my $bytes = do { my $e = "\x{20ac}"; utf8::encode($e); $e };
is_deeply decode(1, [ 12, 3 ], $bytes, '1,5'), [ "\x{20ac}", '1.5' ], 'UTF-8 database: text decoded, number repaired';
is_deeply decode(0, [ 12, 3 ], $bytes, '1,5'), [ $bytes, '1.5' ], 'other database: text as it comes, number repaired';

# several rows, no TYPE
{
  my @rows = ([ '1,5' ], [ '2,5' ]);
  DBIO::DB2::Storage::Cursor->decode_rows(Fake::Storage->new(0), { TYPE => [ 3 ] }, @rows);
  is_deeply \@rows, [ [ '1.5' ], [ '2.5' ] ], 'every given row is repaired';
  @rows = ([ '1,5' ]);
  DBIO::DB2::Storage::Cursor->decode_rows(Fake::Storage->new(1), {}, @rows);
  is_deeply \@rows, [ [ '1,5' ] ], 'no TYPE: nothing happens';
}

done_testing;
