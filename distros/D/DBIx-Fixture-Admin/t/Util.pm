package t::Util;
use strict;
use warnings;
use utf8;

use Test::More;
use Test::mysqld;

BEGIN {
    eval {
        my $mysqld = Test::mysqld->new(
            my_cnf => {
                'skip-networking' => '', # no TCP socket
            }
        ) or die $Test::mysqld::errstr;

        $TEST_GUARDS::MYSQLD = $mysqld;
        $ENV{TEST_MYSQL}     = $mysqld->dsn;

        END { undef $TEST_GUARDS::MYDSLD }
    } or plan(skip_all => 'mysql-server is required to this test');
}

1;
__END__

