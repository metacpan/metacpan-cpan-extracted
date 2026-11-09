use strict;
use warnings;
use utf8;

use Test::More;
use Test::Exception;
use DBI;
use Encode ();
use DBIO::Optional::Dependencies ();
use DBIO::Schema;
use DBIO::MSSQL::Deploy;

# LIVE (karr k47, k58). The type a column has ON THE SERVER decides how its
# value is read and written, not the portable name it is declared with:
# DBIO::MSSQL deploys data_type 'text' as NVARCHAR(MAX) and 'varchar' and
# 'string' as NVARCHAR(n) (DBIO::MSSQL::Adapter, DBIO::MSSQL::DDL). The
# columns of this file are deployed by DBIO (Deploy->install into a database
# of its own); nothing is created by hand, so what the declaration means is
# what the server holds.
#
#   DBD::Sybase   $ENV{DBIO_TEST_MSSQL_DSN}, _USER, _PASS
#   DBD::ODBC     $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER, _PASS
#
# k47, DBD::Sybase: a 'text' column was read as if it were a TEXT, as
# CAST(col AS VARCHAR(MAX)): CJK and emoji arrived as '?', silently, and the
# guard against a value cut at TEXTSIZE counted the bytes of the NVARCHAR(MAX)
# against a VARCHAR(MAX) result. It is read as the NVARCHAR(MAX) it is.
#
# k47, NULL: the guard was a concatenation, col + CASE .. ELSE '' END. Under
# CONCAT_NULL_YIELDS_NULL OFF (a session setting; ON by default, measured
# through dbi:Sybase:) a NULL became ''. The guard is a CASE returning the
# column itself now; a NULL stays NULL whatever the session says.
#
# k58, DBD::ODBC: a value for an NVARCHAR column is bound as SQL_WLONGVARCHAR;
# a 'text' or 'varchar' column is one, and its CJK value was refused by the
# driver (the code page of the database has no such character).

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %WAY;
for my $dbd (keys %ENV_PREFIX) {
  my ($dsn, $user, $pass) = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw/DSN USER PASS/ };
  $WAY{$dbd} = [ $dsn, $user, $pass ] if $dsn and defined $user and defined $pass;
}

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} or $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, '
  . 'with _USER and _PASS, to run this test'
  unless %WAY;

if ($WAY{'DBD::Sybase'}) {
  if (not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase')) {
    diag 'DBD::Sybase is not looked at: test needs '
       . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase');
    delete $WAY{'DBD::Sybase'};
  }
  elsif (not eval { require DBIO::Sybase::Storage; 1 }) {
    die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };
    diag 'DBD::Sybase is not looked at: DBIO::Sybase is not installed';
    delete $WAY{'DBD::Sybase'};
  }
}

if ($WAY{'DBD::ODBC'}
    and not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc')) {
  diag 'DBD::ODBC is not looked at: test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc');
  delete $WAY{'DBD::ODBC'};
}

plan skip_all => 'Neither access path has what it needs installed' unless %WAY;

binmode $_, ':encoding(UTF-8)' for map { Test::More->builder->$_ } qw(output failure_output todo_output);

local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version|_abandon_handle_before_reconnect/;
};

