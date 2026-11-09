use strict;
use warnings;

use Test::More;
use Test::Exception;
use Digest::SHA ();
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

# LIVE (karr k50, karr k56). A value for a binary column, written and read
# through a schema that declares MSSQL, over each access path that has a
# server to talk to:
#
#   DBD::Sybase   $ENV{DBIO_TEST_MSSQL_DSN}, _USER, _PASS
#   DBD::ODBC     $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, _USER, _PASS
#
# Until 2026-10-08 no such value arrived over either: both storage classes
# bound it without a type, the server took it for varchar and refused to make
# VARBINARY of that (Msg 257), or the client library refused to convert its
# bytes as characters. Measured before the fix, through a schema like the one
# below: every INSERT, UPDATE and condition here failed, at every size but an
# empty value in an IMAGE column over DBD::ODBC -- and over DBD::Sybase that
# one was stored as one byte, a blank, without an error.
#
# What each class does about it, and that nothing of a value is put into a
# statement: t/64-binary-bind-values.t (offline). Here: that the server holds
# what was given. Everything is asked of the server afterwards, from another
# session and in statements of ASCII alone: how many bytes it holds and their
# SHA-256.
#
# READING (karr k56). Until 2026-10-08 nothing was read back here: over
# DBD::Sybase a BINARY(n), VARBINARY(n) or IMAGE column came back as its hex
# digits, and A RESULT WITH A VARBINARY(MAX) COLUMN HAD NO ROW FOR ANY VALUE
# OF ONE BYTE OR MORE, without an error -- find() on such a table found
# nothing. The DBD has a buffer of one byte for such a column and drops a row
# whose fetch fails (the plain-DBI test below holds that, as the reason for
# everything else). The DBD::Sybase class now asks for a binary column of a
# result source as an IMAGE, which this DBD carries as bytes, and refuses a
# VARBINARY(MAX) result column it did not rewrite: what it sends is pinned
# offline, in t/66-binary-read-values.t; here, that what comes back through
# the schema is as many bytes as the server holds, and the same.
#
# Two limits on the way back, neither of them this file's to move:
#
#   DBD::Sybase  a value over the TEXTSIZE of the session (the FreeTDS class
#                sets it to LongReadLen, 32768 unless the connect info says
#                otherwise) is REFUSED -- it was cut without an error (karr
#                k47; t/77 has the cases). Larger values are read through a
#                second schema, connected with a LongReadLen.
#   DBD::ODBC    reads a long value up to LongReadLen and throws beyond. The
#                storage sets 1073741824 unless the connect info says
#                otherwise (karr k61; DBI's 80 before); this file still
#                connects with one of its own.

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %WAY;
for my $dbd (sort keys %ENV_PREFIX) {
  my ($dsn, $user, $pass)
    = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw(DSN USER PASS) };

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
  # Only "not installed" is a reason to leave it out. A DBIO::Sybase that is
  # there and does not load is a failure.
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

# The DBD::Sybase class announces its FreeTDS workaround once per process.
my $EXPECTED_WARNING = qr/compiled against buggy FreeTDS version/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0];
  warn $_[0] unless $_[0] =~ $EXPECTED_WARNING;
};

