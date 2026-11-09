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

# OFFLINE (karr k72). A TEXT or IMAGE value does not go to ASE in the INSERT or
# UPDATE that names its column. DBIO::Sybase::Storage::ASE::LOBWriter takes it
# out first -- _remove_blob_cols for insert and update, _remove_blob_cols_array
# for _insert_bulk -- and leaves a placeholder in its place; the content is
# written afterwards with ct_send_data, for the values that have any.
#
# The placeholder is literal SQL: NULL for undef, and '' -- the empty string
# literal -- for every other value. For the second one the code had the STRING
# of two apostrophes, a value: it was bound (or, without placeholders, quoted
# into the statement as ''''''), and a LOB set to the empty string, which gets
# no ct_send_data after it, kept two apostrophes as its content. Measured
# against ASE 16.0 SP02 on 2026-10-07: TEXT of length 2, IMAGE 0x2727.
#
# CLAIMED:
#
#   1. _remove_blob_cols and _remove_blob_cols_array put a SCALAR ref to ''
#      where a defined LOB value was -- empty or not -- and \'NULL' where undef
#      was; they return the values that are not empty, and those only; a column
#      that is no LOB is left alone.
#   2. What the storage then sends for an empty LOB has '' in the statement and
#      no value for it: through insert, through update and through
#      _insert_bulk, and whichever way the storage binds -- placeholders,
#      auto_cast, none at all (NoBindVars), FreeTDS. This is the claim the
#      first one is for; with the string back, every flavour of it is red.
#   3. The update of a LOB that has content goes in two statements, and the
#      first one, which only empties the columns ct_send_data is about to
#      write, sets them to the same literal.
#   4. In _insert_bulk a literal is no bind of the statement and takes nothing
#      from the rows, so a slice of LOB columns only is sent without
#      placeholders at all -- and so goes through a storage that has none.
#
# NOTHING HERE CONNECTS. DBI->connect is replaced; the handle and its
# statements record what they are given. _insert_blobs, which is the
# ct_send_data conversation with a server, is replaced by a record of what it
# was handed. So this file shows what is sent and not what a server makes of
# it: t/68-lob-placeholder-live.t asks ASE.
#
# NOT CLAIMED, and seen while this was written (karr k72), each a card of its
# own:
#
#   * what a row object holds after create() (karr k79): the value it was
#     given, not the placeholder. t/69-lob-row-values.t holds that.
#   * a slice of _insert_bulk that mixes undef and a value in one LOB column
#     (karr k81, settled): t/84-lob-populate-mixed.t holds that.
#   * a LOB column given as literal SQL (karr k80, settled): it stays literal
#     SQL, t/78-create-empty-lob.t holds that.

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

my (@EXECUTED, @INOUT, @SENT);

{
  package T::K72::STH;

  sub new { bless { sql => $_[1], bind => [] }, $_[0] }

  sub bind_param { $_[0]{bind}[ $_[1] - 1 ] = $_[2]; 1 }

  # Where DBIO::Storage::DBI sends a bind value that is a SCALAR ref.
  sub bind_param_inout { push @INOUT, $_[0]{sql}; 1 }

  sub execute {
    my $self = shift;
    push @EXECUTED, { sql => $self->{sql}, bind => [ @{ $self->{bind} } ] };
    return 1;
  }

  sub execute_for_fetch {
    my ($self, $fetch_tuple, $tuple_status) = @_;
    my $rows = 0;
    while (my $tuple = $fetch_tuple->()) {
      push @EXECUTED, { sql => $self->{sql}, bind => [ @$tuple ] };
      push @$tuple_status, 1;
      $rows++;
    }
    return $rows;
  }

  sub fetchall_arrayref { [ [ $IDENTITY ] ] }
  sub fetchrow_array    { () }
  sub finish            { 1 }
  sub err               { undef }
  sub errstr            { undef }
}

{
  package T::K72::DBH;

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

  sub prepare        { T::K72::STH->new($_[1]) }
  sub prepare_cached { T::K72::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K72::DBH->new };

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
  package T::K72::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k72_lob');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K72::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K72::Result::Lob');
}

sub reset_records { @EXECUTED = @INOUT = @SENT = () }

