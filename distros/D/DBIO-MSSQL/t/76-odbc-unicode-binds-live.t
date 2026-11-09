use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use DBI;
use Digest::SHA ();
use Encode ();
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE, DBD::ODBC only (karr k58). What a bound string with characters beyond
# the code page of the database arrives as, through a schema that declares
# MSSQL, over DBIO::MSSQL::Storage::ODBC. $ENV{DBIO_TEST_MSSQL_ODBC_DSN},
# _USER and _PASS.
#
# Measured 2026-10-17, SQL Server 2022 16.0.4295.3 (collation
# SQL_Latin1_General_CP1_CI_AS, code page 1252), DBD::ODBC 1.61 -- built
# WITHOUT Unicode support (odbc_has_unicode 0), so a string goes to the
# driver as bytes, and a string with the UTF-8 flag on as its UTF-8 form --
# over the FreeTDS ODBC driver 1.3.17 with ClientCharset UTF-8 (from the
# locale):
#
#   Bound without a type, as it was, a string is a CHAR to the driver and
#   goes through the code page of the server whatever the column is:
#     - CJK, an emoji, anything the code page lacks: refused by the driver
#       ("Error converting characters into server's character set") -- loud,
#       but for an NVARCHAR column the server could have held it, and the
#       connection is unusable afterwards ("Invalid cursor state");
#     - the euro sign, an a-umlaut: stored (both are in code page 1252).
#   Bound as SQL_WLONGVARCHAR the value goes to the server as Unicode and
#   arrives exact, in NCHAR, NVARCHAR, NVARCHAR(MAX) and NTEXT, from one
#   character to 100000, in INSERT, UPDATE and conditions. SQL_WVARCHAR is
#   cut at 4000 characters without an error from NVARCHAR(MAX) on; SQL_WCHAR
#   pads. Into a VARCHAR column a Unicode bind turns what the code page
#   lacks into "?" silently -- which is why the type is chosen by the column
#   and VARCHAR keeps the driver's refusal.
#
#   With a client character set that is NOT UTF-8 (ClientCharset=ISO-8859-1,
#   or a C locale) the driver reads the UTF-8 bytes of the string as another
#   character set: an a-umlaut is stored as "A-tilde" and the currency sign,
#   without a word, with or without a bind type. The storage asks the
#   connection once what it holds for an a-umlaut and REFUSES a string beyond
#   ASCII when that is not one, naming ClientCharset.
#
# What the server holds is looked at from another session, in ASCII.

my ($DSN, $USER, $PASS) = @ENV{ map { "DBIO_TEST_MSSQL_ODBC_$_" } qw/DSN USER PASS/ };

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER and _PASS to run this test'
  unless $DSN and defined $USER and defined $PASS;

plan skip_all => 'DBD::ODBC test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc');

binmode $_, ':encoding(UTF-8)' for map { Test::More->builder->$_ } qw(output failure_output todo_output);

{
  package T::K76::Result::Uni;
  use base 'DBIO::Core';
  __PACKAGE__->table('k76_live_uni');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    tag => { data_type => 'varchar', size => 40, is_nullable => 1 },
    # the table is made by hand with a real VARCHAR(100): declared in the
    # server's spelling (a portable 'varchar' is deployed as NVARCHAR, and
    # bound as Unicode; t/80)
    v   => { data_type => 'varchar(100)', is_nullable => 1 },
    nv  => { data_type => 'nvarchar', size => 100, is_nullable => 1 },
    nvm => { data_type => 'nvarchar', size => -1, is_nullable => 1 },
    nt  => { data_type => 'ntext', is_nullable => 1 },
    nc  => { data_type => 'nchar', size => 10, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K76::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Uni => 'T::K76::Result::Uni');
}

my $admin = DBI->connect($DSN, $USER, $PASS, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$admin->do('SET LOCK_TIMEOUT 10000');

sub fresh_table {
  $admin->do("IF OBJECT_ID('k76_live_uni', 'U') IS NOT NULL DROP TABLE k76_live_uni");
  $admin->do(
    'CREATE TABLE k76_live_uni (id INT IDENTITY PRIMARY KEY, tag VARCHAR(40) NULL,'
  . ' v VARCHAR(100) NULL, nv NVARCHAR(100) NULL, nvm NVARCHAR(MAX) NULL,'
  . ' nt NTEXT NULL, nc NCHAR(10) NULL)'
  );
}
fresh_table();
END { eval { $admin->do("IF OBJECT_ID('k76_live_uni', 'U') IS NOT NULL DROP TABLE k76_live_uni") } if $admin }

# UTF-16LE hex of a string, as the server returns it for an NVARCHAR
sub utf16_hex { uc unpack 'H*', Encode::encode('UTF-16LE', $_[0]) }

# the hex of the UTF-16LE form the server holds for a column of the row(s)
# with a tag; for a value that long, its length and SHA-256 (asked of the
# server, compared with Perl's).
sub holds {
  my ($column, $tag) = @_;
  my $rows = $admin->selectall_arrayref(
    "SELECT DATALENGTH($column), "
  . "CONVERT(VARCHAR(64), HASHBYTES('SHA2_256', CAST(CAST($column AS NVARCHAR(MAX)) AS VARBINARY(MAX))), 2) "
  . "FROM k76_live_uni WHERE tag = '$tag'"
  );
  return 'no row' unless @$rows;
  return @$rows . ' rows' if @$rows > 1;
  return 'NULL' unless defined $rows->[0][0];
  return $rows->[0];
}

# [ DATALENGTH, SHA-256 of the bytes ] a string must be held as
sub expect {
  my $string = shift;
  my $bytes  = Encode::encode('UTF-16LE', $string);
  return [ length $bytes, uc Digest::SHA::sha256_hex($bytes) ];
}

my %VALUE = (
  umlaut => "\x{e4}\x{f6}\x{fc}\x{df}",
  euro   => "\x{20ac}",
  cjk    => "\x{4e2d}\x{6587}\x{65e5}\x{672c}\x{8a9e}",
  emoji  => "\x{1F600}\x{1F4A9}",
  mix    => "a\x{e4}\x{4e2d}\x{1F600}z",
);

my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version/;
};

