package MyConfig;
use strict;
use warnings;
use Config::ENV::Multi 'ENV';

common {
    cnf => '/etc/my.cnf',
};

config 'prod' => {
    db_host => 'jp.local',
};

config 'dev' => {
    db_host => 'localhost',
};

use Test::More;
use Test::Deep;

undef $ENV{ENV};
cmp_deeply +__PACKAGE__->current, {
    cnf     => '/etc/my.cnf',
};

$ENV{ENV}    = 'prod';
cmp_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'jp.local',
};

$ENV{ENV}    = 'dev';
cmp_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'localhost',
};

package Foo;
use strict;

BEGIN { MyConfig->import(export => 'config') };

undef $ENV{ENV};
use Test::More;
use Test::Deep;
cmp_deeply config->current, { cnf => '/etc/my.cnf' };

done_testing;
