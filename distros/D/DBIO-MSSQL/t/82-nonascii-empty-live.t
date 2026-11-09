use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE (karr k49, k55). What a bound string arrives as, through a schema that
# declares MSSQL, over each access path that has a server to talk to:
#
#   DBD::Sybase   $ENV{DBIO_TEST_MSSQL_DSN}, _USER, _PASS
#   DBD::ODBC     $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER, _PASS
#
# Measured on 2026-10-08, DBD::Sybase 1.27 / FreeTDS 1.3.17, DBD::ODBC 1.61 /
# tdsodbc 1.3.17, SQL Server 2022 16.0.4295.3:
#
#   k49  Over DBD::Sybase a bound string with a character beyond ASCII was
#        stored padded with blanks (an a-umlaut as itself and a blank, the
#        euro sign with two), or -- for a character the server's code page
#        lacks -- as a row of blanks after the client library had refused
#        it. Nothing in the statement helped. The storage now REFUSES such a
#        value before anything is sent, and the message names DBD::ODBC.
#        What the server holds afterwards is: no row.
#
#   k55  Over DBD::Sybase a bound '' was stored as ONE blank (DATALENGTH 1 in
#        a VARCHAR, 2 in an NVARCHAR). The storage writes '' as the literal
#        '' where the placeholder was. DBD::ODBC always had it right, so the
#        expectations below are one set for both access paths.
#
# What the statements look like: t/81-nonascii-empty-binds.t (offline). Here:
# what the server holds, asked from another session in statements of ASCII
# alone.
#
# Over DBD::ODBC only the euro sign is stored in this test. On the test host
# an a-umlaut, a CJK character and an emoji are refused by the FreeTDS ODBC
# driver with an error of its own (client character set conversion) -- loud,
# not this file's to claim anything about.

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %WAY;
for my $dbd (keys %ENV_PREFIX) {
  my ($dsn, $user, $pass) = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw/DSN USER PASS/ };
  $WAY{$dbd} = [ $dsn, $user, $pass ] if $dsn and defined $user and defined $pass;
}

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} or '
  . '$ENV{DBIO_TEST_MSSQL_ODBC_DSN}, with _USER and _PASS, to run this test'
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

my $EXPECTED_WARNING = qr/compiled against buggy FreeTDS version/;
local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ $EXPECTED_WARNING;
};