my $schema = T::K76::Schema->connect($DSN, $USER, $PASS);
my $rs     = $schema->resultset('Uni');
$schema->storage->ensure_connected;

isa_ok $schema->storage, 'DBIO::MSSQL::Storage::ODBC', '(declared MSSQL over a dbi:ODBC: DSN)';

SKIP: {
  skip 'DBD::ODBC is built with Unicode support: no client character set to look at', 1
    if $schema->storage->dbh->{odbc_has_unicode};
  ok 1, "(DBD::ODBC without Unicode support: strings go as bytes, the client character set decides)";
}

my $tag = 0;

# ------------------------------------------------ INSERT, per column and value

for my $column (qw(nv nvm nt)) {
  for my $name (sort keys %VALUE) {
    my $value = $VALUE{$name};
    my $t     = "$column-$name";
    lives_ok { $rs->create({ tag => $t, $column => $value }) }
      "$column: a '$name' value is written";
    is_deeply holds($column, $t), expect($value),
      "$column: ... and the server holds it exact (UTF-16, length and SHA-256)";
  }
}

{
  lives_ok { $rs->create({ tag => 'nc', nc => "\x{4e2d}\x{1F600}" }) }
    'nchar: a CJK value with an emoji is written';
  my ($hex) = $admin->selectrow_array(
    "SELECT CONVERT(VARCHAR(100), CAST(RTRIM(nc) AS VARBINARY(100)), 2) FROM k76_live_uni WHERE tag = 'nc'"
  );
  is $hex, utf16_hex("\x{4e2d}\x{1F600}"), '... exact (padding aside)';
}

# --------------------------------------------------------------- long values

for my $column (qw(nvm nt)) {
  for my $n (4000, 4001, 5000, 100_000) {
    my $value = substr( ("\x{4e2d}\x{1F600}") x ( $n / 2 + 1 ), 0, $n );
    my $t     = "$column-long-$n";
    lives_ok { $rs->create({ tag => $t, $column => $value }) }
      "$column: $n characters beyond the code page are written";
    is_deeply holds($column, $t), expect($value),
      "$column: ... whole (SQL_WVARCHAR cut this at 4000 characters, silently)";
  }
}

# --------------------------------------------------------------- UPDATE, find

{
  my $row = $rs->create({ tag => 'upd', nv => 'first' });
  $row->update({ nv => $VALUE{mix} });
  is_deeply holds(nv => 'upd'), expect($VALUE{mix}), 'UPDATE: exact';

  is $rs->search({ nv => $VALUE{mix} })->count, 2,
    'a condition on an NVARCHAR column finds the rows by a value beyond the code page '
  . '(the updated one and the "nv-mix" row)';
  is $rs->search({ nv => "$VALUE{mix}x" })->count, 0, '... and not by another';
  is $rs->search({ nv => { -like => "a$VALUE{umlaut}%" } })->count, 0,
    '... LIKE with such a value runs';
  my $found = $rs->search({ nvm => $VALUE{cjk} })->count;
  is $found, 1, 'an NVARCHAR(MAX) column too (the CJK row)';
}

# ---------------------------------------------------------------- populate

{
  lives_ok {
    $rs->populate([
      { tag => 'pop-1', nv => $VALUE{cjk},   nvm => $VALUE{emoji} },
      { tag => 'pop-2', nv => $VALUE{umlaut}, nvm => $VALUE{mix} },
    ]);
  } 'populate in void context with such values';
  is_deeply holds(nv  => 'pop-1'), expect($VALUE{cjk}),    '... row 1, nv exact';
  is_deeply holds(nvm => 'pop-1'), expect($VALUE{emoji}),  '... row 1, nvm exact';
  is_deeply holds(nv  => 'pop-2'), expect($VALUE{umlaut}), '... row 2, nv exact';
  is_deeply holds(nvm => 'pop-2'), expect($VALUE{mix}),    '... row 2, nvm exact';

  my @rows = $rs->populate([
    { tag => 'pop-3', nv => $VALUE{emoji} },
  ]);
  is_deeply holds(nv => 'pop-3'), expect($VALUE{emoji}), 'populate in list context: exact';
}

