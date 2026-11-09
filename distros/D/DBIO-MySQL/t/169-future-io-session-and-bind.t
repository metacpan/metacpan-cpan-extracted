use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require DBIO::MySQL::Storage::Async; 1 }
    or plan skip_all =>
      'DBIO::Async not installed (recommends only) -- future_io transport unavailable';
}

use DBI ();
use DBIO::Test;
use DBIO::MySQL::Storage ();
use DBIO::MySQL::Storage::Async ();

# OFFLINE half of karr k121 (t/168 has the live half): what the synchronous
# storage does to the session of a connection (STRICT_ALL_TABLES, k120) and to
# a value on its way out (a binary column bound as SQL_BINARY, DBD::mysql text
# in its 8-bit form bound as characters, k120) holds on every connection of
# the future_io transport too -- from the SAME functions, not copies.
#
# WHY IT MATTERS. A pool connection is a DBD handle of its own. Without the
# session statement a server that is not strict stores a value that does not
# fit cut -- silently, where the synchronous storage refuses it; without the
# bind rules 256 bytes in a BLOB come back as 384 (DBD::MariaDB) and a Latin-1
# string is refused as an incorrect string value (DBD::mysql). Claims:
#   a. every connection _mysql_connect opens -- the pool's and the listen one --
#      runs the session statement, the very one the sync storage runs, and
#      before anything else;
#   b. a statement submitted on the transport binds a Binary value as
#      SQL_BINARY and the 8-bit string of a DBD::mysql handle with the utf8
#      attribute as characters, a copy of it; DBD::MariaDB gets what it is given;
#   c. the CRUD builder keeps the type of a bind: the value of a blob column
#      reaches the runner as Binary, a text column's stays bare.

my $ASYNC = 'DBIO::MySQL::Storage::Async';

# --- a: the session statement ------------------------------------------------

{
  package K121::DBH;
  sub new { my ($class, $dbd) = @_; bless { Active => 1, Driver => { Name => $dbd }, did => [] }, $class }
  sub do { push @{ $_[0]{did} }, $_[1]; 1 }
  sub disconnect { $_[0]{Active} = 0; 1 }
}

{
  no warnings 'redefine';
  local *DBI::connect = sub { K121::DBH->new('mysql') };

  my $conn = bless({}, $ASYNC)->_mysql_connect({ dsn => 'dbi:mysql:database=t', user => 'u', password => 'p' });
  is_deeply $conn->{dbh}{did}, [ DBIO::MySQL::Storage::strict_sql_mode_statement() ],
    'a: a pool connection runs the session statement of the sync storage, and nothing else';

  $conn = bless({}, $ASYNC)->_mysql_connect({ dsn => 'dbi:mysql:database=t' }, 1);
  is_deeply $conn->{dbh}{did}, [ DBIO::MySQL::Storage::strict_sql_mode_statement() ],
    'a: so does the listen connection';
}

# --- b: binding --------------------------------------------------------------

{
  package K121::STH;
  sub new { bless { params => {}, executed => undef }, shift }
  sub bind_param { my ($self, $i, $v, $a) = @_; $self->{params}{$i} = [ $v, $a ]; 1 }
  sub execute { my $self = shift; $self->{executed} = [ @_ ]; 1 }
}

sub submitted {
  my ($dbd, $attrs, @bind) = @_;
  my $sth = K121::STH->new;
  my $dbh = bless { Driver => { Name => $dbd }, %$attrs }, 'K121::BindDBH';
  my $async = bless {}, $ASYNC;
  $async->_bind_and_execute($dbh, $sth, \@bind);
  return $sth;
}

my $latin = "\x{fc}";
ok !utf8::is_utf8($latin), 'b: the test value is the 8-bit form';
my $bytes = join '', map chr, 0 .. 255;
my $binary = DBIO::MySQL::Storage::Async::Binary->new($bytes);

my $sth = submitted(mysql => { mysql_enable_utf8mb4 => 1 }, $latin, $binary, 'ascii', undef);
is $sth->{params}{2}[0], $bytes, 'b: a Binary value is bound as its bytes ...';
is_deeply $sth->{params}{2}[1], { TYPE => DBI::SQL_BINARY() }, '... with the type SQL_BINARY';
ok utf8::is_utf8($sth->{params}{1}[0]) && $sth->{params}{1}[0] eq $latin,
  'b: DBD::mysql with the utf8 attribute: the 8-bit string is bound as characters';
ok !utf8::is_utf8($latin), '... the caller\'s value is not changed';
ok !defined $sth->{params}{1}[1], '... with no type of its own';
ok !defined $sth->{params}{4}[0], 'b: undef stays undef';

$sth = submitted(mysql => { mysql_enable_utf8mb4 => 1 }, $latin, 'ascii');
ok utf8::is_utf8($sth->{executed}[0]), 'b: without a binary value the values go with the execute, upgraded';

$sth = submitted(MariaDB => {}, $latin, $binary);
ok !utf8::is_utf8($sth->{params}{1}[0]), 'b: DBD::MariaDB upgrades itself: the string is left alone';
is_deeply $sth->{params}{2}[1], { TYPE => DBI::SQL_BINARY() }, '... a Binary value is binary there too';

# --- c: the CRUD builder keeps the type ---------------------------------------

{
  my $schema = DBIO::Test->init_schema(no_deploy => 1, storage_type => 'DBIO::MySQL::Storage');
  my $owner  = $schema->storage;
  my $async  = bless {}, $ASYNC;
  $async->_owner_storage($owner);
  my $source = $schema->source('BindType');

  my ($sql, $got);
  my $runner = sub {
    ($sql, $got) = @_;
    return Future->done(1);
  };

  my $row = { blob => $bytes, a_memo => $latin };
  $async->_run_crud(insert => $runner, $source, $row);
  like $sql, qr/\AINSERT INTO `bindtype_test` \(/, 'c: the insert is the usual one';
  my ($blob) = grep { ref $_ } @$got;
  isa_ok $blob, 'DBIO::MySQL::Storage::Async::Binary', 'c: the value of the blob column';
  is $blob->value, $bytes, '... holding its bytes';
  my ($memo) = grep { !ref $_ } @$got;
  is $memo, $latin, 'c: the value of the text column stays bare';

  $async->_run_crud(update => $runner, $source, { blob => $bytes }, { id => 3 });
  is scalar(grep { ref $_ } @$got), 1, 'c: an update types its SET too';
  is $got->[-1], 3, '... and leaves the key of its WHERE bare';

  my $attrs = $schema->resultset('BindType')->search({ 'me.blob' => $bytes })->_resolved_attrs;
  $async->_run_crud(select => $runner, @{$attrs}{qw(from select where)}, $attrs);
  isa_ok $got->[0], 'DBIO::MySQL::Storage::Async::Binary', 'c: a select types its WHERE value';
}

done_testing;
