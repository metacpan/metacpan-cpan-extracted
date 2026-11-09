use strict;
use warnings;

use Test::More;
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Storage::ASE::NoBindVars;

# LIVE (karr k72). The counterpart of t/67-lob-placeholder.t, which pins
# offline that the storage leaves the literal '' in a statement where a TEXT
# or IMAGE value was. Offline that is a string. This file is where the server
# is asked what it keeps.
#
# CLAIMED, as plain tests:
#
#   1. SERVER BEHAVIOUR, not a wish of this driver: ASE has no empty value.
#      The literal '' in a TEXT column is one space (datalength 1). In an
#      IMAGE column it is taken too -- there is no error about converting a
#      character string -- and is the one byte 0x20. An empty binary literal
#      is not SQL:
#        INSERT .. (c_image) VALUES (0x)
#          -> Msg 123: Must attach a value to the binary prefix '0x';
#             zero-length binary value is not allowed.
#   2. create() with a LOB column set to the empty string stores exactly
#      that: one space in the TEXT column, 0x20 in the IMAGE column -- and not
#      the two apostrophes the placeholder was sent as before (TEXT of length
#      2, IMAGE 0x2727). A row found again through the storage has the space.
#   3. update() of a LOB column to the empty string, of rows that had content,
#      stores the same, and leaves the LOB column it does not name alone.
#   4. undef is still NULL, in create() and in update().
#   5. populate() in void context (_insert_bulk) stores the same for a slice
#      of LOB columns only -- also through a storage without placeholders,
#      which that statement, having none, goes through -- and for a slice
#      with another column where the storage has placeholders.
#   6. FreeTDS only: the write of a LOB's content cannot be done there
#      (ct_data_info), and the driver refuses it before it sends anything
#      (karr k97, LOBWriter::_refuse_lob_content), naming table and column.
#      CLAIM REPLACED (karr k97): this said the write fails after the INSERT,
#      and that in a transaction the caller commits the row stays with what
#      the INSERT put into the column, the placeholder, one space. That is
#      the behaviour the refusal was made to end: now no row is made, with or
#      without a transaction of the caller, and nothing stays to be committed.
#
# Each of 2 to 5 for the storage the DSN leads to and for the NoBindVars
# class, pinned.
#
# Measured 2026-10-07 against SAP ASE 16.0 SP02 PL02, with DBD::Sybase 1.27
# built against FreeTDS 1.3.17, TDS 5.0. What this file does NOT claim:
#
#   * anything about a LOB that has content. Its placeholder is overwritten
#     by ct_send_data, which FreeTDS cannot do: t/10-sybase.t
#     skips those tests there, and nothing of it was run.
#     That ct_data_info finds a text pointer in a row whose column was set to
#     the literal '' is what the placeholder is for, and is NOT VERIFIED here.
#   * anything about the Sybase Open Client libraries. Under them 6 is
#     skipped; what an aborted ct_send_data leaves behind there was not
#     looked at.
#   * that auto_cast changes nothing. The storage the DSN leads to has it off
#     here; forced on, this client library and server refuse every statement
#     with a CAST(? AS ..), with or without a LOB column (Msg 12828).
#   * what a row object holds after create(): t/70-lob-row-values-live.t.
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

my $TABLE = "dbio_k72_lob_$$";

# ------------------------------------------------------------ the schemas

