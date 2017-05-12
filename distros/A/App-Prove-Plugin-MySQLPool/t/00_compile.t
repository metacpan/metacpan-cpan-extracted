use strict;
use Test::More tests => 2;

BEGIN {
    use_ok 'App::Prove::Plugin::MySQLPool';
    use_ok 'Test::mysqld::Pool';
};
