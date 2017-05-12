BEGIN {
    $ENV{MYAPP_DB_1_USER} = 'admin';
    $ENV{MYAPP_DB_1_PASS} = 's3cret';
}

use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my $conf = Config::Environment->new('myapp');
   $conf->param('db.1.conn' => 'dbi:mysql:dbname=foobar');

my $db  = $conf->subdomain('db');
my $db1 = $db->subdomain('1');

my $conn = $db1->param('conn');
my $user = $db1->param('user');
my $pass = $db1->param('pass');

ok $conf, '$conf is ok';
is $conn, 'dbi:mysql:dbname=foobar', '$conn is ok';
is $user, 'admin', '$user is ok';
is $pass, 's3cret', '$pass is ok';

$db1->param('conn' => '...');
$db1->param('user' => '...');
$db1->param('pass' => '...');

$conn = $conf->param('db.1.conn');
$user = $conf->param('db.1.user');
$pass = $conf->param('db.1.pass');

is $conn, '...', '$conn is ok';
is $user, '...', '$user is ok';
is $pass, '...', '$pass is ok';

done_testing;
