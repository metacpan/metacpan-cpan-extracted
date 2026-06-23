use strict;
use warnings;
no warnings qw/once/;

use Test::More;
use Test::Exception;
use lib qw(t/lib);
use Scalar::Util; # load before we break require()
use Carp ();   # Carp is not used in the test, but we want to have it loaded for proper %INC comparison

# a dummy test which lazy-loads more modules (so we can compare INC below)
is_deeply([], []);

# record contents of %INC - makes sure there are no extra deps slipping into
# Opt::Dep.
my $inc_before = [ keys %INC ];
ok ( (! grep { $_ =~ m|DBIO| } @$inc_before ), 'Nothing DBIO related is yet loaded');

# DBIO::Optional::Dependencies queries $ENV at compile time
# to build the optional requirements
BEGIN {
  delete @ENV{
    qw(
      DBIO_TEST_PG_DSN DBIO_TEST_MYSQL_DSN DBIO_TEST_ORA_DSN
      DBIO_TEST_MSSQL_DSN DBIO_TEST_MSSQL_ODBC_DSN
      DBIO_TEST_SYBASE_DSN DBIO_TEST_DB2_DSN DBIO_TEST_INFORMIX_DSN
      DBIO_TEST_FIREBIRD_DSN DBIO_TEST_FIREBIRD_INTERBASE_DSN DBIO_TEST_FIREBIRD_ODBC_DSN
      DBIO_TEST_MEMCACHED
    )
  };
  $ENV{DBIO_TEST_PG_DSN} = '1';
}

use_ok 'DBIO::Optional::Dependencies';

my $inc_after = [ keys %INC ];
my %inc_before = map { $_ => 1 } @$inc_before;
my @newly_loaded = grep { ! $inc_before{$_} } @$inc_after;

ok(
  scalar(grep { $_ eq 'DBIO/Optional/Dependencies.pm' } @newly_loaded),
  'DBIO::OptDeps loaded',
);

is_deeply(
  [ sort grep { m|^DBIO/| && $_ ne 'DBIO/Optional/Dependencies.pm' } @newly_loaded ],
  [],
  'No extra DBIO modules loaded as side effects',
);

my $sqlt_dep = DBIO::Optional::Dependencies->req_list_for ('deploy');
is_deeply (
  [ keys %$sqlt_dep ],
  [ 'SQL::Translator' ],
  'Correct deploy() dependency list',
);

# make module loading impossible, regardless of actual libpath contents
{
  local @INC = (sub { die('Optional Dep Test') } );

  ok (
    ! DBIO::Optional::Dependencies->req_ok_for ('deploy'),
    'deploy() deps missing',
  );

  like (
    DBIO::Optional::Dependencies->req_missing_for ('deploy'),
    qr/^SQL::Translator \>\= \d/,
    'expected missing string contents',
  );

  like (
    DBIO::Optional::Dependencies->req_errorlist_for ('deploy')->{'SQL::Translator'},
    qr/Optional Dep Test/,
    'custom exception found in errorlist',
  );
}

#make it so module appears loaded
$INC{'SQL/Translator.pm'} = 1;
$SQL::Translator::VERSION = 999;

ok (
  ! DBIO::Optional::Dependencies->req_ok_for ('deploy'),
  'deploy() deps missing cached properly',
);

#reset cache
%DBIO::Optional::Dependencies::req_availability_cache = ();


ok (
  DBIO::Optional::Dependencies->req_ok_for ('deploy'),
  'deploy() deps present',
);

is (
  DBIO::Optional::Dependencies->req_missing_for ('deploy'),
  '',
  'expected null missing string',
);

is_deeply (
  DBIO::Optional::Dependencies->req_errorlist_for ('deploy'),
  {},
  'expected empty errorlist',
);

# test multiple times to find autovivification bugs
for (1..2) {
  throws_ok {
    DBIO::Optional::Dependencies->req_list_for();
  } qr/\Qreq_list_for() expects a requirement group name/,
  "req_list_for without groupname throws exception on run $_";

  throws_ok {
    DBIO::Optional::Dependencies->req_list_for('');
  } qr/\Qreq_list_for() expects a requirement group name/,
  "req_list_for with empty groupname throws exception on run $_";

  throws_ok {
    DBIO::Optional::Dependencies->req_list_for('invalid_groupname');
  } qr/Requirement group 'invalid_groupname' does not exist/,
  "req_list_for with invalid groupname throws exception on run $_";
}

is_deeply(
  DBIO::Optional::Dependencies->req_list_for('rdbms_pg'),
  {
    'DBD::Pg' => '0',
  }, 'optional dependencies for deploying to Postgres ok');

is_deeply(
  DBIO::Optional::Dependencies->req_list_for('config_files'),
  {
    'Config::Any' => '0',
  }, 'config file parsing dependency list is explicit');

is_deeply(
  DBIO::Optional::Dependencies->req_list_for('admin_script'),
  {
    'Text::CSV' => '1.16',
  }, 'dbioadmin CSV dependency list stays script-specific');

is_deeply(
  DBIO::Optional::Dependencies->req_list_for('test_rdbms_pg'),
  {
    'DBD::Pg'        => '2.009002',
  }, 'optional dependencies for testing Postgres with ENV var ok');

is_deeply(
  DBIO::Optional::Dependencies->req_list_for('test_rdbms_oracle'),
  {}, 'optional dependencies for testing Oracle without ENV var ok');

throws_ok {
  DBIO::Optional::Dependencies->req_list_for('replicated');
} qr/Requirement group 'replicated' does not exist/,
  'removed replicated dependency group stays gone';

done_testing;
