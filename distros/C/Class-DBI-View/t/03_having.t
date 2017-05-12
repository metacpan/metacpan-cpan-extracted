use strict;
use Test::More;

require_ok 'Class::DBI::View';

use lib 't/lib';
use CD::Music;
use CD::Tester;

BEGIN {
    plan check_mysql() ? (tests => 12) : (skip_all => 'no mysql');
}

CD::Tester->test_all('Having', 'mysql');
