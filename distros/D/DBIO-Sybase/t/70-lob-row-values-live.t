use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Storage::ASE::NoBindVars;

# LIVE (karr k79). The counterpart of t/69-lob-row-values.t, which pins
# offline that the row object create() returns holds in a TEXT or IMAGE
# column the value it was given, and not the placeholder the storage sent in
# its place. Here a server keeps the row, and is asked what it holds beside
# what the object answers.
#
# CLAIMED, as plain tests:
#
#   1. SERVER BEHAVIOUR, not a wish of this driver: ASE has no empty value in
#      a VARCHAR column either. The literal '' is one space there, as it is
#      in the TEXT column beside it.
#   2. create() with the empty string in the TEXT, the IMAGE and the VARCHAR
#      column: the object answers the empty string for each of the three --
#      what it was given -- while the server holds a space, the byte 0x20 and
#      a space. So it has not read the row; and the LOB columns answer as the
#      VARCHAR column does, which no storage of this driver touches. That is
#      the reason they answer '' and not ' ': t/69-lob-row-values.t, "THE
#      EMPTY STRING".
#   3. Read again -- discard_changes -- the object answers what the server
#      holds: the space, in the TEXT and in the VARCHAR column.
#   4. create() with undef in both LOB columns: the object answers undef, the
#      columns are NULL.
#   5. 2 and 4 inside a transaction of the caller too, where the storage
#      inserts itself; outside one its writer storage does.
#   6. update() through the row object, of a row that had content, to the
#      empty string and to undef: the object answers what it was given, the
#      server holds the space and NULL. This was so before karr k79.
#   7. Where the client library can write a LOB's content -- not FreeTDS --:
#      the object after a create() and after an update() with content
#      answers the content, and the server holds it.
#
# Each for the storage the DSN leads to and for the NoBindVars class, pinned.
#
# Measured 2026-10-08 against SAP ASE 16.0 SP02 PL02, with DBD::Sybase 1.27
# built against FreeTDS 1.3.17, TDS 5.0. What this file does NOT claim there:
#
#   * anything about a LOB that has content: 7 is SKIPPED under FreeTDS,
#     which cannot write it (ct_data_info fails, the create() dies and there
#     is no object to ask). Its lines were NOT RUN, here or anywhere;
#     offline, t/69-lob-row-values.t has the case with the write replaced.
#   * anything about the Sybase Open Client libraries.
#
# Makes one table in the database of the DSN, named after this process, and
# drops it.

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_SYBASE_${_}" } qw/DSN USER PASS/};

plan skip_all => 'Set $ENV{DBIO_TEST_SYBASE_DSN}, _USER and _PASS to run this test'
  unless $dsn && defined $user && defined $pass;

plan skip_all => 'Test needs '
  . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_ase')
  unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_ase');

# The FreeTDS notice of the ASE class is no finding of this file.
$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

my $TABLE = "dbio_k79_lob_$$";

# ------------------------------------------------------------ the schemas

{
  package T::K79L::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
    tag     => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# The Sybase component: the storage becomes the ASE class at the first use. A
# schema always declares its driver (core ADR 0067, karr k90).
{
  package T::K79L::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K79L::Result::Lob');
}

{
  package T::K79L::NoBindVars;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Lob => 'T::K79L::Result::Lob');
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE::NoBindVars');
}

# ------------------------------------------------------------ the helpers

