use strict;
use warnings;

use Test::More;
use Test::Exception;

my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_PG_$_" } qw(DSN USER PASS)};

plan skip_all => 'Set DBIO_TEST_PG_DSN, _USER and _PASS to run this test'
  unless $dsn;

use DBIO::PostgreSQL::Deploy;
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use PrivatePgDatabase;

# A server that is not there fails the file, with a plan (karr k113).
LiveServer->require_server;

# karr k89 -- extensions are database-level, so the pg_schemas restriction of
# a deploy never reached them: a deploy managing only its own namespaces
# dropped every extension of the whole database it did not declare. Rule
# (maintainer decision, option a): a restricted deploy creates declared
# extensions that are missing but drops none; an unrestricted deploy (no
# pg_schemas) drops undeclared ones as before.
#
# The same schema is deployed twice against the same database, once restricted
# (pg_schemas 'public') and once not -- the restriction is the only difference.
# The database holds pgvector, which neither declares; both declare pg_trgm,
# which the database lacks. Runs in a database of its own: it installs and
# drops extensions, which the shared database must not see.

{
  my $h = LiveServer->control_dbh;
  my %avail = map { $_ => 1 } @{ $h->selectcol_arrayref(
    q{SELECT name FROM pg_catalog.pg_available_extensions
      WHERE name IN ('vector', 'pg_trgm')}
  ) };
  $h->disconnect;
  plan skip_all => "extension $_ not available on the server"
    for grep { !$avail{$_} } qw(vector pg_trgm);
}

($dsn, $user, $pass) = PrivatePgDatabase->create('t79');

{
  package K89::Result::Widget;
  use base 'DBIO::Core';
  __PACKAGE__->table('k89_widget');
  __PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'text' },
  );
  __PACKAGE__->set_primary_key('id');
}
{
  package K89::Restricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_schemas('public');
  __PACKAGE__->pg_extensions('pg_trgm');
}
K89::Restricted->register_class(Widget => 'K89::Result::Widget');
{
  package K89::Unrestricted;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->pg_extensions('pg_trgm');
}
K89::Unrestricted->register_class(Widget => 'K89::Result::Widget');

my $dbh = LiveServer->control_dbh(login => [ $dsn, $user, $pass ]);
$dbh->do('CREATE EXTENSION vector');

sub installed {
  my ($name) = @_;
  return scalar $dbh->selectrow_array(
    q{SELECT 1 FROM pg_catalog.pg_extension WHERE extname = ?}, undef, $name);
}

sub ext_actions {
  my ($diff) = @_;
  return {
    map { $_->extension_name => $_->action }
    grep { $_->isa('DBIO::PostgreSQL::Diff::Extension') }
    @{ $diff->operations }
  };
}

subtest 'restricted deploy creates but does not drop' => sub {
  my $deploy = DBIO::PostgreSQL::Deploy->new(
    schema => K89::Restricted->connect($dsn, $user, $pass),
  );

  my $diff = $deploy->diff;
  my $ext  = ext_actions($diff);
  ok !exists $ext->{vector}, 'diff does not touch the undeclared vector'
    or diag $diff->as_sql;
  is $ext->{pg_trgm}, 'create', 'diff creates the declared, missing pg_trgm';

  lives_ok { $deploy->upgrade } 'upgrade lives';
  ok installed('vector'),  'vector is still installed after upgrade';
  ok installed('pg_trgm'), 'pg_trgm was installed by upgrade';

  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff has nothing left to do'
    or diag $again->as_sql;
};

subtest 'unrestricted deploy drops as before' => sub {
  my $deploy = DBIO::PostgreSQL::Deploy->new(
    schema => K89::Unrestricted->connect($dsn, $user, $pass),
  );

  my $diff = $deploy->diff;
  is_deeply ext_actions($diff), { vector => 'drop' },
    'diff drops the undeclared vector, nothing else about extensions'
    or diag $diff->as_sql;

  lives_ok { $deploy->upgrade(allow_destructive => 1) } 'upgrade lives (it drops the undeclared extension)';
  ok !installed('vector'), 'vector is gone after upgrade';
  ok installed('pg_trgm'), 'the declared pg_trgm stays';

  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff has nothing left to do'
    or diag $again->as_sql;
};

subtest 'restricted deploy with manage_extensions_when_restricted drops the undeclared' => sub {
  # Back to the starting state: vector present, pg_trgm absent.
  $dbh->do('DROP EXTENSION IF EXISTS pg_trgm');
  $dbh->do('CREATE EXTENSION IF NOT EXISTS vector');

  my $deploy = DBIO::PostgreSQL::Deploy->new(
    schema => K89::Restricted->connect($dsn, $user, $pass),
    manage_extensions_when_restricted => 1,
  );

  my $diff = $deploy->diff;
  is_deeply ext_actions($diff), { vector => 'drop', pg_trgm => 'create' },
    'diff drops the undeclared vector and creates the declared pg_trgm'
    or diag $diff->as_sql;

  lives_ok { $deploy->upgrade(allow_destructive => 1) } 'upgrade lives (it drops the undeclared extension)';
  ok !installed('vector'), 'vector is gone after upgrade';
  ok installed('pg_trgm'), 'the declared pg_trgm is installed';

  my $again = $deploy->diff;
  ok !$again->has_changes, 'a second diff has nothing left to do'
    or diag $again->as_sql;
};

$dbh->disconnect;

done_testing;
