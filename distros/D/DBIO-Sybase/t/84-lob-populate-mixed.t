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

# OFFLINE (karr k81). populate() in void context goes through _insert_bulk,
# which (not BCP) hands core's _insert_bulk the rows with the TEXT/IMAGE values
# replaced by placeholders. Core takes a SCALAR ref in the first row as the
# literal SQL of the whole column and dies "Inconsistent literal SQL value" on
# a row with another one. The placeholders were NULL for undef and '' for any
# other value, so rows that are undef in one row and a value in another died,
# in both orders.
#
# CLAIMED, for a LOB column of a populate() slice, whichever the order:
#
#   1. All rows undef: one INSERT per row with the literal NULL, nothing else
#      is done.
#   2. All rows defined: the literal '' for each, the content written after
#      into the row it belongs to; empty strings write nothing.
#   3. Mixed: the column gets ONE literal, '' (the one a value needs, it is
#      what makes ct_send_data find a text pointer), the INSERT is still one
#      statement a row in the order of the slice, and the rows that were undef
#      are set to NULL afterwards by an UPDATE of their own by primary key --
#      no UPDATE for any other row. The identities of the rows are still the
#      last one minus the number of rows, counted up: the slice is not split.
#   4. With or without the identity column in the slice (without, the keys of
#      the rows come from the last identity).
#   5. The rows of the caller stay as they were (t/81).
#   6. A SCALAR ref of the caller in a LOB column stays literal SQL, also
#      beside undef (k80); core wants one literal per column, so it still
#      refuses two different ones.
#
# NOTHING HERE CONNECTS (the fake handle of t/67-lob-placeholder.t). What a
# server makes of the UPDATE is asked in t/85-lob-populate-mixed-live.t.

my $ASE = 'DBIO::Sybase::Storage::ASE';
my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';

my $OPEN_CLIENT = 'Sybase Client-Library/16.0/P/x86_64/Linux';

my $EMPTY = q{''};

our $OC_VERSION   = $OPEN_CLIENT;
our $DYNAMIC      = 1;
our $PLACEHOLDERS = 1;
our $TYPELESS     = 1;

my $IDENTITY = 42;

my (@EXECUTED, @SENT);

{
  package T::K81::STH;

  sub new { bless { sql => $_[1], bind => [] }, $_[0] }

  sub bind_param       { $_[0]{bind}[ $_[1] - 1 ] = $_[2]; 1 }
  sub bind_param_inout { 1 }

  sub execute {
    my $self = shift;
    push @EXECUTED, { sql => $self->{sql}, bind => [ @{ $self->{bind} } ] };
    return 1;
  }

  sub execute_for_fetch {
    my ($self, $fetch, $status) = @_;
    my $n = 0;
    while (my $tuple = $fetch->()) {
      push @EXECUTED, { sql => $self->{sql}, bind => [ @$tuple ] };
      push @$status, 1;
      $n++;
    }
    return $n;
  }

  sub fetchall_arrayref { [ [ $IDENTITY ] ] }
  sub fetchrow_array    { () }
  sub finish            { 1 }
  sub err               { undef }
  sub errstr            { undef }
}

{
  package T::K81::DBH;

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

  sub do {
    my ($self, $sql) = @_;
    die "this connection binds no value without a type\n"
      if $sql =~ /where 1 = \?/ and not $TYPELESS;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }

  sub selectrow_arrayref { [ 1, 'DBMS_NAME', 'SQL Server' ] }
  sub selectrow_array    { $IDENTITY }

  sub quote {
    my ($self, $value) = @_;
    return 'NULL' unless defined $value;
    $value =~ s/'/''/g;
    return "'$value'";
  }

  sub prepare        { T::K81::STH->new($_[1]) }
  sub prepare_cached { T::K81::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K81::DBH->new };

local *DBIO::Sybase::Storage::ASE::LOBWriter::_insert_blobs = sub {
  my ($self, $source, $blob_cols, $row) = @_;
  push @SENT, { content => { %$blob_cols }, id => $row->{id} };
};
use warnings 'redefine';

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

{
  package T::K81::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k81_lob');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K81::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K81::Result::Lob');
}

sub reset_records { @EXECUTED = @SENT = () }

sub inserts { grep { $_->{sql} =~ /\bINSERT INTO\b/ } @EXECUTED }
sub updates { grep { $_->{sql} =~ /\bUPDATE\b/ } @EXECUTED }