# The server's address and the login are the environment's and stay out of the
# output: of an error, what the server said -- "Msg <number>: <text>" -- or,
# where it was not the server, one line of it.
sub said {
  my $text = shift // '';

  my (@messages, %seen);
  while ($text =~ /
    Server\ message\ number=(\d+) [^\n]*? \btext=(.*?) \s*
    (?= Server\ message\ number= | \[for\ Statement | \ at\ \S+\ line\ \d+ | \z )
  /gsx) {
    push @messages, "Msg $1: $2" unless $seen{"$1: $2"}++;
  }
  return join ' | ', @messages if @messages;

  $text =~ s/ at \S+ line \d+.*//s;
  $text =~ s/\b(host|port)=[^;\s]*/$1=../g;
  $text =~ s/\Q$pass\E/../g if length $pass;
  $text =~ s/\s+/ /g;
  return length $text > 400 ? substr($text, 0, 400) . ' ...' : $text;
}

# The value of $code. If it died, undef -- and why() says what of.
my $why;
sub tried (&) {
  my $code = shift;
  undef $why;
  my $value;
  eval { $value = $code->(); 1 } or $why = said($@);
  return $value;
}
sub why { diag '  ' . ( $why // '(it did not die)' ) }

# What a value is, in words a failing test can print.
sub worded {
  my $value = shift;
  return 'undef' unless defined $value;
  return ref($value) . " ref to <$$value>" if ref $value eq 'SCALAR';
  return 'the ' . length($value) . "-character string <$value>";
}

# What the object answers for these columns -- or that there is no object.
sub answers {
  my ($row, @columns) = @_;
  return 'no object' unless $row;
  return { map { $_ => worded($row->get_column($_)) } @columns };
}

sub given {
  my %columns = @_;
  return { map { $_ => worded($columns{$_}) } keys %columns };
}

# Plain DBI, beside every storage under test: makes the table, puts in the
# rows an update needs, and reads what the server holds.
#
# ASE waits for a lock without limit; with a lock wait set a look at a row
# somebody left locked fails after ten seconds (Msg 12205) instead.
my $raw = DBI->connect($dsn, $user, $pass, {
  RaiseError => 1, PrintError => 0, AutoCommit => 1,
});
$raw->do('set lock wait 10');

my $live = 1;   # past every skip_all: from here on there is a table to drop

sub table_there {
  ( $raw->selectrow_array(
    "select count(*) from sysobjects where type = 'U' and name = '$TABLE'"
  ) )[0];
}

# What the server holds in the rows $where selects, by id: [ length of the
# TEXT, the TEXT, length of the IMAGE, the IMAGE in hex, length of the name,
# the name ]
sub held {
  my $where = shift;
  return $raw->selectall_arrayref(
    "select datalength(c_text), convert(varchar(30), c_text), "
  . "datalength(c_image), bintostr(convert(varbinary(30), c_image)), "
  . "datalength(name), name "
  . "from $TABLE where $where order by id"
  );
}

sub last_id { ( $raw->selectrow_array("select isnull(max(id), 0) from $TABLE") )[0] }

my @SPACE       = ( 1, ' ' );      # the literal '' in a TEXT or VARCHAR column
my @SPACE_IMAGE = ( 1, '20' );     # ... and in an IMAGE column
my @NULL        = ( undef, undef );

note 'client library: ' . ( $raw->{syb_oc_version} || '(unknown)' );
note 'server: ' . said( ( split /\n/, ( $raw->selectrow_array('select @@version') )[0] )[0] );

$raw->do(<<"SQL");
CREATE TABLE $TABLE (
  id      INT IDENTITY PRIMARY KEY,
  c_image IMAGE NULL,
  c_text  TEXT NULL,
  name    VARCHAR(40) NULL,
  tag     VARCHAR(40) NULL
)
SQL

# ==================================================== 1. the server itself

$raw->do("INSERT INTO $TABLE (c_text, name, tag) VALUES ('', '', 'server')");

is_deeply held(q{tag = 'server'}), [ [ @SPACE, @NULL, @SPACE ] ],
  q{SERVER: the literal '' is one space in a VARCHAR column, as it is in the }
. q{TEXT column beside it};

# ================================================ 2 - 7. through the storage

for my $schema_class (qw(T::K79L::Declared T::K79L::NoBindVars)) {
  my ($tag) = $schema_class =~ /(\w+)\z/;

  my $schema = tried {
    my $schema = $schema_class->connect($dsn, $user, $pass, {
      on_connect_do => [ 'set lock wait 10' ],
    });
    $schema->storage->ensure_connected;
    $schema;
  };

  ok $schema, "$tag: a storage is connected" or do { why(); next };

  my $storage = $schema->storage;
  my $by      = ref $storage;
  my $rs      = $schema->resultset('Lob');

  note "$tag: the storage is a $by"
     . ( $storage->auto_cast ? ', with auto_cast' : '' );

  # -------------------------------------------------------- 2 - 5. create
  for my $way (
    [ 'outside a transaction', sub { $_[0]->() } ],
    [ 'inside a transaction',  sub { $schema->txn_do($_[0]) } ],
  ) {
    my ($where, $run) = @$way;

    # The empty string, in the LOB columns and in the VARCHAR column.
    {
      my $after = last_id();
      my %empty = ( c_text => '', c_image => '', name => '' );

      my $row = tried {
        my $row;
        $run->(sub { $row = $rs->create({ %empty, tag => $tag }) });
        $row;
      };

      is_deeply [ answers($row, qw(c_text c_image name)), held("id > $after") ],
        [ given(%empty), [ [ @SPACE, @SPACE_IMAGE, @SPACE ] ] ],
        "$by, $where: create() with the empty string in the TEXT, the IMAGE "
      . 'and the VARCHAR column -- the object answers the empty string for '
      . 'each, as given and without a read, where the server holds a space, '
      . '0x20 and a space' or why();

      # 3. only once: the read is the same on either way in.
      if ($row and $where =~ /outside/) {
        tried { $row->discard_changes; 1 };

        is_deeply answers($row, qw(c_text name)), given( c_text => ' ', name => ' ' ),
          '... and read again -- discard_changes -- it answers what the '
        . 'server holds: the space, in the TEXT and in the VARCHAR column'
          or why();
      }
    }

    # undef
    {
      my $after = last_id();
      my %undef = ( c_text => undef, c_image => undef );

      my $row = tried {
        my $row;
        $run->(sub { $row = $rs->create({ %undef, name => 'n', tag => $tag }) });
        $row;
      };

      is_deeply [ answers($row, qw(c_text c_image)), held("id > $after") ],
        [ given(%undef), [ [ @NULL, @NULL, 1, 'n' ] ] ],
        "$by, $where: create() with undef in both LOB columns -- the object "
      . 'answers undef for each, and the columns are NULL' or why();
    }
  }

  # ---------------------------------------- 6. update() through the object
  for my $case (
    [ 'the empty string', '',    [ @SPACE, @SPACE_IMAGE ] ],
    [ 'undef',            undef, [ @NULL,  @NULL        ] ],
  ) {
    my ($what, $value, $expected) = @$case;

    $raw->do("INSERT INTO $TABLE (c_image, c_text, name, tag) VALUES (0x010203, 'before', 'n', '$tag')");
    my $id = last_id();

    my $row = tried {
      my $row = $rs->find($id);
      $row->update({ c_text => $value, c_image => $value });
      $row;
    };

    is_deeply [ answers($row, qw(c_text c_image)), held("id = $id") ],
      [ given( c_text => $value, c_image => $value ), [ [ @$expected, 1, 'n' ] ] ],
      "$by: \$row->update of both LOB columns, which had content, to $what "
    . '-- the object answers what it was given, the server holds '
    . ( defined $value ? 'a space and 0x20' : 'NULL in both' ) or why();
  }

  # ------------------------------------------ 7. a LOB that has content
  SKIP: {
    skip "$by: FreeTDS cannot write a LOB's content (ct_data_info) -- a "
       . 'create() or update() with content dies there and leaves no object '
       . 'to ask; t/69-lob-row-values.t has the case offline', 2
      if $storage->_using_freetds;

    my %content = ( c_text => 'some text', c_image => "\x01\x02\x03" );

    {
      my $after = last_id();
      my $row = tried { $rs->create({ %content, name => 'n', tag => $tag }) };

      is_deeply [ answers($row, qw(c_text c_image)), held("id > $after") ],
        [ given(%content), [ [ 9, 'some text', 3, '010203', 1, 'n' ] ] ],
        "$by: create() with content in both LOB columns -- the object "
      . 'answers the content, and the server holds it' or why();
    }

    {
      $raw->do("INSERT INTO $TABLE (c_image, c_text, name, tag) VALUES (0x0a, 'before', 'n', '$tag')");
      my $id = last_id();

      # With another column beside the content: see t/69-lob-row-values.t,
      # NOT CLAIMED.
      my $row = tried {
        my $row = $rs->find($id);
        $row->update({ %content, name => 'm' });
        $row;
      };

      is_deeply [ answers($row, qw(c_text c_image)), held("id = $id") ],
        [ given(%content), [ [ 9, 'some text', 3, '010203', 1, 'm' ] ] ],
        "$by: \$row->update of both LOB columns to content, and the name -- "
      . 'the object answers the content, and the server holds it' or why();
    }
  }

  $storage->disconnect;
}

# ================================================================ the end

ok tried { $raw->do("DROP TABLE $TABLE"); 1 }, 'the table of this test is dropped'
  or why();
is table_there(), 0, 'nothing of this test is left on the server';

done_testing;

# The table again: for a run that died on the way.
END {
  if ($live && $raw) {
    local $?;
    my $kept = eval { table_there() && !eval { $raw->do("DROP TABLE $TABLE"); 1 } };
    diag "Could not clean up after this test: table $TABLE is still there"
      if $kept;
    $raw->disconnect;
  }
}
