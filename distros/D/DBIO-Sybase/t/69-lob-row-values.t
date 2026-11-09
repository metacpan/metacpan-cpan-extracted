use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::Sybase::Storage::ASE::NoBindVars;

# OFFLINE (karr k79). A TEXT or IMAGE value does not go to ASE in the INSERT
# that names its column: DBIO::Sybase::Storage::ASE::insert has
# _remove_blob_cols put a placeholder in its place -- literal SQL, a SCALAR
# ref (t/67-lob-placeholder.t) -- and writes the content afterwards. Core's
# insert returns the columns as it was handed them, and DBIO::Row::insert
# stores every returned column that is not what the object had. So the object
# create() returned had the placeholder in its LOB columns, a SCALAR ref,
# until it was read again -- whatever it had been given.
#
# CLAIMED:
#
#   1. After create() the row object holds, in a TEXT and in an IMAGE column,
#      the value it was given -- content, the empty string, undef -- and not a
#      reference; it is in storage and has no dirty column. A LOB column that
#      was not named is not in the object.
#   2. It holds that without having read the row: no statement but the INSERT
#      names a LOB column.
#   3. Both ways insert() has out give that: inside a transaction of the
#      caller, where the storage inserts itself, and outside one, where its
#      writer storage does.
#   4. What $storage->insert returns has the values too, beside the identity
#      -- that is where the object gets them from.
#   5. The statement is as it was: the placeholder stands in the INSERT, the
#      content is written after it. The object does not have its value
#      because the placeholder is gone (t/67-lob-placeholder.t, which holds
#      what is sent, is the file for that; here it is one test a case).
#   6. update() through the row object never did this, and is pinned so:
#      DBIO::Row::update takes a row count from the storage and no column, so
#      the object keeps what it was given. Green before the fix of karr k79.
#
# THE EMPTY STRING. ASE has no empty value: it keeps one space for '' (the
# byte 0x20 in an IMAGE column). After create({ c_text => '' }) the object
# could answer '' -- what it was given -- or ' ' -- what the column holds. It
# answers ''. An object holds what it was given, in every column, until the
# row is read: DBIO::Storage::DBI::insert returns the columns as it got them
# and asks the server only for a primary key it was not given and for a
# retrieve_on_insert column without a value, and DBIO::Row::insert stores
# what comes back. Nothing a server makes of a value reaches the object that
# way -- not the padding of a CHAR, not the rounding of a DATETIME, and not
# this space either, which ASE puts into a VARCHAR column for '' just as it
# does into a TEXT column: t/70-lob-row-values-live.t has the two side by
# side, and the object answers '' for both. A LOB column answering ' ' would
# be the one column whose object knows the server's version -- and it would
# not have read it but been told by this driver, which then carries a copy of
# a rule of the server instead of a value. Who wants what the server holds
# asks for it: discard_changes.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced; the handle and its
# statements record what they are given, as in t/67-lob-placeholder.t, and
# _insert_blobs, the ct_send_data conversation with a server, is a record of
# what it was handed. t/70-lob-row-values-live.t asks ASE.
#
# NOT CLAIMED, seen while this was written and left alone:
#
#   * the hash a caller hands to $storage->insert, to $rs->update or -- as
#     rows of arrays -- to populate(): was written into with the
#     placeholders; the storage works on a copy now (karr k83,
#     t/81-lob-caller-data-untouched.t).
#   * (done, karr k82, t/82-lob-only-update-rowcount.t) $row->update of LOB
#     content and nothing else. ASE::update had no row
#     count to return then, and DBIO::Row::update takes that for "row not
#     found" -- after the content is written. The update below names another
#     column beside it.
#   * create({}): the object holds the primary key and nothing else (karr
#     k80, k84), t/78-create-empty-lob.t.

my $ASE = 'DBIO::Sybase::Storage::ASE';
my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';

my $OPEN_CLIENT = 'Sybase Client-Library/16.0/P/x86_64/Linux';
my $FREETDS     = 'freetds v1.3.17';

my $EMPTY = q{''};   # the literal, as it stands in a statement

# What the fake client library answers; set per case.
our $OC_VERSION   = $OPEN_CLIENT;
our $DYNAMIC      = 1;       # syb_dynamic_supported
our $PLACEHOLDERS = 1;       # select ?
our $TYPELESS     = 1;       # select 1 where 1 = ?

my $IDENTITY = 42;           # what the server says the last identity is

my (@EXECUTED, @SENT);

