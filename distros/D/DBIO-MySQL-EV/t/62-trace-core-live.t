use strict;
use warnings;
use Test::More;

# LIVE test for core karr k402 / k404 (core ADR 0025): the statement trace of
# this transport is the core's (DBIO::Storage::Async::_debug_query), written
# on the debugobj of the owning sync storage, with the bind attributes the
# statement was built with.
#
#   a) level 2: an encode_column bind shows ***, a plain one its value, the
#      server stores the real value
#   b) the redact_bind_value hook of the owner sees the column name
#   c) level 1: the statement, no binds
#   d) a transaction: BEGIN and COMMIT are traced, each statement once, and
#      every query_start has its query_end
#   e) a failing statement gets its query_end
#   f) a ResultSet select with the bind attribute (k404) returns the right rows
#   g) nothing is warned
#
# The table lives in a database of its own, mysql_ev_k402, created here and
# dropped at the end.

use DBI;
use DBIO::MySQL::EV::TestHarness;
use DBIO::Storage::DBI;
use DBIO::Storage::Statistics;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

alarm 120;

my $DB = 'mysql_ev_k402';
my ($DSN, $USER, $PASS) = map { $ENV{"DBIO_TEST_MYSQL_$_"} } qw( DSN USER PASS );

(my $own = $DSN) =~ s/(?<=[:;])(?:database|dbname|db)=[^;]*/database=$DB/
  or plan skip_all => 'DBIO_TEST_MYSQL_DSN names no database';

sub connect_sync {
  my ($dsn) = @_;
  return DBI->connect($dsn, $USER, $PASS, { RaiseError => 1, PrintError => 0, PrintWarn => 0 });
}

my $CREATED;
{
  my $dbh = connect_sync($DSN);
  $dbh->do("DROP DATABASE IF EXISTS $DB");
  $dbh->do("CREATE DATABASE $DB");
  $CREATED = 1;
  $dbh->disconnect;
}
END {
  return unless $CREATED;
  my $dbh = eval { connect_sync($DSN) } or return;
  eval { $dbh->do("DROP DATABASE IF EXISTS $DB") };
  $dbh->disconnect;
}
my $check = connect_sync($own);
$check->do('CREATE TABLE trace_user (id INT AUTO_INCREMENT PRIMARY KEY, name VARCHAR(64) NOT NULL, password VARCHAR(255) NULL)');

