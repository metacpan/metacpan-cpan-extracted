use strict;
use Test::More;

require_ok 'Class::DBI::View';

use lib 't/lib';
use CD::Music;
use CD::Tester;

BEGIN {
    plan check_sqlite() ? (tests => 12) : (skip_all => 'no sqlite');
}

CD::Tester->test_all('SubQuery', 'SQLite');
