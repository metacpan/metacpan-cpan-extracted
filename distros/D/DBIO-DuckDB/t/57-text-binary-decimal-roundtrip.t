# t/57-text-binary-decimal-roundtrip.t -- karr k49 (Bind conformance): what the
# application writes into a text, binary or decimal column is what it reads
# back, on a plain DBI handle of the storage.
#
# Each assertion is a round trip through the engine. DBD::DuckDB 0.16 binds a
# digit string as a number, a latin-1 string as invalid UTF-8, forgets a bind
# type on execute(@bind), returns VARCHAR as bytes and a DECIMAL through a
# double; none of it with an error on the way in or out.
use strict;
use warnings;
use Test::More;
use DBI ();

use DBIO::DuckDB::Test;

my $schema  = DBIO::DuckDB::Test->init_schema(no_populate => 1);
my $storage = $schema->storage;
my $dbh     = $storage->dbh;

$dbh->do('CREATE TABLE rt (id INTEGER, v VARCHAR, b BLOB, d DECIMAL(20,4), s DECIMAL(5,2))');

my $insert = sub {
  my ($col, $type, $value) = @_;
  my $sth = $dbh->prepare("INSERT INTO rt (id, $col) VALUES (1, ?)");
  $sth->bind_param(1, $value, $type);
  $sth->execute;
};
my $read = sub {
  my ($col) = @_;
  my ($got) = $dbh->selectrow_array("SELECT $col FROM rt");
  $dbh->do('DELETE FROM rt');
  return $got;
};

# text: characters in, the same characters out
for my $text ("\x{fc}", "\x{20ac}", "\x{65e5}\x{672c}", "Gr\x{fc}\x{df}e \x{20ac}", 'plain') {
  $insert->('v', DBI::SQL_VARCHAR(), $text);
  my $got = $read->('v');
  is($got, $text, 'text round-trips as characters: ' . join ' ', map { sprintf 'U+%04X', ord } split //, $text);
}

# the application's own variable is never touched by the encoding
{
  my $text = "caf\x{e9}";
  my $copy = $text;
  $insert->('v', DBI::SQL_VARCHAR(), $text);
  $read->('v');
  is($text, $copy, 'the bound variable is left as it was');
}

# a string that looks like a number stays a string in a text column
for my $v ('01234', '007', '5.0', '1e2', '-0', '1', 'true') {
  $insert->('v', DBI::SQL_VARCHAR(), $v);
  is($read->('v'), $v, "digit-like string '$v' stays what it was");
}

# a bind type given once holds for execute(@bind): the shape of a populate
{
  my $bytes = join '', map { chr } 0 .. 255;
  my $sth = $dbh->prepare('INSERT INTO rt (id, b) VALUES (1, ?)');
  $sth->bind_param(1, 'x', DBI::SQL_BLOB());
  $sth->execute($bytes);
  is($read->('b'), $bytes, 'a BLOB bind type survives execute(@bind)');
}

# BLOB stays bytes; VARCHAR is decoded, also through bind_columns
{
  my $bytes = "\xe2\x82\xac";
  $insert->('b', DBI::SQL_BLOB(), $bytes);
  my $got = $read->('b');
  is($got, $bytes, 'BLOB comes back as the bytes written');
  ok(!utf8::is_utf8($got), '... not decoded');
}
{
  $dbh->do(q{INSERT INTO rt (id, v) VALUES (1, 'x')});
  $dbh->do(q{UPDATE rt SET v = chr(8364)});
  my $sth = $dbh->prepare('SELECT id, v FROM rt');
  $sth->execute;
  my ($id, $v);
  $sth->bind_columns(\($id, $v));
  $sth->fetch;
  is($v, "\x{20ac}", 'a bound column sees characters');
  $dbh->do('DELETE FROM rt');
}

# DECIMAL: exact, beyond what a double holds, either sign, both widths
for my $pair (
  [ d => '1234567890123456.7890' ],
  [ d => '-1234567890123456.7890' ],
  [ d => '9999999999999999.9999' ],
  [ d => '-9999999999999999.9999' ],
  [ d => '0.0001' ],
  [ d => '-0.0001' ],
  [ d => '0.0000' ],
  [ s => '123.45' ],
  [ s => '-0.05' ],
) {
  my ($col, $value) = @$pair;
  $insert->($col, $storage->bind_attribute_by_data_type('decimal'), $value);
  is($read->($col), $value, "decimal $col round-trips: $value");
}

done_testing;
