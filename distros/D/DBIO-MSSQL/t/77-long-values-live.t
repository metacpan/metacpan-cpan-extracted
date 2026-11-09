use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use File::Temp ();
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE (karr k47, k59, k60, k61). Reading a LOB column through a schema that
# declares MSSQL, over each access path that has a server to talk to:
#
#   DBD::Sybase   $ENV{DBIO_TEST_MSSQL_DSN}, _USER, _PASS
#   DBD::ODBC     $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER, _PASS
#
# Measured 2026-10-17, SQL Server 2022 16.0.4295.3, DBD::Sybase 1.27 / FreeTDS
# 1.3.17, DBD::ODBC 1.61 / tdsodbc 1.3.17.
#
# k47 -- DBD::Sybase. FreeTDS' class sets SET TEXTSIZE from LongReadLen (32768
#   bytes unless the connect info says otherwise). The server cuts a longer
#   value of a TEXT, NTEXT, IMAGE, VARCHAR(MAX), NVARCHAR(MAX) or
#   VARBINARY(MAX) column on its way back, WITHOUT AN ERROR, exactly at
#   TEXTSIZE bytes: 32768 characters of a VARCHAR(MAX), 16384 of an
#   NVARCHAR(MAX). Sized VARCHAR(n) and the XML type are not subject to it.
#   The table has the types DBIO deploys for its declarations: 't' ('text') is
#   an NVARCHAR(MAX), 'vm' is declared 'varchar(max)', the server's own
#   spelling, to be a VARCHAR(MAX) (a portable 'varchar' of size -1 is an
#   NVARCHAR(MAX) too; t/80 deploys and reads through DBIO itself).
#   The storage asks for such a column behind a server-side check
#   (DATALENGTH(col) > @@TEXTSIZE fails), so a value that does not fit is
#   REFUSED, exactly: one of TEXTSIZE bytes is whole, one byte more throws.
#   Raising LongReadLen reads it whole.
#
# k59 -- DBD::Sybase drops, without an error, the row whose fetch fails
#   (CS_ROW_FAIL): a SQL_VARIANT column (described as a CHAR of 8009) with a
#   binary base type; an IMAGE read as hex digits above TEXTSIZE/2 bytes; a
#   VARBINARY(MAX) read on the handle directly. The first is refused here;
#   the other two are pinned as limits (below), upstream draft:
#   maint/upstream/dbd-sybase-row-fail.md.
#
# k60 -- the client library fills the whole buffer (TEXTSIZE times 1, 2 or 4)
#   for an EMPTY value of an IMAGE, NTEXT or TEXT column. TEXT and NTEXT are
#   read as VARCHAR(MAX) / NVARCHAR(MAX) behind the guard, which costs nothing;
#   a binary column is an IMAGE (karr k56) and keeps the price.
#
# k61 -- DBD::ODBC reads every LOB type up to LongReadLen (DBI's default is
#   80) and throws beyond ("long truncated"): loud, no silent loss, and no
#   memory price for a large LongReadLen.

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

my %STORAGE = (
  'DBD::Sybase' => 'DBIO::MSSQL::Storage::Sybase',
  'DBD::ODBC'   => 'DBIO::MSSQL::Storage::ODBC',
);

local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version/;
};

