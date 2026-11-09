use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBI;
use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;

# OFFLINE (karr k56). The value of a binary column did not come back through
# a schema over DBD::Sybase (measured 2026-10-08, SQL Server 2022, DBD::Sybase
# 1.27 / FreeTDS 1.3.17):
#
#   BINARY(n), VARBINARY(n), IMAGE   came back as their hex digits;
#   VARBINARY(MAX)                   A RESULT WITH SUCH A COLUMN HAD NO ROW
#                                    FOR ANY VALUE OF ONE BYTE OR MORE, and no
#                                    error: find() found nothing.
#
# The second is the DBD's: the client library describes VARBINARY(MAX) as
# 2147483647 bytes, the DBD makes room for twice that and two (the hex
# digits), which is 0 in 32 bits, the fetch of a row with a value fails, and
# the DBD drops a row whose fetch fails.
#
# What DBIO::MSSQL::Storage::Sybase does about it:
#
#   * A column of a result source whose data type is a binary one is asked
#     for as CAST(<column> AS IMAGE), with syb_binary_images on for the
#     execute of that statement -- the one form in which this DBD carries
#     the bytes as they are. Decided by the data type, not by what comes
#     back; only for an entry of the select list that is the column itself;
#     not in a subquery, where the column is compared.
#   * A result column the handle describes as VARBINARY(MAX) is refused
#     after the execute, before a row is fetched: whatever was not
#     rewritten throws instead of losing rows.
#
#   1. the select list: which columns, in which statements
#   2. what is not rewritten
#   3. syb_binary_images: for that execute, and not after it
#   4. a VARBINARY(MAX) result column is refused
#   5. the values are handed on as the handle gives them
#   6. the other classes: which read this way, and which do not
#
# NOTHING HERE CONNECTS. DBI->connect is replaced by a fake handle that
# records what is prepared and executed, and describes a result the way the
# test tells it to. That a server answers what is asked this way, and with
# the bytes: t/65-binary-values-live.t.

my $HAVE_SYBASE = eval { require DBIO::Sybase::Storage; 1 };

# Only "not installed" is a reason to skip. With DBIO::Sybase there, this
# distribution's own class not loading is a failure.
die $@ unless $HAVE_SYBASE or $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };

plan skip_all => 'DBIO::Sybase is not installed (optional, cpanfile '
  . 'recommends): what this test is about is built on it'
  unless $HAVE_SYBASE;

require DBIO::MSSQL::Storage::Sybase;

our $PLACEHOLDERS = 1;

# How the fake handle describes the result of a SELECT: [ name, type,
# precision ] per column, or a code reference that is given the statement.
# Without one, a result of a single integer column.
our $DESCRIBE;

# The rows a SELECT hands back, and whether its execute fails.
our @ROWS;
our $EXECUTE_FAILS;
our $EXECUTE_ERROR;      # the text the execute of a SELECT dies with

my %DESCRIBED = (
  int           => [ 4,  10 ],
  varchar       => [ 1,  100 ],
  varchar_max   => [ 1,  2147483647 ],
  binary        => [ -2, 32 ],
  varbinary     => [ -2, 8000 ],
  varbinary_max => [ -2, 2147483647 ],    # what DBD::Sybase reports for it
  image         => [ -4, 2147483647 ],
  sql_variant   => [ 1,  8009 ],          # 8000 and the 9 bytes of its header
);
sub described { [ map { [ $_->[0], @{ $DESCRIBED{ $_->[1] } } ] } @_ ] }

# Every statement a fake handle was given, in order.
my @SENT;

{
  # The attributes of a statement handle are a tied hash, in DBI and here:
  # which of those that describe a result were asked for is kept.
  package T::K56::STH::Attributes;
  require Tie::Hash;
  our @ISA = ('Tie::StdHash');

  my %DESCRIBES = map { $_ => 1 } qw(NUM_OF_FIELDS NAME TYPE PRECISION);

  sub FETCH {
    my ($self, $key) = @_;
    push @{ $self->{asked} }, $key if $DESCRIBES{$key};
    return $self->{$key};
  }
}

