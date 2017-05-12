use strict;
use warnings;

use lib 'xt';

use Test::More;
use connect;

my $dbh = dbi_connect;
ok $dbh->do( "SELECT 1" ) == 1;

done_testing;
