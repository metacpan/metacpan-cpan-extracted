package MyConfig;
use strict;
use warnings;
use Config::ENV::Multi [qw/ENV REGION/];

common {
    cnf => '/etc/my.cnf',
};

config [qw/prod jp/] => {
    db_host => 'jp.local',
};

config [qw/prod us/] => {
    db_host => 'us.local',
};

config ['dev', any] => {
    db_host => 'localhost',
};

config [unset, unset] => {
    db_host => 'localhost',
};

use Test::More;

undef $ENV{ENV};
undef $ENV{REGION};

is_deeply +__PACKAGE__->current, {
    cnf     => '/etc/my.cnf',
    db_host => 'localhost',
};

$ENV{ENV}    = 'prod';
$ENV{REGION} = 'jp';

is_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'jp.local',
};

$ENV{ENV}    = 'prod';
$ENV{REGION} = 'us';

is_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'us.local',
};

$ENV{ENV}    = 'dev';
$ENV{REGION} = 'jp';

is_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'localhost',
};

$ENV{ENV}    = 'dev';
$ENV{REGION} = 'us';

is_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'localhost',
};


done_testing;