{
  package T::K79::STH;

  sub new { bless { sql => $_[1], bind => [] }, $_[0] }

  sub bind_param       { $_[0]{bind}[ $_[1] - 1 ] = $_[2]; 1 }
  sub bind_param_inout { 1 }

  sub execute {
    my $self = shift;
    push @EXECUTED, { sql => $self->{sql}, bind => [ @{ $self->{bind} } ] };
    return 1;
  }

  sub fetchall_arrayref { [ [ $IDENTITY ] ] }
  sub fetchrow_array    { () }
  sub finish            { 1 }
  sub err               { undef }
  sub errstr            { undef }
}

{
  package T::K79::DBH;

  sub new {
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => 'Sybase' },
      syb_oc_version        => $OC_VERSION,
      syb_dynamic_supported => $DYNAMIC,
    }, $_[0];
  }

  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
  sub begin_work { 1 }
  sub commit     { 1 }
  sub rollback   { 1 }
  sub err        { undef }
  sub errstr     { undef }

  # The placeholder probes of DBIO::Storage::DBI are a do() with a bind value.
  sub do {
    my ($self, $sql) = @_;
    die "this connection binds no value without a type\n"
      if $sql =~ /where 1 = \?/ and not $TYPELESS;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }

  sub selectrow_arrayref { [ 1, 'DBMS_NAME', 'SQL Server' ] }   # sp_server_info
  sub selectrow_array    { $IDENTITY }

  sub quote {
    my ($self, $value) = @_;
    return 'NULL' unless defined $value;
    $value =~ s/'/''/g;
    return "'$value'";
  }

  sub prepare        { T::K79::STH->new($_[1]) }
  sub prepare_cached { T::K79::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K79::DBH->new };

# The conversation with the server about a LOB's content.
# These files pin what is SENT, with the write of the content replaced. The
# refusal of LOB content through FreeTDS (karr k97, t/111) is replaced with it:
# their FreeTDS flavour stands for the statements, not for a client that fails.
local *DBIO::Sybase::Storage::ASE::LOBWriter::_refuse_lob_content = sub { };
local *DBIO::Sybase::Storage::ASE::LOBWriter::_insert_blobs = sub {
  my ($self, $source, $blob_cols, $row) = @_;
  push @SENT, { content => { %$blob_cols }, id => $row->{id} };
};
use warnings 'redefine';

# The FreeTDS notice of the ASE class is no finding of this file.
$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

{
  package T::K79::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k79_lob');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K79::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K79::Result::Lob');
}

sub reset_records { @EXECUTED = @SENT = () }

