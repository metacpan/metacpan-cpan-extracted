use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', 'lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix;
use Config;
$|++;
#
use t::lib::nativecall;
#
compile_test_lib('70_affix_varargs');
my $lib = 't/70_affix_varargs';
#
#int min(int arg_count, ...)
subtest 'ellipsis varargs' => sub {
    is wrap( $lib, 'average', [ Int, CC_ELLIPSIS_VARARGS, Int, Int ], Int )->( 2, 3, 4 ), 3,
        'average( 2, 3, 4 )';
    is wrap( $lib, 'average', [ Int, CC_ELLIPSIS_VARARGS, Int, Int, Int ], Int )->( 3, 5, 10, 15 ),
        10, 'average( 3, 5, 10, 15 )';
};
#
done_testing;
