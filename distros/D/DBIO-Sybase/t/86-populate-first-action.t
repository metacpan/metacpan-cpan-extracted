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

# OFFLINE (karr k67). populate() as the FIRST action on a schema whose storage
# is pinned to DBIO::Sybase::Storage::ASE (no dbh yet), void context, array
# rows, died "Can't call method "txn_scope_guard" on an undefined value": the
# writer storage is made by _init, at the first connect, and _insert_bulk used
# it without one.
#
# CLAIMED:
#   1. populate() as the first action lives, inserts one row per INSERT and
#      writes the content of a LOB column into the row it belongs to.
#   2. The same for create() and for an update of LOB content as the first
#      action (insert and update use the writer storage as well).
#   3. The writer storage exists afterwards and is another storage than the
#      one of the schema.
#   4. The rows of the caller stay as they were.
#
# NOTHING HERE CONNECTS (the fake handle of t/84-lob-populate-mixed.t).

my $ASE = 'DBIO::Sybase::Storage::ASE';
my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';

my $OPEN_CLIENT = 'Sybase Client-Library/16.0/P/x86_64/Linux';

our $OC_VERSION   = $OPEN_CLIENT;
our $DYNAMIC      = 1;
our $PLACEHOLDERS = 1;

my $IDENTITY = 42;

my (@EXECUTED, @SENT);

{
  package T::K67::STH;

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
  package T::K67::DBH;

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

  sub prepare        { T::K67::STH->new($_[1]) }
  sub prepare_cached { T::K67::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K67::DBH->new };

local *DBIO::Sybase::Storage::ASE::LOBWriter::_insert_blobs = sub {
  my ($self, $source, $blob_cols, $row) = @_;
  push @SENT, { content => { %$blob_cols }, id => $row->{id} };
};
use warnings 'redefine';

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

{
  package T::K67::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k67_lob');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K67::Schema;
  use base 'DBIO::Schema';
  # pinned to the ASE class itself, not to the base the component declares
  __PACKAGE__->storage_type('+DBIO::Sybase::Storage::ASE');
  __PACKAGE__->register_class(Lob => 'T::K67::Result::Lob');
}

sub inserts { grep { $_->{sql} =~ /\bINSERT INTO\b/ } @EXECUTED }

sub fresh {
  @EXECUTED = @SENT = ();
  my $schema = T::K67::Schema->connect($DSN, 'sa', 's3cret');
  is $schema->storage->_writer_storage, undef,
    '(no dbh yet, so no writer storage yet)';
  return $schema;
}

for my $client (
  [ 'Open Client, placeholders',    $OPEN_CLIENT, 1, $ASE ],
  [ 'Open Client, no placeholders', $OPEN_CLIENT, 0, "${ASE}::NoBindVars" ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, my $class) = @$client;
  local $PLACEHOLDERS = $DYNAMIC;

  {
    my $schema = fresh();
    my @rows  = ( [qw(c_text)], ['a'], [undef], ['b'] );
    my @given = map { [ @$_ ] } @rows;
    lives_ok { $schema->resultset('Lob')->populate(\@rows) }
      "$name: populate() as the first action lives";
    is_deeply \@rows, \@given, '... the rows of the caller are as they were';
    is scalar(inserts()), 3, '... one INSERT a row';
    is_deeply [ map { $_->{content} } grep { %{ $_->{content} } } @SENT ],
      [ { c_text => 'a' }, { c_text => 'b' } ],
      '... the content of the LOB column is written';
    my $st = $schema->storage;
    isa_ok $st, $ASE, '... the storage';
    isa_ok $st->_writer_storage, $ASE, '... the writer storage';
    isnt $st->_writer_storage, $st, '... which is another storage';
  }

  {
    my $schema = fresh();
    lives_ok { $schema->resultset('Lob')->create({ c_text => 'x' }) }
      "$name: create() with LOB content as the first action lives";
    is scalar(inserts()), 1, '... one INSERT';
    is_deeply [ map { $_->{content} } @SENT ], [ { c_text => 'x' } ],
      '... and the content is written';
  }

  {
    my $schema = fresh();
    lives_ok {
      $schema->resultset('Lob')->search({ id => 1 })->update({ c_text => 'y' })
    } "$name: update of LOB content as the first action lives";
  }
}

# the schema that declares the driver base (component, -syb): the storage
# becomes ::ASE at the first use, which is the populate() itself
{
  package T::K67::Declared;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K67::Result::Lob');
}

{
  @EXECUTED = @SENT = ();
  my $schema = T::K67::Declared->connect($DSN, 'sa', 's3cret');
  lives_ok { $schema->resultset('Lob')->populate([ [qw(c_text)], ['a'], ['b'] ]) }
    'declared base: populate() as the first action lives';
  is scalar(inserts()), 2, '... one INSERT a row';
  isa_ok $schema->storage, $ASE, '... the storage';
}

done_testing;