{
  package T::K47::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
}
{
  package T::K47::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->load_components('MSSQL::Result');
  __PACKAGE__->table('k47_doc');
  __PACKAGE__->add_columns(
    id     => { data_type => 'integer' },
    body   => { data_type => 'text', is_nullable => 1 },
    label  => { data_type => 'varchar', size => 100, is_nullable => 1 },
    name   => { data_type => 'string', size => 100, is_nullable => 1 },
    fixed  => { data_type => 'char', size => 10, is_nullable => 1 },
    # the server's own spelling stands: a real VARCHAR(MAX)
    vm     => { data_type => 'varchar(max)', is_nullable => 1 },
    # and a legacy NTEXT
    nt     => { data_type => 'ntext', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}
T::K47::Schema->register_class(Doc => 'T::K47::Result::Doc');

my $CJK   = "\x{4e2d}\x{6587}\x{65e5}\x{672c}\x{8a9e}";
my $EMOJI = "\x{1F600}\x{1F4A9}";
my $MIX   = "a\x{e4}${CJK}${EMOJI}z";

# the value as an NVARCHAR expression of the server, free of any client
# character set: the code points as NCHAR()
sub nchars {
  my $string = shift;
  my @units  = unpack 'v*', Encode::encode('UTF-16LE', $string);
  return join ' + ', map { "NCHAR($_)" } @units;
}

# UTF-16 hex of a string, as the server holds an NVARCHAR
sub utf16_hex { uc unpack 'H*', Encode::encode('UTF-16LE', $_[0]) }

for my $way (sort keys %WAY) {
  my $sybase = $way eq 'DBD::Sybase';
  my ($dsn, $user, $pass) = @{ $WAY{$way} };

  my $db = '_dbio_k47_' . $$ . '_' . time();
  # keep the spelling of the key: DBD::Sybase reads `database=` and ignores
  # `Database=`, which lands on the login's default database
  my $dsn_db = $dsn;
  $dsn_db =~ s/\b((?:database|dbname)=)[^;]*/$1$db/i
    or $dsn_db .= ($sybase ? ';database=' : ';Database=') . $db;

  my $admin = DBI->connect($dsn, $user, $pass, {
    RaiseError => 1, PrintError => 0, AutoCommit => 1,
    ( $sybase ? () : ( LongReadLen => 1_000_000 ) ),
  });
  $admin->do("CREATE DATABASE $db");

  my $ok = eval {
    my $schema = T::K47::Schema->connect($dsn_db, $user, $pass);
    DBIO::MSSQL::Deploy->new(schema => $schema)->install;
    $schema->storage->disconnect;

    my $dbh = DBI->connect($dsn_db, $user, $pass, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
      ( $sybase ? () : ( LongReadLen => 1_000_000 ) ),
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');

    # ---------------------------------------- what DBIO deployed (the premise)
    my %type = map { $_->[0] => "$_->[1]($_->[2])" } @{ $dbh->selectall_arrayref(
      "SELECT c.name, t.name, c.max_length FROM sys.columns c JOIN sys.types t "
    . "ON t.user_type_id = c.user_type_id WHERE c.object_id = OBJECT_ID('k47_doc')"
    ) };
    is_deeply [ @type{qw(body label name fixed vm nt)} ],
      [ 'nvarchar(-1)', 'nvarchar(200)', 'nvarchar(200)', 'nchar(20)', 'varchar(-1)', 'ntext(16)' ],
      "$way: 'text' is deployed as NVARCHAR(MAX), 'varchar' and 'string' as NVARCHAR(n), "
    . "'char' as NCHAR(n); 'varchar(max)' stays a VARCHAR(MAX)";

    $dbh->do('INSERT INTO k47_doc (id) VALUES (3)');    # all NULL
    $dbh->do("INSERT INTO k47_doc (id, body, vm, nt) VALUES (4, N'', '', N'')");
    $dbh->do(
      "INSERT INTO k47_doc (id, body, label, name, nt) VALUES (5, "
    . nchars($MIX) . ', ' . nchars($CJK) . ', ' . nchars($EMOJI) . ', ' . nchars($MIX) . ')'
    );
    $dbh->do("INSERT INTO k47_doc (id, vm) VALUES (6, 'plain ascii')");
    $dbh->do(
      "INSERT INTO k47_doc (id, body) VALUES (7, REPLICATE(CAST(N'x' AS NVARCHAR(MAX)), 20000))"
    );
    # 8000 characters (16000 bytes), exactly TEXTSIZE bytes (16384 characters of
    # an NVARCHAR(MAX)), one character more
    for my $case ([ 8, 8000 ], [ 9, 16384 ], [ 10, 16385 ]) {
      $dbh->do(
        "INSERT INTO k47_doc (id, body) VALUES ($case->[0], "
      . "REPLICATE(CAST(N'y' AS NVARCHAR(MAX)), $case->[1]))"
      );
    }
    $dbh->do("INSERT INTO k47_doc (id, body) VALUES (11, REPLICATE(CAST(" . nchars($CJK) . " AS NVARCHAR(MAX)), 3000))");

    if ($sybase) {
      # ================================================ k47: DBD::Sybase

      my $reading = T::K47::Schema->connect($dsn_db, $user, $pass);
      $reading->storage->ensure_connected;
      isa_ok $reading->storage, 'DBIO::MSSQL::Storage::Sybase', "$way: (the storage)";
      my $rs = $reading->resultset('Doc');

      my ($textsize, $concat) = $reading->storage->dbh->selectrow_array(
        "SELECT \@\@TEXTSIZE, SESSIONPROPERTY('CONCAT_NULL_YIELDS_NULL')"
      );
      is $textsize, 32768, "$way: (TEXTSIZE is 32768, the default)";
      is $concat, 1, "$way: CONCAT_NULL_YIELDS_NULL is ON on a fresh session over dbi:Sybase:";

      # the value comes back as the characters it was written as (DBD::Sybase
      # hands over the UTF-8 bytes of the client character set; decoded for
      # the comparison), not as '?'
      my $read = sub {
        my $value = shift;
        return $value unless defined $value;
        return utf8::is_utf8($value) ? $value : Encode::decode('UTF-8', $value, Encode::FB_CROAK);
      };

      my $row = $rs->find(5);
      is $read->($row->get_column('body')), $MIX,
        "$way: 'text' column: CJK and emoji come back unchanged (they came back as '?')";
      is $read->($row->get_column('label')), $CJK, "$way: 'varchar' column (NVARCHAR(100)): CJK unchanged";
      is $read->($row->get_column('name')),  $EMOJI, "$way: 'string' column: emoji unchanged";
      is $read->($row->get_column('nt')),    $MIX, "$way: ntext column: unchanged";

      # 3000 x 5 CJK characters: 15000 characters, 30000 bytes of UTF-16
      is $read->($rs->find(11)->get_column('body')), $CJK x 3000,
        "$way: 15000 CJK characters are read whole";

      # NULL and empty
      my $null = $rs->find(3);
      is_deeply [ map { $null->get_column($_) } qw(body label vm nt) ], [ (undef) x 4 ],
        "$way: NULL is NULL in an NVARCHAR(MAX), an NVARCHAR(100), a VARCHAR(MAX) and an NTEXT";
      my $empty = $rs->find(4);
      is_deeply [ map { $empty->get_column($_) } qw(body vm nt) ], [ ('') x 3 ],
        "$way: an empty value is empty";
      is $rs->find(6)->get_column('vm'), 'plain ascii', "$way: a VARCHAR(MAX) value is read";

      # the size: TEXTSIZE counts the bytes of the NVARCHAR(MAX) (two per
      # character), and a value over it is refused, never cut
      is $rs->find(8)->get_column('body'), 'y' x 8000, "$way: 8000 characters (16000 bytes) are read whole";
      is $rs->find(9)->get_column('body'), 'y' x 16384,
        "$way: 16384 characters, exactly TEXTSIZE bytes, are read whole";
      for my $id (10, 7) {
        throws_ok { $rs->find($id) }
          qr/\Qthe column 'me.body' holds a value longer than the TEXTSIZE of the session, 32768 bytes\E/,
          "$way: a value of more than 16384 characters is REFUSED under the default TEXTSIZE, not cut (id $id)";
      }

      # ... and read whole when the session is told it may be that long
      {
        my $wide = T::K47::Schema->connect($dsn_db, $user, $pass, { LongReadLen => 100_000 });
        is $wide->resultset('Doc')->find(7)->get_column('body'), 'x' x 20000,
          "$way: LongReadLen 100000: 20000 characters are read whole";
      }

      # CONCAT_NULL_YIELDS_NULL OFF must not turn a NULL into ''
      {
        my $off = T::K47::Schema->connect($dsn_db, $user, $pass, {
          on_connect_do => [ 'SET CONCAT_NULL_YIELDS_NULL OFF' ],
        });
        my ($now) = $off->storage->dbh_do(sub {
          ($_[1]->selectrow_array("SELECT SESSIONPROPERTY('CONCAT_NULL_YIELDS_NULL')"))[0];
        });
        is $now, 0, "$way: (the session has CONCAT_NULL_YIELDS_NULL OFF)";
        my $n = $off->resultset('Doc')->find(3);
        is_deeply [ map { $n->get_column($_) } qw(body label vm nt) ], [ (undef) x 4 ],
          "$way: ... and a NULL is still NULL in every kind of LOB column";
        is $off->resultset('Doc')->find(4)->get_column('vm'), '', "$way: ... an empty value is empty";
        is $off->resultset('Doc')->find(6)->get_column('vm'), 'plain ascii', "$way: ... a value is whole";
      }
    }
    else {
      # ================================================= k58: DBD::ODBC

      my $writing = T::K47::Schema->connect($dsn_db, $user, $pass);
      $writing->storage->ensure_connected;
      isa_ok $writing->storage, 'DBIO::MSSQL::Storage::ODBC', "$way: (the storage)";
      my $rs = $writing->resultset('Doc');

      # what the server holds, from the plain handle
      my $holds = sub {
        my ($column, $id) = @_;
        my ($hex) = $dbh->selectrow_array(
          "SELECT CONVERT(VARCHAR(MAX), CAST(RTRIM(CAST($column AS NVARCHAR(MAX))) AS VARBINARY(MAX)), 2) FROM k47_doc WHERE id = $id"
        );
        return $hex;
      };

      my $id = 100;
      for my $case (
        [ body => 'text' ], [ label => 'varchar' ], [ name => 'string' ], [ nt => 'ntext' ],
      ) {
        my ($column, $declared) = @$case;
        for my $value ($CJK, $EMOJI, $MIX) {
          $id++;
          lives_ok { $rs->create({ id => $id, $column => $value }) }
            "$way: a CJK / emoji value is written to the '$declared' column ($column)";
          is $holds->($column, $id), utf16_hex($value), "$way: ... and the server holds it exact";
        }
      }

      $id++;
      lives_ok { $rs->create({ id => $id, fixed => $CJK }) } "$way: ... to the 'char' column (NCHAR)";
      is $holds->('fixed', $id), utf16_hex($CJK), "$way: ... exact";

      # find by such a value
      is $rs->search({ body => $CJK })->count, 1, "$way: a condition on the 'text' column with CJK finds its row";
      is $rs->search({ id => { ">" => 100 }, label => { -like => "$CJK%" } })->count, 1, "$way: ... LIKE on the 'varchar' column";

      # reading: what the DBD hands back are the UTF-8 bytes of the value
      my $row = $rs->search({ body => $CJK })->single;
      my $got = $row->get_column('body');
      $got = Encode::decode('UTF-8', $got, Encode::FB_CROAK) unless utf8::is_utf8($got);
      is $got, $CJK, "$way: ... and reads back unchanged";

      # a real VARCHAR(MAX) is not national: it keeps the driver's refusal
      # of what the code page lacks
      $id++;
      throws_ok { $rs->create({ id => $id, vm => $CJK }) } qr/./,
        "$way: 'varchar(max)' (a real VARCHAR) keeps the driver's refusal of what the code page lacks";
      lives_ok { $rs->create({ id => ++$id, vm => 'ascii' }) } "$way: ... ASCII goes in";
    }

    $dbh->disconnect;
    1;
  };
  my $err = $@;
  eval { $admin->do("DROP DATABASE $db"); 1 } or diag "could not drop $db: $@";
  $admin->disconnect;
  die $err unless $ok;
}

done_testing;
