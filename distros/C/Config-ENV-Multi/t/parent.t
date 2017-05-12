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
    parent([qw/prod jp/]),
    db_host => 'us.local',
};

use Test::More;
use Test::Deep;

$ENV{ENV}    = 'prod';
$ENV{REGION} = 'us';

cmp_deeply +__PACKAGE__->current, {
    cnf => '/etc/my.cnf',
    db_host => 'us.local',
};

done_testing;
