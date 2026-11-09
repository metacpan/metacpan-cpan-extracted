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

# OFFLINE (karr k82). ASE::update takes the content of TEXT/IMAGE columns out
# of the statement, sets those columns to '' in a first UPDATE and writes the
# content after it (_update_blobs). When no other column was left to set, it
# returned what _update_blobs returned -- no row count -- and
# DBIO::Row::update read that as "0 rows" and died "row not found" after the
# content was written and committed.
#
# CLAIMED:
#
#   1. $storage->update / $rs->update of LOB content and nothing else returns
#      the number of rows the $where hit. The number is that of the first
#      UPDATE (the LOB columns to their placeholders), the one statement that
#      carries the $where for every row it selects; the content write
#      afterwards is aimed at the same rows and counts nothing of its own.
#   2. $row->update of LOB content alone lives, writes the content, and
#      leaves the object clean and holding what it was given.
#   3. Content in one LOB column and the empty string/undef in the other
#      (also nothing else to set) is the same case.
#   4. With another column beside the content, the count is that of the
#      statement for it (unchanged).
#   5. The empty string / undef alone never reach the content write: one
#      UPDATE, its count comes through; $row->update lives.
#   6. A $where that hits no row returns 0 (as "0E0"), and $row->update
#      then dies "row not found" -- that is true.
#
# NOTHING HERE CONNECTS (see t/69-lob-row-values.t).

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

our $ROWS = 1;               # what execute() answers: the rows a statement hit
my $IDENTITY = 42;           # what the server says the last identity is

my (@EXECUTED, @SENT);

{
  package T::K82::STH;

  sub new { bless { sql => $_[1], bind => [] }, $_[0] }

  sub bind_param       { $_[0]{bind}[ $_[1] - 1 ] = $_[2]; 1 }
  sub bind_param_inout { 1 }

  sub execute {
    my $self = shift;
    push @EXECUTED, { sql => $self->{sql}, bind => [ @{ $self->{bind} } ] };
    return $ROWS;
  }

  sub fetchall_arrayref { [ [ $IDENTITY ] ] }
  sub fetchrow_array    { () }
  sub finish            { 1 }
  sub err               { undef }
  sub errstr            { undef }
}

{
  package T::K82::DBH;

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

  sub prepare        { T::K82::STH->new($_[1]) }
  sub prepare_cached { T::K82::STH->new($_[1]) }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K82::DBH->new };

# The conversation with the server about a LOB's content: a record of what it
# was handed. It answers like the real one, which returns no row count.
local *DBIO::Sybase::Storage::ASE::LOBWriter::_update_blobs = sub {
  my ($self, $source, $blob_cols, $where) = @_;
  push @SENT, { content => { %$blob_cols }, where => $where };
  return '';
};
use warnings 'redefine';

# The FreeTDS notice of the ASE class is no finding of this file.
$ENV{DBIO_SYBASE_FREETDS_NOWARN} = 1;
# These files pin what is SENT, with the write of the content replaced. The
# refusal of LOB content through FreeTDS (karr k97, t/111) is replaced with it:
# their FreeTDS flavour stands for the statements, not for a client that fails.
local *DBIO::Sybase::Storage::ASE::LOBWriter::_refuse_lob_content = sub { };

{
  package T::K82::Result::Lob;
  use base 'DBIO::Core';
  __PACKAGE__->table('k82_lob');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer', is_auto_increment => 1 },
    c_image => { data_type => 'image', is_nullable => 1 },
    c_text  => { data_type => 'text',  is_nullable => 1 },
    name    => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K82::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('Sybase');
  __PACKAGE__->register_class(Lob => 'T::K82::Result::Lob');
}


sub reset_records { @EXECUTED = @SENT = () }

for my $client (
  [ 'Open Client, placeholders',    $OPEN_CLIENT, 1, 1, 1, $ASE ],
  [ 'Open Client, no placeholders', $OPEN_CLIENT, 0, 1, 1, "${ASE}::NoBindVars" ],
  [ 'FreeTDS, placeholders',        $FREETDS,     1, 1, 1, "${ASE}::FreeTDS" ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, local $PLACEHOLDERS,
    local $TYPELESS, my $class) = @$client;

  my $schema  = T::K82::Schema->connect($DSN, 'sa', 's3cret');
  my $storage = $schema->storage;
  $storage->ensure_connected;
  is ref $storage, $class, "$name: (the storage is $class)";

  my $rs     = $schema->resultset('Lob');
  my $source = $rs->result_source;

  my $stored = sub {
    $rs->result_class->inflate_result($source, {
      id => 7, c_text => 'old text', c_image => 'old image', name => 'old',
    });
  };

  # 1. the storage and the resultset
  for my $rows (1, 3) {
    local $ROWS = $rows;

    reset_records();
    is $storage->update($source, { c_text => 'new' }, { id => 7 }), $rows,
      "$name: the storage update of content alone returns the $rows row(s) the where hit";
    is_deeply [ map { $_->{content} } @SENT ], [ { c_text => 'new' } ],
      '... and the content is written';

    reset_records();
    is $rs->search({ id => 7 })->update({ c_text => 'new', c_image => 'img' }), $rows,
      "$name: the rs update of content in both LOB columns returns $rows";

    reset_records();
    is $rs->search({ id => 7 })->update({ c_text => 'new', c_image => '' }), $rows,
      "$name: the rs update of content and the empty string returns $rows (3)";

    reset_records();
    is $rs->search({ id => 7 })->update({ c_text => 'new', name => 'x' }), $rows,
      "$name: the rs update of content and another column returns $rows (4)";

    reset_records();
    is $rs->search({ id => 7 })->update({ c_text => '', c_image => undef }), $rows,
      "$name: the rs update of the empty string and undef alone returns $rows (5)";
    is scalar(@SENT), 0, '... and writes no content';
  }

  # 2. 3. 5. the row object
  for my $case (
    [ 'content in the TEXT column', { c_text => 'new text' } ],
    [ 'content in both LOB columns', { c_text => 'new text', c_image => 'img' } ],
    [ 'content and the empty string', { c_text => 'new text', c_image => '' } ],
    [ 'content and undef', { c_text => 'new text', c_image => undef } ],
    [ 'the empty string alone', { c_text => '' } ],
    [ 'undef alone', { c_text => undef } ],
  ) {
    my ($what, $update) = @$case;
    local $ROWS = 1;

    reset_records();
    my $row = $stored->();
    lives_ok { $row->update({ %$update }) } "$name: the row update of $what lives";

    is_deeply { map { $_ => $row->get_column($_) } keys %$update }, $update,
      '... the object holds what it was given';
    ok !$row->get_dirty_columns, '... and has no dirty column';
  }

  # 6. a where that hits nothing
  {
    local $ROWS = "0E0";   # what DBI answers for no row
    my $row = $stored->();
    throws_ok { $row->update({ c_text => 'new text' }) } qr/not found/,
      "$name: the row update of content, the row gone: row not found (6)";
  }
}

done_testing;
