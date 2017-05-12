#
#===============================================================================
#
#         FILE:  02-plugin.t
#
#  DESCRIPTION:  
#
#        FILES:  ---
#         BUGS:  ---
#        NOTES:  ---
#       AUTHOR:  Andrey Kostenko, <andrey@kostenko.name>
#      COMPANY:  Rambler Internet Holding
#      VERSION:  $Revision: 13 $
#      CREATED:  22.10.2008 12:51:38 MSD
#     REVISION:  $Revision: 13 $
#===============================================================================

use strict;
use warnings;

use Test::More ;

if ( ! $ENV{ MEMCACHED_SERVER } ) {
    plan skip_all => '$ENV{MEMCACHED_SERVER} is not set';
}
plan tests => 13;

use lib 't/TestApp/lib';

use_ok 'Catalyst::Test', 'TestApp';

foreach ( 1 .. 5 ) {
    is( request('/checked_page')->code, 200, 'test');
}
foreach ( 1 .. 5 ) {
    is( request('/protected_page')->code, 200, 'test');
}
is( request('/checked_page')->code, 500 );
is( request('/protected_page')->code, 500 );
