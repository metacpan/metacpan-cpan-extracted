use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;

# OFFLINE (karr k80, k84). ASE has no INSERT .. DEFAULT VALUES, so
# DBIO::Sybase::Storage::ASE::insert writes the literal DEFAULT itself for
# every column of a create({}) (except identity, timestamp and columns with a
# literal default of their own).
#
# CLAIMED:
#
#   1. (k80) A SCALAR ref in a TEXT or IMAGE column is literal SQL and stays
#      so: _remove_blob_cols and _remove_blob_cols_array leave it where it is
#      and make no entry for it; a LOB beside it that has content is still
#      returned. So create({}) on a table with LOB columns names DEFAULT for
#      them in the statement and writes no content afterwards.
#   2. (k84) After create({}) the row object holds the primary key and no
#      other column: no SCALAR ref of the DEFAULT, and the columns are not
#      loaded (has_column_loaded false), as after create({}) on dbio-sqlite.
#      Who wants the values reads the row (discard_changes).
#   3. (k79, kept) A column the caller did give is still in the object, LOB
#      columns with their value; the ones nobody gave are not.
#
# NOTHING HERE CONNECTS: DBI->connect is replaced, as in
# t/67-lob-placeholder.t; t/79-create-empty-lob-live.t asks ASE.

my $DSN = 'dbi:Sybase:host=ase.example;port=5000;database=app';
my $IDENTITY = 42;

my (@EXECUTED, @SENT);

{
  package T::K80::STH;
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
  package T::K80::DBH;
  sub new {
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => 'Sybase' },
      syb_oc_version        => 'Sybase Client-Library/16.0/P/x86_64/Linux',
      syb_dynamic_supported => 1,
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
  sub do         { 1 }
  sub selectrow_arrayref { [ 1, 'DBMS_NAME', 'SQL Server' ] }
  sub selectrow_array    { $IDENTITY }
  sub quote { my $v = $_[1]; $v =~ s/'/''/g; "'$v'" }
  sub prepare        { T::K80::STH->new($_[1]) }
  sub prepare_cached { T::K80::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K80::DBH->new };
# These files pin what is SENT, with the write of the content replaced. The
# refusal of LOB content through FreeTDS (karr k97, t/111) is replaced with it:
# their FreeTDS flavour stands for the statements, not for a client that fails.
local *DBIO::Sybase::Storage::ASE::LOBWriter::_refuse_lob_content = sub { };
local *DBIO::Sybase::Storage::ASE::LOBWriter::_insert_blobs = sub {
  my ($self, $source, $blob_cols, $row) = @_;
  push @SENT, { content => { %$blob_cols }, id => $row->{id} };
};
use warnings 'redefine';

$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;

{
  package T::K80::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k80_lob');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K80::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K80::Result::Lob');
}

sub inserts { grep { $_->{sql} =~ /\bINSERT INTO\b/ } @EXECUTED }

sub values_of {
  my ($list) = $_[0] =~ /\bVALUES\s*\((.*)\)/;
  return [ map { s/\A\s+|\s+\z//gr } split /,/, $list // '' ];
}

# ------------------------------------------------ 1. the LOBWriter itself

{
  my $storage = 'DBIO::Sybase::Storage::ASE'->new;
  my $source  = T::K80::Schema->source('Lob');

  my $default = \'DEFAULT';
  my %fields = ( c_image => $default, c_text => 'text', name => 'n' );
  is_deeply $storage->_remove_blob_cols($source, \%fields), { c_text => 'text' },
    '_remove_blob_cols: a SCALAR ref in a LOB column is no content; the one '
  . 'with content beside it is returned';
  is $fields{c_image}, $default,
    '... and the ref is still the very literal it was';

  my %only = ( c_image => \'NULL', c_text => \'DEFAULT' );
  is $storage->_remove_blob_cols($source, \%only), undef,
    '_remove_blob_cols: LOB columns of literals only: nothing is returned';
  is_deeply [ map { ${ $only{$_} } } qw(c_image c_text) ], [ 'NULL', 'DEFAULT' ],
    '... and both literals stand';

  my @cols = qw(name c_image c_text);
  my @data = ( [ 'a', \'DEFAULT', 'x' ], [ 'b', \'DEFAULT', '' ] );
  my $blob_cols = $storage->_remove_blob_cols_array($source, \@cols, \@data);
  is_deeply [ map { ref $_->[1] ? ${ $_->[1] } : $_->[1] } @data ],
    [ 'DEFAULT', 'DEFAULT' ],
    '_remove_blob_cols_array: a literal in a LOB cell is left alone';
  is_deeply $blob_cols, [ [ undef, undef, 'x' ] ],
    '... and only the content is returned';
}

# ------------------------------------- 2. create({}) through the storage

for my $in_txn (0, 1) {
  my $how = $in_txn ? 'in a transaction' : 'outside one';

  my $schema = T::K80::Schema->connect($DSN, 'sa', 's3cret');
  my $rs     = $schema->resultset('Lob');
  $schema->storage->ensure_connected;
  $schema->txn_begin if $in_txn;

  @EXECUTED = @SENT = ();
  my $row;
  lives_ok { $row = $rs->create({}) } "create({}) $how lives";

  my @ins = inserts();
  is scalar @ins, 1, '... in one INSERT';
  is_deeply values_of($ins[0]{sql}), [qw(DEFAULT DEFAULT DEFAULT)],
    '... which names DEFAULT for every column but the identity, the LOB '
  . 'columns among them' or diag $ins[0]{sql};
  is_deeply $ins[0]{bind}, [], '... with no value for any of them';
  is_deeply \@SENT, [], '... and nothing is written to a LOB afterwards';

  is_deeply { $row->get_columns }, { id => $IDENTITY },
    '... the object holds the primary key and nothing else (no DEFAULT ref)';
  ok !$row->has_column_loaded($_), "... $_ is not loaded"
    for qw(c_image c_text name);
  ok !$row->is_changed, '... and nothing is dirty';

  $schema->txn_rollback if $in_txn;
}

# ----------------------- 3. what the caller gave stays, defaults do not

{
  my $schema = T::K80::Schema->connect($DSN, 'sa', 's3cret');
  my $rs     = $schema->resultset('Lob');
  $schema->storage->ensure_connected;

  @EXECUTED = @SENT = ();
  my $row = $rs->create({ c_text => 'some text' });

  is_deeply \@SENT, [ { content => { c_text => 'some text' }, id => $IDENTITY } ],
    'create() with a text only: it is written afterwards';
  is $row->get_column('c_text'), 'some text',
    '... the object holds the text it was given (k79)';
  ok !$row->has_column_loaded($_), "... and not $_, which it was not given"
    for qw(c_image name);
}

done_testing;
