use strict;
use Test::More 0.98;
use Test::More::UTF8;
use FindBin::libs;
use open ':std' => ( $^O eq 'MSWin32' ? ':locale' : ':utf8' );

use_ok $_ for qw(
    Data::HTML::TreeDumper
);

done_testing;