{
  package T::K56::STH;

  sub new {
    my ($class, $how, $sql, $dbh) = @_;

    tie my %attributes, 'T::K56::STH::Attributes';
    %attributes = (
      how => $how, Statement => $sql, dbh => $dbh, bound => [], executed => 0,
      asked => [], fetched => 0, finished => 0, NUM_OF_FIELDS => 0,
    );

    my $self = bless \%attributes, $class;
    push @SENT, $self;
    return $self;
  }
  sub bind_param { $_[0]{bound}[ $_[1] - 1 ] = $_[2]; 1 }

  sub execute {
    my $self = shift;

    # what the DBD would decide the fetch of an IMAGE column by
    $self->{binary_images} = $self->{dbh}{syb_binary_images} ? 1 : 0;
    $self->{executed}++;

    # the statement under test, not the connection's own queries: a ping
    # (do) the server answers, or core takes the handle for lost and runs the
    # statement a second time on a new connection
    die "the server refuses this statement\n"
      if $EXECUTE_FAILS and $self->{how} ne 'do';
    die $EXECUTE_ERROR
      if defined $EXECUTE_ERROR and $self->{how} ne 'do';

    if ($self->{Statement} =~ /\A\s*SELECT\b/i) {
      my $columns = ref $DESCRIBE eq 'CODE' ? $DESCRIBE->( $self->{Statement} ) : $DESCRIBE;
      $columns ||= [ [ 'id', 4, 10 ] ];

      $self->{NUM_OF_FIELDS} = @$columns;

      # a type the client library cannot describe leaves these undefined
      @{$self}{qw(NAME TYPE PRECISION)} = map {
        my $i = $_; [ map { $_->[$i] } @$columns ];
      } 0 .. 2 unless $columns->[0][0] eq 'UNDESCRIBED';

      $self->{rows} = [ map { [ @$_ ] } @ROWS ];
    }
    return 1;
  }

  sub bind_columns { my $self = shift; $self->{into} = [ @_ ]; 1 }
  sub fetchrow_array {
    my $self = shift;
    $self->{fetched}++;
    my $row = shift @{ $self->{rows} || [] } or return;
    return @$row;
  }
  sub fetch {
    my $self = shift;
    $self->{fetched}++;
    my $row = shift @{ $self->{rows} || [] } or return;
    ${ $self->{into}[$_] } = $row->[$_] for 0 .. $#$row;
    return $row;
  }
  sub fetchall_arrayref {
    my $self = shift;
    $self->{fetched}++;
    return [ splice @{ $self->{rows} || [] } ];
  }
  sub finish { $_[0]{finished}++; 1 }
  sub err    { undef }
  sub errstr { undef }
  sub FETCH  { $_[0]{ $_[1] } }
}

