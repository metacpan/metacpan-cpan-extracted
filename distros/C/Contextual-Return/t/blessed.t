use Contextual::Return;

sub   blessed_obj     { return bless {}, 'Blessed' }
sub unblessed_obj     { return 42 }

sub   blessed_OBJREF  { return OBJREF  { bless {}, 'Blessed' } }
sub   blessed_REF     { return REF     { bless {}, 'Blessed' } }
sub   blessed_SCALAR  { return SCALAR  { bless {}, 'Blessed' } }
sub   blessed_VALUE   { return VALUE   { bless {}, 'Blessed' } }
sub   blessed_NONVOID { return NONVOID { bless {}, 'Blessed' } }
sub   blessed_DEFAULT { return DEFAULT { bless {}, 'Blessed' } }
sub   blessed_BLESSED { return BLESSED { 'EXPLICITLY_BLESSED' } }

sub unblessed_OBJREF  { return OBJREF  { 'unblessed' } }
sub unblessed_REF     { return REF     { 'unblessed' } }
sub unblessed_SCALAR  { return SCALAR  { 'unblessed' } }
sub unblessed_VALUE   { return VALUE   { 'unblessed' } }
sub unblessed_NONVOID { return NONVOID { 'unblessed' } }
sub unblessed_DEFAULT { return DEFAULT { 'unblessed' } }
sub unblessed_BLESSED { return BLESSED { undef }       }

package Other;
use Test::More 'no_plan';
use Scalar::Util 'blessed';

is ref(  ::blessed_obj    ()), 'Blessed'                   => 'ref blessed obj    ';
is ref(  ::blessed_OBJREF ()), 'Contextual::Return::Value' => 'ref blessed OBJREF ';
is ref(  ::blessed_REF    ()), 'Contextual::Return::Value' => 'ref blessed REF    ';
is ref(  ::blessed_SCALAR ()), 'Contextual::Return::Value' => 'ref blessed SCALAR ';
is ref(  ::blessed_VALUE  ()), 'Contextual::Return::Value' => 'ref blessed VALUE  ';
is ref(  ::blessed_NONVOID()), 'Contextual::Return::Value' => 'ref blessed NONVOID';
is ref(  ::blessed_DEFAULT()), 'Contextual::Return::Value' => 'ref blessed DEFAULT';
is ref(  ::blessed_BLESSED()), 'Contextual::Return::Value' => 'ref blessed BLESSED';

is ref(  ::unblessed_obj    ()), q{}                         => 'ref unblessed obj    ';
is ref(  ::unblessed_OBJREF ()), 'Contextual::Return::Value' => 'ref unblessed OBJREF ';
is ref(  ::unblessed_REF    ()), 'Contextual::Return::Value' => 'ref unblessed REF    ';
is ref(  ::unblessed_SCALAR ()), 'Contextual::Return::Value' => 'ref unblessed SCALAR ';
is ref(  ::unblessed_VALUE  ()), 'Contextual::Return::Value' => 'ref unblessed VALUE  ';
is ref(  ::unblessed_NONVOID()), 'Contextual::Return::Value' => 'ref unblessed NONVOID';
is ref(  ::unblessed_DEFAULT()), 'Contextual::Return::Value' => 'ref unblessed DEFAULT';
is ref(  ::unblessed_BLESSED()), 'Contextual::Return::Value' => 'ref unblessed BLESSED';

is blessed(  ::blessed_obj    ()), 'Blessed' => 'blessed obj    ';
is blessed(  ::blessed_OBJREF ()), 'Blessed' => 'blessed OBJREF ';
is blessed(  ::blessed_REF    ()), 'Blessed' => 'blessed REF    ';
is blessed(  ::blessed_SCALAR ()), 'Blessed' => 'blessed SCALAR ';
is blessed(  ::blessed_VALUE  ()), 'Blessed' => 'blessed VALUE  ';
is blessed(  ::blessed_NONVOID()), 'Blessed' => 'blessed NONVOID';
is blessed(  ::blessed_DEFAULT()), 'Blessed' => 'blessed DEFAULT';
is blessed(  ::blessed_BLESSED()), 'EXPLICITLY_BLESSED' => 'blessed BLESSED';

is blessed(::unblessed_obj    ()), undef()   => 'unblessed obj    ';
is blessed(::unblessed_OBJREF ()), undef()   => 'unblessed OBJREF ';
is blessed(::unblessed_REF    ()), undef()   => 'unblessed REF    ';
is blessed(::unblessed_SCALAR ()), undef()   => 'unblessed SCALAR ';
is blessed(::unblessed_VALUE  ()), undef()   => 'unblessed VALUE  ';
is blessed(::unblessed_NONVOID()), undef()   => 'unblessed NONVOID';
is blessed(::unblessed_DEFAULT()), undef()   => 'unblessed DEFAULT';
is blessed(::unblessed_BLESSED()), undef()   => 'unblessed BLESSED';