{
  package T::K72L::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table($TABLE);
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# The Sybase component: the storage becomes the ASE class at the first use. A
# schema always declares its driver (core ADR 0067, karr k90).
{
  package T::K72L::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K72L::Result::Lob');
}

{
  package T::K72L::NoBindVars;
  use base 'DBIO::Schema';
  __PACKAGE__->register_class(Lob => 'T::K72L::Result::Lob');
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

# What the server holds in the two LOB columns of the rows $where selects, by
# id: [ length of the TEXT, the TEXT, length of the IMAGE, the IMAGE in hex ]
sub held {
  my $where = shift;
  return $raw->selectall_arrayref(
    "select datalength(c_text), convert(varchar(30), c_text), "
  . "datalength(c_image), bintostr(convert(varbinary(30), c_image)) "
  . "from $TABLE where $where order by id"
  );
}

sub last_id { ( $raw->selectrow_array("select isnull(max(id), 0) from $TABLE") )[0] }

my @SPACE_TEXT  = ( 1, ' ' );      # the literal '' in a TEXT column
my @SPACE_IMAGE = ( 1, '20' );     # ... and in an IMAGE column
my @NULL        = ( undef, undef );

# What the server says to one statement: nothing, or said() of its refusal.
sub refusal {
  my $sql = shift;
  local $raw->{RaiseError} = 0;
  return defined $raw->do($sql) ? '' : said($raw->errstr);
}

note 'client library: ' . ( $raw->{syb_oc_version} || '(unknown)' );
note 'server: ' . said( ( split /\n/, ( $raw->selectrow_array('select @@version') )[0] )[0] );

$raw->do(<<"SQL");
CREATE TABLE $TABLE (
  id      INT IDENTITY PRIMARY KEY,
  c_image IMAGE NULL,
  c_text  TEXT NULL,
  name    VARCHAR(40) NULL
)
SQL

# ==================================================== 1. the server itself

is_deeply [
    refusal("INSERT INTO $TABLE (c_text, name) VALUES ('', 'server text')") || 'accepted',
    held(q{name = 'server text'}),
  ],
  [ 'accepted', [ [ @SPACE_TEXT, @NULL ] ] ],
  q{SERVER: the literal '' in a TEXT column is one space};

is_deeply [
    refusal("INSERT INTO $TABLE (c_image, name) VALUES ('', 'server image')") || 'accepted',
    held(q{name = 'server image'}),
  ],
  [ 'accepted', [ [ @NULL, @SPACE_IMAGE ] ] ],
  q{SERVER: the literal '' is taken for an IMAGE column too, and is the one }
. q{byte 0x20};

like refusal("INSERT INTO $TABLE (c_image, name) VALUES (0x, 'server empty binary')") || 'accepted',
  qr/\AMsg 123: Must attach a value to the binary prefix '0x'; zero-length binary value is not allowed\./,
  'SERVER: an empty binary literal, 0x, is refused -- there is no empty value '
. 'to store';

# ================================================ 2 - 6. through the storage

for my $schema_class (qw(T::K72L::Declared T::K72L::NoBindVars)) {
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

  # ---------------------------------------------------------- 2. create
  for my $case (
    [ { c_image => '' },               [ @NULL,       @SPACE_IMAGE ],
      'the IMAGE column empty: it holds the byte 0x20, not 0x2727' ],
    [ { c_text  => '' },               [ @SPACE_TEXT, @NULL        ],
      'the TEXT column empty: it holds one space, not two apostrophes' ],
    [ { c_image => '', c_text => '' }, [ @SPACE_TEXT, @SPACE_IMAGE ],
      'both LOB columns empty: a space and 0x20' ],
  ) {
    my ($values, $expected, $what) = @$case;
    my $after = last_id();

    my $row = tried { $rs->create({ %$values, name => $tag }) };

    is_deeply [ $row ? 'lived' : 'died', held("id > $after") ],
      [ 'lived', [ $expected ] ],
      "$by: create() with $what" or why();
  }

  {
    my $id = last_id();
    is tried { $rs->find($id)->c_text }, ' ',
      "$by: the row found again through the storage has the space in its "
    . 'TEXT column' or why();
  }

  # ------------------------------------------------------------ 4. undef
  {
    my $after = last_id();
    my $row = tried { $rs->create({ c_image => undef, c_text => undef, name => $tag }) };

    is_deeply [ $row ? 'lived' : 'died', held("id > $after") ],
      [ 'lived', [ [ @NULL, @NULL ] ] ],
      "$by: create() with both LOB columns undef: both are NULL" or why();
  }

  # ---------------------------------------------------------- 3. update
  my $content = sub {
    my $name = shift;
    $raw->do("INSERT INTO $TABLE (c_image, c_text, name) VALUES (0x010203, 'before', '$name')")
      for 1 .. 2;
  };
  my @BEFORE_TEXT  = ( 6, 'before' );
  my @BEFORE_IMAGE = ( 3, '010203' );

  for my $case (
    [ text  => { c_text  => '' },               [ @SPACE_TEXT,  @BEFORE_IMAGE ],
      'the TEXT column to the empty string: a space, and the IMAGE column as it was' ],
    [ image => { c_image => '' },               [ @BEFORE_TEXT, @SPACE_IMAGE  ],
      'the IMAGE column to the empty string: 0x20, and the TEXT column as it was' ],
    [ both  => { c_image => '', c_text => '' }, [ @SPACE_TEXT,  @SPACE_IMAGE  ],
      'both LOB columns to the empty string: a space and 0x20' ],
    [ undef => { c_image => undef, c_text => undef }, [ @NULL, @NULL ],
      'both LOB columns to undef: both are NULL' ],
  ) {
    my ($key, $values, $expected, $what) = @$case;
    my $name = "$tag update $key";

    $content->($name);

    my $lived = tried { $rs->search({ name => $name })->update($values); 1 };

    is_deeply [ $lived ? 'lived' : 'died', held("name = '$name'") ],
      [ 'lived', [ $expected, $expected ] ],
      "$by: update() of two rows with content, $what" or why();
  }

  # ------------------------------------------------- 5. populate, void context
  {
    my $after = last_id();

    my $lived = tried {
      $rs->populate([
        { c_image => '', c_text => '' },
        { c_image => '', c_text => '' },
      ]);
      1;
    };

    is_deeply [ $lived ? 'lived' : 'died', held("id > $after") ],
      [ 'lived', [ ( [ @SPACE_TEXT, @SPACE_IMAGE ] ) x 2 ] ],
      "$by: populate() of two rows of empty LOB columns only: a space and "
    . '0x20 in each' or why();
  }

  SKIP: {
    skip "$by: core's _insert_bulk needs a placeholder for a value", 1
      if $storage->isa('DBIO::Sybase::Storage::ASE::NoBindVars');

    my $after = last_id();

    my $lived = tried {
      $rs->populate([
        { c_image => '', c_text => '', name => "$tag bulk" },
        { c_image => '', c_text => '', name => "$tag bulk" },
      ]);
      1;
    };

    is_deeply [ $lived ? 'lived' : 'died', held("id > $after and name = '$tag bulk'") ],
      [ 'lived', [ ( [ @SPACE_TEXT, @SPACE_IMAGE ] ) x 2 ] ],
      "$by: populate() of two rows of empty LOB columns and a name: a space "
    . 'and 0x20 in each' or why();
  }

  # ------------------------------- 6. the content cannot be written (FreeTDS)
  SKIP: {
    skip "$by: not FreeTDS -- a LOB's content can be written, and what an "
       . 'aborted write leaves behind was not looked at', 3
      unless $storage->_using_freetds;

    my $after = last_id();
    my $refused;

    # DBD::Sybase warns of the same thing it then fails of.
    local $SIG{__WARN__} = sub { warn @_ unless $_[0] =~ /ct_data_info/ };

    my $lived = tried {
      $schema->txn_do(sub {
        eval { $rs->create({ c_text => 'some text', name => "$tag abort" }); 1 }
          or $refused = said($@);
      });
      1;
    };

    like $refused // '(it did not die)',
      qr/table \Q$TABLE\E, column c_text: .*is refused: FreeTDS cannot write the content of a TEXT or IMAGE column/s,
      "$by: under FreeTDS, create() with a TEXT that has content is refused, naming table and column";

    is_deeply [ $lived ? 'lived' : 'died', held("id > $after") ],
      [ 'lived', [] ],
      '... in a transaction the caller commits all the same, no row was made '
    . '(nothing was sent)' or why();

    my $outside = tried { $rs->create({ c_text => 'some text', name => "$tag abort" }); 1 };
    is_deeply [ $outside ? 'lived' : 'died', held("id > $after") ], [ 'died', [] ],
      '... and outside a transaction it is refused as well, no row' or why();
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
