use strict;
use warnings;

use Test::More;

my @type_constraints = qw(
    Any
    AnyObj
    AnyObject
    ArrayObj
    ArrayObject
    ArrayRef
    Bool
    ClassName
    CodeObj
    CodeObject
    CodeRef
    ConsumerOf
    Defined
    Dict
    Enum
    FileHandle
    FloatObj
    FloatObject
    GlobRef
    HasMethods
    HashObj
    HashObject
    HashRef
    InstanceOf
    Int
    IntObj
    IntObject
    IntegerObj
    IntegerObject
    Item
    LaxNum
    Map
    Maybe
    Num
    NumObj
    NumObject
    NumberObj
    NumberObject
    Object
    OptList
    Optional
    Overload
    Ref
    RegexpObj
    RegexpObject
    RegexpRef
    RoleName
    ScalarObj
    ScalarObject
    ScalarRef
    Str
    StrMatch
    StrObj
    StrObject
    StrictNum
    StringObj
    StringObject
    Tied
    Tuple
    Undef
    UndefObj
    UndefObject
    UniversalObj
    UniversalObject
    Value
);

use_ok 'Data::Object::Library', ':types';
can_ok 'main', @type_constraints;

ok 1 and done_testing;
