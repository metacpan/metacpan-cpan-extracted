use strict;
no warnings 'portable';
use Test::More 0.98;
BEGIN { chdir '../' if !-d 't'; }
use lib '../lib', '../blib/arch', '../blib/lib', 'blib/arch', 'blib/lib', '../../', '.';
use Affix qw[:all];
use File::Spec;
use t::lib::nativecall;
use experimental 'signatures';
$|++;
#
compile_test_lib('43_simple_returns');
#
sub ReturnVoid : Signature([Int]=>Void) : Native('t/43_simple_returns');
is ReturnVoid(4), undef, 'returning void works';
#
sub ReturnBool : Signature([Int]=>Bool) : Native('t/43_simple_returns');
is ReturnBool(4), !1, 'returning bool works';
is ReturnBool(5), !0, 'returning bool works';
#
sub ReturnInt : Signature([]=>Int) : Native('t/43_simple_returns');
is ReturnInt(), 101, 'returning int works';
is ReturnInt(), 101, 'returning int works';
#
sub ReturnNegInt : Signature([]=>Int) : Native('t/43_simple_returns');
is ReturnNegInt(), -101, 'returning negative int works';
is ReturnNegInt(), -101, 'returning negative int works';
#
sub ReturnShort : Signature([]=>Short) : Native('t/43_simple_returns');
is ReturnShort(), 102, 'returning short works';
is ReturnShort(), 102, 'returning short works';
#
sub ReturnNegShort : Signature([]=>Short) : Native('t/43_simple_returns');
is ReturnNegShort(), -102, 'returning negative short works';
is ReturnNegShort(), -102, 'returning negative short works';
#
TODO: {
    sub ReturnByte : Signature([]=>Char) : Native('t/43_simple_returns');
    local $TODO = 'platforms are might define a char any way they like';
    is ReturnByte(), -103, 'returning char works';
    is ReturnByte(), -103, 'returning char works';
}
#
sub ReturnDouble : Signature([]=>Double) : Native('t/43_simple_returns');
is_approx ReturnDouble(), 99.9e0, 'returning double works';
#
sub ReturnFloat : Signature([]=>Float) : Native('t/43_simple_returns');
is_approx ReturnFloat(), -4.5e0, 'returning float works';
#
sub ReturnString : Signature([]=>Str) : Native('t/43_simple_returns');
is ReturnString(), "epic cuteness", 'returning string works';
#
sub ReturnNullString : Native('t/43_simple_returns') : Signature([]=>Str);
is ReturnNullString(), undef, 'returning null string pointer';
#
sub ReturnInt64 : Signature([]=>LongLong) : Native('t/43_simple_returns');
is ReturnInt64(), 0xFFFFFFFFFF, 'returning int64 works';
#
sub ReturnNegInt64 : Signature([]=>LongLong) : Native('t/43_simple_returns');
is ReturnNegInt64(), -0xFFFFFFFFFF, 'returning negative int64 works';
is ReturnNegInt64(), -0xFFFFFFFFFF, 'returning negative int64 works';
#
sub ReturnUint8 : Signature([]=>UChar) : Native('t/43_simple_returns');
is ReturnUint8(), 0xFE, 'returning uint8 works';
#
sub ReturnUint16 : Signature([]=>UShort) : Native('t/43_simple_returns');
is ReturnUint16(), 0xFFFE, 'returning uint16 works';
#
sub ReturnUint32 : Signature([]=>ULong) : Native('t/43_simple_returns');
is ReturnUint32(), 0xFFFFFFFE, 'returning uint32 works';
#
done_testing;