# literal SQL with a typed bind
{
  $rs->create({ tag => 'lit', nv => 'x' });
  my $affected = $schema->storage->dbh_do(sub { 0 });   # keep storage connected
  lives_ok {
    $rs->search({ tag => 'lit' })->update({
      nv => \[ '?', [ { sqlt_datatype => 'nvarchar' } => $VALUE{cjk} ] ],
    });
  } 'a literal with a bind of data type nvarchar';
  is_deeply holds(nv => 'lit'), expect($VALUE{cjk}), '... exact';
}

# ---------------------------------------------------------------- VARCHAR

{
  lives_ok { $rs->create({ tag => 'v-umlaut', v => $VALUE{umlaut} }) }
    'varchar: characters of the code page are written';
  my ($hex) = $admin->selectrow_array(
    "SELECT CONVERT(VARCHAR(100), CAST(v AS VARBINARY(100)), 2) FROM k76_live_uni WHERE tag = 'v-umlaut'"
  );
  is $hex, 'E4F6FCDF', '... as the code page 1252 bytes of them';

  lives_ok { $rs->create({ tag => 'v-euro', v => $VALUE{euro} }) }
    'varchar: the euro sign (code page 1252) is written';
  ($hex) = $admin->selectrow_array(
    "SELECT CONVERT(VARCHAR(100), CAST(v AS VARBINARY(100)), 2) FROM k76_live_uni WHERE tag = 'v-euro'"
  );
  is $hex, '80', '... as 0x80';

  # What the code page lacks does not become "?" in silence: the driver
  # refuses it, no row is written.
  my $secret = "\x{4e2d}\x{6587}";
  my $before = @warnings;
  throws_ok { $rs->create({ tag => 'v-cjk', v => $secret }) }
    qr/character/i,
    'varchar: CJK is refused by the driver (a VARCHAR cannot hold it)';

  # The driver's connection is unusable after such a refusal ("Invalid cursor
  # state"), so the rollback of create()'s transaction fails and core
  # abandons the handle, saying so (core k303).
  my @new = splice @warnings, $before;
  is scalar @new, 1, '... core says, once, that it abandoned the handle';
  like $new[0] // '', qr/Retrying on a new connection/, '...';
  # (core's DBI exception text carries ParamValues of the statement: that is
  # core's, for every error, and not looked at here)
  is holds(v => 'v-cjk'), 'no row', '... no row was written';
}

# the connection a refused value left behind is a new one (the driver's
# "Invalid cursor state" after a refusal): the storage goes on
{
  my $before = @warnings;
  my $row;
  lives_ok { $row = $rs->create({ tag => 'after-refusal', nv => $VALUE{cjk} }) }
    'after a refused value the next statement runs';
  my @new = splice @warnings, $before;
  is scalar @new, 1, '... core says once more that it abandoned the handle (the refusal left it so)';
  like $new[0] // '', qr/Retrying on a new connection/, '...';
  is_deeply holds(nv => 'after-refusal'), expect($VALUE{cjk}), '... and writes exact';
}

# ------------------------------------------------------- the client charset

SKIP: {
  skip 'DBD::ODBC has Unicode support: no client character set to look at', 8
    if $schema->storage->dbh->{odbc_has_unicode};

  # same connection, ClientCharset the driver reads the UTF-8 bytes in
  my $latin = T::K76::Schema->connect("$DSN;ClientCharset=ISO-8859-1", $USER, $PASS);
  my $lrs   = $latin->resultset('Uni');

  lives_ok { $lrs->create({ tag => 'latin-ascii', nv => 'plain ascii', v => 'plain' }) }
    'ClientCharset ISO-8859-1: ASCII is written';
  is_deeply holds(nv => 'latin-ascii'), expect('plain ascii'), '... exact';

  for my $name (qw(umlaut cjk mix)) {
    my $value = $VALUE{$name};
    throws_ok { $lrs->create({ tag => "latin-$name", nv => $value }) }
      qr/ClientCharset/,
      "ClientCharset ISO-8859-1: a '$name' value is REFUSED, naming ClientCharset";
    unlike "$@", qr/\Q$value\E|\Q$PASS\E/, '... without the value or the password';
    is holds(nv => "latin-$name"), 'no row', "... no row (it would have been stored as other characters)";
  }

  throws_ok { $lrs->search({ nv => $VALUE{umlaut} })->count }
    qr/ClientCharset/, '... a condition with such a value as well';

  throws_ok { $lrs->populate([ { tag => 'latin-pop', nv => $VALUE{umlaut} } ]) }
    qr/ClientCharset/, '... populate in void context as well';
  is holds(nv => 'latin-pop'), 'no row', '... nothing written';
}

is_deeply \@warnings, [], 'no warnings';

done_testing;
