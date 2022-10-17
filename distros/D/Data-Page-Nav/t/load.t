use strict;
use warnings;
use Test::More;

use_ok('Data::Page::Nav');

can_ok(
    'Data::Page::Nav',
    'number_of_pages',
    'pages_nav',
    'first_nav_page',
    'last_nav_page'
);

done_testing;
