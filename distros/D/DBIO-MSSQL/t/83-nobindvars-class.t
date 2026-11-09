use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::MSSQL::Storage;

# OFFLINE (karr k57, k48, k63). The class DBIO::MSSQL::Storage::Sybase::
# NoBindVars, which a connection that takes no placeholders gets:
#
#   k57  populate in void context. Core's fast path prepares one statement
#        and executes it once per row, and throws "Unable to invoke fast-path
#        insert without storage placeholder support" when the storage has
#        interpolated the values into the statement -- for every data set, a
#        pure ASCII one included. The class inserts row by row, in one
#        transaction, as the Sybase class does for a data set that cannot go
#        the fast way.
#
#   k48  The decision "this connection takes no placeholders" was taken
#        only for a storage whose class IS DBIO::MSSQL::Storage::Sybase. A
#        storage pinned to that class directly (storage_type) with a storage
#        layer registered on the schema is an instance of a synthesised class
#        that merely derives from it, so the decision was never taken and
#        "?" went to a connection that cannot take it.
#
#   k63  An empty string for an integer column: core's NoBindVars writes it
#        UNQUOTED (interpolate_unquoted: a number needs no quotes), which is
#        no statement ("VALUES ( )"). Measured and pinned here; the server's
#        answer is Msg 102, live in t/84-nobindvars-live.t.
#
# NOTHING HERE CONNECTS: DBI->connect is replaced by a fake DBD::Sybase
# handle that records what is prepared and executed (as in t/81).

my $HAVE_SYBASE = eval { require DBIO::Sybase::Storage; 1 };
die $@ unless $HAVE_SYBASE or $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

plan skip_all => 'DBIO::Sybase is not installed (optional, cpanfile '
  . 'recommends): the class this test is about is built on it'
  unless $HAVE_SYBASE;

require DBIO::MSSQL::Storage::Sybase;

our $PLACEHOLDERS = 1;
our $FAIL_ON;

my @SENT;

{
  package T::K57::STH;

  sub new {
    my ($class, $how, $sql) = @_;
    my $self = bless {
      how => $how, Statement => $sql, bound => [], executed => 0, tuples => [],
    }, $class;
    push @SENT, $self;
    return $self;
  }
  sub bind_param {
    my ($self, $position, $value, $attrs) = @_;
    $self->{bound}[ $position - 1 ] = $value;
    return 1;
  }
  sub execute {
    my $self = shift;
    $self->{executed}++;
    die "server refused\n" if defined $FAIL_ON and $self->{Statement} =~ $FAIL_ON;
    return 1;
  }
  sub execute_for_fetch {
    my ($self, $fetch_tuple, $tuple_status) = @_;
    while (my $tuple = $fetch_tuple->()) {
      push @{ $self->{tuples} }, [ @$tuple ];
      push @$tuple_status, 1;
    }
    return scalar @{ $self->{tuples} };
  }
  sub fetchrow_array     { return }
  sub fetchall_arrayref  { [] }
  sub finish             { 1 }
  sub err                { undef }
  sub errstr             { undef }
}

{
  package T::K57::DBH;

  sub new {
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => 'Sybase' },
      syb_oc_version => 'freetds v1.3.17',
    }, shift;
  }
  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { 1 }
  sub do {
    my ($self, $sql) = @_;
    T::K57::STH->new(do => $sql)->execute;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }
  sub selectrow_array { return 1 }
  sub prepare        { T::K57::STH->new(prepare        => $_[1]) }
  sub prepare_cached { T::K57::STH->new(prepare_cached => $_[1]) }
  sub quote { return "NULL" unless defined $_[1]; (my $value = $_[1]) =~ s/'/''/g; "'$value'" }
}

no warnings 'redefine';
local *DBI::connect = sub { T::K57::DBH->new };
use warnings 'redefine';