{
  package T::K77::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k77_lob');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    t     => { data_type => 'text', is_nullable => 1 },
    nt    => { data_type => 'ntext', is_nullable => 1 },
    vm    => { data_type => 'varchar(max)', is_nullable => 1 },
    nvm   => { data_type => 'nvarchar', size => -1, is_nullable => 1 },
    im    => { data_type => 'image', is_nullable => 1 },
    vb    => { data_type => 'varbinary', size => -1, is_nullable => 1 },
    vbs   => { data_type => 'varbinary', size => 100, is_nullable => 1 },
    small => { data_type => 'varchar', size => 100, is_nullable => 1 },
    doc   => { data_type => 'xml', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  # the SQL_VARIANT column of the same table, apart: reading it is refused
  package T::K77::Result::Variant;
  use base 'DBIO::Core';
  __PACKAGE__->table('k77_lob');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    sv => { data_type => 'sql_variant', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K77::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Lob     => 'T::K77::Result::Lob');
  __PACKAGE__->register_class(Variant => 'T::K77::Result::Variant');
}

my %ADMIN;
sub admin {
  my $way = shift;
  return $ADMIN{$way} ||= do {
    my $dbh = DBI->connect(@{ $WAY{$way} }, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
      ( $way eq 'DBD::ODBC' ? ( LongReadLen => 1_000_000 ) : () ),
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $dbh;
  };
}

sub fresh_table {
  my $way = shift;
  admin($way)->do("IF OBJECT_ID('k77_lob', 'U') IS NOT NULL DROP TABLE k77_lob");
  admin($way)->do(
    'CREATE TABLE k77_lob (id INT PRIMARY KEY, t NVARCHAR(MAX) NULL, nt NTEXT NULL,'
  . ' vm VARCHAR(MAX) NULL, nvm NVARCHAR(MAX) NULL, im IMAGE NULL,'
  . ' vb VARBINARY(MAX) NULL, vbs VARBINARY(100) NULL, small VARCHAR(100) NULL,'
  . ' doc XML NULL, sv SQL_VARIANT NULL)'
  );
}
END { for my $way (keys %ADMIN) { eval { $ADMIN{$way}->do("IF OBJECT_ID('k77_lob', 'U') IS NOT NULL DROP TABLE k77_lob") } } }

# the value a column is given for N units, and what it reads back as
my %FILL = (
  t   => { sql => sub { "REPLICATE(CAST('a' AS VARCHAR(MAX)), $_[0])" },  char => 'a' },
  nt  => { sql => sub { "REPLICATE(CAST(N'b' AS NVARCHAR(MAX)), $_[0])" }, char => 'b' },
  vm  => { sql => sub { "REPLICATE(CAST('c' AS VARCHAR(MAX)), $_[0])" },  char => 'c' },
  nvm => { sql => sub { "REPLICATE(CAST(N'd' AS NVARCHAR(MAX)), $_[0])" }, char => 'd' },
  im  => { sql => sub { "CAST(CAST(REPLICATE(CAST('e' AS VARCHAR(MAX)), $_[0]) AS VARBINARY(MAX)) AS IMAGE)" }, char => 'e' },
  vb  => { sql => sub { "CAST(REPLICATE(CAST('f' AS VARCHAR(MAX)), $_[0]) AS VARBINARY(MAX))" }, char => 'f' },
);

# What the session's TEXTSIZE (bytes) lets through, in the units of a column:
# a national column holds two bytes per character
sub limit_of { my ($column, $textsize) = @_; $column =~ /\A(?:t|nt|nvm)\z/ ? $textsize / 2 : $textsize }

sub put {
  my ($way, $id, $column, $units) = @_;
  admin($way)->do("INSERT INTO k77_lob (id, $column) VALUES ($id, " . $FILL{$column}{sql}->($units) . ')');
}

# the memory a child process needs for a read, in MB of peak (VmHWM)
sub peak_mb {
  my ($way, $long_read_len, $column, $id) = @_;

  return undef unless -r '/proc/self/status';

  my $script = File::Temp->new(SUFFIX => '.pl');
  print {$script} <<'CHILD';
use strict; use warnings;
use DBIO::Schema;
{ package T::K77C::Result::Lob; use base 'DBIO::Core'; __PACKAGE__->table('k77_lob');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer' },
    t  => { data_type => 'text', is_nullable => 1 },
    nt => { data_type => 'ntext', is_nullable => 1 },
    vm => { data_type => 'varchar(max)', is_nullable => 1 },
    nvm => { data_type => 'nvarchar', size => -1, is_nullable => 1 },
    im => { data_type => 'image', is_nullable => 1 },
    vb => { data_type => 'varbinary', size => -1, is_nullable => 1 });
  __PACKAGE__->set_primary_key('id'); }
{ package T::K77C::Schema; use base 'DBIO::Schema'; __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Lob => 'T::K77C::Result::Lob'); }
sub hwm { open my $f, '<', '/proc/self/status' or return 0; while (<$f>) { return $1 / 1024 if /^VmHWM:\s+(\d+)/ } 0 }
local $SIG{__WARN__} = sub {};
my ($dsn, $user, $pass, $lrl, $column, $id) = @ARGV;
my $schema = T::K77C::Schema->connect($dsn, $user, $pass, { LongReadLen => $lrl });
$schema->storage->ensure_connected;
my $before = hwm();
my $row = $schema->resultset('Lob')->search({ id => $id }, { columns => [ 'id', $column ] })->single;
printf "%.1f\n", hwm() - $before if $row;
CHILD
  close $script;

  my $file = $script->filename;
  my ($dsn, $user, $pass) = @{ $WAY{$way} };
  my $out  = qx{$^X -Ilib $file '$dsn' '$user' '$pass' $long_read_len $column $id 2>/dev/null};
  return undef unless defined $out and $out =~ /\A([\d.]+)\s*\z/;
  return $1;
}

