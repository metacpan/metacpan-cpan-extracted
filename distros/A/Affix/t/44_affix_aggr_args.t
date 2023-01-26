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
sub TakeIntStruct : Native('t/src/44_affix_aggr_args') : Signature([Struct[int => Int]]=> Int);
sub TakeIntIntStruct : Native('t/src/44_affix_aggr_args') :
    Signature([Struct[a => Int, b => Int]]=> Int);
sub TakeIntArray : Native('t/src/44_affix_aggr_args') : Signature([ArrayRef[Int, 3]]=> Int);
#
is TakeIntStruct( { int => 42 } ),         1,  'passed struct with a single int';
is TakeIntIntStruct( { a => 5, b => 9 } ), 14, 'passed struct with a two ints';
is TakeIntArray( [ 1, 2, 3 ] ),            6,  'passed array with a three ints';
#
done_testing;