{
  package T::K56::DBH;

  sub new {
    my ($class, $driver) = @_;
    bless {
      Active => 1, AutoCommit => 1, RaiseError => 1, PrintError => 0,
      Driver => { Name => $driver },
      syb_oc_version => 'freetds v1.3.17',
    }, $class;
  }
  sub FETCH      { $_[0]{$_[1]} }
  sub ping       { 1 }
  sub disconnect { 1 }
  sub get_info   { undef }

  # BEGIN TRAN, COMMIT and the placeholder probe are do()s.
  sub do {
    my ($self, $sql) = @_;
    T::K56::STH->new(do => $sql, $self)->execute;
    die "this connection takes no placeholders\n"
      if $sql =~ /\?/ and not $PLACEHOLDERS;
    return 1;
  }
  sub begin_work { 1 }
  sub commit     { 1 }
  sub rollback   { 1 }
  sub selectrow_array    { return 1 }    # select @@identity
  sub selectrow_arrayref { [ 1 ] }
  sub prepare        { T::K56::STH->new(prepare        => $_[1], $_[0]) }
  sub prepare_cached { T::K56::STH->new(prepare_cached => $_[1], $_[0]) }
  sub quote { (my $value = $_[1]) =~ s/'/''/g; "'$value'" }
}

no warnings 'redefine';
local *DBI::connect = sub {
  my ($class, $dsn) = @_;
  T::K56::DBH->new( $dsn =~ /\Adbi:(\w+):/ ? $1 : 'Sybase' );
};
use warnings 'redefine';

{
  package T::K56::Result::Owner;
  use base 'DBIO::Core';
  __PACKAGE__->table('k56_owner');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    name => { data_type => 'varchar', size => 100 },
    seal => { data_type => 'varbinary', size => -1, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::K56::Result::Doc;
  use base 'DBIO::Core';
  __PACKAGE__->table('k56_doc');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    title    => { data_type => 'varchar', size => 100, is_nullable => 1 },
    body     => { data_type => 'varbinary', size => -1, is_nullable => 1 },
    owner_id => { data_type => 'integer', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
  __PACKAGE__->belongs_to(
    owner => 'T::K56::Result::Owner', 'owner_id', { join_type => 'left' },
  );
}
T::K56::Result::Owner->has_many( docs => 'T::K56::Result::Doc', 'owner_id' );

{
  # every binary data type, and what is none
  package T::K56::Result::Types;
  use base 'DBIO::Core';
  __PACKAGE__->table('k56_types');
  __PACKAGE__->add_columns(
    id      => { data_type => 'integer' },
    fixed   => { data_type => 'binary', size => 16 },
    sized   => { data_type => 'VARBINARY', size => 8000 },
    long    => { data_type => 'varbinary(max)' },
    picture => { data_type => 'image' },
    legacy  => { data_type => 'blob' },
    flag    => { data_type => 'bit' },
    stamp   => { data_type => 'timestamp' },
    words   => { data_type => 'nvarchar', size => -1 },
    untyped => {},
  );
  __PACKAGE__->set_primary_key('id');
}

{
  # a binary primary key
  package T::K56::Result::Hashed;
  use base 'DBIO::Core';
  __PACKAGE__->table('k56_hashed');
  __PACKAGE__->add_columns(
    digest => { data_type => 'binary', size => 32 },
    note   => { data_type => 'varchar', size => 100, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('digest');
}

{
  # every column the session's TEXTSIZE can cut, and some that it cannot
  package T::K56::Result::Notes;
  use base 'DBIO::Core';
  __PACKAGE__->table('k56_notes');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer' },
    t     => { data_type => 'text', is_nullable => 1 },
    nt    => { data_type => 'ntext', is_nullable => 1 },
    vm    => { data_type => 'varchar', size => -1, is_nullable => 1 },
    nvm   => { data_type => 'nvarchar(max)', is_nullable => 1 },
    rvm   => { data_type => 'varchar(max)', is_nullable => 1 },
    small => { data_type => 'varchar', size => 100, is_nullable => 1 },
    doc   => { data_type => 'xml', is_nullable => 1 },
    sv    => { data_type => 'sql_variant', is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

my @SOURCES = qw(Owner Doc Types Hashed Notes);

{
  package T::K56::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class($_ => "T::K56::Result::$_") for @SOURCES;
}

# The DBD::Sybase class announces its FreeTDS workaround once per process.
my $FREETDS_NOTICE = qr/compiled against buggy FreeTDS version/;
my @warnings;
local $SIG{__WARN__} = sub {
  push @warnings, $_[0] unless $_[0] =~ $FREETDS_NOTICE;
};

my @KEEP;   # a storage holds its schema weakly

sub connected {
  my ($dsn, $class, $attrs) = @_;
  my $schema = ( $class || 'T::K56::Schema' )->connect(
    $dsn || 'dbi:Sybase:server=k56srv', 'k56', 'k56', $attrs || {},
  );
  push @KEEP, $schema;
  $schema->storage->ensure_connected;
  return $schema;
}

# What $code made the storage prepare: the statements of a result source,
# not the session set-up around them.
sub sent (&) {
  my $code = shift;
  @SENT = ();
  $code->();
  return grep { $_->{how} ne 'do' } @SENT;
}

# The statement of the one SELECT $code runs, on one line.
sub selected (&) {
  my @sent = &sent(@_);
  die 'expected one statement, got ' . @sent unless @sent == 1;
  ( my $sql = $sent[0]{Statement} ) =~ s/\s+/ /g;
  $sql =~ s/\A | \z//g;
  return $sql;
}

my $schema  = connected();
my $storage = $schema->storage;
my $docs    = $schema->resultset('Doc');
my $dbh     = $storage->dbh;

is ref $storage, 'DBIO::MSSQL::Storage::Sybase::FreeTDS',
  '(the DBD::Sybase storage under test is the class a schema declaring '
. 'MSSQL gets on a dbi:Sybase: DSN)';

# karr k47. A column the session's TEXTSIZE can cut is read behind a guard that
# fails on the server when the value is longer than TEXTSIZE (exact: a value of
# TEXTSIZE bytes is whole). A binary column is, since karr k56, an IMAGE too.
sub guard_message {
  my $label = shift;
  return "'DBIO::MSSQL TEXTSIZE guard: column ''$label'' holds a value longer "
       . "than the session''s TEXTSIZE, ' + CONVERT(VARCHAR(20), \@\@TEXTSIZE) + ' bytes'";
}
sub image {
  my ($column, $label) = @_;
  return "CAST(CASE WHEN DATALENGTH($column) > \@\@TEXTSIZE THEN "
       . 'CONVERT(VARBINARY(MAX), CONVERT(INT, ' . guard_message($label) . ')) '
       . "ELSE CAST($column AS VARBINARY(MAX)) END AS IMAGE)";
}
# kind: 'ntext' (cast, a CASE cannot return one), 'varchar_max', 'nvarchar_max'
# -- by the type the column has on the server (karr k47): 'text' is deployed as
# NVARCHAR(MAX), 'varchar' of size -1 as NVARCHAR(MAX), 'varchar(max)' stays.
sub textual {
  my ($kind, $column, $label) = @_;
  my $fail = 'CONVERT(INT, ' . guard_message($label) . ')';
  my $long = "DATALENGTH($column) > \@\@TEXTSIZE";

  return "CASE WHEN $long THEN CONVERT(NVARCHAR(MAX), $fail) ELSE CAST($column AS NVARCHAR(MAX)) END"
    if $kind eq 'ntext';

  # VARCHAR(MAX) / NVARCHAR(MAX): stays the type it is -- a CASE between the
  # two would return an NVARCHAR, which TEXTSIZE cuts at half the characters.
  # The column itself is the ELSE branch, not a concatenation: a NULL stays
  # NULL under CONCAT_NULL_YIELDS_NULL OFF too.
  my $type = $kind eq 'nvarchar_max' ? 'NVARCHAR(MAX)' : 'VARCHAR(MAX)';
  return "CASE WHEN $long THEN CONVERT($type, $fail) ELSE $column END";
}

my $BODY = image('[me].[body]', 'me.body');

# ====================================== 1. the select list: which, and where

# find() and single() read one row from the statement handle themselves,
# every other read goes through a cursor: both come by the same way.
is selected { $docs->find(7) },
  "SELECT [me].[id], [me].[title], $BODY, [me].[owner_id] "
. 'FROM [k56_doc] [me] WHERE ( [me].[id] = ? )',
  'find(): a VARBINARY(MAX) column is asked for as an IMAGE -- as the column '
. 'itself DBD::Sybase has a buffer of one byte for it, and drops the row';

is selected { $docs->search({ title => 'a' })->single },
  "SELECT [me].[id], [me].[title], $BODY, [me].[owner_id] "
. 'FROM [k56_doc] [me] WHERE ( [title] = ? )',
  'single(): the same';

is selected { $docs->search({ title => 'a' })->all },
  "SELECT [me].[id], [me].[title], $BODY, [me].[owner_id] "
. 'FROM [k56_doc] [me] WHERE ( [title] = ? )',
  'all(), through a cursor: the same';

is selected { my $rs = $docs->search({ title => 'a' }); 1 while $rs->next },
  "SELECT [me].[id], [me].[title], $BODY, [me].[owner_id] "
. 'FROM [k56_doc] [me] WHERE ( [title] = ? )',
  'next(): the same';

is selected { $docs->search({ title => 'a' })->get_column('body')->all },
  "SELECT $BODY FROM [k56_doc] [me] WHERE ( [title] = ? )",
  'get_column() of the binary column';

# Which column is a binary one is what its data type says -- the question
# asked of a bind value since karr k50, with the same answer.
is selected { $schema->resultset('Types')->search->all },
  'SELECT [me].[id], ' . image('[me].[fixed]', 'me.fixed') . ', '
. image('[me].[sized]', 'me.sized') . ', ' . image('[me].[long]', 'me.long')
. ', ' . image('[me].[picture]', 'me.picture') . ', '
. image('[me].[legacy]', 'me.legacy') . ', [me].[flag], [me].[stamp], '
. textual(nvarchar_max => '[me].[words]', 'me.words') . ', '
. '[me].[untyped] FROM [k56_types] [me]',
  'every binary data type is rewritten -- binary, varbinary of any size, '
. 'image, and a name the DDL makes one of them -- since the sized ones come '
. 'back as hex digits; a bit, a timestamp and a column without a '
. 'declared data type are not (an NVARCHAR(MAX) is behind the TEXTSIZE guard '
. 'and no IMAGE)';

is selected {
  $docs->search({}, { columns => [ 'id', { content => 'body' } ] })->all
},
  "SELECT [me].[id], $BODY FROM [k56_doc] [me]",
  'a binary column selected under another name';

is selected { $docs->search({}, { prefetch => 'owner' })->all },
  "SELECT [me].[id], [me].[title], $BODY, [me].[owner_id], [owner].[id], "
. '[owner].[name], ' . image('[owner].[seal]', 'owner.seal') . ' FROM [k56_doc] [me] '
. 'LEFT JOIN [k56_owner] [owner] ON [owner].[id] = [me].[owner_id]',
  'through a join: the binary column of each source';

is selected {
  $docs->search({}, {
    join => 'owner', columns => ['id'], '+columns' => { seal => 'owner.seal' },
  })->all
},
  'SELECT [me].[id], ' . image('[owner].[seal]', 'owner.seal') . ' FROM [k56_doc] [me] '
. 'LEFT JOIN [k56_owner] [owner] ON [owner].[id] = [me].[owner_id]',
  '... and one of the joined source alone';

# The limit dialect wraps the statement in subqueries. The column is an
# IMAGE from the innermost one on, under the name it is selected by.
like selected {
  $docs->search({}, { columns => [qw(id body)], order_by => 'id', rows => 2, offset => 1 })->all
},
  qr/\ASELECT \[me\]\.\[id\], \[body\] FROM \( SELECT \[me\]\.\[id\], \[body\], ROW_NUMBER\(\) OVER\( ORDER BY \[id\] \) AS \[rno__row__index\] FROM \( SELECT \[me\]\.\[id\], \Q$BODY\E AS \[body\] FROM \[k56_doc\] \[me\] \) \[me\] \) \[me\] WHERE /,
  'under rows and offset';

# distinct is a GROUP BY: the column is grouped by as it is (an IMAGE cannot
# be), and selected as an IMAGE.
is selected { $docs->search({}, { columns => ['body'], distinct => 1 })->all },
  "SELECT $BODY FROM [k56_doc] [me] GROUP BY [me].[body]",
  'with distinct: grouped by the column, selected as an IMAGE';

is selected { $docs->search({}, { columns => [qw(id body)], order_by => 'body' })->all },
  "SELECT [me].[id], $BODY FROM [k56_doc] [me] ORDER BY [body]",
  'ordered by the column: the ORDER BY keeps it';

# a condition on a binary value (karr k50) and the column read back
is selected { $docs->search({ body => "\x01\x02" })->all },
  "SELECT [me].[id], [me].[title], $BODY, [me].[owner_id] FROM [k56_doc] [me] "
. 'WHERE ( [body] = CONVERT(VARBINARY(MAX), ?, 1) )',
  'a condition on a binary value is what it was, beside the column read';

is selected { $schema->resultset('Hashed')->find("\xAA" x 32) },
  'SELECT ' . image('[me].[digest]', 'me.digest') . ', [me].[note] FROM [k56_hashed] [me] '
. 'WHERE ( [me].[digest] = CONVERT(VARBINARY(MAX), ?, 1) )',
  'a binary primary key: read as bytes, so that the row object holds the '
. 'key it can be updated and found again by';

{
  my $unquoted = connected(undef, undef, { quote_names => 0 });

  is selected { $unquoted->resultset('Doc')->search({}, { columns => ['body'] })->all },
    'SELECT ' . image('me.body', 'me.body') . ' FROM k56_doc me',
    'without name quoting: the column as the statement names it';
}

# The trace shows what is sent. (For a value that is written it shows the
# statement as it was built, karr k50: there the rewriting would put what
# redact_bind_value is to hide beside the placeholder. A select list has no
# value.)
{
  my @traced;

  $storage->debugcb(sub { push @traced, $_[1] });
  $storage->debug(2);
  $docs->search({ title => 'a' }, { columns => ['body'] })->all;
  $storage->debug(0);
  $storage->debugcb(undef);

  like $traced[0], qr/\ASELECT \Q$BODY\E FROM \[k56_doc\] \[me\] WHERE \( \[title\] = \? \): 'a'/,
    'the trace shows the statement that is sent';
}

# ============================================== 2. what is not rewritten

# A subquery: its column is compared, and an IMAGE cannot be. as_query does
# not come by _select.
is ${ $docs->search({ title => 'a' }, { columns => ['body'] })->as_query }->[0],
  '(SELECT [me].[body] FROM [k56_doc] [me] WHERE ( [title] = ? ))',
  'as_query: the column as it is';

is selected {
  $docs->search(
    { body => { -in => $docs->search({ title => 'a' })->get_column('body')->as_query } },
    { columns => [qw(id body)] },
  )->all
},
  "SELECT [me].[id], $BODY FROM [k56_doc] [me] WHERE ( [body] IN "
. '( SELECT [me].[body] FROM [k56_doc] [me] WHERE ( [title] = ? ) ) )',
  'a subquery in a condition keeps the column, the statement around it has '
. 'the IMAGE';

{
  local @ROWS = ( [ 4 ] );   # count() reads a number

  is selected { $docs->search({}, { columns => ['body'] })->count },
    'SELECT COUNT( * ) FROM [k56_doc] [me]',
    'count() selects no column';

  is selected { $docs->search({}, { columns => ['body'], distinct => 1 })->count },
    'SELECT COUNT( * ) FROM (SELECT [me].[body] FROM [k56_doc] [me] '
  . 'GROUP BY [me].[body]) [me]',
    '... and counts what a subquery with the column as it is gives';
}

is selected { $docs->search({ title => 'a' })->as_subselect_rs->search({}, { columns => ['body'] })->all },
  "SELECT $BODY FROM (SELECT [me].[id], [me].[title], [me].[body], "
. '[me].[owner_id] FROM [k56_doc] [me] WHERE ( [title] = ? )) [me]',
  'a subquery in the FROM keeps it, what is read from it is the IMAGE';

# Not the column itself. A VARBINARY(n) or IMAGE value comes back as hex
# digits there, as before; a VARBINARY(MAX) one is refused (part 4).
is selected { $docs->search->get_column('body')->func('DATALENGTH') },
  'SELECT DATALENGTH( [me].[body] ) FROM [k56_doc] [me]',
  'a function over a binary column is not rewritten';

is selected { $docs->search({}, { select => [ \'me.body' ], as => ['body'] })->all },
  'SELECT me.body FROM [k56_doc] [me]',
  'literal SQL is not rewritten';

is selected {
  $docs->search({}, { select => [ { coalesce => 'body', -as => 'b' } ], as => ['b'] })->all
},
  'SELECT COALESCE( [body] ) AS [b] FROM [k56_doc] [me]',
  '... and neither is the column inside another construct';

# The statements that write are what karr k50 made them.
{
  my ($sth) = sent { $docs->search({ body => "\x01" })->update({ title => 'x' }) };

  is $sth->{Statement},
    'UPDATE [k56_doc] SET [title] = ? WHERE [body] = CONVERT(VARBINARY(MAX), ?, 1)',
    'an UPDATE by a binary value is untouched';

  ($sth) = sent { $schema->resultset('Hashed')->search({ note => 'x' }, { rows => 1 })->delete };

  like $sth->{Statement} =~ s/\s+/ /gr,
    qr/\ADELETE FROM \[k56_hashed\] WHERE \[digest\] IN \( SELECT \[me\]\.\[digest\] FROM /,
    'the subquery of a DELETE by a binary primary key compares the key: '
  . 'the column as it is';
  unlike $sth->{Statement}, qr/IMAGE/, '... nowhere an IMAGE';
}

# ============================================ 3. syb_binary_images

# DBD::Sybase reads an IMAGE column as hex digits too unless this is on, and
# decides it when it describes the result -- in the execute. On for a
# rewritten statement alone: what hand-written SQL and dbh_do read from an
# IMAGE column stays what it was.
{
  local $DESCRIBE = described([ id => 'int' ], [ body => 'image' ]);

  my ($sth) = sent { $docs->search({}, { columns => [qw(id body)] })->all };

  is $sth->{binary_images}, 1,
    'a rewritten statement is executed with syb_binary_images on';
  ok !$dbh->{syb_binary_images}, '... and the handle is as it was afterwards';

  ($sth) = sent { $docs->find(7) };

  is $sth->{binary_images}, 1, 'find(): the same';
  ok !$dbh->{syb_binary_images}, '... and off again';

  ($sth) = sent { $docs->search({}, { columns => [qw(id title)] })->all };

  is $sth->{binary_images}, 0,
    'a statement without a binary column is executed as before';

  ($sth) = sent {
    $docs->search({}, { select => [ \'CAST(me.body AS IMAGE)' ], as => ['body'] })->all
  };

  is $sth->{binary_images}, 0,
    'an IMAGE of hand-written SQL is read as it was: hex digits';

  ($sth) = sent { $docs->search({ title => 'a' })->update({ title => 'b' }) };

  is $sth->{binary_images}, 0, 'an UPDATE is executed as before';
}

{
  local $EXECUTE_FAILS = 1;

  throws_ok { $docs->find(7) } qr/the server refuses this statement/,
    'a rewritten statement the server refuses throws what the server said';
  ok !$dbh->{syb_binary_images},
    '... and syb_binary_images is off again, after a failed execute too';
}

{
  # somebody turned it on for the whole handle
  local $dbh->{syb_binary_images} = 1;
  local $DESCRIBE = described([ id => 'int' ], [ body => 'image' ]);

  my ($sth) = sent { $docs->search({}, { columns => [qw(id body)] })->all };

  is_deeply [ $sth->{binary_images}, $dbh->{syb_binary_images} ], [ 1, 1 ],
    'a handle that has syb_binary_images on keeps it on';
}

# ======================== 4. a VARBINARY(MAX) result column is refused

# What _select did not rewrite and the handle describes as VARBINARY(MAX)
# would lose every row with a value, without an error. Refused after the
# execute -- the first moment the description is there -- and before a fetch.
{
  local $DESCRIBE = described([ id => 'int' ], [ body => 'varbinary_max' ]);
  local @ROWS = ( [ 1, undef ] );
  my @sent;

  throws_ok {
    @sent = sent { $docs->search({}, { select => [ 'id', \'me.body' ], as => [qw(id body)] })->all };
  } qr/\QCannot read this result through DBD::Sybase: its column 2 ('body') is VARBINARY(MAX)\E/,
    'a VARBINARY(MAX) column in literal SQL: the statement is refused, with '
  . 'the position and the name of the column';

  like "$@", qr/drops every row that has a value of one byte or more in such a column, without an error/,
    '... the exception says what would have happened';
  like "$@", qr/data_type is declared as a binary one and it is selected as the column itself/,
    '... what makes the storage read such a column';
  like "$@", qr/\QCONVERT(VARCHAR(MAX), <expression>, 2)\E.*TEXTSIZE.*half as many bytes.*cut/s,
    '... and what to select otherwise, with its limit';

  # Finished, because core asks next whether the connection is alive: with
  # a statement handle still active DBD::Sybase would open a second
  # connection for that (karr k41).
  is_deeply
    [ map { $_->{executed}, $_->{fetched}, $_->{finished} } grep { $_->{how} ne 'do' } @SENT ],
    [ 1, 0, 1 ],
    '... thrown after the execute, before a fetch, the statement finished';

  # by the column, not by the rows: this result has a NULL alone and would
  # have been read right
  throws_ok { $docs->search({}, { select => [ 'id', \'me.body' ], as => [qw(id body)] })->single }
    qr/is VARBINARY\(MAX\)/,
    'single(): refused too -- and whatever the rows hold';

  throws_ok { scalar $docs->search->get_column("body")->max }
    qr/its column 2 \('body'\) is VARBINARY\(MAX\)/,
    'a function over the column that gives a VARBINARY(MAX): refused';

  # a column whose data type is not declared is not rewritten
  throws_ok { $schema->resultset('Types')->search({}, { columns => [qw(id untyped)] })->all }
    qr/is VARBINARY\(MAX\)/,
    'a VARBINARY(MAX) column without a declared data type: refused';

  local $DESCRIBE = described([ id => 'int' ], [ body => 'image' ]);

  my ($next) = sent { $docs->find(7) };

  is $next->{executed}, 1, 'the next statement runs on the same handle';
}

{
  # one column rewritten, one not: every statement is looked at
  local $DESCRIBE = described([ body => 'image' ], [ '' => 'varbinary_max' ]);

  throws_ok {
    $docs->search({}, { select => [ 'body', \'me.body' ], as => [qw(body again)] })->all
  } qr/its column 2 is VARBINARY\(MAX\)/,
    'a rewritten statement with a VARBINARY(MAX) column beside: refused, '
  . 'and a column without a name by its position alone';
}

# What a rewritten column is described as, and everything else that is not
# VARBINARY(MAX): read.
for my $case (
  [ image         => 'an IMAGE (what a rewritten column is)' ],
  [ varbinary     => 'a VARBINARY(8000) (hex digits, as before)' ],
  [ binary        => 'a BINARY(32)' ],
  [ varchar_max   => 'a VARCHAR(MAX), as long and no binary' ],
  [ int           => 'an integer' ],
) {
  my ($type, $what) = @$case;

  local $DESCRIBE = described([ id => 'int' ], [ body => $type ]);
  local @ROWS = ( [ 1, 'value' ] );

  my @rows;
  lives_ok { @rows = $docs->search({}, { columns => [qw(id body)] })->all }
    "a result column described as $what is not refused";
  is scalar @rows, 1, '... and its row is read';
}

{
  # a type the client library cannot describe at all (measured: GEOGRAPHY,
  # HIERARCHYID -- "ct_describe() failed", no TYPE)
  local $DESCRIBE = [ [ 'UNDESCRIBED' ] ];

  lives_ok { $docs->search({}, { columns => ['id'] })->all }
    'a result the handle does not describe is not refused here';
}

# A statement without a result has nothing to look at.
{
  local $DESCRIBE = described([ id => 'varbinary_max' ]);

  my ($sth) = sent { $docs->search({ title => 'a' })->update({ title => 'b' }) };

  is_deeply $sth->{asked}, ['NUM_OF_FIELDS'],
    'an UPDATE: the handle is asked for its number of result columns and '
  . 'nothing else';

  ($sth) = sent { $docs->search({ title => 'a' })->delete };

  is_deeply $sth->{asked}, ['NUM_OF_FIELDS'], 'a DELETE: the same';

  lives_ok { ($sth) = sent { $docs->create({ title => 'a', body => "\x01" }) } }
    'an INSERT with a binary value is not refused';
  is_deeply $sth->{asked}, ['NUM_OF_FIELDS'], '... and asked no more';
}

# =========================== 5. the values, as the handle gives them

# Nothing is decoded: the bytes are the DBD's, from an IMAGE column read
# with syb_binary_images on.
{
  my $bytes = join '', map { chr } reverse 0 .. 255;

  local $DESCRIBE = described(
    [ id => 'int' ], [ title => 'varchar' ], [ body => 'image' ], [ owner_id => 'int' ],
  );
  local @ROWS = ( [ 7, '30783031', $bytes, undef ] );

  my $row = $docs->find(7);

  is $row->body, $bytes, 'find(): the value is what the handle gave';
  is $row->title, '30783031',
    '... and a text that looks like hex digits is left alone';

  local @ROWS = ( [ 7, 'a', $bytes, undef ], [ 8, 'b', '', undef ], [ 9, 'c', undef, undef ] );

  is_deeply [ map { $_->body } $docs->search->all ], [ $bytes, '', undef ],
    'all(): every row, with a value, an empty one and NULL';

  local @ROWS = ( [ 7, 'a', $bytes, undef ] );

  my $rs = $docs->search;
  is $rs->next->body, $bytes, 'next(): the same';
}

# ================================================= 6. the other classes

# The class of a connection without placeholders inherits it: reading has no
# bind values.
{
  local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
  local $PLACEHOLDERS = 0;

  my $no_binds = connected();

  is ref $no_binds->storage,
    'DBIO::MSSQL::Storage::Sybase::NoBindVars::FreeTDS',
    '(a connection that takes no placeholders gets the NoBindVars class)';

  local $DESCRIBE = described([ id => 'int' ], [ body => 'image' ]);

  my ($sth) = sent { $no_binds->resultset('Doc')->search({ id => 7 }, { columns => [qw(id body)] })->all };

  is $sth->{Statement}, "SELECT [me].[id], $BODY FROM [k56_doc] [me] WHERE ( [id] = 7 )",
    'the NoBindVars class reads a binary column the same way';
  is $sth->{binary_images}, 1, '... with syb_binary_images on for the execute';
}

# The base class knows no transport. A private subclass of it on a
# DBD::Sybase handle is refused (karr k42; before, it read as it always did:
# hex digits, and no rows for VARBINARY(MAX), nothing rewritten, nothing
# refused).
{
  package T::K56::Private::Storage;
  use base 'DBIO::MSSQL::Storage';
  use mro 'c3';

  package T::K56::Private::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('+T::K56::Private::Storage');
  __PACKAGE__->register_class($_ => "T::K56::Result::$_") for @SOURCES;
}
{
  throws_ok { connected(undef, 'T::K56::Private::Schema') }
    qr/T::K56::Private::Storage.*DBD::Sybase.*DBIO::MSSQL::Storage::Sybase/s,
    'a private subclass of the base class on a DBD::Sybase handle is refused, '
  . 'naming the class to derive from';
}

# DBD::ODBC hands back the bytes of a binary column of any size (live:
# t/65). Its class asks for the column as it is.
{
  my $odbc = connected('dbi:ODBC:DSN=k56');

  is ref $odbc->storage, 'DBIO::MSSQL::Storage::ODBC',
    '(over a dbi:ODBC: DSN the storage is the DBD::ODBC class)';

  # a description no ODBC driver gives; were the refusal in the base class,
  # it would throw here
  local $DESCRIBE = described([ id => 'int' ], [ body => 'varbinary_max' ]);
  my $sth;

  lives_ok {
    ($sth) = sent { $odbc->resultset('Doc')->search({}, { columns => [qw(id body)] })->all };
  } 'DBD::ODBC: nothing is refused by how a result is described';

  is $sth->{Statement}, 'SELECT [me].[id], [me].[body] FROM [k56_doc] [me]',
    'DBD::ODBC: the statement is what it was -- the DBD reads a binary value';
  ok !exists $odbc->storage->dbh->{syb_binary_images},
    '... and the handle is not given an attribute of another DBD';
}

# ================================ 7. the TEXTSIZE guard (karr k47)

# SET TEXTSIZE cuts a longer value of a TEXT, NTEXT, IMAGE, VARCHAR(MAX),
# NVARCHAR(MAX) or VARBINARY(MAX) column on its way back, without an error,
# exactly at TEXTSIZE bytes (live: t/77-long-values-live.t). The client cannot
# tell a value that was cut from one that is that long; the server can. So
# the column is asked for behind a CASE that fails when DATALENGTH(column) is
# above @@TEXTSIZE, and the failure carries a message.
{
  my $notes = $schema->resultset('Notes');

  is selected { $notes->search({}, { columns => [qw(id t nt)] })->all },
    'SELECT [me].[id], ' . textual(nvarchar_max => '[me].[t]', 'me.t') . ', '
  . textual(ntext => '[me].[nt]', 'me.nt') . ' FROM [k56_notes] [me]',
    "a 'text' column is an NVARCHAR(MAX) on the server (DBIO::MSSQL::Adapter), read as one, "
  . 'not as a TEXT through VARCHAR(MAX); an NTEXT is cast to the MAX type '
  . '(a CASE cannot return an NTEXT) (karr k47)';

  is selected { $notes->search({}, { columns => [qw(vm nvm rvm)] })->all },
    'SELECT ' . textual(nvarchar_max => '[me].[vm]', 'me.vm') . ', '
  . textual(nvarchar_max => '[me].[nvm]', 'me.nvm') . ', '
  . textual(varchar_max => '[me].[rvm]', 'me.rvm') . ' FROM [k56_notes] [me]',
    "a 'varchar' of size -1 is deployed as NVARCHAR(MAX) and read as one, like an "
  . "'nvarchar(max)'; only 'varchar(max)', the server's own spelling, is a "
  . 'VARCHAR(MAX): behind the guard, each as the type it is on the server';

  is selected { $notes->search({}, { columns => [qw(id small doc)] })->all },
    'SELECT [me].[id], [me].[small], [me].[doc] FROM [k56_notes] [me]',
    'a VARCHAR(100) and an XML column are not subject to TEXTSIZE: untouched '
  . '(measured: 8000 bytes under a TEXTSIZE of 100, 50007 characters of XML '
  . 'under 32768)';

  my ($sth) = sent { $notes->search({}, { columns => [qw(t nt)] })->all };
  is $sth->{binary_images}, 0,
    'a statement with these alone does not turn syb_binary_images on';

  is selected { $notes->search({}, { columns => ['t'] })->get_column('t')->func('DATALENGTH') },
    'SELECT DATALENGTH( [me].[t] ) FROM [k56_notes] [me]',
    'a function over the column is not behind the guard (documented limit)';

  is ${ $notes->search({}, { columns => ['t'] })->as_query }->[0],
    '(SELECT [me].[t] FROM [k56_notes] [me])',
    'a subquery keeps the column as it is';

  # the message of the failing conversion comes to the caller in words
  local $EXECUTE_ERROR = "DBD::Sybase::st execute failed: Server message number=245 "
    . "text=Conversion failed when converting the varchar value 'DBIO::MSSQL TEXTSIZE guard: "
    . "column 'me.nvm' holds a value longer than the session's TEXTSIZE, 32768 bytes' to data type int.\n";

  throws_ok { $notes->search({}, { columns => ['nvm'] })->all }
    qr/\QCannot read this result through DBD::Sybase: the column 'me.nvm' holds a value longer than the TEXTSIZE of the session, 32768 bytes\E/,
    'a value beyond TEXTSIZE is refused, naming the column and the size';
  like "$@", qr/LongReadLen/, '... and the way out';
  unlike "$@", qr/DBD::Sybase::st execute failed/,
    '... in place of the raw server message';

  local $EXECUTE_ERROR = "some other failure\n";
  throws_ok { $notes->search({}, { columns => ['nvm'] })->all }
    qr/some other failure/, 'any other failure is thrown as it was';
}

# ===================================== 8. SQL_VARIANT (karr k59)

# DBD::Sybase describes SQL_VARIANT as a CHAR of 8009; a value with a binary
# base type loses its row without an error (live: t/77). What the column
# holds is not known before the rows are, so the column is refused.
{
  my $notes = $schema->resultset('Notes');
  local $DESCRIBE = described([ id => 'int' ], [ sv => 'sql_variant' ]);
  local @ROWS = ( [ 1, '42' ] );

  @SENT = ();
  throws_ok { $notes->search({}, { columns => [qw(id sv)] })->all }
    qr/\QCannot read this result through DBD::Sybase: its column 2 ('sv') is SQL_VARIANT\E/,
    'a SQL_VARIANT result column is refused, with its position and name';
  like "$@", qr/drops the row of a value with a binary base type/,
    '... saying what would have happened';
  like "$@", qr/CONVERT\(VARCHAR\(8000\), <expression>\).*SQL_VARIANT_PROPERTY/s,
    '... and what to select instead';

  is_deeply
    [ map { $_->{executed}, $_->{fetched}, $_->{finished} } grep { $_->{how} ne 'do' } @SENT ],
    [ 1, 0, 1 ],
    '... after the execute, before a fetch, the statement finished';

  throws_ok { $notes->search({}, { select => [ \'CAST(1 AS SQL_VARIANT)' ], as => ['v'] })->all }
    qr/is SQL_VARIANT/, 'literal SQL too -- it is decided by how the handle describes it';

  # a CHAR(8000) is 32000 to the client library, a VARCHAR(8000) too: nothing
  # but a variant has 8009
  for my $case ([ varchar => 'a VARCHAR(100)' ], [ varchar_max => 'a VARCHAR(MAX)' ]) {
    local $DESCRIBE = described([ id => 'int' ], [ v => $case->[0] ]);
    lives_ok { $notes->search({}, { columns => [qw(id small)] })->all }
      "$case->[1] is not taken for a SQL_VARIANT";
  }
}

is_deeply \@warnings, [], 'no warning on the way';

done_testing;
