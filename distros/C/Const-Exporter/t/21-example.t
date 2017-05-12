use Test::Most;
use if $ENV{RELEASE_TESTING}, 'Test::Warnings';

use Const::Exporter

   non_numeric => [

       [qw/ FOO BAR BAZ /] => [qw/ foo bar baz /],

    ];

is(FOO, 'foo');
is(BAR, 'bar');
is(BAZ, 'baz');

done_testing;
