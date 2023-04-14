use strict;
use warnings;
use Affix;
use Test::More;
#
typedef 'Structure'                                                    => Struct [];
typedef halide_buffer_t                                                => Struct [];
typedef 'test_namespace::test_namespace::enclosing_class::test_struct' => Struct [];
#
is Affix::Itanium_mangle( undef, 'test_function', [] ), '_Z13test_functionv', '_Z13test_functionv';
is Affix::Itanium_mangle(
    undef,
    'test_function',
    [   Bool, Char, UChar, Short, UShort, Int, UInt, Long, ULong, LongLong, ULongLong, Float,
        Double,
        Pointer [Void],
        Pointer [Void]
    ]
    ),
    '_Z13test_functionbchstijlmxyfdPvS_', '_Z13test_functionbchstijlmxyfdPvS_';
is Affix::Itanium_mangle(
    undef,
    'test_function',
    [   Bool,           Char,
        UChar,          Short,
        UShort,         Int,
        UInt,           Long,
        ULong,          LongLong,
        ULongLong,      Float,
        Double,         Pointer [Void],
        Structure(),    Pointer [ Structure() ],
        Pointer [Void], Pointer [Void],
        Pointer [ Pointer [Void] ]
    ]
    ),
    '_Z13test_functionbchstijlmxyfdPv9StructurePS0_S_S_PS_',
    '_Z13test_functionbchstijlmxyfdPv9StructurePS0_S_S_PS_';
is Affix::Itanium_mangle(
    undef,
    'test_function',
    [   Bool,                       Char,
        UChar,                      Short,
        UShort,                     Int,
        UInt,                       Long,
        ULong,                      LongLong,
        ULongLong,                  Float,
        Double,                     Pointer [Void],
        Structure(),                Pointer [ Structure() ],
        Pointer [Void],             Pointer [Void],
        Pointer [ Pointer [Void] ], Structure()
    ]
    ),
    '_Z13test_functionbchstijlmxyfdPv9StructurePS0_S_S_PS_S0_',
    '_Z13test_functionbchstijlmxyfdPv9StructurePS0_S_S_PS_S0_';
is Affix::Itanium_mangle( undef, 'foo::test_function', [] ), '_ZN3foo13test_functionEv',
    '_ZN3foo13test_functionEv';
is Affix::Itanium_mangle( undef, 'foo::bar::test_function', [] ), '_ZN3foo3bar13test_functionEv',
    '_ZN3foo3bar13test_functionEv';
is Affix::Itanium_mangle( undef, 'foo::bar::test_function', [Int] ),
    '_ZN3foo3bar13test_functionEi', '_ZN3foo3bar13test_functionEi';
is Affix::Itanium_mangle( undef, 'foo::bar::test_function',
    [ Int, Pointer [ halide_buffer_t() ] ] ),
    '_ZN3foo3bar13test_functionEiP15halide_buffer_t',
    '_ZN3foo3bar13test_functionEiP15halide_buffer_t';

#~ [   'test_namespace::test_namespace::test_function',
#~ CodeRef [ [ test_namespace::test_namespace::enclosing_class::test_struct() ] => Int ],
#~ '_ZN14test_namespace14test_namespace13test_functionENS0_15enclosing_class11test_structE'
#~ ],
#~ {"_ZN14test_namespace14test_namespace13test_functionENS0_15enclosing_class11test_structE",
#~ "test_namespace::test_namespace::test_function(test_namespace::test_namespace::enclosing_class::test_struct)"},
#~ {"_ZN3foo3bar13test_functionEiP15halide_buffer_tS2_", "foo::bar::test_function(int, halide_buffer_t*, halide_buffer_t*)"},
#~ {"_ZN14test_namespace14test_namespace13test_functionEPNS_11test_structEPKS1_", "test_namespace::test_namespace::test_function(test_namespace::test_struct*, test_namespace::test_struct const*)"},
#~ {"_ZN14test_namespace14test_namespace13test_functionENS0_15enclosing_class11test_structES2_",
#~ "test_namespace::test_namespace::test_function(test_namespace::test_namespace::enclosing_class::test_struct, test_namespace::test_namespace::enclosing_class::test_struct)"},
#~ {"_ZSt13test_functionv", "std::test_function()"},
#~ {"_ZNSt3foo13test_functionEv", "std::foo::test_function()"},
#~ {"_ZSt13test_functionNSt15enclosing_class11test_structE", "std::test_function(std::enclosing_class::test_struct)"},
#~ {"_ZN14test_namespace14test_namespace13test_functionEPNS_10test_classE", "test_namespace::test_namespace::test_function(test_namespace::test_class*)"},
#~ {"_ZN14test_namespace14test_namespace13test_functionEPNS_10test_unionE", "test_namespace::test_namespace::test_function(test_namespace::test_union*)"},
#~ {"_ZN14test_namespace14test_namespace13test_functionEPNS_9test_enumE", "test_namespace::test_namespace::test_function(test_namespace::test_enum*)"},
done_testing;
