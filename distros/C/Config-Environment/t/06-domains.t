use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my @domains = qw(
    MYAPP-LEJUICE
    MYAPP::LeJuice
    myapp\lejuice
    myapp_lejuice
    myapp/lejuice
    myapp.lejuice
    myapp...lejuice
);

for my $domain (@domains) {
    my $conf = Config::Environment->new(domain => $domain);

    my $db1  = $conf->subdomain('db.1');
    my $conn = $db1->param('conn' => 'dbi:mysql:dbname=barbaz');
    my $user = $db1->param('user' => 'nimda');
    my $pass = $db1->param('pass' => 'r00mur');
    my $host = $db1->param('host' => '127.0.0.1');
    my $port = $db1->param('port' => '5000');

    is $conf->param('db.1.conn'), 'dbi:mysql:dbname=barbaz',
        'db.1.conn returns ok';
    is $conf->param('db.1.user'), 'nimda',
        'db.1. returns ok';
    is $conf->param('db.1.pass'), 'r00mur',
        'db.1. returns ok';
    is $conf->param('db.1.host'), '127.0.0.1',
        'db.1. returns ok';
    is $conf->param('db.1.port'), '5000',
        'db.1. returns ok';

    ok exists($ENV{MYAPP_LEJUICE_DB_1_CONN}),
        '$ENV{MYAPP_LEJUICE_DB_1_CONN} exists';
    ok exists($ENV{MYAPP_LEJUICE_DB_1_USER}),
        '$ENV{MYAPP_LEJUICE_DB_1_USER} exists';
    ok exists($ENV{MYAPP_LEJUICE_DB_1_PASS}),
        '$ENV{MYAPP_LEJUICE_DB_1_PASS} exists';
    ok exists($ENV{MYAPP_LEJUICE_DB_1_HOST}),
        '$ENV{MYAPP_LEJUICE_DB_1_HOST} exists';
    ok exists($ENV{MYAPP_LEJUICE_DB_1_PORT}),
        '$ENV{MYAPP_LEJUICE_DB_1_PORT} exists';

    is $ENV{MYAPP_LEJUICE_DB_1_CONN}, 'dbi:mysql:dbname=barbaz',
        'MYAPP_LEJUICE_DB_1_CONN returns ok';
    is $ENV{MYAPP_LEJUICE_DB_1_USER}, 'nimda',
        'MYAPP_LEJUICE_DB_1_USER returns ok';
    is $ENV{MYAPP_LEJUICE_DB_1_PASS}, 'r00mur',
        'MYAPP_LEJUICE_DB_1_PASS returns ok';
    is $ENV{MYAPP_LEJUICE_DB_1_HOST}, '127.0.0.1',
        'MYAPP_LEJUICE_DB_1_HOST returns ok';
    is $ENV{MYAPP_LEJUICE_DB_1_PORT}, '5000',
        'MYAPP_LEJUICE_DB_1_PORT returns ok';

}

done_testing;
