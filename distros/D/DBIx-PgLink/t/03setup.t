use strict;
use Test::More tests => 12;
use Test::Exception;
use Data::Dumper;

# setup test database for all following tests

use Cwd; 

BEGIN {
  use lib 't';
  use_ok('PgLinkTestUtil');
}

ok($Test, 'test setup loaded');

# drop and create database
{
  my $dbh_init;
  my $dbname = $Test->{TEST}->{database};

  ok($dbh_init = PgLinkTestUtil::connect('postgres'), 'connect to system database');
  {
    my $sth_database = $dbh_init->prepare('SELECT datname FROM pg_database WHERE datname=?');
    $sth_database->execute($dbname);
    my $database = ($sth_database->fetchrow_array)[0];
    if (defined $database && $database eq $dbname) {
diag <<END_OF_MESSAGE;

#########################################################
  WARNING: database '$dbname' now will be dropped
  Disconnect all sessions from this database
  (spurious failure may be caused by autovacuum process)
#########################################################
END_OF_MESSAGE

      $dbh_init->do("DROP DATABASE $dbname");
      diag "\ndrop database $dbname\n";
    }
  }

  # clean db from template0
  diag "\ncreate database $dbname\n";
  ok($dbh_init->do(<<END_OF_SQL), 'create database');
CREATE DATABASE $dbname
TEMPLATE template0
ENCODING 'utf8'
END_OF_SQL
}

my $dbh;
ok($dbh = PgLinkTestUtil::connect(), 'connect to new database');

ok($dbh->do("CREATE LANGUAGE plpgsql"), 'CREATE LANGUAGE plpgsql');
ok($dbh->do("CREATE LANGUAGE plperlu"), 'CREATE LANGUAGE plperlu');

{
  local $dbh->{RaiseError} = 0;
  $dbh->do('drop user test_pglink1');
  $dbh->do('drop user test_pglink2');
}

$dbh->do(q/create user test_pglink1 with password 'secret1'/);
$dbh->do(q/create user test_pglink2 with password 'secret2'/);

my $blib = Cwd::abs_path . "/blib/lib";

# TODO: `chmod -R 644 blib/lib` in portable way

ok($dbh->do(<<'END_OF_SQL'), 'check_file_read_access');
CREATE OR REPLACE FUNCTION public.check_file_read_access(_file text) RETURNS void LANGUAGE plperlu AS $body$
my $filename = shift;
open my $fh, '<', $filename or die "PostgreSQL process have no read access to file '$filename'";
$body$
END_OF_SQL

lives_ok {
  $dbh->selectrow_array("SELECT public.check_file_read_access(?)", {}, "$blib/DBIx/PgLink.pm" );
  $dbh->selectrow_array("SELECT public.check_file_read_access(?)", {}, "$blib/DBIx/PgLink/Adapter.pm" );
} 'test directory is readable by PostgreSQL process';

ok($dbh->do(<<EOF), 'plperl_use_blib');
CREATE OR REPLACE FUNCTION public.plperl_use_blib() RETURNS void LANGUAGE plperlu AS \$body\$
use lib '$blib';
\$body\$
EOF

$dbh->do(<<'EOF');
COMMENT ON FUNCTION public.plperl_use_blib() IS $$Part of test suite. 
Add build directory absolute pathname to Perl @INC$$
EOF


ok(
  PgLinkTestUtil::psql(
    file     => 't/setup.sql',
  ), 
  'setting up test database'
);


# setup test connections
for my $conn_name (sort keys %{$Test}) {
  my $c = $Test->{$conn_name};

  $c->{logon_mode} ||= 0;
  $dbh->do(<<'END_OF_SQL', {}, $conn_name, $c->{dsn}, $c->{logon_mode}, $c->{adapter_class});
INSERT INTO dbix_pglink.connections (conn_name, data_source, logon_mode, adapter_class) VALUES (?, ?, ?, ?)
END_OF_SQL

  my $cnt=0;
  for my $r (@{$c->{roles}}) {
    $dbh->do(<<'END_OF_SQL', {}, $conn_name, $r->{role_kind}, $cnt++, $r->{role_name});
INSERT INTO dbix_pglink.roles (conn_name, role_kind, role_seq, role_name) VALUES (?, ?, ?, ?)
END_OF_SQL
  }

  for my $u (@{$c->{users}}) {
    $dbh->do(<<'END_OF_SQL', {}, $conn_name, $u->{local_user}, $u->{remote_user}, $u->{remote_password});
INSERT INTO dbix_pglink.users (conn_name, local_user, remote_user, remote_password) VALUES (?, ?, ?, ?)
END_OF_SQL
  }
  for my $a (@{$c->{attributes}}) {
    $dbh->do(<<'END_OF_SQL', {}, $conn_name, $a->{attr_name}, $a->{attr_value});
INSERT INTO dbix_pglink.attributes (conn_name, attr_name, attr_value) VALUES (?, ?, ?)
END_OF_SQL
  }
  $cnt = 0;
  for my $i (@{$c->{init_session}}) {
    $dbh->do(<<'END_OF_SQL', {}, $conn_name, $cnt++, $i->{init_query});
INSERT INTO dbix_pglink.init_session (conn_name, init_seq, init_query) VALUES (?, ?, ?)
END_OF_SQL
  }
  for my $i (@{$c->{environment}}) {
    $dbh->do(<<'END_OF_SQL', {}, $conn_name, $i->{env_action}, $i->{env_name}, $i->{env_value});
INSERT INTO dbix_pglink.environment (conn_name, env_action, env_name, env_value) VALUES (?, ?, ?, ?)
END_OF_SQL
  }

}

is(
  scalar($dbh->selectrow_array('SELECT count(*) FROM dbix_pglink.connections')),
  scalar(keys %{$Test}) + 1, # plus default connection
  'connections setup'
);
