use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my $conf = Config::Environment->new(domain => 'myapp');
my $db1  = $conf->subdomain('db.1');
my $conn = $db1->param('conn' => 'dbi:mysql:dbname=foobar');
my $user = $db1->param('user' => 'admin');
my $pass = $db1->param('pass' => 's3cret');

is $ENV{MYAPP_DB_1_CONN}, 'dbi:mysql:dbname=foobar', '$ENV{MYAPP_DB_1_CONN} is ok';
is $ENV{MYAPP_DB_1_USER}, 'admin',  '$ENV{MYAPP_DB_1_USER} is ok';
is $ENV{MYAPP_DB_1_PASS}, 's3cret', '$ENV{MYAPP_DB_1_PASS} is ok';

{
    my $conf = Config::Environment->new(domain => 'myapp', lifecycle => 1);
    my $db1  = $conf->subdomain('db.1');
    my $conn = $db1->param('conn' => 'dbi:mysql:dbname=barbaz');
    my $user = $db1->param('user' => 'nimda');
    my $pass = $db1->param('pass' => 'r00mur');
    my $port = $db1->param('port' => '5000');

    is $ENV{MYAPP_DB_1_CONN}, 'dbi:mysql:dbname=barbaz', '$ENV{MYAPP_DB_1_CONN} is ok';
    is $ENV{MYAPP_DB_1_USER}, 'nimda',  '$ENV{MYAPP_DB_1_USER} is ok';
    is $ENV{MYAPP_DB_1_PASS}, 'r00mur', '$ENV{MYAPP_DB_1_PASS} is ok';
    is $ENV{MYAPP_DB_1_PORT}, '5000',   '$ENV{MYAPP_DB_1_PORT} is ok';
}

ok not(exists($ENV{MYAPP_DB_1_PORT})), '$ENV{MYAPP_DB_1_PORT} does not exist';
is $ENV{MYAPP_DB_1_CONN}, 'dbi:mysql:dbname=foobar', '$ENV{MYAPP_DB_1_CONN} is ok';
is $ENV{MYAPP_DB_1_USER}, 'admin',  '$ENV{MYAPP_DB_1_USER} is ok';
is $ENV{MYAPP_DB_1_PASS}, 's3cret', '$ENV{MYAPP_DB_1_PASS} is ok';

done_testing;
