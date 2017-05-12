# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More 0.96;
use DBIx::RoboQuery::Util ();
*order_from_sql = \&DBIx::RoboQuery::Util::order_from_sql;

my @order = (
  [
    'SELECT * FROM table ORDER BY field',
    [qw(field)]
  ],
  [
    'SELECT * FROM table ORDER BY field;',
    [qw(field)]
  ],
  [
    "SELECT * FROM table\nORDER BY field\n;",
    [qw(field)]
  ],
  [
    'SELECT * FROM table ORDER BY field FETCH 1 ROW',
    [qw(field)],
    {suffix => 'FETCH 1 ROW'}
  ],
  [
    "SELECT * FROM table\nORDER BY field\nFETCH 1 ROW;",
    [qw(field)],
    {suffix => 'FETCH 1 ROW'}
  ],
  [
    'SELECT * FROM table ORDER BY field FETCH 1 ROW',
    [qw(field)],
    {suffix => qr'FETCH \d+ ROWS?'}
  ],
  [
    'SELECT * FROM table ORDER BY field FETCH 12 ROWS',
    [qw(field)],
    {suffix => qr'FETCH \d+ ROWS?'}
  ],
  [
    'SELECT * FROM table ORDER BY fld1, fld2',
    [qw(fld1 fld2)]
  ],
  [
    "SELECT * FROM table ORDER BY fld1, fld2\nLIMIT 2",
    [qw(fld1 fld2)],
    {suffix => 'LIMIT 2'}
  ],
  [
    "SELECT * FROM table\nORDER BY\nfld1,\nfld2\nLIMIT\n2",
    [qw(fld1 fld2)],
    {suffix => qr/LIMIT\s+   \d+/x}
  ],
  [
    "SELECT * FROM table\nORDER BY\nfldA DESC,\nfld2 ASC, fldD\nLIMIT\n2",
    [qw(fldA fld2 fldD)],
    {suffix => qr/LIMIT\s+   \d+/x}
  ],
  # TODO: "SELECT * FROM table WHERE order_clause = 'ORDER BY something' ORDER BY order_clause"
);

foreach my $order ( @order ){
  my ($sql, $columns, $opts) = @$order;
  is_deeply([order_from_sql($sql, $opts||{})], $columns, "sql column order guess: $sql");
}

done_testing;
