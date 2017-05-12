#!perl

use strict;
use warnings;

use Test::More tests => 13;
use Test::Exception;
use Test::MockObject;

use Auth::Kokolores::Request;
use Auth::Kokolores::Plugin::SqlConnection;
use Auth::Kokolores::Plugin::SqlRetrieve;

my $server = Test::MockObject->new;
$server->set_isa('Auth::Kokolores', 'Net::Server');
$server->mock( 'log',
  sub {
    my ( $self, $level, $message ) = @_;
    print '# LOG('.$level.'): '.$message."\n"
  }
);

my $r;
lives_ok {
  $r = Auth::Kokolores::Request->new(
    server => $server,
    username => 'user',
    password => 'secret',
    realm => '',
    service => '',
  );
} 'create Auth::Kokolores::Request object';
isa_ok( $r, 'Auth::Kokolores::Request');

my $conn;
lives_ok {
  $conn = Auth::Kokolores::Plugin::SqlConnection->new(
    server => $server,
    name => 'database',
    dsn => 'dbi:SQLite::memory:',
  );
  $conn->child_init;
} 'create Auth::Kokolores::Plugin::SqlConnection object';
isa_ok( $conn, 'Auth::Kokolores::Plugin::SqlConnection');

my $dbh = $conn->dbh;

$dbh->do(
'CREATE TABLE `passwd` (
   `id` INTEGER PRIMARY KEY AUTOINCREMENT,
   `username` varchar(255) DEFAULT NULL,
   `password` varchar(255) DEFAULT NULL,
   `cost` varchar(255) DEFAULT NULL,
   `method` varchar(255) DEFAULT NULL
 )'
);
# insert test data
$dbh->do("INSERT INTO `passwd` VALUES (NULL, 'user', 'secret', NULL, NULL);");

my $p;
lives_ok {
  $p = Auth::Kokolores::Plugin::SqlRetrieve->new(
    server => $server,
    name => 'passwd',
    select => 'SELECT * FROM passwd WHERE username = ?',
  );
} 'create Auth::Kokolores::Plugin::SqlRetrieve object with plain';
isa_ok( $p, 'Auth::Kokolores::Plugin::SqlRetrieve');

## retrieve user
my $result;

lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 1, 'authentication must be successfull' );

cmp_ok( $r->get_info('username'), 'eq', 'user', 'get_info("username") must be "user"' );
cmp_ok( $r->get_info('password'), 'eq', 'secret', 'get_info("password") must be "secret"' );

$r->username('unknown user');
lives_ok {
  $result = $p->authenticate( $r );
} 'authenticate';
cmp_ok( $result, '==', 0, 'authentication must fail' );

lives_ok {
  $conn->shutdown;
} 'shutdown Auth::Kokolores::Plugin::SqlConnection';