{
  package T::K50L::Result::Bin;
  use base 'DBIO::Core';
  __PACKAGE__->table('k50_live_bin');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    tag   => { data_type => 'varchar', size => 60, is_nullable => 1 },
    body  => { data_type => 'varbinary', size => -1, is_nullable => 1 },
    sized => { data_type => 'varbinary', size => 8000, is_nullable => 1 },
    fixed => { data_type => 'binary', size => 16, is_nullable => 1 },
    img   => { data_type => 'image', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K50L::Result::Hashed;
  use base 'DBIO::Core';
  __PACKAGE__->table('k50_live_hashed');
  __PACKAGE__->add_columns(
    digest => { data_type => 'binary', size => 32 },
    note   => { data_type => 'varchar', size => 60, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('digest');
}

{
  package T::K50L::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class($_ => "T::K50L::Result::$_") for qw(Bin Hashed);
}

my @TABLES = qw(k50_live_bin k50_live_hashed);

# A second connection per access path, plain DBI, for setup and for looking
# at what the server really holds: from another session, and through no
# storage. Statements and results are ASCII alone.
my %ADMIN;
my $live;
sub admin {
  my $way = shift;
  return $ADMIN{$way} ||= do {
    my $dbh = DBI->connect(@{ $WAY{$way} }, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $live = 1;
    $dbh;
  };
}

sub drop_tables {
  my $way = shift;
  admin($way)->do("IF OBJECT_ID('$_', 'U') IS NOT NULL DROP TABLE $_") for @TABLES;
}

sub fresh_tables {
  my $way = shift;
  drop_tables($way);
  admin($way)->do($_) for (
    'CREATE TABLE k50_live_bin ('
  . ' id INT IDENTITY PRIMARY KEY, tag VARCHAR(60) NULL,'
  . ' body VARBINARY(MAX) NULL, sized VARBINARY(8000) NULL,'
  . ' fixed BINARY(16) NULL, img IMAGE NULL)',
    'CREATE TABLE k50_live_hashed ('
  . ' digest BINARY(32) NOT NULL PRIMARY KEY, note VARCHAR(60) NULL)',
  );
}

# All 256 byte values, FF 00 80 first, as often as it takes. $salt changes
# the last byte.
my $PATTERN = join '', "\xFF\x00\x80", map { chr } 0 .. 255;
sub bytes {
  my ($size, $salt) = @_;
  my $value = substr $PATTERN x ( 1 + int( $size / length $PATTERN ) ), 0, $size;
  substr($value, -1, 1) = chr( ( ord( substr $value, -1, 1 ) + $salt ) % 256 )
    if $salt and $size;
  utf8::downgrade($value);
  return $value;
}

sub hex_literal { '0x' . uc unpack 'H*', $_[0] }

# [ bytes, SHA-256 ] of what the server holds in a column of the rows with a
# tag, and of what was given.
sub server_holds {
  my ($way, $column, $tag) = @_;

  my $rows = admin($way)->selectall_arrayref(
    "SELECT DATALENGTH($column), CONVERT(VARCHAR(64), "
  . "HASHBYTES('SHA2_256', CONVERT(VARBINARY(MAX), $column)), 2) "
  . "FROM k50_live_bin WHERE tag = '$tag'"
  );

  return 'no row'             unless @$rows;
  return @$rows . ' rows'     unless @$rows == 1;
  return 'NULL'               unless defined $rows->[0][0];
  return [ $rows->[0][0] + 0, lc $rows->[0][1] ];
}
sub given { [ length $_[0], Digest::SHA::sha256_hex($_[0]) ] }

# The same of a value that was read: 'NULL' and 'no row' as the server side
# says them.
sub was_read { defined $_[0] ? given($_[0]) : 'NULL' }

# The LongReadLen for reading a value that is larger than the access path
# hands back by default (see the head of this file).
my $LONG_READ = 200_000;

# What a DBD::Sybase session reads of a long value by default: the TEXTSIZE
# the FreeTDS class sets, DBD::Sybase's own LongReadLen.
my $DEFAULT_TEXTSIZE = 32768;

for my $way (sort keys %WAY) {
  fresh_tables($way);

  my $sybase = $way eq 'DBD::Sybase';

  # DBD::ODBC throws on a long value over LongReadLen, and that is 80 bytes
  # unless something is said. DBD::Sybase stays as a schema connects by
  # default, with its TEXTSIZE of 32768.
  my $schema = T::K50L::Schema->connect(
    @{ $WAY{$way} }, ( $sybase ? () : { LongReadLen => $LONG_READ } ),
  );
  my $rs     = $schema->resultset('Bin');
  my $tag    = 0;

  # For reading what is over that TEXTSIZE: a second schema.
  my $long = $sybase
    ? T::K50L::Schema->connect(@{ $WAY{$way} }, { LongReadLen => $LONG_READ })
    : $schema;
  my $reader = sub { ( $_[0] > $DEFAULT_TEXTSIZE ? $long : $schema )->resultset('Bin') };

  $schema->storage->ensure_connected;
  isa_ok $schema->storage, $STORAGE{$way},
    "$way: (the storage of a schema that declares MSSQL)";

  # ---- INSERT into VARBINARY(MAX): around the size of one piece over
  #      DBD::Sybase (1999), around 8000, where a value bound as SQL_VARBINARY
  #      is cut over DBD::ODBC, and far beyond
  for my $size (0, 1, 256, 1999, 2000, 2001, 8000, 8001, 9000, 100_000) {
    my $value = bytes($size);
    my $row   = $rs->create({ tag => ++$tag, body => $value });

    is_deeply server_holds($way, body => $tag), given($value),
      "$way: a binary value of $size bytes arrives in a VARBINARY(MAX) "
    . 'column: as many bytes, and the same';

    # ---- and back (karr k56). find() reads the one row from the statement
    #      handle itself, the other reads below go through a cursor.
    my $found = $reader->($size)->find( $row->id );

    is_deeply $found ? was_read( $found->body ) : 'no row',
      server_holds($way, body => $tag),
      "$way: find() reads $size bytes back from a VARBINARY(MAX) column: "
    . 'the row is there, with as many bytes as the server holds, and the same';
  }

  # ---- the reason for all of it, held where it would be seen to change:
  #      plain DBI over DBD::Sybase has no row for a VARBINARY(MAX) column
  #      with a value, and no error.
  if ($sybase) {
    is_deeply
      admin($way)->selectall_arrayref(
        q{SELECT tag, body FROM k50_live_bin WHERE tag IN ('1', '2') ORDER BY id}
      ),
      [ [ 1, '' ] ],
      "$way, plain DBI: of the rows with an empty value and with one byte "
    . 'in a VARBINARY(MAX) column, the DBD hands back the first alone';
  }

  # ---- the other binary columns
  {
    my $value = bytes(8000);
    $rs->create({ tag => ++$tag, sized => $value });

    is_deeply server_holds($way, sized => $tag), given($value),
      "$way: 8000 bytes arrive in a VARBINARY(8000) column";

    $value = bytes(16);
    $rs->create({ tag => ++$tag, fixed => $value });

    is_deeply server_holds($way, fixed => $tag), given($value),
      "$way: 16 bytes arrive in a BINARY(16) column";

    $value = bytes(9000);
    $rs->create({ tag => ++$tag, img => $value });

    is_deeply server_holds($way, img => $tag), given($value),
      "$way: 9000 bytes arrive in an IMAGE column";

    # ---- and back, through a cursor: the three rows above, each with its
    #      column. Over DBD::Sybase these came back as hex digits.
    my %read = map { ( $_->tag => $_ ) }
      $rs->search({ tag => [ $tag - 2 .. $tag ] })->all;

    is_deeply
      [ map { was_read( $read{ $tag - 2 + $_->[0] }->get_column( $_->[1] ) ) }
          [ 0, 'sized' ], [ 1, 'fixed' ], [ 2, 'img' ] ],
      [ given(bytes(8000)), given(bytes(16)), given(bytes(9000)) ],
      "$way: all() reads the bytes of a VARBINARY(8000), a BINARY(16) and "
    . 'an IMAGE column, not their hex digits';

    is_deeply
      [ map { was_read($_) } $rs->search({ tag => $tag })->get_column('img')->all ],
      [ given(bytes(9000)) ],
      "$way: get_column() of a binary column reads the bytes";

    my $next = $rs->search({ tag => $tag - 2 }, { columns => [qw(tag sized)] });

    is_deeply was_read( $next->next->sized ), given(bytes(8000)),
      "$way: next() reads them";
    1 while $next->next;
  }

  # ---- NULL, and what a value is
  {
    $rs->create({ tag => ++$tag, body => undef });

    is server_holds($way, body => $tag), 'NULL',
      "$way: NULL for a binary column is NULL";

    my @null = $rs->search({ tag => $tag })->all;

    is_deeply [ map { was_read( $_->body ) } @null ], ['NULL'],
      "$way: ... and is read back as NULL, with its row";

    my $flagged = bytes(600);
    utf8::upgrade($flagged);
    $rs->create({ tag => ++$tag, body => $flagged });

    is_deeply server_holds($way, body => $tag), given(bytes(600)),
      "$way: a value Perl holds with the UTF-8 flag on arrives as the same "
    . '600 bytes, not as the bytes of its UTF-8 form';

    throws_ok {
      $rs->create({ tag => ++$tag, body => "no bytes \x{20AC}" });
    } qr/binary column 'body' has a character above 255/,
      "$way: a value with a character above 255 is no binary value: refused";

    is server_holds($way, body => $tag), 'no row',
      "$way: ... and nothing was written";
  }

  # ---- UPDATE
  {
    admin($way)->do("INSERT INTO k50_live_bin (tag, body) VALUES ('upd', 0x5A5A)");

    my $value = bytes(9000);
    $rs->search({ tag => 'upd' })->update({ body => $value });

    is_deeply server_holds($way, body => 'upd'), given($value),
      "$way: an UPDATE sets a binary value of 9000 bytes";

    $rs->search({ tag => 'upd' })->update({ body => '' });

    is_deeply server_holds($way, body => 'upd'), given(''),
      "$way: ... and an empty one: no bytes, not a blank and not NULL";
  }

  # ---- a condition. Three rows: the value, the value with another last
  #      byte, the value without its last byte.
  for my $case (
    [ body  => 9000, 'VARBINARY(MAX) column, 9000 bytes' ],
    [ sized => 8000, 'VARBINARY(8000) column, 8000 bytes' ],
    [ fixed => 16,   'BINARY(16) column' ],
  ) {
    my ($column, $size, $what) = @$case;
    my $value = bytes($size);

    admin($way)->do(sprintf
      "INSERT INTO k50_live_bin (tag, $column) VALUES ('$column/%s', %s)",
      $_->[0], hex_literal($_->[1]),
    ) for [ exact => $value ], [ lastbyte => bytes($size, 1) ],
          [ shorter => substr $value, 0, $size - 1 ];

    is_deeply
      [ $rs->search({ tag => { -like => "$column/%" }, $column => $value })
           ->get_column('tag')->all ],
      [ "$column/exact" ],
      "$way: a condition on a binary value finds the row with that value "
    . "and no other ($what)";
  }

  # ---- a binary primary key
  {
    my $hashed = $schema->resultset('Hashed');
    my $mine   = bytes(32);
    my $other  = bytes(32, 1);

    admin($way)->do(
      'INSERT INTO k50_live_hashed (digest, note) VALUES '
    . "(@{[ hex_literal($mine) ]}, 'mine'), (@{[ hex_literal($other) ]}, 'other')"
    );

    my $found = $hashed->find($mine);

    is $found && $found->note, 'mine',
      "$way: find() by a binary primary key finds its row";

    # The key the row object holds is the one that was read. Read as hex
    # digits (DBD::Sybase before karr k56) it found no row to update.
    is_deeply was_read( $found && $found->digest ), given($mine),
      "$way: ... and the row object holds the key as its bytes";

    $found->update({ note => 'changed' });

    is_deeply
      admin($way)->selectall_arrayref(
        'SELECT note FROM k50_live_hashed ORDER BY note'
      ),
      [ ['changed'], ['other'] ],
      "$way: \$row->update on a row found by its binary primary key "
    . 'changes that row and no other';

    $found->discard_changes;

    is $found->note, 'changed',
      "$way: ... and the row is found again by the key it holds";

    $hashed->create({ digest => bytes(32, 2), note => 'new' });
    $hashed->search({ digest => $mine })->delete;

    is_deeply
      admin($way)->selectall_arrayref(
        'SELECT note FROM k50_live_hashed ORDER BY note'
      ),
      [ ['new'], ['other'] ],
      "$way: a row is created with a binary key, and a DELETE by a binary "
    . 'key deletes that row only';
  }

  # ---- populate in void context
  {
    my %populated = map { ( "pop/$_" => bytes($_) ) } 1, 2001, 0, 9000, 100_000;

    $rs->populate([
      map { { tag => $_, body => $populated{$_} } } sort keys %populated
    ]);

    is_deeply
      { map { $_ => server_holds($way, body => $_) } keys %populated },
      { map { $_ => given($populated{$_}) } keys %populated },
      "$way: populate in void context: every row arrives with its own "
    . 'binary value, from none to 100000 bytes';

    # ---- and all of them back in one result, through a cursor
    is_deeply
      { map { ( $_->tag => was_read( $_->body ) ) }
          $long->resultset('Bin')->search({ tag => { -like => 'pop/%' } })->all },
      { map { $_ => given($populated{$_}) } keys %populated },
      "$way: one result with five rows reads each with its own value, "
    . 'from none to 100000 bytes';
  }

  # ---- reading: where it ends (karr k56, karr k47)
  if ($sybase) {
    my $dbh = $schema->storage->dbh;

    ok !$dbh->{syb_binary_images},
      "$way: after all that reading the handle has syb_binary_images off, as "
    . 'it was: it is on for the execute of a rewritten statement alone';

    # ---- a value over the TEXTSIZE of the session is refused, not cut
    #
    # Was (karr k47): read as its first 32768 bytes, without an error. The
    # claim of the two tests that stood here -- "IS: cut" and "SHOULD: whole,
    # or the read throws" (a TODO) -- is the second one now, and it holds: the
    # column is read behind a check the server runs (t/77 has the rest).
    my $value = bytes( $DEFAULT_TEXTSIZE + 1 );
    my $row   = $rs->create({ tag => ++$tag, body => $value });

    throws_ok { $rs->find( $row->id ) }
      qr/the column 'me\.body' holds a value longer than the TEXTSIZE of the session, \Q$DEFAULT_TEXTSIZE\E bytes/,
      "$way: a value of one byte more than the TEXTSIZE of the session "
    . "($DEFAULT_TEXTSIZE) is REFUSED, naming the column and the size -- "
    . 'it is not read as its first bytes';

    is_deeply was_read( $rs->find( $rs->create({ tag => ++$tag, body => substr $value, 0, $DEFAULT_TEXTSIZE })->id )->body ),
      given( substr $value, 0, $DEFAULT_TEXTSIZE ),
      "$way: ... and one of exactly that many bytes is read whole";

    is_deeply was_read( $long->resultset('Bin')->find( $row->id )->body ),
      given($value),
      "$way: ... with a LongReadLen in the connect info it is read whole";

    # ---- what the storage did not rewrite and DBD::Sybase would lose the
    #      rows of is refused: a VARBINARY(MAX) result column
    throws_ok {
      $rs->search({ tag => $tag }, { select => [ \'me.body' ], as => ['body'] })->all
    } qr/Cannot read this result through DBD::Sybase: its column 1 \('body'\) is VARBINARY\(MAX\)/,
      "$way: a VARBINARY(MAX) column in literal SQL, which is not rewritten: "
    . 'refused, where its row would have been dropped without an error';

    throws_ok {
      scalar $rs->search({ tag => $tag })->get_column('body')->max
    } qr/is VARBINARY\(MAX\)/,
      "$way: a function over such a column: refused";

    is $schema->storage->dbh, $dbh,
      "$way: ... on the connection it was, which carries the next statement";

    # ---- what the exception names instead: the hex digits
    my $hex = $rs->search({ tag => 9 }, {
      select => [ \'CONVERT(VARCHAR(MAX), me.body, 2)' ], as => ['body'],
    })->single;

    is $hex && $hex->body, uc unpack('H*', bytes(9000)),
      "$way: CONVERT(VARCHAR(MAX), <expression>, 2) in literal SQL arrives, "
    . 'as the hex digits of 9000 bytes';

    # ---- a limit of the form: an IMAGE cannot be compared. distinct => 1
    #      is a GROUP BY over the column as it is; a DISTINCT of literal SQL
    #      beside a binary column is the server's to refuse.
    is_deeply
      [ map { was_read( $_->sized ) }
          $rs->search({ tag => 11 }, { columns => ['sized'], distinct => 1 })->all ],
      [ given(bytes(8000)) ],
      "$way: distinct => 1 with a binary column reads its bytes";

    {
      # the DBD warns about the prepare the server refused, beside throwing
      local $SIG{__WARN__} = sub {
        push @warnings, $_[0] unless $_[0] =~ /ct_dynamic\(CS_PREPARE\)/;
      };

      throws_ok {
        $rs->search({ tag => 11 }, {
          select => [ \'DISTINCT me.tag', 'me.sized' ], as => [qw(tag sized)],
        })->all
      } qr/image data type cannot be selected as DISTINCT/,
        "$way IS: a DISTINCT written in literal SQL beside a binary column "
      . 'is refused by the server, with its Msg 421';
    }

    # ---- not reached: a sized binary value that is not the column itself
    #      comes back as its hex digits, as before
    my $max = $rs->search({ tag => 11 })->get_column('sized')->max;

    is $max, unpack('H*', bytes(8000)),
      "$way IS: a function over a VARBINARY(8000) column hands back hex "
    . 'digits (not reached: only a column itself is rewritten)';
  }

  $long->storage->disconnect;
  $schema->storage->disconnect;
  drop_tables($way);

  is_deeply
    admin($way)->selectall_arrayref(
      q{SELECT name FROM sys.objects WHERE name LIKE 'k50[_]live%'}
    ),
    [],
    "$way: nothing of this test is left in the database";
}

is_deeply [ grep { $_ !~ $EXPECTED_WARNING } @warnings ], [],
  'no warning but the DBD::Sybase class\'s own FreeTDS notice';

done_testing;

# The tables again, on new connections: for a run that died on the way.
END {
  if ($live) {
    local $?;
    for my $way (sort keys %WAY) {
      delete $ADMIN{$way};
      eval { drop_tables($way); 1 }
        or diag "Could not drop the k50_live_* tables over $way: $@";
    }
  }
}
