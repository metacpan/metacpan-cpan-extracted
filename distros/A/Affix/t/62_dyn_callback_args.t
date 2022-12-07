use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:all];
use Dyn::Call;
use Dyn::Callback qw[dcbNewCallback dcbArgInt];
use File::Spec;
use t::lib::nativecall;
use experimental 'signatures';
$|++;
#
compile_test_lib('62_dyn_callback_args');
#
sub TakeCallback : Native('t/62_dyn_callback_args') :
    Signature([ InstanceOf['Dyn::Callback'] ] => Int);
is TakeCallback(
    dcbNewCallback(
        'i)i',
        sub {
            my ( $cb, $args, $result, $userdata ) = @_;
            is dcbArgInt($args), 101, 'dcbArgInt(...) snags the first param';
            is_deeply $userdata, [ 1, 5 ], 'userdata passed is correct!';
            is $result->i(5400), 5400, 'setting the callback up to return 5400...';
            diag '     ...and telling dyncall to expect an integer result...';
            'i';
        },
        [ 1, 5 ]
    )
    ),
    5400, 'return value from callback is 5400';
#
done_testing;
