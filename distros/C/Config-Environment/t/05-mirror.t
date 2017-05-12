use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my $conf = Config::Environment->new(domain => 'myapp', mirror => 0);
my $env  = $conf->environment;

my $db1  = $conf->subdomain('db.1');
my $conn = $db1->param('conn' => 'dbi:mysql:dbname=barbaz');
my $user = $db1->param('user' => 'nimda');
my $pass = $db1->param('pass' => 'r00mur');
my $host = $db1->param('host' => '127.0.0.1');
my $port = $db1->param('port' => '5000');

ok not(exists($ENV{MYAPP_DB_1_CONN})), '$ENV{MYAPP_DB_1_CONN} does not exist';
ok not(exists($ENV{MYAPP_DB_1_USER})), '$ENV{MYAPP_DB_1_USER} does not exist';
ok not(exists($ENV{MYAPP_DB_1_PASS})), '$ENV{MYAPP_DB_1_PASS} does not exist';
ok not(exists($ENV{MYAPP_DB_1_HOST})), '$ENV{MYAPP_DB_1_HOST} does not exist';
ok not(exists($ENV{MYAPP_DB_1_PORT})), '$ENV{MYAPP_DB_1_PORT} does not exist';

done_testing;