{
  package T::K70::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k70_live_doc');
  __PACKAGE__->add_columns(
    id  => { data_type => 'integer', is_auto_increment => 1 },
    tag => { data_type => 'varchar', size => 60, is_nullable => 1 },
    v   => { data_type => 'varchar', size => 60, is_nullable => 1 },
    nv  => { data_type => 'nvarchar', size => 60, is_nullable => 1 },
    nvm => { data_type => 'nvarchar', size => -1, is_nullable => 1 },
    t   => { data_type => 'text', is_nullable => 1 },
    n   => { data_type => 'integer', is_nullable => 1 },
    d   => { data_type => 'datetime', is_nullable => 1 },
    c   => { data_type => 'char', size => 5, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K70::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Doc => 'T::K70::Result::Doc');
}

# A second connection per access path, plain DBI, for setup and for looking at
# what the server really holds: from another session, through no storage.
my %ADMIN;
sub admin {
  my $way = shift;
  return $ADMIN{$way} ||= do {
    my $dbh = DBI->connect(@{ $WAY{$way} }, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $dbh;
  };
}

sub drop_tables {
  my $way = shift;
  admin($way)->do("IF OBJECT_ID('k70_live_doc', 'U') IS NOT NULL DROP TABLE k70_live_doc");
}

sub fresh_tables {
  my $way = shift;
  drop_tables($way);
  admin($way)->do(
    'CREATE TABLE k70_live_doc ('
  . ' id INT IDENTITY PRIMARY KEY, tag VARCHAR(60) NULL,'
  . ' v VARCHAR(60) NULL, nv NVARCHAR(60) NULL, nvm NVARCHAR(MAX) NULL,'
  . ' t TEXT NULL, n INT NULL, d DATETIME NULL, c CHAR(5) NULL)'
  );
}

# What the server holds in a column of the row(s) with a tag, as [ DATALENGTH,
# hex of the first 100 bytes ]; 'NULL', 'no row' or 'N rows' otherwise.
sub holds {
  my ($way, $column, $tag) = @_;

  # TEXT cannot be converted to VARBINARY
  my $value = $column eq 't' ? 'CAST(t AS VARCHAR(100))' : $column;

  my $rows = admin($way)->selectall_arrayref(
    "SELECT DATALENGTH($column), CONVERT(VARCHAR(200), "
  . "CAST($value AS VARBINARY(100)), 2) FROM k70_live_doc WHERE tag = '$tag'"
  );

  return 'no row'         unless @$rows;
  return @$rows . ' rows' unless @$rows == 1;
  return 'NULL'           unless defined $rows->[0][0];
  return [ $rows->[0][0] + 0, $rows->[0][1] ];
}

sub rows_with_tag {
  my ($way, $tag) = @_;
  return admin($way)->selectrow_array(
    "SELECT COUNT(*) FROM k70_live_doc WHERE tag = '$tag'"
  );
}

# hex of an ASCII string
sub ascii_hex { uc unpack 'H*', $_[0] }

for my $way (sort keys %WAY) {
  fresh_tables($way);

  my $schema = T::K70::Schema->connect(@{ $WAY{$way} });
  my $rs     = $schema->resultset('Doc');
  my $tag    = 0;
  my $sybase = $way eq 'DBD::Sybase';

  $schema->storage->ensure_connected;
  isa_ok $schema->storage, $STORAGE{$way},
    "$way: (the storage of a schema that declares MSSQL)";

  # ---------------------------------------------------------- control

  $rs->create({ tag => ++$tag, v => 'plain', nv => 'plain', t => 'plain' });
  is_deeply holds($way, v  => $tag), [ 5, ascii_hex('plain') ],
    "$way: (control) an ASCII value in a VARCHAR arrives as it is";
  is_deeply holds($way, nv => $tag), [ 10, join '', map { ascii_hex($_) . '00' } split //, 'plain' ],
    "$way: ... in an NVARCHAR";

  # ------------------------------------------------ k55: '' is empty

  $rs->create({ tag => ++$tag, v => '', nv => '', nvm => '', t => '' });
  for my $column (qw(v nv nvm t)) {
    is_deeply holds($way, $column => $tag), [ 0, '' ],
      "$way: a bound '' arrives empty in $column: DATALENGTH 0, not one blank";
  }

  $rs->create({ tag => ++$tag, v => ' ', nv => ' ', t => ' ' });
  is_deeply holds($way, v  => $tag), [ 1, '20' ],
    "$way: a value of one blank is one blank (VARCHAR)";
  is_deeply holds($way, nv => $tag), [ 2, '2000' ], '... (NVARCHAR)';
  is_deeply holds($way, t  => $tag), [ 1, '20' ],    '... (TEXT)';

  $rs->create({ tag => ++$tag, v => undef, nv => undef, t => undef });
  is holds($way, v => $tag), 'NULL', "$way: undef is NULL, not an empty string";

  # UPDATE: set to '', and set to '' by a '' condition
  my $row = $rs->create({ tag => ++$tag, v => 'x', nv => 'x', t => 'x' });
  $row->update({ v => '', nv => '', t => '' });
  is_deeply [ map { holds($way, $_ => $tag)->[0] } qw(v nv t) ], [ 0, 0, 0 ],
    "$way: an UPDATE to '' leaves it empty";

  $rs->search({ tag => $tag })->update({ v => 'again' });
  $rs->search({ tag => $tag })->update({ v => '' });
  is_deeply holds($way, v => $tag), [ 0, '' ],
    "$way: ... also through the resultset";

  # populate, void context and list context
  $tag++;
  $rs->populate([
    { tag => "p$tag", v => 'one',   nv => 'one' },
    { tag => "p$tag" . 'b', v => '', nv => '' },
    { tag => "p$tag" . 'c', v => ' ', nv => ' ' },
  ]);
  is_deeply
    [ map { holds($way, v => $_)->[0] } "p$tag", "p${tag}b", "p${tag}c" ],
    [ 3, 0, 1 ],
    "$way: populate in void context: the empty row is empty, a blank is one";

  $tag++;
  my @rows = $rs->populate([
    { tag => "q$tag",  v => '', nv => '' },
    { tag => "q${tag}b", v => 'y', nv => 'y' },
  ]);
  is_deeply
    [ map { holds($way, $_->[0] => $_->[1])->[0] } [ v => "q$tag" ], [ nv => "q$tag" ] ],
    [ 0, 0 ], "$way: ... in list context";

  # conditions: = finds the empty row and not the blank one, LIKE too
  $tag++;
  $rs->create({ tag => "c$tag", v => '', nv => '', t => '' });
  $rs->create({ tag => "c$tag", v => ' ', nv => ' ', t => ' ' });
  $rs->create({ tag => "c$tag", v => 'z', nv => 'z', t => 'z' });
  my $same = $rs->search({ tag => "c$tag" });

  # '=' compares with ANSI padding: '' equals ' ' on the server, for a value
  # that was bound as it is just as for one that was written into the
  # statement. That is the server's, and the same over both access paths.
  is $same->search({ nv => '' })->count, 2,
    "$way: a condition nv = '' finds the empty row and the row of one blank "
  . '(ANSI padding, as over DBD::ODBC)';
  is $same->search({ nv => { -like => '' } })->count, 1,
    "$way: ... LIKE '' finds one row -- the empty one (bound, the row of one "
  . 'blank was found in its place)';
  is $same->search({ nv => { -like => '' } })->first->nv, '',
    '... and it is the empty one';
  is $same->search({ nv => { -in => [ '', 'z' ] } })->count, 3,
    "$way: ... and IN ('', 'z') finds both by the same padding, and z";
  is $same->search({ nv => { '<>' => '' } })->count, 1,
    "$way: ... <> '' leaves out the empty row and the blank row (equal by "
  . 'ANSI padding), and finds z';

  # what an empty string is in other types: the same over both access paths
  $tag++;
  $rs->create({ tag => $tag, n => '', d => '', c => '' });
  is_deeply holds($way, n => $tag), [ 4, '00000000' ],
    "$way: '' in an INT column is 0, as it always was (ODBC and Sybase)";
  is_deeply
    [ admin($way)->selectrow_array(
        "SELECT CONVERT(VARCHAR(10), d, 120) FROM k70_live_doc WHERE tag = '$tag'") ],
    [ '1900-01-01' ], "$way: ... in a DATETIME column 1900-01-01";
  is_deeply holds($way, c => $tag), [ 5, ascii_hex('     ') ],
    "$way: ... in a CHAR(5) column five blanks";

  # --------------------------------------------- k49: beyond ASCII

  if ($sybase) {
    for my $case (
      [ 'a-umlaut'    => "\x{E4}" ],
      [ 'the euro sign' => "\x{20AC}" ],
      [ 'a CJK character' => "\x{4E2D}" ],
      [ 'beyond the BMP' => "\x{1F600}" ],
      [ 'a-umlaut inside ASCII' => "caf\x{E9} au lait" ],
    ) {
      my ($what, $value) = @$case;
      my $t = ++$tag;

      for my $column (qw(v nv t)) {
        throws_ok { $rs->create({ tag => $t, $column => $value }) }
          qr/DBD::ODBC/,
          "$way: $what in $column is refused, naming DBD::ODBC";
      }

      is rows_with_tag($way, $t), 0,
        "$way: ... and no row was written, not one of blanks either";
    }

    {
      my $t = ++$tag;
      throws_ok { $rs->search({ v => "\x{E4}" })->update({ n => 1 }) }
        qr/beyond ASCII/, "$way: a condition is refused as well";
      throws_ok { $rs->populate([ { tag => $t, v => 'ok' }, { tag => $t, v => "\x{E4}" } ]) }
        qr/beyond ASCII/, "$way: populate in void context too";
      is rows_with_tag($way, $t), 0,
        "$way: ... before the first of its rows was written";
    }

    # a value over 4000 bytes is a literal (karr k40): exact
    {
      my $t = ++$tag;
      my $euros = "\x{20AC}" x 1334;
      $rs->create({ tag => $t, nvm => $euros });
      is_deeply holds($way, nvm => $t)->[0], 2668,
        "$way: a value beyond ASCII of 4002 bytes is a literal and arrives "
      . 'whole (karr k40), so it is not refused';
    }
  }
  else {
    my $t = ++$tag;
    $rs->create({ tag => $t, v => "\x{20AC}", nv => "\x{20AC}" });
    is_deeply holds($way, v => $t), [ 1, '80' ],
      "$way: the euro sign arrives exactly in a VARCHAR: one byte of CP1252";
    is_deeply holds($way, nv => $t), [ 2, 'AC20' ],
      '... and in an NVARCHAR: U+20AC';
  }
}

END {
  if (%WAY) {
    eval { drop_tables($_) for sort keys %WAY };
  }
}

done_testing;
