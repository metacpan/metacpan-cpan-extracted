BEGIN {
    $ENV{MYAPP_DB_1_USER} = 'admin';
    $ENV{MYAPP_DB_1_PASS} = 's3cret';
}

use utf8;
use strict;
use warnings;
use Test::More;
use Config::Environment;

my $stash = {
    http => [
        {
            type => 'starman',
            host => '0.0.0.0',
            port => 9000,
            opts => {
                startup_check => 1
            }
        },
        {
            type => 'twiggy',
            host => '0.0.0.0',
            port => 9001,
            opts => {
                startup_check => 1
            }
        }
    ]
};

my $conf = Config::Environment->new(domain => 'myapp', stash => $stash);
   $conf->stash->{db} = [{conn => 'dbi:mysql:dbname=foobar'}];

my $db  = $conf->subdomain('db');
my $db1 = $db->subdomain('1');

my $conn = $db1->param('conn');
my $user = $db1->param('user');
my $pass = $db1->param('pass');

ok $conf, '$conf is ok';
is $conn, 'dbi:mysql:dbname=foobar', '$conn is ok';
is $user, 'admin', '$user is ok';
is $pass, 's3cret', '$pass is ok';

my $http  = $conf->subdomain('http');
my $http1 = $http->subdomain('1');
my $http2 = $http->subdomain('2');

ok $http,  '$http is ok';
ok $http1, '$http1 is ok';
ok $http2, '$http2 is ok';

is $http1->param('type'), 'starman', 'http1.type is ok';
is $http1->param('host'), '0.0.0.0', 'http1.host is ok';
is $http1->param('port'), 9000,      'http1.port is ok';
is $http1->param('opts.startup_check'), 1, 'http1.startup_check is ok';
is_deeply $http1->param('opts') => { startup_check => 1 };

is $http2->param('type'), 'twiggy',  'http2.type is ok';
is $http2->param('host'), '0.0.0.0', 'http2.host is ok';
is $http2->param('port'), 9001,      'http2.port is ok';
is $http2->param('opts.startup_check'), 1, 'http2.startup_check is ok';
is_deeply $http2->param('opts') => { startup_check => 1 };

done_testing;