{
  package K402::Live::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('trace_user');
  __PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    name     => { data_type => 'varchar', size => 64 },
    password => { data_type => 'varchar', size => 255, is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K402::Live::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MySQL');
  __PACKAGE__->register_class(User => 'K402::Live::User');
}

{
  package K402::Stats;
  our @ISA = ('DBIO::Storage::Statistics');
  our (@started, @ended);
  sub query_start { my $s = shift; push @started, [@_]; $s->SUPER::query_start(@_) }
  sub query_end   { my $s = shift; push @ended,   [@_]; $s->SUPER::query_end(@_) }
}

my @warnings;
local $SIG{__WARN__} = sub { push @warnings, $_[0] };

my $h = DBIO::MySQL::EV::TestHarness->new(
  schema_class  => 'K402::Live::Schema',
  dsn           => $own, user => $USER, pass => $PASS,
  connect_attrs => { pool_size => 2 },
);
$h->warm_pool;
END { eval { $h->disconnect } if $h }

my $async  = $h->async;
my $owner  = $h->sync_storage;
my $source = $h->schema->source('User');

my $out = '';
open my $fh, '>', \$out or die;
my $stats = K402::Stats->new;
$stats->debugfh($fh);
$owner->debugobj($stats);

sub reset_trace { $out = ''; @K402::Stats::started = @K402::Stats::ended = () }
# The session reset at the end of a borrow (COM_RESET_CONNECTION, SET NAMES) is
# traced too, and runs after the Future of the call has settled: the cases look
# at the statements of their own.
sub own { grep { !/\A(?:COM_RESET_CONNECTION|SET NAMES)/ } @_ }
sub started_sql { own(map { $_->[0] } @K402::Stats::started) }
sub ended_sql   { own(map { $_->[0] } @K402::Stats::ended) }

# a) level 2, encode_column
{
  reset_trace();
  $async->{debug} = 2;
  $h->await($async->insert_async($source, { name => 'alice', password => 'hunter2-secret' }));
  like $out, qr/INSERT INTO/, 'level 2: the statement is traced';
  like $out, qr/'alice'/, 'level 2: a plain column value is traced';
  like $out, qr/'\*\*\*'/, 'level 2: the encode_column bind shows ***';
  unlike $out, qr/hunter2/, 'level 2: the encoded value is not traced';
  is scalar(grep { /^INSERT/ } started_sql()), 1, 'the INSERT is traced once';
  ok scalar(grep { /LAST_INSERT_ID/ } started_sql()), 'the LAST_INSERT_ID() read is traced';
  is_deeply [ sort(ended_sql()) ], [ sort(started_sql()) ], 'every query_start has its query_end';
  is $check->selectrow_array('SELECT password FROM trace_user WHERE name = ?', undef, 'alice'),
    'hunter2-secret', 'the server got the real value';
}

# b) the hook sees the column name
{
  my $old = DBIO::Storage::DBI->redact_bind_value;
  my @asked;
  DBIO::Storage::DBI->redact_bind_value(sub { push @asked, [@_]; $_[1] });
  reset_trace();
  $h->await($async->delete_async($source, { name => 'nobody' }));
  DBIO::Storage::DBI->redact_bind_value($old);
  is_deeply [ map { [ $_->[0], $_->[1] ] } @asked ], [[ 'name', 'nobody' ]],
    'the hook sees the column name and the value';
}

# c) level 1
{
  reset_trace();
  $async->{debug} = 1;
  $h->await($async->delete_async($source, { name => 'secretname' }));
  like $out, qr/DELETE FROM/, 'level 1: the statement is traced';
  unlike $out, qr/secretname/, 'level 1: no bind value';
}

# d) a transaction
{
  reset_trace();
  $async->{debug} = 2;
  $h->await($async->txn_do_async(sub {
    my $ctx = shift;
    return $ctx->insert_async($source, { name => 'bob' });
  }));
  my @sql = started_sql();
  ok scalar(grep { /^\s*(?:BEGIN|START TRANSACTION)/i } @sql), 'BEGIN is traced';
  is scalar(grep { /^\s*COMMIT/i } @sql), 1, 'COMMIT is traced once';
  is scalar(grep { /^INSERT/ } @sql), 1, 'the INSERT of the transaction is traced once';
  is_deeply [ sort(ended_sql()) ], [ sort(started_sql()) ], 'every query_start has its query_end';
}

# e) a failing statement
{
  reset_trace();
  my $f = $async->_query_async('SELECT * FROM trace_no_such_table', []);
  eval { $h->await($f) };
  ok $@, 'the statement failed';
  is_deeply [ ended_sql() ], ['SELECT * FROM trace_no_such_table'],
    'query_end ran for the failed statement';
}

# f) a ResultSet select with the bind attribute (k404)
{
  reset_trace();
  $async->{debug} = 2;
  my @rows = $h->await($h->schema->resultset('User')->search(
    { 'me.id' => { '>' => 0 }, -and => [ \'me.name = ?' ] },
    { bind => [ 'alice' ] },
  )->all_async);
  is scalar(@rows), 1, 'the select with the bind attribute returns the one row';
  is $rows[0]->name, 'alice', 'the right row';
  like $out, qr/'alice'/, 'the bind attribute value is traced at level 2';
}

# g)
is_deeply \@warnings, [], 'nothing was warned';

$async->{debug} = 0;
done_testing;
