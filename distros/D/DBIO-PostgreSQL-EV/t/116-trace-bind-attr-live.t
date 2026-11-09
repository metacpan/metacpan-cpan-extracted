use strict;
use warnings;
use Test::More;

# LIVE check (core k402, k404): a select with a bind attribute runs against a
# server with the statement trace at level 2, and returns the right rows.
#
# WHY: the trace of an async transport is core's _debug_query, and at level 2
# it reads the bind attributes core builds for the statement. A select whose
# literal where carries a placeholder (the `bind` attribute of the ResultSet)
# has its values in front of the SQL maker's own; if the attribute list did
# not line up with the binds, the trace would shift or mask the wrong value --
# or break the query. Here the server answers, so the claim holds on the wire.
# The column with encode_column must show *** in the trace, never its value.

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
LiveServer->require_server;

alarm 120;

my $table = 'k404_trace_user';

{
  package K404Live::Schema::Result::User;
  use base 'DBIO::Core';
  __PACKAGE__->table('k404_trace_user');
  __PACKAGE__->add_columns(
    id    => { data_type => 'integer', is_auto_increment => 1 },
    name  => { data_type => 'text' },
    token => { data_type => 'text', is_nullable => 1, encode_column => 1 },
  );
  __PACKAGE__->set_primary_key('id');

  package K404Live::Schema;
  use DBIO 'Schema', -pg;
  __PACKAGE__->register_class(User => 'K404Live::Schema::Result::User');
}

# The level is read when the transport is built.
local $ENV{DBIO_TRACE} = 2;

my $h = DBIO::PostgreSQL::EV::TestHarness->new(schema_class => 'K404Live::Schema');
my $schema = $h->schema;
END {
  return unless $h;
  eval { $schema->storage->dbh->do("DROP TABLE IF EXISTS $table") };
  eval { $h->disconnect };
}

my $dbh = $schema->storage->dbh;
$dbh->do("DROP TABLE IF EXISTS $table");
$dbh->do("CREATE TABLE $table (id serial PRIMARY KEY, name text NOT NULL, token text)");

my $buffer = '';
open my $fh, '>', \$buffer or die;
$schema->storage->debugfh($fh);

my $users = $schema->resultset('User');
$users->create_async({ name => 'zed',  token => 'sekrit-zed'  })->get;
$users->create_async({ name => 'anna', token => 'sekrit-anna' })->get;

$buffer = '';
my @rows = $users->search(
  { 'me.id' => { '>' => 0 }, -and => [ \'me.name = ?' ] },
  { bind => [ 'zed' ], order_by => 'me.id' },
)->all_async->get;

is scalar(@rows), 1, 'select with a bind attribute at trace level 2: one row';
is $rows[0]->name, 'zed', '... the right one';
like $buffer, qr/SELECT/, 'the select was traced';
like $buffer, qr/'zed', '0'/, '... with the values of the bind attribute and of the condition';

$buffer = '';
$users->create_async({ name => 'mia', token => 'sekrit-mia' })->get;
like $buffer, qr/INSERT INTO/, 'the insert was traced';
like $buffer, qr/'\*\*\*'/, '... the encode_column bind masked';
unlike $buffer, qr/sekrit/, '... its value nowhere in the trace';

done_testing;
