# test-script for Class::CompiledC (aka Hive::Ex aka Hive::Core)
# all tests should pass without any exception
# if any test fails, something is really broken
# this test-script is far from complete, additions welcome ;)


use Test::More tests => 234;
use Scalar::Util qw'dualvar';
use strict;
use warnings;
no warnings qw'prototype';

use_ok('Class::CompiledC');

{
        local $_ = 'foobar';
        is (Class::CompiledC::__include(), "\n#include foobar\n", 
            'test __include');
}

sub dies_with(&$$)
{
        my $sub  = shift;
        my $die  = shift;
        my $text = shift;
        my $tmp;
        my $res = eval {&$sub};
        $tmp = $@; 
        
        warn "is $tmp\nresult is $res\n" unless $tmp =~ $die;
        
        ok ($tmp =~ $die, $text);
}

sub no_die(&$)
{
        my $sub  = shift;
        my $text = shift;
        
        local $@;
        
        eval {&$sub};
        
        pass($text) unless  $@;
        fail($text." \n expected no die but got '$@'") if $@;
}


ok( Class::CompiledC::__baseref({},     'HASH'), 'baseref hash positive'); 
ok(!Class::CompiledC::__baseref('foo',  'HASH'), 
   'baseref hash negative (string)');    
ok(!Class::CompiledC::__baseref([],     'HASH'), '
   baseref hash negative (arrayref)');
ok(!Class::CompiledC::__baseref(12,     'HASH'), 
   'baseref hash negative (number)');
ok(!Class::CompiledC::__baseref(sub {}, 'HASH'), 
   'baseref hash negative (coderef)');
ok(!Class::CompiledC::__baseref(undef,  'HASH'), 
   'baseref hash negative (undef)');
ok(!Class::CompiledC::__baseref(\*foo,  'HASH'), 
   'baseref hash negative (globref)');
ok(!Class::CompiledC::__baseref(\1,     'HASH'), 
   'baseref hash negative (scalarref)');

ok( Class::CompiledC::__baseref([],     'ARRAY'), 
   'baseref array positive'); 
ok(!Class::CompiledC::__baseref('foo',  'ARRAY'), 
   'baseref array negative (string)');    
ok(!Class::CompiledC::__baseref({},     'ARRAY'), 
   'baseref array negative (hashref)');
ok(!Class::CompiledC::__baseref(12,     'ARRAY'), 
   'baseref array negative (number)');
ok(!Class::CompiledC::__baseref(sub {}, 'ARRAY'), 
   'baseref array negative (coderef)');
ok(!Class::CompiledC::__baseref(undef,  'ARRAY'), 
   'baseref array negative (undef)');
ok(!Class::CompiledC::__baseref(\*foo,  'ARRAY'), 
   'baseref array negative (globref)');
ok(!Class::CompiledC::__baseref(\1,     'ARRAY'), 
   'baseref array negative (scalarref)');

ok( Class::CompiledC::__baseref(\1,     'SCALAR'), 
   'baseref array positive'); 
ok(!Class::CompiledC::__baseref('foo',  'SCALAR'), 
   'baseref array negative (string)');    
ok(!Class::CompiledC::__baseref({},     'SCALAR'), 
   'baseref array negative (hashref)');
ok(!Class::CompiledC::__baseref(12,     'SCALAR'), 
   'baseref array negative (number)');
ok(!Class::CompiledC::__baseref(sub {}, 'SCALAR'), 
   'baseref array negative (coderef)');
ok(!Class::CompiledC::__baseref(undef,  'SCALAR'), 
   'baseref array negative (undef)');
ok(!Class::CompiledC::__baseref(\*foo,  'SCALAR'), 
   'baseref array negative (globref)');
ok(!Class::CompiledC::__baseref([],     'SCALAR'), 
   'baseref array negative (arrayref)');

ok( Class::CompiledC::__baseref(sub {}, 'CODE'), 
   'baseref code positive'); 
ok(!Class::CompiledC::__baseref('foo',  'CODE'),
   'baseref code negative (string)');    
ok(!Class::CompiledC::__baseref({},     'CODE'),
   'baseref code negative (hashref)');
ok(!Class::CompiledC::__baseref(12,     'CODE'),
   'baseref code negative (number)');
ok(!Class::CompiledC::__baseref(\*foo,  'CODE'),
   'baseref code negative (globref)');
ok(!Class::CompiledC::__baseref(undef,  'CODE'),
   'baseref code negative (undef)');
ok(!Class::CompiledC::__baseref(\1,     'CODE'),
   'baseref code negative (scalarref)');
ok(!Class::CompiledC::__baseref([],     'CODE'),
   'baseref code negative (arrayref)');

ok( Class::CompiledC::__baseref(\*foo,  'GLOB'), 
   'baseref glob positive'); 
ok(!Class::CompiledC::__baseref('foo',  'GLOB'), 
   'baseref glob negative (string)');    
ok(!Class::CompiledC::__baseref({},     'GLOB'), 
   'baseref glob negative (hashref)');
ok(!Class::CompiledC::__baseref(12,     'GLOB'), 
   'baseref glob negative (number)');
ok(!Class::CompiledC::__baseref(sub {}, 'GLOB'), 
   'baseref glob negative (coderef)');
ok(!Class::CompiledC::__baseref(undef,  'GLOB'), 
   'baseref glob negative (undef)');
ok(!Class::CompiledC::__baseref(\1,     'GLOB'), 
   'baseref glob negative (scalarref)');
ok(!Class::CompiledC::__baseref([],     'GLOB'), 
   'baseref glob negative (arrayref)');

ok( Class::CompiledC::__arrayref([]),     '__arrayref positive'); 
ok(!Class::CompiledC::__arrayref('foo'),  '__arrayref negative (string)');    
ok(!Class::CompiledC::__arrayref({}),     '__arrayref negative (hashref)');
ok(!Class::CompiledC::__arrayref(12),     '__arrayref negative (number)');
ok(!Class::CompiledC::__arrayref(sub {}), '__arrayref negative (coderef)');
ok(!Class::CompiledC::__arrayref(undef),  '__arrayref negative (undef)');
ok(!Class::CompiledC::__arrayref(\*foo),  '__arrayref negative (globref)');
ok(!Class::CompiledC::__arrayref(\1),     '__arrayref negative (scalarref)');

ok( Class::CompiledC::__hashref({}),     '__hashref positive'); 
ok(!Class::CompiledC::__hashref('foo'),  '__hashref negative (string)');    
ok(!Class::CompiledC::__hashref([]),     '__hashref negative (arrayref)');
ok(!Class::CompiledC::__hashref(12),     '__hashref negative (number)');
ok(!Class::CompiledC::__hashref(sub {}), '__hashref negative (coderef)');
ok(!Class::CompiledC::__hashref(undef),  '__hashref negative (undef)');
ok(!Class::CompiledC::__hashref(\*foo),  '__hashref negative (globref)');
ok(!Class::CompiledC::__hashref(\1),     '__hashref negative (scalarref)');

ok( Class::CompiledC::__coderef(sub {}), '__coderef positive'); 
ok(!Class::CompiledC::__coderef('foo'),  '__coderef negative (string)');    
ok(!Class::CompiledC::__coderef([]),     '__coderef negative (arrayref)');
ok(!Class::CompiledC::__coderef(12),     '__coderef negative (number)');
ok(!Class::CompiledC::__coderef({}),     '__coderef negative (hashref)');
ok(!Class::CompiledC::__coderef(undef),  '__coderef negative (undef)');
ok(!Class::CompiledC::__coderef(\*foo),  '__coderef negative (globref)');
ok(!Class::CompiledC::__coderef(\1),     '__coderef negative (scalarref)');

is(Class::CompiledC::__circumPrint('b', 'a', 'c'),        
   'abc', 
   'test __circumPrint simple');
is(Class::CompiledC::__circumPrint('b', 'a', 'c', 'd'),   
   'abc', 
   'test __circumPrint extra parameter');
is(Class::CompiledC::__circumPrint(2, 1, 3),              
   '123', 
   'test __circumPrint numeric parameters');
is(Class::CompiledC::__circumPrint(dualvar (1, 'b'), 'a', 'c'),   
   'abc', 
   'test __circumPrint daulvar\'ed parameter');

is(Class::CompiledC::__circumPrint('b' x 500, 'a' x 500, 'c' x 500),   
   ('a' x 500).('b' x 500).('c' x 500), 
   'test __circumPrint large parameters');


is(Class::CompiledC::__fetchSymbolName(\*FOO), 'FOO', 
   '__fetchSymbolName positive');

dies_with
{
        Class::CompiledC::__fetchSymbolName(\&FOO),
} qr/not a glob reference/i, '__fetchSymbolName negative (coderef)';

dies_with
{
        Class::CompiledC::__fetchSymbolName(1),
} qr/not a glob reference/i, '__fetchSymbolName negative (number)';

dies_with
{
        Class::CompiledC::__fetchSymbolName('foobar'),
} qr/not a glob reference/i, '__fetchSymbolName negative (string)';

dies_with
{
        Class::CompiledC::__fetchSymbolName([]),
} qr/not a glob reference/i, '__fetchSymbolName negative (arrayref)';

dies_with
{
        Class::CompiledC::__fetchSymbolName({}),
} qr/not a glob reference/i, '__fetchSymbolName negative (hashref)';

dies_with
{
        Class::CompiledC::__fetchSymbolName(\$$),
} qr/not a glob reference/i, '__fetchSymbolName negative (scalarref)';

dies_with
{
        Class::CompiledC::__fetchSymbolName(qr/foo/),
} qr/not a glob reference/i, '__fetchSymbolName negative (regexref)';

dies_with
{
        Class::CompiledC::__fetchSymbolName(bless [], 'foobar'),
} qr/not a glob reference/i, '__fetchSymbolName negative (blessed reference)';

is (Class::CompiledC::__promoteFieldTypeToMacro('FOO'), 
    '__CHECK(__ISFOO(__ARG0), "FOO")',
    '__promoteFieldTypeToMacro simple test');

is (Class::CompiledC::__promoteFieldTypeToMacro('fOoBaR'), 
    '__CHECK(__ISFOOBAR(__ARG0), "fOoBaR")',
    '__promoteFieldTypeToMacro case test');

is (Class::CompiledC::__promoteFieldTypeToMacro('any'), 
    '',
    '__promoteFieldTypeToMacro any test');

is (Class::CompiledC::__parseFieldType('Isa(FOO)'),
    '__CHECK(__ISA(__ARG0, "FOO"), "__ISA")',
    '__parseFieldType isa test');

is (Class::CompiledC::__parseFieldType('int'), 
    '__CHECK(__ISINT(__ARG0), "int")',
    '__parseFieldType int test');

is (Class::CompiledC::__parseFieldType('float'), 
    '__CHECK(__ISFLOAT(__ARG0), "float")',
    '__parseFieldType float test');

is (Class::CompiledC::__parseFieldType('number'), 
    '__CHECK(__ISNUMBER(__ARG0), "number")',
    '__parseFieldType number test');

is (Class::CompiledC::__parseFieldType('string'), 
    '__CHECK(__ISSTRING(__ARG0), "string")',
    '__parseFieldType string test');

is (Class::CompiledC::__parseFieldType('ref'), 
    '__CHECK(__ISREF(__ARG0), "ref")',
    '__parseFieldType ref test');

is (Class::CompiledC::__parseFieldType('arrayref'), 
    '__CHECK(__ISARRAYREF(__ARG0), "arrayref")',
    '__parseFieldType arrayref test');

is (Class::CompiledC::__parseFieldType('hashref'), 
    '__CHECK(__ISHASHREF(__ARG0), "hashref")',
    '__parseFieldType hashref test');

is (Class::CompiledC::__parseFieldType('coderef'), 
    '__CHECK(__ISCODEREF(__ARG0), "coderef")',
    '__parseFieldType coderef test');

is (Class::CompiledC::__parseFieldType('object'), 
    '__CHECK(__ISOBJECT(__ARG0), "object")',
    '__parseFieldType object test');

is (Class::CompiledC::__parseFieldType('regexpref'), 
    '__CHECK(__ISREGEXPREF(__ARG0), "regexpref")',
    '__parseFieldType regexpref test');

is (Class::CompiledC::__parseFieldType('any'), 
    '',
    '__parseFieldType any test');

is (Class::CompiledC::__parseFieldType('uint'), 
    '__CHECK(__ISUINT(__ARG0), "uint")',
    '__parseFieldType uint test');
    
dies_with
{
        Class::CompiledC::__parseFieldType('bad field type')
} qr/fail0r: bad type specified/i, '__parseFieldType unknown field test';


BEGIN
{
        my $test_class1 = <<'HERE';

package Class::CompiledCTest;
use base qw/Class::CompiledC/;

sub int_field       : Field(Int);
sub float_field     : Field(Float);
sub number_field    : Field(Number);
sub string_field    : Field(String);
sub ref_field       : Field(Ref);
sub arrayref_field  : Field(Arrayref);
sub hashref_field   : Field(Hashref);
sub coderef_field   : Field(Coderef);
sub object_field    : Field(Object);
sub regexpref_field : Field(Regexpref);
sub any_field       : Field(Any);


HERE
        eval $test_class1;        
}

my $obj = Class::CompiledCTest->new();

no_die
{
        $obj->int_field(1)
} 'int_field positive';
    
dies_with
{
        $obj->int_field([])
} qr/fail0r: bad arguments, expected/, 'int_field negative (arrayref)';

dies_with
{
        $obj->int_field({})
} qr/fail0r: bad arguments, expected/, 'int_field negative (hashref)';

dies_with
{
        $obj->int_field(sub {})
} qr/fail0r: bad arguments, expected/, 'int_field negative (coderef)';

dies_with
{
        $obj->int_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'int_field negative (globref)';

dies_with
{
        $obj->int_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'int_field negative (regexp ref)';

dies_with
{
        $obj->int_field(bless([], 'foo'))
} qr/fail0r: bad arguments, expected/, 'int_field negative (object)';

dies_with
{
        $obj->int_field(\[])
} qr/fail0r: bad arguments, expected/, 'int_field negative (scalarref)';

dies_with
{
        $obj->int_field('foobar')
} qr/fail0r: bad arguments, expected/, 'int_field negative (string)';

dies_with
{
        $obj->int_field('123')
} qr/fail0r: bad arguments, expected/, 'int_field negative (string int)';

dies_with
{
        $obj->int_field(123.3)
} qr/fail0r: bad arguments, expected/, 'int_field negative (float)';

no_die
{
        $obj->float_field(1)
} 'float_field positive (bare 1)';
    
no_die
{
        $obj->float_field('123')
} 'float_field negative (string int)';

no_die
{
        $obj->float_field(123.3)
} 'float_field negative (float)';


dies_with
{
        $obj->float_field([])
} qr/fail0r: bad arguments, expected/, 'float_field negative (arrayref)';

dies_with
{
        $obj->float_field({})
} qr/fail0r: bad arguments, expected/, 'float_field negative (hashref)';

dies_with
{
        $obj->float_field(sub {})
} qr/fail0r: bad arguments, expected/, 'float_field negative (coderef)';

dies_with
{
        $obj->float_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'float_field negative (globref)';

dies_with
{
        $obj->float_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'float_field negative (regexp ref)';

dies_with
{
        $obj->float_field(bless([], 'foo'))
} qr/fail0r: bad arguments, expected/, 'float_field negative (object)';

dies_with
{
        $obj->float_field(\[])
} qr/fail0r: bad arguments, expected/, 'float_field negative (scalarref)';

dies_with
{
        $obj->float_field('foobar')
} qr/fail0r: bad arguments, expected/, 'float_field negative (string)';

no_die
{
        $obj->number_field(1)
} 'number_field positive (bare 1)';
    
no_die
{
        $obj->number_field('123')
} 'number_field negative (string int)';

no_die
{
        $obj->number_field(123.3)
} 'number_field negative (number)';


dies_with
{
        $obj->number_field([])
} qr/fail0r: bad arguments, expected/, 'number_field negative (arrayref)';

dies_with
{
        $obj->number_field({})
} qr/fail0r: bad arguments, expected/, 'number_field negative (hashref)';

dies_with
{
        $obj->number_field(sub {})
} qr/fail0r: bad arguments, expected/, 'number_field negative (coderef)';

dies_with
{
        $obj->number_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'number_field negative (globref)';

dies_with
{
        $obj->number_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'number_field negative (regexp ref)';

dies_with
{
        $obj->number_field(bless([], 'foo'))
} qr/fail0r: bad arguments, expected/, 'number_field negative (object)';

dies_with
{
        $obj->number_field(\[])
} qr/fail0r: bad arguments, expected/, 'number_field negative (scalarref)';

dies_with
{
        $obj->number_field('foobar')
} qr/fail0r: bad arguments, expected/, 'number_field negative (string)';


no_die
{
        $obj->string_field('foobar')
} 'string_field positive (string)';

no_die
{
        $obj->string_field('123')
} 'string_field positive (int string)';


dies_with
{
        $obj->string_field([])
} qr/fail0r: bad arguments, expected/, 'string_field negative (arrayref)';

dies_with
{
        $obj->string_field({})
} qr/fail0r: bad arguments, expected/, 'string_field negative (hashref)';

dies_with
{
        $obj->string_field(sub {})
} qr/fail0r: bad arguments, expected/, 'string_field negative (coderef)';

dies_with
{
        $obj->string_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'string_field negative (globref)';

dies_with
{
        $obj->string_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'string_field negative (regexp ref)';

dies_with
{
        $obj->string_field(bless([], 'foo'))
} qr/fail0r: bad arguments, expected/, 'string_field negative (object)';

dies_with
{
        $obj->string_field(\[])
} qr/fail0r: bad arguments, expected/, 'string_field negative (scalarref)';

dies_with
{
        $obj->string_field(1)
} qr/fail0r: bad arguments, expected/, 'string_field negative (bare number)';
    
dies_with
{
        $obj->string_field(123.3)
} qr/fail0r: bad arguments, expected/, 'string_field negative (float)';


no_die
{
        $obj->ref_field([])
}  'ref_field positive (arrayref)';

no_die
{
        $obj->ref_field({})
}  'ref_field positive (hashref)';

no_die
{
        $obj->ref_field(sub {})
}  'ref_field positive (coderef)';

no_die
{
        $obj->ref_field(\*foo)
}  'ref_field positive (globref)';

no_die
{
        $obj->ref_field(qr/foo?/)
}  'ref_field positive (regexp ref)';

no_die
{
        $obj->ref_field(bless([], 'foo'))
}  'ref_field positive (object)';

no_die
{
        $obj->ref_field(\[])
}  'ref_field positive (scalarref)';


dies_with
{
        $obj->ref_field(1)
} qr/fail0r: bad arguments, expected/, 'ref_field negative (bare number)';
    

dies_with
{
        $obj->ref_field('foobar')
} qr/fail0r: bad arguments, expected/, 'ref_field negative (string)';

dies_with
{
        $obj->ref_field('123')
} qr/fail0r: bad arguments, expected/, 'ref_field negative (string ref)';

dies_with
{
        $obj->ref_field(123.3)
} qr/fail0r: bad arguments, expected/, 'ref_field negative (float)';

dies_with
{
        $obj->arrayref_field(1)
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (bare number)';    

no_die
{
        $obj->arrayref_field([])
} 'arrayref_field positive (arrayref)';

no_die
{
        $obj->arrayref_field(bless([], 'foo'))
}  'arrayref_field positive (object from arrayref)';

dies_with
{
        $obj->arrayref_field({})
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (hashref)';

dies_with
{
        $obj->arrayref_field(sub {})
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (coderef)';

dies_with
{
        $obj->arrayref_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (globref)';

dies_with
{
        $obj->arrayref_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (regexp ref)';

dies_with
{
        $obj->arrayref_field(\[])
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (scalarref)';

dies_with
{
        $obj->arrayref_field('foobar')
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (string)';

dies_with
{
        $obj->arrayref_field('123')
} qr/fail0r: bad arguments, expected/, 
'arrayref_field negative (string arrayref)';

dies_with
{
        $obj->arrayref_field(123.3)
} qr/fail0r: bad arguments, expected/, 'arrayref_field negative (float)';

dies_with
{
        $obj->hashref_field(1)
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (bare number)';    

no_die
{
        $obj->hashref_field({})
} 'hashref_field positive (hashref)';

dies_with
{
        $obj->hashref_field([])
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (arrayref)';

dies_with
{
        $obj->hashref_field(sub {})
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (coderef)';

dies_with
{
        $obj->hashref_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (globref)';

dies_with
{
        $obj->hashref_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (regexp ref)';

dies_with
{
        $obj->hashref_field(bless([], 'foo'))
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (object)';

dies_with
{
        $obj->hashref_field(\[])
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (scalarref)';

dies_with
{
        $obj->hashref_field('foobar')
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (string)';

dies_with
{
        $obj->hashref_field('123')
} qr/fail0r: bad arguments, expected/, 
'hashref_field negative (string hashref)';

dies_with
{
        $obj->hashref_field(123.3)
} qr/fail0r: bad arguments, expected/, 'hashref_field negative (float)';

dies_with
{
        $obj->coderef_field(1)
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (bare number)';    

no_die
{
        $obj->coderef_field(sub {})
} 'coderef_field positive (coderef)';

dies_with
{
        $obj->coderef_field([])
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (arrayref)';

dies_with
{
        $obj->coderef_field({})
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (hashref)';

dies_with
{
        $obj->coderef_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (globref)';

dies_with
{
        $obj->coderef_field(qr/foo?/)
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (regexp ref)';

dies_with
{
        $obj->coderef_field(bless([], 'foo'))
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (object)';

dies_with
{
        $obj->coderef_field(\[])
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (scalarref)';

dies_with
{
        $obj->coderef_field('foobar')
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (string)';

dies_with
{
        $obj->coderef_field('123')
} qr/fail0r: bad arguments, expected/, 
'coderef_field negative (string coderef)';

dies_with
{
        $obj->coderef_field(123.3)
} qr/fail0r: bad arguments, expected/, 'coderef_field negative (float)';

dies_with
{
        $obj->object_field(1)
} qr/fail0r: bad arguments, expected/, 'object_field negative (bare number)';    

no_die
{
        $obj->object_field(bless {}, 'foo')
} 'object_field positive (object)';

no_die
{
        $obj->object_field(qr/foo?/)
} 'object_field positive (regexp ref)';


dies_with
{
        $obj->object_field([])
} qr/fail0r: bad arguments, expected/, 'object_field negative (arrayref)';

dies_with
{
        $obj->object_field({})
} qr/fail0r: bad arguments, expected/, 'object_field negative (hashref)';

dies_with
{
        $obj->object_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'object_field negative (globref)';

dies_with
{
        $obj->object_field(sub {})
} qr/fail0r: bad arguments, expected/, 'object_field negative (coderef)';

dies_with
{
        $obj->object_field(\[])
} qr/fail0r: bad arguments, expected/, 'object_field negative (scalarref)';

dies_with
{
        $obj->object_field('foobar')
} qr/fail0r: bad arguments, expected/, 'object_field negative (string)';

dies_with
{
        $obj->object_field('123')
} qr/fail0r: bad arguments, expected/, 'object_field negative (string object)';

dies_with
{
        $obj->object_field(123.3)
} qr/fail0r: bad arguments, expected/, 'object_field negative (float)';

dies_with
{
        $obj->regexpref_field(1)
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (bare number)';    

no_die
{
        $obj->regexpref_field(qr/foo?/)
} 'regexpref_field positive (regexpref)';

dies_with
{
        $obj->regexpref_field([])
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (arrayref)';

dies_with
{
        $obj->regexpref_field({})
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (hashref)';

dies_with
{
        $obj->regexpref_field(\*foo)
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (globref)';

dies_with
{
        $obj->regexpref_field(bless [], 'foo')
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (regexp ref)';

dies_with
{
        $obj->regexpref_field(sub {})
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (coderef)';

dies_with
{
        $obj->regexpref_field(\[])
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (scalarref)';

dies_with
{
        $obj->regexpref_field('foobar')
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (string)';

dies_with
{
        $obj->regexpref_field('123')
} qr/fail0r: bad arguments, expected/, 
'regexpref_field negative (string regexpref)';

dies_with
{
        $obj->regexpref_field(123.3)
} qr/fail0r: bad arguments, expected/, 'regexpref_field negative (float)';

no_die
{
        $obj->any_field(1)
}  'any_field positive (bare number)';    

no_die
{
        $obj->any_field(qr/foo?/)
} 'any_field positive (any)';

no_die
{
        $obj->any_field([])
}  'any_field positive (arrayref)';

no_die
{
        $obj->any_field({})
}  'any_field positive (hashref)';

no_die
{
        $obj->any_field(\*foo)
}  'any_field positive (globref)';

no_die
{
        $obj->any_field(bless [], 'foo')
}  'any_field positive (regexp ref)';

no_die
{
        $obj->any_field(sub {})
}  'any_field positive (coderef)';

no_die
{
        $obj->any_field(\[])
}  'any_field positive (scalarref)';

no_die
{
        $obj->any_field('foobar')
}  'any_field positive (string)';

no_die
{
        $obj->any_field('123')
}  'any_field positive (string any)';

no_die
{
        $obj->any_field(123.3)
}  'any_field positive (float)';

BEGIN
{
        my $test_class2 = <<'HERE';

package Class::CompiledCTest2;
use overload;
use base 'Class::CompiledC';

sub foo : Field(String);

sub not_there : Abstract;
sub bar       : Alias(\&foo);
sub eternal   : Const('foobar');


sub concat    : Overload(+)
{
        my $self = shift;
        $self->foo($self->foo . shift)
}


HERE
        eval $test_class2;
}

$obj = Class::CompiledCTest2->new();
$obj->foo('8472');

is($obj->bar, '8472', 'test alias trait');

dies_with 
{
        $obj->not_there;
} qr/not implemented/i, 'test Abstract trait';

is($obj->eternal, 'foobar', 'test Const trait');
$obj + 'foo';
is($obj->foo, '8472foo', 'test Overload trait');

$obj = Class::CompiledCTest->new;
$obj->int_field(1);
$obj->float_field(1.2);
$obj->number_field(1.2);
$obj->string_field('foo');
$obj->ref_field([]);
$obj->arrayref_field([]);
$obj->hashref_field({});
$obj->coderef_field(sub {});
$obj->object_field(bless [], 'foo');
$obj->regexpref_field(qr/foo?/);
$obj->any_field('something');

ok(defined $obj->int_field(),       'int_field sanity checks');       
ok(defined $obj->float_field(),     'float_field sanity checks');     
ok(defined $obj->number_field(),    'number_field sanity checks');    
ok(defined $obj->string_field(),    'string_field sanity checks');    
ok(defined $obj->ref_field(),       'ref_field sanity checks');       
ok(defined $obj->arrayref_field(),  'arrayref_field sanity checks');  
ok(defined $obj->hashref_field(),   'hashref_field sanity checks');   
ok(defined $obj->coderef_field(),   'coderef_field sanity checks');   
ok(defined $obj->object_field(),    'object_field sanity checks');    
ok(defined $obj->regexpref_field(), 'regexpref_field sanity checks'); 
ok(defined $obj->any_field(),       'any_field sanity checks');    

my $fields = $obj->inspect;
my $ref    =
{
        int_field        => 'Int',      
        float_field      => 'Float',    
        number_field     => 'Number',   
        string_field     => 'String',   
        ref_field        => 'Ref',      
        arrayref_field   => 'Arrayref', 
        hashref_field    => 'Hashref',  
        coderef_field    => 'Coderef',  
        object_field     => 'Object',   
        regexpref_field  => 'Regexpref',
        any_field        => 'Any',      
};

is_deeply($fields, $ref, 'test inspect method');