# What stands in the VALUES list of an INSERT, one entry per column.
sub values_of {
  my ($list) = $_[0] =~ /\bVALUES\s*\((.*)\)/;
  return [ map { s/\A\s+|\s+\z//gr } split /,/, $list // '' ];
}

# What a value is, in words a failing test can print.
sub worded {
  my $value = shift;
  return 'undef' unless defined $value;
  return ref($value) . " ref to <$$value>" if ref $value eq 'SCALAR';
  return 'the ' . length($value) . "-character string <$value>";
}

sub worded_columns {
  my $columns = shift;
  return { map { $_ => worded($columns->{$_}) } keys %$columns };
}

# The statements that name a LOB column and are no INSERT: a read of the row.
sub reads {
  [ map { $_->{sql} }
    grep { $_->{sql} =~ /c_text|c_image/ and $_->{sql} !~ /\bINSERT INTO\b/ }
    @EXECUTED ];
}

my @GIVEN = (
  # what, the TEXT, the IMAGE, are they written after the INSERT
  [ 'content',          'some text', 'image bytes', 1 ],
  [ 'the string 0',     '0',         '0',           1 ],
  [ 'the empty string', '',          '',            0 ],
  [ 'undef',            undef,       undef,         0 ],
);

for my $client (
  # name, client library, dynamic, placeholders, typeless, class
  [ 'Open Client, placeholders',
    $OPEN_CLIENT, 1, 1, 1, $ASE ],
  [ 'Open Client, auto_cast',
    $OPEN_CLIENT, 1, 1, 0, $ASE ],
  [ 'Open Client, no placeholders',
    $OPEN_CLIENT, 0, 1, 1, "${ASE}::NoBindVars" ],
  [ 'FreeTDS, placeholders',
    $FREETDS, 1, 1, 1, "${ASE}::FreeTDS" ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, local $PLACEHOLDERS,
    local $TYPELESS, my $class) = @$client;

  my $schema  = T::K79::Schema->connect($DSN, 'sa', 's3cret');
  my $storage = $schema->storage;
  $storage->ensure_connected;

  is ref $storage, $class, "$name: (the storage is $class)";

  my $rs     = $schema->resultset('Lob');
  my $source = $rs->result_source;

  # ------------------------------------------------- 1 - 3, 5. create()
  for my $way (
    [ 'outside a transaction', sub { $_[0]->() } ],
    [ 'inside a transaction',  sub { $schema->txn_do($_[0]) } ],
  ) {
    my ($where, $run) = @$way;

    for my $given (@GIVEN) {
      my ($what, $text, $image, $written_after) = @$given;

      reset_records();
      my $row;
      lives_ok {
        $run->(sub {
          $row = $rs->create({ c_text => $text, c_image => $image, name => 'n' });
        });
      } "$name, $where: create() with $what in both LOB columns lives";

      is_deeply worded_columns({ $row ? $row->get_columns : () }),
        worded_columns({ id => $IDENTITY, c_text => $text, c_image => $image, name => 'n' }),
        '... and the object holds what it was given in each of them, beside '
      . 'the identity -- no reference';

      ok $row && $row->in_storage && !$row->get_dirty_columns,
        '... is in storage and has no dirty column';

      is_deeply reads(), [],
        '... and has that without a read: no statement but the INSERT names '
      . 'a LOB column';

      my ($insert) = grep { $_->{sql} =~ /\bINSERT INTO\b/ } @EXECUTED;
      my $literal  = defined $text ? $EMPTY : 'NULL';

      is_deeply [
          [ @{ values_of($insert->{sql}) }[0, 1] ],
          [ map { $_->{content} } @SENT ],
        ],
        [
          [ $literal, $literal ],
          [ $written_after ? { c_text => $text, c_image => $image } : () ],
        ],
        "... the INSERT has the placeholder $literal for both all the same"
      . ( $written_after ? ', and the content is written after it' : '' )
        or diag $insert->{sql};
    }
  }

  # A LOB column with content beside an empty one, and one that is not named.
  {
    reset_records();
    my $row = $rs->create({ c_text => 'some text', c_image => '' });

    is_deeply worded_columns({ $row->get_columns }),
      worded_columns({ id => $IDENTITY, c_text => 'some text', c_image => '' }),
      "$name: create() with content in one LOB column and the empty string "
    . 'in the other: the object holds each';
  }

  {
    reset_records();
    my $row = $rs->create({ c_text => 'some text', name => 'n' });

    is_deeply worded_columns({ $row->get_columns }),
      worded_columns({ id => $IDENTITY, c_text => 'some text', name => 'n' }),
      "$name: create() without the IMAGE column: the object has no such "
    . 'column, and the TEXT it was given';
  }

  # --------------------------------------------- 4. what the storage returns
  for my $given (@GIVEN) {
    my ($what, $text, $image) = @$given;

    reset_records();
    my $returned = $storage->insert(
      $source, { c_text => $text, c_image => $image, name => 'n' },
    );

    is_deeply worded_columns($returned),
      worded_columns({ id => $IDENTITY, c_text => $text, c_image => $image, name => 'n' }),
      "$name: \$storage->insert with $what in both LOB columns returns the "
    . 'values, not their placeholders';
  }

  # ------------------------------------------- 6. update() through the object
  #
  # Pinned, and green before karr k79 was fixed: nothing of an update comes
  # back from the storage into the object.
  my $stored = sub {
    $rs->result_class->inflate_result($source, {
      id => 7, c_text => 'old text', c_image => 'old image', name => 'old',
    });
  };

  for my $case (
    [ 'both LOB columns to the empty string',
      { c_text => '', c_image => '' },
      { c_text => '', c_image => '', name => 'old' } ],
    [ 'both LOB columns to undef',
      { c_text => undef, c_image => undef },
      { c_text => undef, c_image => undef, name => 'old' } ],
    [ 'a LOB column to content, the other to the empty string, and the name',
      { c_text => 'new text', c_image => '', name => 'new' },
      { c_text => 'new text', c_image => '', name => 'new' } ],
  ) {
    my ($what, $update, $expected) = @$case;

    reset_records();
    my $row = $stored->();
    lives_ok { $row->update({ %$update }) }
      "$name: \$row->update of $what lives";

    is_deeply worded_columns({ $row->get_columns }),
      worded_columns({ id => 7, %$expected }),
      '... and the object holds what it was given -- no reference';

    ok !$row->get_dirty_columns, '... and has no dirty column';
  }

  {
    my $row = $stored->();
    $row->c_text('');
    $row->c_image(undef);
    $row->update;

    is_deeply worded_columns({ $row->get_columns }),
      worded_columns({ id => 7, c_text => '', c_image => undef, name => 'old' }),
      "$name: the LOB columns set through their accessors, then update(): "
    . 'the object holds what was set';
  }
}

done_testing;