{
  package T::K57::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k57_doc');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    title => { data_type => 'varchar', size => 100, is_nullable => 1 },
    num   => { data_type => 'integer', is_nullable => 1 },
    price => { data_type => 'decimal', size => [10, 2], is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

# A storage layer: a plain method package.
{
  package T::K57::Layer;
  sub t71_layer { 'layered' }
}

{
  package T::K57::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(Doc => 'T::K57::Result::Doc');
}

{
  package T::K57::LayeredSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_storage_layer('T::K57::Layer');
  __PACKAGE__->register_class(Doc => 'T::K57::Result::Doc');
}

{
  package T::K57::PinnedSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::MSSQL::Storage::Sybase');
  __PACKAGE__->register_class(Doc => 'T::K57::Result::Doc');
}

{
  package T::K57::PinnedLayeredSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+DBIO::MSSQL::Storage::Sybase');
  __PACKAGE__->register_storage_layer('T::K57::Layer');
  __PACKAGE__->register_class(Doc => 'T::K57::Result::Doc');
}

my $FREETDS_NOTICE = qr/compiled against buggy FreeTDS version|Placeholders do not seem/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ $FREETDS_NOTICE;
};
local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;

my @KEEP;

sub connected {
  my $class = shift;
  my $schema = $class->connect('dbi:Sybase:server=k57srv', 'k57', 'k57pw');
  push @KEEP, $schema;
  $schema->storage->ensure_connected;
  return $schema;
}

sub sent (&) {
  my $code = shift;
  @SENT = ();
  $code->();
  return grep { $_->{how} ne 'do' } @SENT;
}

sub transaction_statements {
  return [ map { $_->{Statement} } grep { $_->{how} eq 'do' } @SENT ];
}

my $NOBINDVARS = 'DBIO::Storage::DBI::NoBindVars';

# ============================ k48: the decision, whatever the class is made of

for my $case (
  [ 'declared'                    => 'T::K57::Schema',              0 ],
  [ 'declared, with a layer'      => 'T::K57::LayeredSchema',       1 ],
  [ 'pinned to ::Sybase'          => 'T::K57::PinnedSchema',        0 ],
  [ 'pinned to ::Sybase, layered' => 'T::K57::PinnedLayeredSchema', 1 ],
) {
  my ($what, $class, $layered) = @$case;

  for my $placeholders (1, 0) {
    local $PLACEHOLDERS = $placeholders;
    my $schema  = connected($class);
    my $storage = $schema->storage;
    my $label   = "$what, " . ( $placeholders ? 'placeholders' : 'no placeholders' );

    is $storage->isa($NOBINDVARS) ? 1 : 0, $placeholders ? 0 : 1,
      "$label: the storage is " . ( $placeholders ? 'not ' : '' ) . 'a NoBindVars class';

    ok $storage->isa('DBIO::MSSQL::Storage::Sybase'),
      "$label: still the class of this driver";
    ok $storage->isa('DBIO::Sybase::Storage::FreeTDS'),
      "$label: the FreeTDS class is mixed in";
    is +( $storage->can('t71_layer') ? $storage->t71_layer : undef ),
      ( $layered ? 'layered' : undef ),
      "$label: the storage layers of the schema are "
    . ( $layered ? 'kept' : 'none' );

    unless ($placeholders) {
      my ($sth) = sent { $schema->resultset('Doc')->create({ title => 'x' }) };
      like $sth->{Statement}, qr/VALUES \('x'\)/,
        "$label: the value is in the statement, no \"?\" went to the connection";
    }
  }
}

# ================================ k57: populate in void context, no placeholders

{
  local $PLACEHOLDERS = 0;
  my $schema = connected('T::K57::Schema');
  my $rs     = $schema->resultset('Doc');

  isa_ok $schema->storage, $NOBINDVARS, '(the storage under test)';

  @SENT = ();
  lives_ok {
    $rs->populate([
      { title => 'one', num => 1 },
      { title => 'two', num => 2 },
      { title => "o'3", num => 3 },
    ]);
  } 'populate in void context, ASCII alone, does not throw';

  my @sent = grep { $_->{how} ne 'do' } @SENT;
  is scalar @sent, 3, '... one statement per row';
  like $sent[0]{Statement}, qr/VALUES \(1, 'one'\)/, '... values in the statement';
  like $sent[2]{Statement}, qr/VALUES \(3, 'o''3'\)/, '... quoted';
  is_deeply [ map { $_->{bound} } @sent ], [ [], [], [] ],
    '... nothing is bound';
  is_deeply transaction_statements(), [ 'BEGIN TRAN', 'COMMIT' ],
    '... in one transaction';

  @SENT = ();
  lives_ok {
    $rs->populate([ { title => 'a', price => '1.50' }, { title => '' } ]);
  } 'also with an empty string and a column some rows lack';

  # the failure of a row rolls the transaction back, it is not half-committed
  {
    local $FAIL_ON = qr/'boom'/;
    @SENT = ();
    throws_ok {
      $rs->populate([ { title => 'ok' }, { title => 'boom' } ]);
    } qr/server refused/, 'a row the server refuses throws';
    is_deeply transaction_statements(), [ 'BEGIN TRAN', 'ROLLBACK' ],
      '... and the transaction is rolled back';
  }

  # a returning context was never the fast path
  my @rows = sent { my @r = $rs->populate([ { title => 'x' }, { title => 'y' } ]) };
  is scalar @rows, 2, 'populate in list context: one INSERT per row, as before';
}

# ===================================== k63: '' for an integer column, pinned

{
  local $PLACEHOLDERS = 0;
  my $rs = connected('T::K57::Schema')->resultset('Doc');

  my ($sth) = sent { $rs->create({ num => '' }) };
  like $sth->{Statement}, qr/VALUES \(\s*\)/,
    "core's NoBindVars writes '' for an integer column unquoted, which is no "
  . 'statement: the server refuses it (Msg 102, t/84-nobindvars-live.t) -- '
  . 'pinned so that a change of core or of this class is noticed';

  ($sth) = sent { $rs->search({ id => 1 })->update({ num => '' }) };
  like $sth->{Statement}, qr/SET \[num\] =\s+WHERE/, '... an UPDATE too';

  ($sth) = sent { $rs->create({ title => '' }) };
  like $sth->{Statement}, qr/VALUES \(''\)/,
    "(for a string column '' is the literal '')";
}

is_deeply \@warnings, [], 'no warning on the way';

done_testing;
