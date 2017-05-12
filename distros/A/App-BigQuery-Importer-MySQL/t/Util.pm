package t::Util;
use strict;
use warnings;
use utf8;

use Test::More 0.98;
use Test::mysqld;

sub start_mysqld {
    eval {
        require Test::mysqld;
        Test::mysqld->new(
             my_cnf => {
                 'skip-networking' => '', # no TCP socket
             }
         ) or die $Test::mysqld::errstr;
    } or plan(skip_all => 'mysql-server is required to this test');
}

1;
__END__

