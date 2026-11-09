use strict;
use warnings;

use Test::More;

use DBI;
use Storable ();
use DBIO::Core;
use DBIO::Schema;
use DBIO::Sybase::Storage;
use DBIO::Sybase::Storage::ASE;
use DBIO::Sybase::Storage::ASE::NoBindVars;

# OFFLINE (karr k83). The LOBWriter replaces the TEXT/IMAGE values by
# placeholders -- literal SQL, a SCALAR ref -- before the statement is built.
# It did that in the structure the caller handed in. CLAIMED: the data of the
# caller is the same after the call as before, deeply, on the three ways that
# gave it away:
#
#   1. $rs->update(\%h): LOB columns with content were deleted from %h, empty
#      strings and undef replaced by a placeholder.
#   2. $storage->insert($source, \%h) called directly: the placeholders (and
#      the DEFAULTs of an empty insert) stayed in %h. Through DBIO::Row::insert
#      nobody saw it, that hands the storage a hash of its own.
#   3. populate() in void context with rows as arrays (_insert_bulk): the
#      arrays of the caller got the placeholders.
#
# And the work is as it was: the content is still written after the
# statement, a hash used twice writes twice.
#
# NOTHING HERE CONNECTS; the fake handle is that of t/69-lob-row-values.t.

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

  # populate: take every tuple, as a driver does, and record the binds
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

my @GIVEN = (
  [ 'content',          'some text', 'image bytes' ],
  [ 'the string 0',     '0',         '0'           ],
  [ 'the empty string', '',          ''            ],
  [ 'undef',            undef,       undef         ],
);

for my $client (
  [ 'Open Client', $OPEN_CLIENT, 1, 1, 1, $ASE ],
  [ 'FreeTDS',     $FREETDS,     1, 1, 1, "${ASE}::FreeTDS" ],
) {
  (my $name, local $OC_VERSION, local $DYNAMIC, local $PLACEHOLDERS,
    local $TYPELESS, my $class) = @$client;

  my $schema  = T::K79::Schema->connect($DSN, 'sa', 's3cret');
  my $storage = $schema->storage;
  $storage->ensure_connected;
  is ref $storage, $class, "$name: (the storage is $class)";

  my $rs     = $schema->resultset('Lob');
  my $source = $rs->result_source;

  for my $given (@GIVEN) {
    my ($what, $text, $image) = @$given;

    # 1. $rs->update(\%h)
    {
      reset_records();
      my %h    = (c_text => $text, c_image => $image, name => 'n');
      my $copy = Storable::dclone(\%h);
      $rs->search({ id => 1 })->update(\%h);
      ok scalar(@EXECUTED), "$name, $what: (update ran)";
      is_deeply \%h, $copy, "$name, $what: \$rs->update leaves the hash as it was";
    }

    # 2. $storage->insert($source, \%h)
    {
      reset_records();
      my %h    = (c_text => $text, c_image => $image, name => 'n');
      my $copy = Storable::dclone(\%h);
      $storage->insert($source, \%h);
      ok scalar(grep { $_->{sql} =~ /INSERT INTO/ } @EXECUTED),
        "$name, $what: (insert ran)";
      is_deeply \%h, $copy, "$name, $what: \$storage->insert leaves the hash as it was";
    }

    # 3. populate in void context, array rows
    {
      reset_records();
      my @rows = ([ $text, $image, 'a' ], [ $text, $image, 'b' ]);
      my $copy = Storable::dclone(\@rows);
      $rs->populate([ [qw(c_text c_image name)], @rows ]);
      ok scalar(@EXECUTED), "$name, $what: (populate ran)";
      is_deeply \@rows, $copy,
        "$name, $what: populate leaves the row arrays as they were";
    }
  }

  # an empty insert does not write its DEFAULTs into the caller's hash
  {
    reset_records();
    my %h;
    $storage->insert($source, \%h);
    is_deeply \%h, {}, "$name: an empty insert leaves the empty hash empty";
  }

  # the copy goes through to the work: the content is sent, each time
  {
    my %h = (c_text => 'kept', name => 'n');
    for my $time (qw(first second)) {
      reset_records();
      $storage->insert($source, \%h);
      is_deeply [ map { $_->{content} } @SENT ], [ { c_text => 'kept' } ],
        "$name: the content is written after the INSERT ($time use of the hash)";
    }
    reset_records();
    $rs->search({ id => 1 })->update(\%h);
    ok scalar(grep { $_->{sql} =~ /UPDATE/ } @EXECUTED),
      "$name: (the update of the same hash ran)";
  }
}

done_testing;
