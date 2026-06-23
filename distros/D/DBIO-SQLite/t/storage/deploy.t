use strict;
use warnings;

use Test::More;
use Test::Exception;
use DBIO::Util qw(dir_path file_path slurp_file mkpath rmtree);

use DBIO::SQLite::Test;

BEGIN {
  plan skip_all =>
    'Legacy SQL::Translator deployment path. DBIO replaced SQLT with the '
    . 'native DBIO::SQLite::Deploy/DDL classes (clean break, see Changes); '
    . 'deployment_statements()/create_ddl_dir() no longer generate SQL.';
}

BEGIN {
  require DBIO;
  plan skip_all =>
      'Test needs ' . DBIO::Optional::Dependencies->req_missing_for ('deploy')
    unless DBIO::Optional::Dependencies->req_ok_for ('deploy')
}

local $ENV{DBI_DSN};

# this is how maint/gen_schema did it (connect() to force a storage
# instance, but no conninfo)
# there ought to be more code like this in the wild
like(
  DBIO::Test::Schema->connect->deployment_statements('SQLite'),
  qr/\bCREATE TABLE artist\b/i  # ensure quoting *is* disabled
);

lives_ok( sub {
    my $parse_schema = DBIO::SQLite::Test->init_schema(no_deploy => 1);
    $parse_schema->deploy({},'t/lib/test_deploy');
    $parse_schema->resultset("Artist")->all();
}, 'artist table deployed correctly' );

my $schema = DBIO::SQLite::Test->init_schema(quote_names => 1 );

my $var = dir_path("t", "var", "ddl_dir-$$");
mkpath($var) unless -d $var;

my $test_dir_1 = dir_path($var, 'test1', 'foo', 'bar');
rmtree($test_dir_1) if -d $test_dir_1;
$schema->create_ddl_dir( [qw(SQLite MySQL)], 1, $test_dir_1 );

ok( -d $test_dir_1, 'create_ddl_dir did a make_path on its target dir' );
ok( scalar( glob $test_dir_1.'/*.sql' ), 'there are sql files in there' );

my $less = $schema->clone;
$less->unregister_source('BindType');
$less->create_ddl_dir( [qw(SQLite MySQL)], 2, $test_dir_1, 1 );

for (
  [ SQLite => '"' ],
  [ MySQL => '`' ],
) {
  my $type = $_->[0];
  my $q = quotemeta($_->[1]);

  for my $f (map { file_path($test_dir_1, "DBIO-Test-Schema-${_}-$type.sql") } qw(1 2) ) {
    like scalar slurp_file($f), qr/CREATE TABLE ${q}track${q}/, "Proper quoting in $f";
  }

  {
    local $TODO = 'SQLT::Producer::MySQL has no knowledge of the mythical beast of quoting...'
      if $type eq 'MySQL';

    my $f = file_path($test_dir_1, "DBIO-Test-Schema-1-2-$type.sql");
    like scalar slurp_file($f), qr/DROP TABLE ${q}bindtype_test${q}/, "Proper quoting in diff $f";
  }
}

{
  local $TODO = 'we should probably add some tests here for actual deployability of the DDL?';
  ok( 0 );
}

END {
  rmtree($var);
}

done_testing;