sub values_of {
  my ($list) = $_[0] =~ /\bVALUES\s*\((.*)\)/;
  return [ map { s/\A\s+|\s+\z//gr } split /,/, $list // '' ];
}

sub set_of {
  my ($list) = $_[0] =~ /\bSET\s+(.*?)\s+WHERE\b/s;
  return [ map { s/\A\s+|\s+\z//gr } split /,/, $list // '' ];
}

# the id an UPDATE is aimed at: bound, or (no placeholders) in the statement
sub id_of {
  my $u = shift;
  return $u->{bind}[0] if @{ $u->{bind} };
  return ($u->{sql} =~ /\[id\]\s*=\s*(\d+)/)[0];
}

# [ name, values of c_text per row ]
my @CASES = (
  [ 'undef, value',        [ undef, 'a' ]            ],
  [ 'value, undef',        [ 'a', undef ]            ],
  [ 'undef, value, undef', [ undef, 'a', undef ]     ],
  [ 'undef, empty, undef', [ undef, '', undef ]      ],
  [ 'value, undef, empty', [ 'a', undef, '' ]        ],
  [ 'all undef',           [ undef, undef ]          ],
  [ 'all value',           [ 'a', 'b' ]              ],
  [ 'all empty',           [ '', '' ]                ],
);

for my $client (
  [ 'Open Client, placeholders', $OPEN_CLIENT, 1, $ASE ],
  [ 'Open Client, no placeholders', $OPEN_CLIENT, 0, "${ASE}::NoBindVars" ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, my $class) = @$client;
  local $PLACEHOLDERS = $DYNAMIC;

  my $schema  = T::K81::Schema->connect($DSN, 'sa', 's3cret');
  $schema->storage->ensure_connected;
  is ref $schema->storage, $class, "$name: (the storage is $class)";

  my $rs = $schema->resultset('Lob');

  for my $with_id (0, 1) {
    # core's _insert_bulk needs a placeholder for the key it binds
    next if $with_id and not $PLACEHOLDERS;
    for my $case (@CASES) {
      my ($what, $texts) = @$case;
      my $n = @$texts;
      my $tag = "$name, $what" . ( $with_id ? ', id given' : '' );

      my @ids  = $with_id ? (101 .. 100 + $n) : ($IDENTITY - $n + 1 .. $IDENTITY);
      my @rows = $with_id
        ? ( [qw(id c_text)], map { [ $ids[$_], $texts->[$_] ] } 0 .. $#$texts )
        : ( [qw(c_text)],    map { [ $texts->[$_] ] } 0 .. $#$texts );
      my @given = map { [ @$_ ] } @rows;

      reset_records();
      lives_ok { $rs->populate(\@rows) } "$tag: populate() lives"
        or next;

      is_deeply \@rows, \@given, "... the rows of the caller are as they were";

      my $any_value = grep { defined } @$texts;
      my $any_undef = grep { !defined } @$texts;
      my $literal   = $any_value ? $EMPTY : 'NULL';

      my @ins = inserts();
      is_deeply [ map { values_of($_->{sql}) } @ins ],
        [ map { $with_id ? [ $literal, '?' ] : [ $literal ] } 1 .. $n ],
        "... one INSERT a row, in order, the whole column with the literal $literal"
        or diag map { "$_->{sql}\n" } @ins;
      if ($with_id) {
        is_deeply [ map { $_->{bind}[0] } @ins ], \@ids,
          '... the rows in the order of the slice';
      }

      my @upd = updates();
      if ($any_value && $any_undef) {
        is_deeply [ map { [ id_of($_), @{ set_of($_->{sql}) } ] } @upd ],
          [ map { [ $ids[$_], '[c_text] = NULL' ] } grep { !defined $texts->[$_] } 0 .. $#$texts ],
          '... exactly the undef rows are set to NULL afterwards, by their key'
          or diag map { "$_->{sql}\n" } @upd;
      }
      else {
        is scalar @upd, 0, '... no UPDATE';
      }

      is_deeply [ grep { %{ $_->{content} } } @SENT ],
        [ map { { content => { c_text => $texts->[$_] }, id => $ids[$_] } }
            grep { defined $texts->[$_] && length $texts->[$_] } 0 .. $#$texts ],
        '... the content is written into the row it belongs to, and only '
      . 'where there is some';
    }
  }

  # two LOB columns, each its own pattern
  {
    reset_records();
    my @rows = (
      [qw(c_text c_image)],
      [ undef,  'x'   ],
      [ 'a',    undef ],
      [ undef,  undef ],
    );
    my @given = map { [ @$_ ] } @rows;
    lives_ok { $rs->populate(\@rows) } "$name: two LOB columns, mixed in both: lives";
    is_deeply \@rows, \@given, '... the rows of the caller are as they were';

    is_deeply [ map { values_of($_->{sql}) } inserts() ],
      [ ( [ $EMPTY, $EMPTY ] ) x 3 ],
      '... both columns carry the one literal';
    is_deeply [ map { [ id_of($_), sort @{ set_of($_->{sql}) } ] } updates() ],
      [
        [ 40, '[c_text] = NULL' ],
        [ 41, '[c_image] = NULL' ],
        [ 42, '[c_image] = NULL', '[c_text] = NULL' ],
      ],
      '... each row has exactly the NULLs it was given, in one UPDATE';
  }

  # a literal of the caller
  {
    reset_records();
    lives_ok { $rs->populate([ [qw(c_text)], [ \'NULL' ], [ \'NULL' ] ]) }
      "$name: the same literal of the caller in every row stays";
    is_deeply [ map { values_of($_->{sql}) } inserts() ], [ ['NULL'], ['NULL'] ],
      '... as it is';
    throws_ok { $rs->populate([ [qw(c_text)], [ \'NULL' ], [ \"''" ] ]) }
      qr/Inconsistent literal SQL value/,
      '... two different ones of the caller are still refused by core';
  }
}

done_testing;
