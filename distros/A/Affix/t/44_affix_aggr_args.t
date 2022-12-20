use strict;
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:all];
use File::Spec;
use t::lib::nativecall;
use experimental 'signatures';
$|++;
#
compile_test_lib('44_affix_aggr_args');

# Int related
sub TakeIntStruct : Native('t/44_affix_aggr_args') : Signature([Struct[int => Int]]=> Int);
sub TakeIntIntStruct : Native('t/44_affix_aggr_args') :
    Signature([Struct[a => Int, b => Int]]=> Int);
is TakeIntStruct( { int => 42 } ),         1,  'passed struct with a single int';
is TakeIntIntStruct( { a => 5, b => 9 } ), 14, 'passed struct with a two ints';
done_testing;