for my $way (sort keys %WAY) {
  my $sybase = $way eq 'DBD::Sybase';

  fresh_table($way);

  my $schema = T::K77::Schema->connect(@{ $WAY{$way} });
  $schema->storage->ensure_connected;
  isa_ok $schema->storage, $STORAGE{$way}, "$way: (the storage of a schema that declares MSSQL)";

  my $rs = $schema->resultset('Lob');

  if ($sybase) {
    # ===================================================== k47: the guard

    my $textsize = $schema->storage->dbh->selectrow_array('SELECT @@TEXTSIZE');
    is $textsize, 32768, "$way: (TEXTSIZE is LongReadLen of the connect info, 32768 by default)";

    my $id = 0;
    for my $column (qw(t nt vm nvm im vb)) {
      my $limit = limit_of($column, $textsize);
      my $char  = $FILL{$column}{char};

      my ($small, $edge, $over, $far) = map { ++$id } 1 .. 4;
      put($way, $small, $column, 100);
      put($way, $edge,  $column, $limit);
      put($way, $over,  $column, $limit + 1);
      put($way, $far,   $column, 100_000);

      is $rs->find($small)->get_column($column), $char x 100, "$way: $column: a short value is read";

      # exactly the limit is whole
      my $value;
      lives_ok { $value = $rs->find($edge)->get_column($column) }
        "$way: $column: a value of exactly TEXTSIZE bytes ($limit units) is read";
      ok defined $value && $value eq $char x $limit,
        "$way: ... whole" or diag "$column: " . ( defined $value ? 'got ' . length($value) . ' units, first 10: ' . substr($value, 0, 10) . ', last: ' . unpack('H*', substr($value, -3)) : 'undef' );

      # one unit more is refused, not cut
      for my $victim ($over, $far) {
        throws_ok { $rs->find($victim) }
          qr/\QCannot read this result through DBD::Sybase: the column 'me.$column' holds a value longer than the TEXTSIZE of the session, 32768 bytes\E/,
          "$way: $column: a value over TEXTSIZE is REFUSED, naming the column and the size (id $victim)";
      }
      like "$@", qr/LongReadLen/, "$way: ... and the way out";
    }

    # every way of reading goes through the guard
    my $over_t = 3;    # t: limit + 1
    throws_ok { $rs->search({ id => $over_t })->single } qr/the column 'me\.t' holds/,
      "$way: single(): refused";
    throws_ok { $rs->search({ id => $over_t })->first } qr/the column 'me\.t' holds/,
      "$way: first(): refused";
    throws_ok { $rs->search({ id => $over_t })->all } qr/the column 'me\.t' holds/,
      "$way: all(): refused";
    throws_ok { my $c = $rs->search({ id => $over_t }); $c->next }
      qr/the column 'me\.t' holds/, "$way: next(): refused";
    throws_ok { $rs->search({ id => $over_t })->get_column('t')->all }
      qr/the column 'me\.t' holds/, "$way: get_column()->all: refused";
    throws_ok {
      $rs->search({ id => $over_t })->search({}, { result_class => 'DBIO::ResultClass::HashRefInflator' })->all
    } qr/the column 'me\.t' holds/, "$way: the hashref inflator: refused";
    throws_ok { $rs->search({ id => $over_t }, { rows => 1, offset => 0, order_by => 'id' })->all }
      qr/the column 'me\.t' holds/, "$way: under rows: refused";

    # a failure half way through a result: the rows before are not delivered as
    # if the result was whole
    throws_ok { $rs->search({ id => [ 1, $over_t, 5 ] }, { order_by => 'id' })->all }
      qr/the column 'me\.t' holds/, "$way: a long value among others: the whole read is refused";

    # NULL and empty values are not long
    admin($way)->do("INSERT INTO k77_lob (id, t, vm, im) VALUES (900, '', '', 0x)");
    admin($way)->do('INSERT INTO k77_lob (id) VALUES (901)');
    {
      my $empty = $rs->find(900);
      is_deeply [ map { $empty->get_column($_) } qw(t vm im) ], [ '', '', '' ],
        "$way: empty values are read as empty";
      is $rs->find(901)->get_column('t'), undef, "$way: NULL is NULL";
    }

    # sized VARCHAR(n) and XML are not subject to TEXTSIZE
    admin($way)->do("INSERT INTO k77_lob (id, small, doc) VALUES (902, REPLICATE('x', 100), "
      . "CAST('<a>' + REPLICATE(CAST('y' AS VARCHAR(MAX)), 50000) + '</a>' AS XML))");
    {
      my $row = $rs->find(902);
      is length $row->small, 100, "$way: VARCHAR(100) is read whole";
      is length $row->doc, 50007, "$way: an XML value of 50007 characters is read whole (TEXTSIZE does not apply)";
    }

    # LongReadLen is the regulator
    {
      my $wide = T::K77::Schema->connect(@{ $WAY{$way} }, { LongReadLen => 200_000 });
      $wide->storage->ensure_connected;
      is $wide->storage->dbh->selectrow_array('SELECT @@TEXTSIZE'), 200_000,
        "$way: LongReadLen => 200000: TEXTSIZE is 200000";
      my $wrs = $wide->resultset('Lob');
      for my $column (qw(t nt vm nvm im vb)) {
        my $far = { t => 4, nt => 8, vm => 12, nvm => 16, im => 20, vb => 24 }->{$column};
        my $v = $wrs->find($far)->get_column($column);
        ok defined $v && $v eq $FILL{$column}{char} x 100_000,
          "$way: $column: with LongReadLen 200000 the 100000-unit value is read whole";
      }
      # and too short a LongReadLen for a binary column of a sized type
      admin($way)->do("INSERT INTO k77_lob (id, vbs) VALUES (903, CAST(REPLICATE('z', 100) AS VARBINARY(100)))");
      is $wrs->find(903)->get_column('vbs'), 'z' x 100, "$way: VARBINARY(100) is read as its bytes";

      my $tiny = T::K77::Schema->connect(@{ $WAY{$way} }, { LongReadLen => 50 });
      throws_ok { $tiny->resultset('Lob')->find(903) }
        qr/the column 'me\.vbs' holds a value longer than the TEXTSIZE of the session, 50 bytes/,
        "$way: a sized binary column is read as an IMAGE, so TEXTSIZE applies to it: refused, not cut";
    }

    # ---- what the guard does not reach (documented limits) -------------------

    {
      my $far = 4;    # t, 100000 units
      my $cut = $schema->storage->dbh_do(sub {
        ($_[1]->selectrow_array('SELECT t FROM k77_lob WHERE id = ?', undef, $far))[0];
      });
      is length $cut, 16384,
        "$way: LIMIT: on the handle directly (dbh_do) a value over TEXTSIZE is cut to it "
      . '(32768 bytes: 16384 characters of the NVARCHAR(MAX) a text column is), without an error';

      my $literal = $rs->search({ id => $far }, { select => [ \'me.t' ], as => ['t'] })->single;
      is length $literal->get_column('t'), 16384,
        "$way: LIMIT: a column in literal SQL is cut to TEXTSIZE, without an error";
    }

    # ============================================ k59: what DBD::Sybase drops

    # SQL_VARIANT: refused
    admin($way)->do("INSERT INTO k77_lob (id, sv) VALUES (910, 42)");
    admin($way)->do("INSERT INTO k77_lob (id, sv) VALUES (911, 'hello')");
    admin($way)->do("INSERT INTO k77_lob (id, sv) VALUES (912, 0x0102)");
    {
      my $variants = $schema->resultset('Variant');

      throws_ok { $variants->find(910) }
        qr/\QCannot read this result through DBD::Sybase: its column 2 ('sv') is SQL_VARIANT\E/,
        "$way: a SQL_VARIANT column is refused, even for a value that would have read";
      throws_ok { $variants->find(912) } qr/is SQL_VARIANT/,
        "$way: ... and for one that DBD::Sybase would have dropped without an error";

      # (measured on the handle: the row of 912 is not there, alone or first)
      my $raw = $schema->storage->dbh_do(sub {
        my $sth = $_[1]->prepare('SELECT id, sv FROM k77_lob WHERE id = 912');
        $sth->execute;
        [ $sth->fetchrow_array ];
      });
      is_deeply $raw, [], "$way: (without the refusal that row is silently not there)";

      # the ways out the message names
      my $cast = $schema->storage->dbh_do(sub {
        $_[1]->selectall_arrayref(
          'SELECT id, CONVERT(VARCHAR(8000), sv), '
        . "SQL_VARIANT_PROPERTY(sv, 'BaseType') FROM k77_lob WHERE id IN (910, 911) ORDER BY id"
        );
      });
      is_deeply $cast, [
        [ 910, '42', 'int' ],
        [ 911, 'hello', 'varchar' ],
      ], "$way: CONVERT(VARCHAR(8000), sv) reads a variant of a text or number type";
      # a binary variant: only the second form
      my $hex = $variants->search({ id => 912 }, { select => [ \'CONVERT(VARCHAR(MAX), CONVERT(VARBINARY(8000), me.sv), 2)' ], as => ['hex'] })
        ->single;
      is $hex->get_column('hex'), '0102', "$way: the hex digits of a binary variant, via the second form";
    }

    # IMAGE as hex digits above TEXTSIZE/2: the row is dropped (limit)
    {
      my $half = $textsize / 2;
      put($way, 920, 'im', $half);
      put($way, 921, 'im', $half + 1);
      my $hex_len = sub {
        my $id = shift;
        $schema->storage->dbh_do(sub {
          my $sth = $_[1]->prepare("SELECT im FROM k77_lob WHERE id = $id");
          $sth->execute;
          my @row = $sth->fetchrow_array;
          return @row ? length $row[0] : 'no row';
        });
      };
      is $hex_len->(920), $half * 2, "$way: LIMIT: an IMAGE of TEXTSIZE/2 bytes on the handle: its hex digits, whole";
      is $hex_len->(921), 'no row',
        "$way: LIMIT: one byte more: NO ROW, and no error (DBD::Sybase drops the row whose fetch fails; "
      . 'maint/upstream/dbd-sybase-row-fail.md)';
    }

    # VARBINARY(MAX) on the handle: no row (limit; the storage rewrites it)
    {
      put($way, 922, 'vb', 1);
      my $row = $schema->storage->dbh_do(sub {
        my $sth = $_[1]->prepare('SELECT id, vb FROM k77_lob WHERE id = 922');
        $sth->execute;
        [ $sth->fetchrow_array ];
      });
      is_deeply $row, [], "$way: LIMIT: a VARBINARY(MAX) value on the handle: no row, no error";
      is $rs->find(922)->get_column('vb'), 'f', "$way: ... through the storage it is read";
    }

    # ---- other types (k59 item 4): measured, nothing to do ------------------

    {
      admin($way)->do("INSERT INTO k77_lob (id, small) VALUES (930, NULL)");
      my $got = $schema->storage->dbh_do(sub {
        $_[1]->selectrow_arrayref(
          'SELECT CAST(12345678901234567890.1234567890 AS DECIMAL(38,10)), '
        . 'CAST(99999999999999999999999999999999999999 AS DECIMAL(38,0)), '
        . "CAST('2020-01-02 03:04:05.1234567' AS DATETIME2(7)), "
        . "CAST('12:34:56.1234567' AS TIME(7)), CAST(1 AS BIT), CAST(1.5 AS MONEY)"
        );
      });
      ok $got && $got->[0] eq '12345678901234567890.1234567890' && $got->[1] eq '99999999999999999999999999999999999999',
        "$way: DECIMAL(38,10) and DECIMAL(38,0) at 38 digits are read exactly";
    }

    for my $expression ('hierarchyid::GetRoot()', 'geography::Point(1, 1, 4326)', 'geometry::Point(1, 1, 0)') {
      # DBD::Sybase warns "ct_describe() failed" and the execute returns false
      # without an error of the DBI: on the handle that is a result of no rows;
      # the storage takes an execute that returned false for an error.
      local $SIG{__WARN__} = sub { warn $_[0] unless $_[0] =~ /ct_describe\(\) failed/ };
      throws_ok {
        $rs->search({}, { select => [ \$expression ], as => ['v'] })->single;
      } qr/execute\(\) returned false/,
        "$way: $expression is refused loudly (the client library cannot describe a CLR type)";
    }

    # ================================================ k60: the memory price

    SKIP: {
      skip 'no /proc/self/status', 6 unless -r '/proc/self/status';
      admin($way)->do("INSERT INTO k77_lob (id, t, nt, vm, nvm, im, vb) VALUES (940, '', N'', '', N'', 0x, 0x)");

      my $LRL = 50_000_000;
      my %peak = map { $_ => peak_mb($way, $LRL, $_, 940) } qw(t nt vm nvm im vb);

      for my $column (qw(t nt vm nvm)) {
        cmp_ok $peak{$column} // 1e9, '<', 20,
          "$way: $column: an EMPTY value costs no memory at LongReadLen 50000000 "
        . "(read behind the guard as a VARCHAR(MAX); measured $peak{$column} MB; "
        . 'plain DBI: 190 MB for a TEXT, 95 MB for an NTEXT)';
      }
      for my $column (qw(im vb)) {
        # documented limit: a binary column is an IMAGE, and the client library
        # fills the whole buffer of an empty IMAGE
        cmp_ok $peak{$column} // 0, '>', 30,
          "$way: LIMIT: an EMPTY binary value costs about LongReadLen bytes of memory "
        . "(measured $peak{$column} MB at 50000000)";
      }
    }
  }
  else {
    # ======================================================= k61: DBD::ODBC
    #
    # DBI's LongReadLen is 80; the ODBC class takes 1073741824 unless the
    # connect info says otherwise (a large one costs nothing here). With the
    # default every size reads whole; with a small explicit one the fetch
    # throws beyond it -- and at the boundary DBD::ODBC 1.61 hands back a
    # value with its last character replaced by a NUL, without an error.

    my $LONG = 1_073_741_824;
    is $schema->storage->dbh->{LongReadLen}, $LONG,
      "$way: LongReadLen is $LONG unless the connect info says otherwise";

    my $explicit = T::K77::Schema->connect(@{ $WAY{$way} }, { LongReadLen => 80 });
    my $ers      = $explicit->resultset('Lob');
    is $explicit->storage->dbh->{LongReadLen}, 80, "$way: ... and the connect info's LongReadLen wins";

    my $id = 0;
    for my $column (qw(t nt vm nvm im vb)) {
      my $char = $FILL{$column}{char};
      my $binary = $column =~ /\A(?:im|vb)\z/;

      # the sizes the default must read whole
      for my $n (1, 80, 81, 82, 32768, 32769, 100_000) {
        put($way, ++$id, $column, $n);
        my $value;
        lives_ok { $value = $rs->find($id)->get_column($column) }
          "$way: $column: $n characters are read with the default LongReadLen";
        ok defined $value && $value eq $char x $n, "$way: ... whole"
          or diag "$column $n: got " . ( defined $value ? length $value : 'undef' );
      }

      # an explicit LongReadLen of 80
      my ($below, $beyond) = map { ++$id } 1 .. 2;
      put($way, $below,  $column, 79);
      put($way, $beyond, $column, 83);
      is $ers->find($below)->get_column($column), $char x 79,
        "$way: $column: LongReadLen 80: 79 characters are read whole";
      throws_ok { $ers->find($beyond) } qr/long truncated/,
        "$way: $column: ... and 83 THROWS (long truncated), nothing is cut";

      # the boundary: a value of LongReadLen (+1) characters. A VARCHAR(MAX),
      # TEXT or NTEXT value of 81 and an NVARCHAR(MAX) value of 80 come back
      # with the last character a NUL, no error (DBD::ODBC 1.61 / FreeTDS
      # 1.3.17). A binary value of 80 is whole and of 81 throws.
      my $edge_n = $column =~ /\A(?:t|nvm)\z/ ? 80 : $binary ? 81 : 81;
      my $edge   = ++$id;
      put($way, $edge, $column, $edge_n);

      if ($binary) {
        throws_ok { $ers->find($edge) } qr/long truncated/,
          "$way: $column: at the boundary a binary value throws";
      }
      else {
        local $TODO = 'DBD::ODBC 1.61 returns a value of LongReadLen (+1) characters with its '
          . 'last character replaced by a NUL, without an error: maint/upstream/dbd-odbc-longreadlen-boundary.md';
        my $value = eval { $ers->find($edge)->get_column($column) };
        ok !defined $value || $value eq $char x $edge_n,
          "$way: $column: at the boundary the value is whole, or the read throws";
      }
    }

    # XML: read whole by default, throws over an explicit small LongReadLen
    admin($way)->do("INSERT INTO k77_lob (id, doc) VALUES (902, CAST('<a>' + REPLICATE(CAST('y' AS VARCHAR(MAX)), 50000) + '</a>' AS XML))");
    is length $rs->find(902)->get_column('doc'), 50007, "$way: an XML value is read whole by default";
    throws_ok { $ers->find(902) } qr/long truncated/, "$way: ... and throws over a small explicit LongReadLen";

    # SQL_VARIANT is read, a binary one as the hex digits of its value, as text
    admin($way)->do("INSERT INTO k77_lob (id, sv) VALUES (910, 42)");
    admin($way)->do("INSERT INTO k77_lob (id, sv) VALUES (912, 0x0102)");
    {
      my $variants = $schema->resultset('Variant');
      is $variants->find(910)->sv, 42, "$way: a SQL_VARIANT holding an integer is read";
      my $binary;
      lives_ok { $binary = $variants->find(912) } "$way: a SQL_VARIANT holding bytes: its row is there";
      is $binary && $binary->sv, '0102',
        "$way: ... as the hex digits of the value, as text (not its bytes)";
    }

    # the CLR types: refused by the driver, loudly
    for my $expression ('hierarchyid::GetRoot()', 'geography::Point(1, 1, 4326)') {
      dies_ok {
        $rs->search({}, { select => [ \$expression ], as => ['v'] })->single;
      } "$way: $expression is refused loudly";
    }

    # memory: no price for a large LongReadLen, empty values included
    SKIP: {
      skip 'no /proc/self/status', 6 unless -r '/proc/self/status';
      admin($way)->do("INSERT INTO k77_lob (id, t, nt, vm, nvm, im, vb) VALUES (940, '', N'', '', N'', 0x, 0x)");
      for my $column (qw(t nt vm nvm im vb)) {
        my $mb = peak_mb($way, $LONG, $column, 940);
        cmp_ok $mb // 1e9, '<', 20,
          "$way: $column: an EMPTY value costs no memory at LongReadLen $LONG (measured "
        . ( $mb // 'no answer' ) . ' MB)';
      }
    }
  }
}
done_testing;