# The INSERT and UPDATE statements that were executed, in order.
sub written { grep { $_->{sql} =~ /\b(?:INSERT INTO|UPDATE)\b/ } @EXECUTED }

# What stands in a statement: the VALUES list of an INSERT, the SET list of an
# UPDATE, one entry per column.
sub values_of {
  my ($list) = $_[0] =~ /\bVALUES\s*\((.*)\)/;
  return [ map { s/\A\s+|\s+\z//gr } split /,/, $list // '' ];
}

sub set_of {
  my ($list) = $_[0] =~ /\bSET\s+(.*?)\s+WHERE\b/s;
  return [ map { s/\A\s+|\s+\z//gr } split /,/, $list // '' ];
}

# What a placeholder is, in words a failing test can print.
sub placeholder {
  my $value = shift;
  return 'undef' unless defined $value;
  return ref($value) . " ref to <$$value>" if ref $value eq 'SCALAR';
  return 'the ' . length($value) . "-character string <$value>";
}

my $LITERAL_EMPTY = "SCALAR ref to <$EMPTY>";
my $LITERAL_NULL  = 'SCALAR ref to <NULL>';

# ----------------------------------- 1. the placeholders, without a storage
#                                        that is connected to anything

{
  my $storage = $ASE->new;
  my $source  = T::K72::Schema->source('Lob');

  for my $column (qw(c_image c_text)) {
    for my $case (
      [ 'content',            "\x01\x02 it's", 1 ],
      [ 'the empty string',   '',              0 ],
      [ 'the string 0',       '0',             1 ],
    ) {
      my ($what, $value, $sent) = @$case;

      my %fields = ( $column => $value, name => 'n', id => 3 );
      my $blob_cols = $storage->_remove_blob_cols($source, \%fields);

      is placeholder($fields{$column}), $LITERAL_EMPTY,
        "_remove_blob_cols, $column given $what: its placeholder is the "
      . 'literal -- a SCALAR ref, not a string to bind';

      is_deeply $blob_cols, ( $sent ? { $column => $value } : undef ),
        '... and ' . ( $sent
          ? 'the value is returned, to be written after the statement'
          : 'nothing is returned: there is no content to write' );

      is_deeply [ @fields{qw(name id)} ], [ 'n', 3 ],
        '... the columns that are no LOB are left alone';
    }

    my %fields = ( $column => undef, name => 'n' );
    my $blob_cols = $storage->_remove_blob_cols($source, \%fields);

    is placeholder($fields{$column}), $LITERAL_NULL,
      "_remove_blob_cols, $column given undef: its placeholder is the "
    . 'literal NULL';
    is $blob_cols, undef, '... and nothing is returned';
  }

  {
    my %fields = ( c_image => '', c_text => 'text', name => 'n' );
    is_deeply $storage->_remove_blob_cols($source, \%fields), { c_text => 'text' },
      '_remove_blob_cols, an empty LOB beside one with content: the one with '
    . 'content is returned, the empty one is not';
    is_deeply [ map { placeholder($fields{$_}) } qw(c_image c_text) ],
      [ $LITERAL_EMPTY, $LITERAL_EMPTY ],
      '... and both have the same placeholder';
  }

  my @cols = qw(name c_image c_text);
  my @data = (
    [ 'a', "\x01\x02", ''     ],
    [ 'b', '',         'text' ],
    [ 'c', undef,      undef  ],
    [ 'd', '',         ''     ],
  );
  my $blob_cols = $storage->_remove_blob_cols_array($source, \@cols, \@data);

  is_deeply [ map { [ map { placeholder($_) } @$_[1, 2] ] } @data ],
    [
      [ $LITERAL_EMPTY, $LITERAL_EMPTY ],
      [ $LITERAL_EMPTY, $LITERAL_EMPTY ],
      [ $LITERAL_EMPTY, $LITERAL_EMPTY ],
      [ $LITERAL_EMPTY, $LITERAL_EMPTY ],
    ],
    '_remove_blob_cols_array: every defined LOB value of every row, empty or '
  . 'not, is replaced by the literal -- a SCALAR ref --; the row that is undef '
  . 'in a column that has values elsewhere gets the same one (karr k81, one '
  . 'literal for a column; t/84 holds the NULL it gets afterwards)';

  {
    my @undef = ( [ 'a', undef, undef ], [ 'b', undef, undef ] );
    $storage->_remove_blob_cols_array($source, \@cols, \@undef);
    is_deeply [ map { [ map { placeholder($_) } @$_[1, 2] ] } @undef ],
      [ ( [ $LITERAL_NULL, $LITERAL_NULL ] ) x 2 ],
      '_remove_blob_cols_array: undef in every row of a column is the '
    . 'literal NULL';
  }

  is_deeply [ map { $_->[0] } @data ], [qw(a b c d)],
    '... the column that is no LOB is left alone';

  is_deeply $blob_cols, [ [ undef, "\x01\x02" ], [ undef, undef, 'text' ] ],
    '... and what is returned is the content, by row and column';

  ok !exists $blob_cols->[0][2] && !exists $blob_cols->[1][1],
    '... without the empty values: nothing is written for them';

  my @empty = ( [ 'a', '', '' ], [ 'b', undef, '' ] );
  is $storage->_remove_blob_cols_array($source, \@cols, \@empty), undef,
    '_remove_blob_cols_array, no row with content: nothing is returned';
}

# ------------------------------------------ 2 - 4. what the storage sends

for my $client (
  # name, client library, dynamic, placeholders, typeless, class,
  # how the value of a varchar column stands in the statement, is it bound
  [ 'Open Client, placeholders',
    $OPEN_CLIENT, 1, 1, 1, $ASE,
    sub { '?' }, 1 ],
  [ 'Open Client, auto_cast',
    $OPEN_CLIENT, 1, 1, 0, $ASE,
    sub { 'CAST(? AS VARCHAR)' }, 1 ],
  [ 'Open Client, no placeholders',
    $OPEN_CLIENT, 0, 1, 1, "${ASE}::NoBindVars",
    sub { "'$_[0]'" }, 0 ],
  [ 'FreeTDS, placeholders',
    $FREETDS, 1, 1, 1, "${ASE}::FreeTDS",
    sub { '?' }, 1 ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, local $PLACEHOLDERS,
    local $TYPELESS, my $class, my $varchar, my $binds) = @$client;

  my $schema  = T::K72::Schema->connect($DSN, 'sa', 's3cret');
  my $storage = $schema->storage;
  $storage->ensure_connected;

  is ref $storage, $class, "$name: (the storage is $class)";

  my $rs     = $schema->resultset('Lob');
  my $source = $rs->result_source;

  # --------------------------------------------------------------- insert
  {
    reset_records();
    lives_ok { $rs->create({ c_image => '', c_text => '', name => 'n' }) }
      "$name: create() with both LOB columns empty lives";

    my @written = written();
    is scalar @written, 1, '... in one INSERT';

    is_deeply values_of($written[0]{sql}), [ $EMPTY, $EMPTY, $varchar->('n') ],
      "... which has the literal $EMPTY for each of them"
      or diag $written[0]{sql};
    is_deeply $written[0]{bind}, [ $binds ? 'n' : () ],
      '... and no value for either: '
    . ( $binds ? 'the one that is bound is the name' : 'nothing is bound' );
    is_deeply \@SENT, [], '... nothing is written after it';
  }

  {
    reset_records();
    lives_ok { $rs->create({ c_image => undef, c_text => undef, name => 'n' }) }
      "$name: create() with both LOB columns undef lives";

    my @written = written();
    is_deeply values_of($written[0]{sql}), [ 'NULL', 'NULL', $varchar->('n') ],
      '... and has the literal NULL for each of them'
      or diag $written[0]{sql};
    is_deeply $written[0]{bind}, [ $binds ? 'n' : () ],
      '... and no value for either';
  }

  {
    reset_records();
    lives_ok { $rs->create({ c_image => '', c_text => 'some text', name => 'n' }) }
      "$name: create() with a LOB that has content, beside an empty one, lives";

    my @written = written();
    is_deeply values_of($written[0]{sql}), [ $EMPTY, $EMPTY, $varchar->('n') ],
      "... its INSERT has the literal $EMPTY for both"
      or diag $written[0]{sql};
    is_deeply $written[0]{bind}, [ $binds ? 'n' : () ],
      '... and the content is no value of it';
    is_deeply \@SENT, [ { content => { c_text => 'some text' }, id => $IDENTITY } ],
      '... it is written afterwards, into the row just inserted, and the empty '
    . 'column is not';
  }

  # --------------------------------------------------------------- update
  {
    reset_records();
    lives_ok { $rs->search({ id => 7 })->update({ c_image => '', c_text => '' }) }
      "$name: update() of both LOB columns to the empty string lives";

    my @written = written();
    is scalar @written, 1, '... in one UPDATE';

    is_deeply set_of($written[0]{sql}),
      [ "[c_image] = $EMPTY", "[c_text] = $EMPTY" ],
      "... which sets each of them to the literal $EMPTY"
      or diag $written[0]{sql};
    is_deeply $written[0]{bind}, [ $binds ? 7 : () ],
      '... and has no value for either';
    is_deeply \@SENT, [], '... nothing is written after it';
  }

  # A LOB that has content: the columns ct_send_data is to write are emptied
  # by a statement of their own, the rest of the update comes after them.
  {
    reset_records();
    lives_ok {
      $storage->update(
        $source,
        { c_image => '', c_text => 'new text', name => 'n' },
        { id => 7 },
      );
    } "$name: update() of a LOB to content, an empty LOB and a name lives";

    my @written = written();
    is scalar @written, 2, '... in two UPDATE statements';

    is_deeply set_of($written[0]{sql}), [ "[c_text] = $EMPTY" ],
      '... the first empties the column that is to get content, with the '
    . "literal $EMPTY"
      or diag $written[0]{sql};
    is_deeply $written[0]{bind}, [ $binds ? 7 : () ],
      '... and has no value for it';

    is_deeply \@SENT, [ { content => { c_text => 'new text' }, id => 7 } ],
      '... the content is written into that row';

    is_deeply set_of($written[1]{sql}),
      [ "[c_image] = $EMPTY", '[name] = ' . $varchar->('n') ],
      "... and the second sets the empty LOB to the literal $EMPTY, beside "
    . 'the name'
      or diag $written[1]{sql};
    is_deeply $written[1]{bind}, [ $binds ? ( 'n', 7 ) : () ],
      '... with no value for the LOB';
  }

  # ---------------------------------------------------------- _insert_bulk
  #
  # populate() in void context. A slice of LOB columns only has no bind at
  # all once the placeholders are literals.
  {
    reset_records();
    lives_ok {
      $rs->populate([
        { c_image => '', c_text => 'first'  },
        { c_image => '', c_text => 'second' },
      ]);
    } "$name: populate() of two rows of LOB columns only lives";

    my @written = written();
    is_deeply [ map { values_of($_->{sql}) } @written ],
      [ ( [ $EMPTY, $EMPTY ] ) x 2 ],
      "... the INSERT has the literal $EMPTY for both and is executed once a row"
      or diag map { "$_->{sql}\n" } @written;
    is_deeply [ map { $_->{bind} } @written ], [ [], [] ],
      '... without a value: a literal takes nothing from the rows';
    is_deeply \@SENT, [
        { content => { c_text => 'first'  }, id => $IDENTITY - 1 },
        { content => { c_text => 'second' }, id => $IDENTITY     },
      ],
      '... and the content of each row is written afterwards';
  }

  SKIP: {
    skip "$name: core's _insert_bulk needs a placeholder for a value", 4
      unless $binds;

    reset_records();
    lives_ok {
      $rs->populate([
        { c_image => '', c_text => '', name => 'first'  },
        { c_image => '', c_text => '', name => 'second' },
      ]);
    } "$name: populate() of two rows with empty LOB columns and a name lives";

    my @written = written();
    is_deeply [ map { values_of($_->{sql}) } @written ],
      [ ( [ $EMPTY, $EMPTY, $varchar->('n') ] ) x 2 ],
      "... the INSERT has the literal $EMPTY for both LOB columns"
      or diag map { "$_->{sql}\n" } @written;
    is_deeply [ map { $_->{bind} } @written ], [ [ 'first' ], [ 'second' ] ],
      '... and each row gives it its name, and nothing for a LOB';
    is_deeply \@SENT, [], '... nothing is written after it';
  }

  is_deeply \@INOUT, [],
    "$name: no placeholder reached the statement as a bind value";
}

done_testing;
