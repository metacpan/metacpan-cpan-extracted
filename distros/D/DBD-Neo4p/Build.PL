use Module::Build;
use strict;
use warnings;

my $build = Module::Build->new(
  'dist_name' => 'DBD-Neo4p',
  'dist_abstract' => 'DBI-compliant interface for Neo4j server',
  'dist_version_from' => 'lib/DBD/Neo4p.pm',
  'dist_author' => 'Mark A. Jensen',
  license => 'perl',
  perl => '5.010',
  'configure_requires' => {
    'Module::Build' => 0
   },
  'build_requires' => {
    'REST::Neo4p' => '0.3010',
    'Test::More' => 0,
    'Test::Exception' => 0,
    'Module::Build' => 0,
    'DBI' => '1.632',
    'experimental' => 0
   },
  'requires' => {
    'REST::Neo4p' => '0.3010',
    'DBI' => '1.632',
    'JSON' => 0
   },
  meta_merge => {
    resources => {
      repository  => 'http://github.com/majensen/dbd-neo4p.git',
      bugtracker =>  'http://github.com/majensen/dbd-neo4p.git/issues',
    }
   },
  perl => 5.0101
);
$build->notes( test_server => $ENV{DBD_NEO4P_TEST_SERVER} //$build->prompt("Test server?", "http://127.0.0.1:7474"));
$build->notes( user => $ENV{DBD_NEO4P_TEST_USER} //$build->prompt("Username?", ""));
$build->notes( pass => $ENV{DBD_NEO4P_TEST_PASS} //$build->prompt("Pass?",""));
$build->notes( backend => $ENV{DBD_NEO4P_AGENT} //$build->prompt("UserAgent module?","LWP::UserAgent"));
$build->create_build_script;
