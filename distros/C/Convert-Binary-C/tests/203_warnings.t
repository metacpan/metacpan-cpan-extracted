################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;
use Convert::Binary::C::Cached;

$^W = 1;

BEGIN { plan tests => 7302 }

my($code, $data);
$code = do { local $/; <DATA> };
$data = "abcd";

my %code = (
  macro => <<'ENDC',
#define FOO 1
#define FOO 2
ENDC
  assert => <<'ENDC',
#assert THIS(is) garbage
#assert VOID()
ENDC
  assert_syntax => <<'ENDC',
#assert TEST(assertion)
#if #TEST ()
  /* this is a syntax error */
#endif
ENDC
  include => <<'ENDC',
#include <not_here.h>
ENDC
  endif => <<'ENDC',
#ifdef FOO BLABLA
#endif
#endif
ENDC
  else => <<'ENDC',
#else
ENDC
  elif => <<'ENDC',
#elif 1
ENDC
  unknown => <<'ENDC',
#foobar
ENDC
  pragma_pack_1 => <<'ENDC',
#pragma pack(1)
struct foo {
  int x;
};
#pragma pack(3)
ENDC
  pragma_pack_2 => <<'ENDC',
#pragma pack(push, 5)
struct foo {
  int x;
};
#pragma pack(0)
ENDC
  pragma_pack_3 => <<'ENDC',
#pragma pack(1)
struct foo {
  int x;
};
#pragma pack(0)
ENDC
);

eval_test(q{

  $p->configure;                                                # (1) Useless use of configure in void context

  Convert::Binary::C::feature('foo');                           # (1) Useless use of feature in void context
  $p->feature('foo');                                           # (1) Useless use of feature in void context
  $x = Convert::Binary::C::feature();                           # (E) Usage: Convert::Binary::C::feature(feat)
  $x = Convert::Binary::C::feature(1, 2);                       # (E) Usage: Convert::Binary::C::feature(feat)
  $x = $p->feature();                                           # (E) Usage: Convert::Binary::C::feature(feat)
  $x = $p->feature(1, 2);                                       # (E) Usage: Convert::Binary::C::feature(feat)

  Convert::Binary::C::native('IntSize');                        # (1) Useless use of native in void context
  $p->native('IntSize');                                        # (1) Useless use of native in void context

  $x = Convert::Binary::C::native('foo', 'bar');                # (E) Usage: Convert::Binary::C::native(property)
  $x = $p->native('foo', 'bar');                                # (E) Usage: Convert::Binary::C::native(property)
  $x = $p->native('foobar');                                    # (E) Invalid property 'foobar'

  $p->member('xxx', 666);                                       # (E) Call to member without parse data
  $p->def('xxx');                                               # (1) Useless use of def in void context
  $p->pack('xxx', {foo=>123});                                  # (1) Useless use of pack in void context
  $p->unpack('xxx', 'yyy');                                     # (1) Useless use of unpack in void context
  $p->sizeof('xxx');                                            # (1) Useless use of sizeof in void context
  $p->typeof('xxx');                                            # (1) Useless use of typeof in void context
  $p->offsetof('xxx', 'yyy');                                   # (E) Call to offsetof without parse data
  $p->member('xxx', 123);                                       # (E) Call to member without parse data
  $p->enum_names;                                               # (E) Call to enum_names without parse data
  $p->enum;                                                     # (E) Call to enum without parse data
  $p->compound_names;                                           # (E) Call to compound_names without parse data
  $p->compound;                                                 # (E) Call to compound without parse data
  $p->struct_names;                                             # (E) Call to struct_names without parse data
  $p->struct;                                                   # (E) Call to struct without parse data
  $p->union_names;                                              # (E) Call to union_names without parse data
  $p->union;                                                    # (E) Call to union without parse data
  $p->typedef_names;                                            # (E) Call to typedef_names without parse data
  $p->typedef;                                                  # (E) Call to typedef without parse data
  $p->dependencies;                                             # (E) Call to dependencies without parse data
  $p->sourcify;                                                 # (E) Call to sourcify without parse data
  $p->macro_names;                                              # (E) Call to macro_names without parse data
  $p->macro;                                                    # (E) Call to macro without parse data
  $p->defined('foo');                                           # (E) Call to defined without parse data

  $p->parse_file('');                                           # (E) Cannot find input file ''
  $p->parse_file('foobar.c');                                   # (E) Cannot find input file 'foobar.c'

  $p->Include('tests/include/files', 'include/files');          # no errors/warnings
  $p->parse_file('empty.h')->clean;                             # no errors/warnings
  // $p->parse_file('nlnone.h')->clean;                            # (2) file is not newline-terminated
  $p->parse_file('nlunix.h')->clean;                            # no errors/warnings
  $p->parse_file('nldos.h')->clean;                             # no errors/warnings
  $p->parse_file('nlmac.h')->clean;                             # no errors/warnings
  // $p->parse_file('ifnonl.h')->clean;                            # (2) file is not newline-terminated
  $p->parse('')->clean;                                         # no errors/warnings
  $p->parse("typedef int foo;")->clean;                         # no errors/warnings
  $p->parse("typedef int foo;\n")->clean;                       # no errors/warnings
  $p->parse("typedef int foo;\r\n")->clean;                     # no errors/warnings
  $p->parse("typedef int foo;\r")->clean;                       # no errors/warnings

  $p->Define(qw( DEFINE=3 DEFINE=2 ));
  $p->parse('');                                                # (E) macro ... DEFINE ... redefined
  $p->Define(['=']);
  $p->parse('');                                                # (E) void macro name
  $p->Define(['=']);
  $p->Define(['FOO=']);
  $p->parse("#if\n#endif\n");                                   # (E) void condition for a #if/#elif
  $p->parse("#if 0\n#elif\n#endif\n");                          # (E) void condition for a #if/#elif
  $p->parse("#if FOO\n#endif\n");                               # (E) void condition (after expansion) for a #if/#elif
  $p->parse("#if 0\n#elif FOO\n#endif\n");                      # (E) void condition (after expansion) for a #if/#elif

  $p->Assert(qw{ PRED(answer) 1(foo) });
  $p->parse('');                                                # (E) illegal assertion name for #assert
  $p->Assert([qw{ PRED(answer) SYNTAX) }]);
  $p->parse('');                                                # (E) syntax error in #assert
  $p->Assert([qw{ PRED(answer) UNFINISHED( }]);
  $p->parse('');                                                # (E) unfinished #assert
  $p->Assert([]);

  $x = $p->pack('signed int', 1);                               # no warning
  $x = $p->unpack('signed int', $x);                            # no warning
  $x = $p->sizeof('long long');                                 # no warning
  $x = $p->typeof('long double');                               # no warning

  $p->parse($code{pragma_pack_1});                              # (E) line 5: invalid argument 3 to #pragma pack
  $p->parse($code{pragma_pack_2});                              # (E) line 1: invalid argument 5 to #pragma pack
  $p->parse($code{pragma_pack_3});                              # no warning

  $p->parse($code{macro});                                      # (E) macro ... FOO ... redefined
  $p->parse($code{assert});                                     # (2) (warning) ... trailing garbage in #assert
                                                                # (E) void assertion in #assert
  $p->parse($code{assert_syntax});                              # (E) syntax error for assertion in #if
  $p->parse($code{include});                                    # (E) file ... not_here.h ... not found
  $p->parse($code{endif});                                      # (2) (warning) ... trailing garbage in #ifdef
                                                                # (E) unmatched #endif
  $p->parse($code{else});                                       # (E) rogue #else
  $p->parse($code{elif});                                       # (E) rogue #elif
  $p->parse($code{unknown});                                    # (E) unknown cpp directive '#foobar'

  $p->parse($code);                                             # (2) (warning) ... trailing garbage in #assert
                                                                # (2) (warning) ... trailing garbage in #ifdef

  $p->def('xxx');                                               # (1) Useless use of def in void context
  $p->dependencies;                                             # (1) Useless use of dependencies in void context
  $p->sourcify;                                                 # (1) Useless use of sourcify in void context
  $p->clone;                                                    # (1) Useless use of clone in void context

  $p->configure(Include => 'Boo');                              # (E) Include wants a reference to an array of strings
  $p->Include({ Boo => 'Boo' });                                # (E) Include wants an array reference
  $p->Include('Boo', ['Boo']);                                  # (E) Argument 2 to Include must not be a reference
  $p->Include(['Boo'], ['Boo']);                                # (E) Invalid number of arguments to Include
  $p->ByteOrder(['Boo']);                                       # (E) ByteOrder must be a string value, not a reference
  $p->ByteOrder('Boo');                                         # (E) ByteOrder must be 'BigEndian' or 'LittleEndian', not 'Boo'
  $p->FloatSize([1]);                                           # (E) FloatSize must be an integer value, not a reference
  $p->FloatSize(13);                                            # (E) FloatSize must be 0, 1, 2, 4, 8, 12 or 16, not 13
  $p->FloatSize(1);                                             # no warning

  $p->StdCVersion([1]);                                         # (E) StdCVersion must be undef or an integer value, not a reference
  $p->StdCVersion(undef);                                       # no warnings

  $p->HostedC([1]);                                             # (E) HostedC must be undef or a boolean value, not a reference
  $p->HostedC(undef);                                           # no warnings

  $p->configure(DisabledKeywords => 42);                        # (E) DisabledKeywords wants a reference to an array of strings
  $p->configure(DisabledKeywords => { foo => 42 });             # (E) DisabledKeywords wants an array reference

  $p->configure(Bitfields => 42);                               # (E) Bitfields wants a hash reference
  $p->configure(Bitfields => []);                               # (E) Bitfields wants a hash reference
  $p->configure(Bitfields => { Engine => 'FooBar' });           # (E) Unknown bitfield layout engine 'FooBar'
  $p->configure(Bitfields => { Engine => 'Simple' });           # no warning
  $p->configure(Bitfields => { ByteOrder => 'BigEndian' });     # (E) Invalid option 'ByteOrder' for bitfield layout engine 'Simple'
  $p->configure(Bitfields => { NoSuchOption => 42 });           # (E) Invalid option 'NoSuchOption' for bitfield layout engine 'Simple'

  $x = $p->def('');                                             # no warning
  $x = $p->def('struct  ');                                     # no warning
  $x = $p->def('notthere');                                     # no warning

  $x = $p->sourcify;                                            # no warning
  $x = $p->sourcify('foo');                                     # (E) Sourcification of individual types is not yet supported
  $x = $p->sourcify({ foo => 1 }, 'foo');                       # (E) Sourcification of individual types is not yet supported
  $x = $p->sourcify([ 1 ], 'foo', 'bar');                       # (E) Sourcification of individual types is not yet supported
  $x = $p->sourcify([ 1 ]);                                     # (E) Need a hash reference for configuration options
  $x = $p->sourcify({ foo => 1 });                              # (E) Invalid option 'foo'
  $x = $p->sourcify({ Context => 1 });                          # no warning

  $p->pack('xxx', 'yyy');                                       # (1) Useless use of pack in void context
  $x = $p->pack('', 1);                                         # (E) Cannot find ''
  $x = $p->pack('na', 'yyy');                                   # (E) Cannot find 'na'
  $x = $p->pack('nodef', 'yyy');                                # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->pack('xxx', 'yyy');                                  # (E) Got no definition for 'union xxx'
  $p->pack('na', 'yyy', $data);                                 # (E) Cannot find 'na'
  $x = $p->pack('hasbf', {});                                   # no warning
  $x = $p->pack('t_unsafe', []);                                # (1) Unsafe values used in pack('t_unsafe')
  $x = $p->pack('s_unsafe', {});                                # (1) Unsafe values used in pack('s_unsafe')
  $x = $p->pack('nonnative', 0);                                # [ ieeefp] (1) Cannot pack 1 byte floating point values
                                                                # [!ieeefp] (1) Cannot pack non-native floating point values
  $p->pack('enum enu', 'A', ['xxxx']);                          # (E) Type of arg 3 to pack must be string
  $p->pack('enum enu', 'A', 'xxxx');                            # (E) Modification of a read-only value attempted
  $x = $p->pack('enum enu', 'A', 'xxxx');                       # no warning

  $x = $p->pack('test.foo', 23);                                # (1) 'test.foo' should be an array reference
  $x = $p->pack('test.foo', {});                                # (1) 'test.foo' should be an array reference
  $x = $p->pack('test.foo', sub { 1 });                         # (1) 'test.foo' should be an array reference
  $x = $p->pack('test.bar', []);                                # (1) 'test.bar' should be a scalar value
  $x = $p->pack('test.xxx', {});                                # (1) 'test.xxx' should be a scalar value

  $x = $p->pack('test', {foo => {}});                           # (1) 'test.foo' should be an array reference
  $x = $p->pack('test', {foo => [undef, {}] });                 # (1) 'test.foo[1]' should be an array reference
  $x = $p->pack('test', {foo => [undef, [1]] });                # (1) 'test.foo[1][0]' should be a hash reference
  $x = $p->pack('test', {foo => [undef, [{a => {}}]]});         # (1) 'test.foo[1][0].a' should be a scalar value
  $x = $p->pack('test', {foo => [undef, [{b => {}}]]});         # (1) 'test.foo[1][0].b' should be an array reference

  $x = []; $x->[1]{d}[2] = 1;
  $x = $p->pack('stuff', $x);                                   # (1) 'stuff[1].d[2]' should be an array reference
  $x = []; $x->[10]{u} = 1;
  $x = $p->pack('stuff', $x);                                   # (1) 'stuff[10].u' should be a hash reference
  $x = []; $x->[11]{u} = [1];
  $x = $p->pack('stuff', $x);                                   # (1) 'stuff[11].u' should be a hash reference
  $x = []; $x->[8]{u}{b} = {};
  $x = $p->pack('stuff', $x);                                   # (1) 'stuff[8].u.b' should be an array reference
  $x = []; $x->[7]{u}{b} = [undef, {}];
  $x = $p->pack('stuff', $x);                                   # (1) 'stuff[7].u.b[1]' should be a scalar value
  $x = []; $x->[6]{d}[5][4] = undef;
  $x = $p->pack('stuff', $x);                                   # no warning
  $x = []; $x->[6]{d}[5][4] = sub { 1 };
  $x = $p->pack('stuff', $x);                                   # (1) 'stuff[6].d[5][4]' should be a scalar value

  $x = $p->pack('unsigned char', 42);                           # no warning
  $x = $p->pack('double', 42);                                  # no warning
  $x = $p->pack('short double', 42);                            # (E) Unsupported basic type 'short double'
  $x = $p->pack('fp_unsupp', 42);                               # (1) Unsupported floating point type 'short float' in pack

  $x = $p->pack('hasbf.bf', {});                                # no warning

  $p->unpack('test', $data);                                    # (1) Useless use of unpack in void context
  $x = $p->unpack('', $data);                                   # (E) Cannot find ''
  $x = $p->unpack('na', $data);                                 # (E) Cannot find 'na'
  $x = $p->unpack('nodef', $data);                              # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->unpack('xxx', $data);                                # (E) Got no definition for 'union xxx'
  $x = $p->unpack('test', $data);                               # (1) Data too short
  @x = $p->unpack('test', $data);                               # no warning
  $x = $p->unpack('array', '');                                 # no warning
  $x = $p->unpack('hasbf', $data);                              # no warning
  $x = $p->unpack('t_unsafe', $data);                           # (1) Unsafe values used in unpack('t_unsafe')
                                                                # (1) Data too short
  $x = $p->unpack('s_unsafe', $data);                           # (1) Unsafe values used in unpack('s_unsafe')
                                                                # (1) Data too short
  $x = $p->unpack('nonnative', 'x');                            # [ ieeefp] (1) Cannot unpack 1 byte floating point values
                                                                # [!ieeefp] (1) Cannot unpack non-native floating point values
  $x = $p->unpack('multiple', 'x'x100);                         # (1) Member 'a' used more than once in struct multiple defined in [buffer](62)
                                                                # (1) Member 'b' used more than once in union defined in [buffer](66)

  $x = $p->unpack('unsigned char', 'x'x100);                    # no warning
  $x = $p->unpack('double', 'x'x100);                           # no warning
  $x = $p->unpack('signed float', 'x'x100);                     # (E) Unsupported basic type 'signed float'
  $x = $p->unpack('fp_unsupp', 'x'x100);                        # (1) Unsupported floating point type 'short float' in unpack

  $x = $p->unpack('hasbf.bf', 'x'x100);                         # no warning

  $p->initializer('test');                                      # (1) Useless use of initializer in void context
  $p->initializer('test', $data);                               # (1) Useless use of initializer in void context
  $x = $p->initializer('', $data);                              # (E) Cannot find ''
  $x = $p->initializer('na');                                   # (E) Cannot find 'na'
  $x = $p->initializer('na', $data);                            # (E) Cannot find 'na'
  $x = $p->initializer('nodef', $data);                         # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->initializer('xxx', $data);                           # (E) Got no definition for 'union xxx'

  $x = $p->initializer('test.foo', 23);                         # (1) 'test.foo' should be an array reference
  $x = $p->initializer('test.foo', {});                         # (1) 'test.foo' should be an array reference
  $x = $p->initializer('test.foo', sub { 1 });                  # (1) 'test.foo' should be an array reference
  $x = $p->initializer('test.bar', []);                         # (1) 'test.bar' should be a scalar value
  $x = $p->initializer('test.xxx', {});                         # (1) 'test.xxx' should be a scalar value

  $x = $p->initializer('test', {foo => {}});                    # (1) 'test.foo' should be an array reference
  $x = $p->initializer('test', {foo => [undef, {}] });          # (1) 'test.foo[1]' should be an array reference
  $x = $p->initializer('test', {foo => [undef, [1]] });         # (1) 'test.foo[1][0]' should be a hash reference
  $x = $p->initializer('test', {foo => [undef, [{a => {}}]]});  # (1) 'test.foo[1][0].a' should be a scalar value
  $x = $p->initializer('test', {foo => [undef, [{b => {}}]]});  # (1) 'test.foo[1][0].b' should be an array reference

  $x = []; $x->[1]{d}[2] = 1;
  $x = $p->initializer('stuff', $x);                            # (1) 'stuff[1].d[2]' should be an array reference
  $x = []; $x->[10]{c} = 1;
  $x = $p->initializer('stuff', $x);                            # (1) 'stuff[10].c' should be a hash reference
  $x = []; $x->[11]{c} = [1];
  $x = $p->initializer('stuff', $x);                            # (1) 'stuff[11].c' should be a hash reference
  $x = []; $x->[8]{c}{b} = {};
  $x = $p->initializer('stuff', $x);                            # (1) 'stuff[8].c.b' should be an array reference
  $x = []; $x->[7]{c}{b} = [undef, {}];
  $x = $p->initializer('stuff', $x);                            # (1) 'stuff[7].c.b[1]' should be a scalar value
  $x = []; $x->[6]{d}[5][4] = undef;
  $x = $p->initializer('stuff', $x);                            # no warning
  $x = []; $x->[6]{d}[5][4] = sub { 1 };
  $x = $p->initializer('stuff', $x);                            # (1) 'stuff[6].d[5][4]' should be a scalar value

  $p->sizeof('na');                                             # (1) Useless use of sizeof in void context
  $x = $p->sizeof('');                                          # (E) Cannot find ''
  $x = $p->sizeof('na');                                        # (E) Cannot find 'na'
  $x = $p->sizeof('long =');                                    # (E) Cannot find 'long ='
  $x = $p->sizeof('nodef');                                     # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->sizeof('xxx');                                       # (E) Got no definition for 'union xxx'
  $x = $p->sizeof('hasbf');                                     # no warning
  $x = $p->sizeof('hasbf.bf.c');                                # (E) Cannot use sizeof on bitfields
  $x = $p->sizeof('t_unsafe');                                  # (1) Unsafe values used in sizeof('t_unsafe')
  $x = $p->sizeof('s_unsafe');                                  # (1) Unsafe values used in sizeof('s_unsafe')
  $x = $p->sizeof('enum enu . foo');                            # (E) Cannot access member 'foo' of non-compound type
  $x = $p->sizeof('enumtype.foo');                              # (E) Cannot access member 'foo' of non-compound type
  $x = $p->sizeof('ptrtype.foo');                               # (E) Cannot access member 'foo' of pointer type
  $x = $p->sizeof('scalar.foo');                                # (E) Cannot access member 'foo' of non-compound type
  $x = $p->sizeof('enumtype [0]');                              # (E) Cannot use type as an array
  $x = $p->sizeof('test.666');                                  # (E) Struct members must start with a character or an underscore
  $x = $p->sizeof('test.foo.d');                                # (E) Cannot access member 'd' of array type
  $x = $p->sizeof('test.bar.d');                                # (E) Cannot access member 'd' of non-compound type
  $x = $p->sizeof('test.yyy.d');                                # (E) Cannot access member 'd' of pointer type
  $x = $p->sizeof('test.ptr.d');                                # (E) Cannot access member 'd' of pointer type
  $x = $p->sizeof('test.xxx[1]');                               # (E) Cannot use 'xxx' as an array
  $x = $p->sizeof('test.bar[1]');                               # (E) Cannot use 'bar' as an array
  $x = $p->sizeof('test.bar()');                                # (E) Invalid character '(' (0x28) in compound member expression
  $x = $p->sizeof('test.bar+');                                 # (E) Invalid character '+' (0x2B) in compound member expression
  $x = $p->sizeof('test.bar+a');                                # (E) Invalid character '+' (0x2B) in compound member expression
  $x = $p->sizeof('test.bar a');                                # (E) Invalid character 'a' (0x61) in compound member expression
  $x = $p->sizeof('test bar');                                  # (E) Invalid character 'b' (0x62) in compound member expression
  $x = $p->sizeof('test.bar+1');                                # no warning
  $x = $p->sizeof('test.foo[1][2');                             # (E) Incomplete compound member expression
  $x = $p->sizeof('test.foo[1][2].d');                          # (E) Cannot find struct member 'd'
  $x = $p->sizeof('test.foo[a]');                               # (E) Array indices must be constant decimal values
  $x = $p->sizeof('test.foo[0x1]');                             # (E) Index operator not terminated correctly
  $x = $p->sizeof('test.foo[2]');                               # no warning
  $x = $p->sizeof('test.foo[1][2][0]');                         # (E) Cannot use 'foo' as a 3-dimensional array
  $x = $p->sizeof('array[1][2]');                               # (E) Cannot use type as a 2-dimensional array

  $p->typeof('na');                                             # (1) Useless use of typeof in void context
  $x = $p->typeof('');                                          # (E) Cannot find ''
  $x = $p->typeof('na');                                        # (E) Cannot find 'na'
  $x = $p->typeof('nodef');                                     # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->typeof('xxx');                                       # (E) Got no definition for 'union xxx'
  $x = $p->typeof('enum enu . foo');                            # (E) Cannot access member 'foo' of non-compound type
  $x = $p->typeof('enumtype.foo');                              # (E) Cannot access member 'foo' of non-compound type
  $x = $p->typeof('ptrtype.foo');                               # (E) Cannot access member 'foo' of pointer type
  $x = $p->typeof('scalar.foo');                                # (E) Cannot access member 'foo' of non-compound type
  $x = $p->typeof('enumtype [0]');                              # (E) Cannot use type as an array
  $x = $p->typeof('test.666');                                  # (E) Struct members must start with a character or an underscore
  $x = $p->typeof('test.foo.d');                                # (E) Cannot access member 'd' of array type
  $x = $p->typeof('test.bar.d');                                # (E) Cannot access member 'd' of non-compound type
  $x = $p->typeof('test.yyy.d');                                # (E) Cannot access member 'd' of pointer type
  $x = $p->typeof('test.ptr.d');                                # (E) Cannot access member 'd' of pointer type
  $x = $p->typeof('test.xxx[1]');                               # (E) Cannot use 'xxx' as an array
  $x = $p->typeof('test.bar[1]');                               # (E) Cannot use 'bar' as an array
  $x = $p->typeof('test.bar()');                                # (E) Invalid character '(' (0x28) in compound member expression
  $x = $p->typeof('test.bar+');                                 # (E) Invalid character '+' (0x2B) in compound member expression
  $x = $p->typeof('test.bar+a');                                # (E) Invalid character '+' (0x2B) in compound member expression
  $x = $p->typeof('test.bar+1');                                # no warning
  $x = $p->typeof('test.foo[1][2');                             # (E) Incomplete compound member expression
  $x = $p->typeof('test.foo[1][2].d');                          # (E) Cannot find struct member 'd'
  $x = $p->typeof('test.foo[a]');                               # (E) Array indices must be constant decimal values
  $x = $p->typeof('test.foo[0x1]');                             # (E) Index operator not terminated correctly
  $x = $p->typeof('test.foo[2]');                               # no warning
  $x = $p->typeof('test.foo[1][2][0]');                         # (E) Cannot use 'foo' as a 3-dimensional array

  $p->offsetof('xxx', 666);                                     # (1) Useless use of offsetof in void context
  $x = $p->offsetof('', 666);                                   # (E) Cannot find ''
  $x = $p->offsetof('abc', 666);                                # (E) Cannot find 'abc'
  $x = $p->offsetof('nodef', 666);                              # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->offsetof('xxx', 666);                                # (E) Got no definition for 'union xxx'
  $x = $p->offsetof('ptrtype', '666');                          # (E) Invalid character '6' (0x36) in compound member expression
  $x = $p->offsetof('scalar', '666');                           # (E) Invalid character '6' (0x36) in compound member expression
  $x = $p->offsetof('enu', '666');                              # (E) Invalid character '6' (0x36) in compound member expression
  $x = $p->offsetof('ptrtype', 'a66');                          # (E) Cannot access member 'a66' of pointer type
  $x = $p->offsetof('scalar', 'a66');                           # (E) Cannot access member 'a66' of non-compound type
  $x = $p->offsetof('enu', 'a66');                              # (E) Cannot access member 'a66' of non-compound type
  $x = $p->offsetof('long int', 'a66');                         # (E) Cannot access member 'a66' of non-compound type
  $x = $p->offsetof('test', 'foo[0][0].666');                   # (E) Struct members must start with a character or an underscore
  $x = $p->offsetof('test', 'foo.d');                           # (E) Cannot access member 'd' of array type
  $x = $p->offsetof('test', 'bar.d');                           # (E) Cannot access member 'd' of non-compound type
  $x = $p->offsetof('test', 'yyy.d');                           # (E) Cannot access member 'd' of pointer type
  $x = $p->offsetof('test', 'ptr.d');                           # (E) Cannot access member 'd' of pointer type
  $x = $p->offsetof('test', 'xxx[1]');                          # (E) Cannot use 'xxx' as an array
  $x = $p->offsetof('test', 'bar[1]');                          # (E) Cannot use 'bar' as an array
  $x = $p->offsetof('test', 'bar()');                           # (E) Invalid character '(' (0x28) in compound member expression
  $x = $p->offsetof('test', 'foo[1][2');                        # (E) Incomplete compound member expression
  $x = $p->offsetof('test', 'foo[1][2].d');                     # (E) Cannot find struct member 'd'
  $x = $p->offsetof('test', 'foo[a]');                          # (E) Array indices must be constant decimal values
  $x = $p->offsetof('test', 'foo[0x1]');                        # (E) Index operator not terminated correctly
  $x = $p->offsetof('test', 'foo[+');                           # (E) Array indices must be constant decimal values
  $x = $p->offsetof('test', 'foo[+%');                          # (E) Array indices must be constant decimal values
  $x = $p->offsetof('test', 'foo[');                            # (E) Incomplete compound member expression
  $x = $p->offsetof('test', 'foo[%');                           # (E) Array indices must be constant decimal values
  $x = $p->offsetof('test', 'foo[  ');                          # (E) Incomplete compound member expression
  $x = $p->offsetof('test', 'foo[   %');                        # (E) Array indices must be constant decimal values
  $x = $p->offsetof('test', 'foo[2]');                          # no warning
  $x = $p->offsetof('test', 'foo[1][2][0]');                    # (E) Cannot use 'foo' as a 3-dimensional array
  $x = $p->offsetof('array', '[1][2]');                         # (E) Cannot use type as a 2-dimensional array
  $x = $p->offsetof('hasbf', 'nobf');                           # no warning
  $x = $p->offsetof('s_unsafe', 'foo');                         # (1) Unsafe values used in offsetof('s_unsafe')

  $x = $p->offsetof('test.bar', 'foo');                         # (E) Cannot access member 'foo' of non-compound type
  $x = $p->offsetof('test.arx[3][4]', 'uni[3].str.c');          # (E) Cannot find struct member 'arx'
  $x = $p->offsetof('test.ary[3][4]', 'uni[3].bar.c');          # (E) Cannot find union member 'bar'
  $x = $p->offsetof('test.ary[3][4]', 'uni[3].str.c');          # (E) Cannot find struct member 'c'
  $x = $p->offsetof('test.ary[2][4]', 'uni[3].str.c');          # (E) Cannot find struct member 'c'
  $x = $p->offsetof('test.ary[2][3]', 'uni[6].str.c');          # (E) Cannot find struct member 'c'
  $x = $p->offsetof('test.ary[2][3]', 'uni[1].str.c');          # (E) Cannot find struct member 'c'
  $x = $p->offsetof('test.ary[2][3].uni.a', 'xxx');             # (E) Cannot access member 'a' of array type
  $x = $p->offsetof('test.ary[2][3].uni', 'xxx');               # (E) Cannot access member 'xxx' of array type
  $x = $p->offsetof('test.ary[2][3]', 'uni.xxx');               # (E) Cannot access member 'xxx' of array type
  $x = $p->offsetof('test.ary[2][3].uni[0].a', 'xxx');          # (E) Cannot access member 'xxx' of non-compound type
  $x = $p->offsetof('test.ary[2][3].uni[0].str.a', 'b');        # (E) Cannot access member 'b' of pointer type

  $x = $p->offsetof('test.ary[2][2]', 'uni');                   # no warning
  $x = $p->offsetof('test.ary[2][2]', '');                      # (1) Empty string passed as member expression
  $x = $p->offsetof('test.ary[2][2]', "\t ");                   # (1) Empty string passed as member expression

  $x = $p->offsetof('hasbf', 'bf');                             # no warning
  $x = $p->offsetof('hasbf', 'bf.c');                           # (E) Cannot use offsetof on bitfields

  $p->member('xxx', 6666);                                      # (1) Useless use of member in void context
  $x = $p->member('', 6666);                                    # (E) Cannot find ''
  $x = $p->member('abc', 6666);                                 # (E) Cannot find 'abc'
  $x = $p->member('nodef', 6666);                               # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->member('xxx', 6666);                                 # (E) Got no definition for 'union xxx'
  $x = $p->member('ptrtype', 6666);                             # (E) Cannot use member on a pointer type
  $x = $p->member('scalar', 6666);                              # (E) Cannot use member on a basic type
  $x = $p->member('long long', 6666);                           # (E) Cannot use member on a basic type
  $x = $p->member('enu', 6666);                                 # (E) Cannot use member on an enum
  $x = $p->member('test', 6666);                                # (E) Offset 6666 out of range
  $x = $p->member('test', -10);                                 # (E) Offset -10 out of range
  $x = $p->member('hasbf', 1);                                  # no warning
  $x = $p->member('s_unsafe', 1);                               # (1) Unsafe values used in member('s_unsafe')

  $x = $p->member('test.bar', 6666);                            # (E) Cannot use member on a basic type
  $x = $p->member('test.arx[3][4]', 6666);                      # (E) Cannot find struct member 'arx'
  $x = $p->member('test.ary[3][4]', 6666);                      # (E) Offset 6666 out of range
  $x = $p->member('test.ary[2][4]', 6666);                      # (E) Offset 6666 out of range
  $x = $p->member('test.ary[2][3]', 6666);                      # (E) Offset 6666 out of range
  $x = $p->member('test.ary[2][3].uni.a', 6666);                # (E) Cannot access member 'a' of array type
  $x = $p->member('test.ary[2][3].uni', 0);                     # no error
  $x = $p->member('test.ary[2][3].uni[0].a', 6666);             # (E) Cannot use member on an enum
  $x = $p->member('test.ary[2][3].uni[0].str.a', 6666);         # (E) Cannot use member on a pointer type

  $p->member('xxx');                                            # (1) Useless use of member in void context
  $x = $p->member('');                                          # (E) Cannot find ''
  $x = $p->member('abc');                                       # (E) Cannot find 'abc'
  $x = $p->member('nodef');                                     # (E) Got no struct declarations in resolution of 'nodef'
  $x = $p->member('xxx');                                       # (E) Got no definition for 'union xxx'
  $x = $p->member('ptrtype');                                   # (E) Cannot use member on a pointer type
  $x = $p->member('scalar');                                    # (E) Cannot use member on a basic type
  $x = $p->member('long long');                                 # (E) Cannot use member on a basic type
  $x = $p->member('enu');                                       # (E) Cannot use member on an enum
  $x = $p->member('hasbf');                                     # no warning
  $x = $p->member('s_unsafe');                                  # (1) Unsafe values used in member('s_unsafe')

  $x = $p->member('test.bar');                                  # (E) Cannot use member on a basic type
  $x = $p->member('test.arx[3][4]');                            # (E) Cannot find struct member 'arx'
  $x = $p->member('test.ary[3][4]');                            # no warning
  $x = $p->member('test.ary[2][4]');                            # no warning
  $x = $p->member('test.ary[2][3].uni.a');                      # (E) Cannot access member 'a' of array type
  $x = $p->member('test.ary[2][3].uni');                        # no error
  $x = $p->member('test.ary[2][3].uni[0].a');                   # (E) Cannot use member on an enum
  $x = $p->member('test.ary[2][3].uni[0].str.a');               # (E) Cannot use member on a pointer type

  $p->enum_names;                                               # (1) Useless use of enum_names in void context
  $p->enum;                                                     # (1) Useless use of enum in void context
  $x = $p->enum('na');                                          # no warning
  $x = $p->enum('enum na');                                     # no warning
  @x = $p->enum('enu', '');                                     # no warning
  $x = $p->enum('enum enu');                                    # no warning

  $p->compound_names;                                           # (1) Useless use of compound_names in void context
  $p->compound;                                                 # (1) Useless use of compound in void context
  @x = $p->compound('na', '');                                  # no warning
  $x = $p->compound('union na');                                # no warning
  $x = $p->compound('struct na');                               # no warning
  $x = $p->compound('__hasbf');                                 # no warning
  $x = $p->compound('test');                                    # no warning
  $x = $p->compound('struct __hasbf');                          # no warning
  $x = $p->compound('union test');                              # no warning
  $x = $p->compound('union __hasbf');                           # no warning
  $x = $p->compound('struct test');                             # no warning

  $p->struct_names;                                             # (1) Useless use of struct_names in void context
  $p->struct;                                                   # (1) Useless use of struct in void context
  $x = $p->struct('na');                                        # no warning
  $x = $p->struct('union na');                                  # no warning
  $x = $p->struct('struct na');                                 # no warning
  $x = $p->struct('__hasbf');                                   # no warning
  $x = $p->struct('struct test');                               # no warning

  $p->union_names;                                              # (1) Useless use of union_names in void context
  $p->union;                                                    # (1) Useless use of union in void context
  $x = $p->union('na');                                         # no warning
  $x = $p->union('union na');                                   # no warning
  $x = $p->union('struct na');                                  # no warning
  $x = $p->union('test');                                       # no warning
  $x = $p->union('union __hasbf');                              # no warning

  $p->typedef_names;                                            # (1) Useless use of typedef_names in void context
  $p->typedef;                                                  # (1) Useless use of typedef in void context
  @x = $p->typedef('na', '');                                   # no warning

  $p->macro_names;                                              # (1) Useless use of macro_names in void context
  $p->macro;                                                    # (1) Useless use of macro in void context
  $x = $p->macro('foo');                                        # no warning
  @x = $p->macro('foo', 'bar');                                 # no warning

  $x = $p->pack('e_unsafe', 'SAFE');                            # no warning
  $x = $p->pack('e_unsafe', 'GOOD');                            # no warning
  $x = $p->pack('e_unsafe', 'UNSAFE');                          # (1) Enumerator value 'UNSAFE' is unsafe
  $x = $p->pack('e_unsafe', 'BAD');                             # (1) Enumerator value 'BAD' is unsafe

  $p->EnumType('Integer');
  $x = $p->unpack('e_unsafe', $data);                           # no warning
  $p->EnumType('String');
  $x = $p->unpack('e_unsafe', $data);                           # (1) Enumeration 'e_unsafe' contains unsafe values
  $p->EnumType('Both');
  $x = $p->unpack('e_unsafe', $data);                           # (1) Enumeration 'e_unsafe' contains unsafe values

  $p->EnumType('Integer');
  $x = $p->unpack('e_unsafe_noname', $data);                    # no warning
  $p->EnumType('String');
  $x = $p->unpack('e_unsafe_noname', $data);                    # (1) Enumeration contains unsafe values
  $p->EnumType('Both');
  $x = $p->unpack('e_unsafe_noname', $data);                    # (1) Enumeration contains unsafe values

  $p->arg('test');                                              # (1) Useless use of arg in void context
  $x = $p->arg('test');                                         # (E) Unknown argument type 'test' in arg

  $p->tag('stuff[0]', Format => 'String');                      # (E) Cannot tag array members
  $p->tag('stuff[0].d[1]', Format => 'String');                 # (E) Cannot tag array members
  $p->tag('stuff[0].d[1][2]', Format => 'String');              # (E) Cannot tag array members
  $p->untag('stuff[0].d[1][2]', 'Format');                      # (E) Cannot tag array members
  $p->tag('stuff[0].d', Format => 'String');                    # no error
  $p->tag('stuff[0].a', Format => 'String');                    # no error
  $p->tag('stuff', Format => 'String');                         # no error

  $p->tag('noway');                                             # (1) Useless use of tag in void context
  $x = $p->tag('noway');                                        # (E) Cannot find 'noway'
  $p->tag('test.bar', { foo => 1 });                            # (1) Useless use of tag in void context
  $x = $p->tag('test.bar', { foo => 1 });                       # (E) Tag name must be a string, not a reference
  $p->tag('test.bar', 'foo');                                   # (1) Useless use of tag in void context
  $x = $p->tag('test.bar', 'foo');                              # (E) Invalid tag name 'foo'
  $p->tag('test.bar', 'Format');                                # (1) Useless use of tag in void context
  $x = $p->tag('test.bar', 'Format');                           # no error
  $p->tag('test.bar', Format => 'foo');                         # (E) Invalid value 'foo' for Format tag
  $p->tag('test.bar', Format => 'String', 'foo');               # (E) Invalid number of arguments to tag
  $p->tag('test.bar', Format => 'String', foo => 1);            # (E) Invalid tag name 'foo'
  $p->tag('test.bar', Format => { foo => 1 });                  # (E) Value for Format tag must not be a reference

  $p->tag('test.bar', Hooks => 'foo');                          # (E) Need a hash reference to define hooks for 'test.bar'
  $p->tag('int', Hooks => 'foo');                               # (E) Need a hash reference to define hooks for 'int'
  $p->tag('test', Hooks => 'foo');                              # (E) Need a hash reference to define hooks for 'test'
  $p->tag('test', Hooks => {pack => 42});                       # (E) pack hook defined for 'test' is not a code or array reference
  $p->tag('test', Hooks => {pack => {foo => 42}});              # (E) pack hook defined for 'test' is not a code or array reference
  $p->tag('test', Hooks => {pack => [42]});                     # (E) pack hook defined for 'test' is not a code reference
  $p->tag('test', Hooks => {unpack => []});                     # (E) Need at least a code reference in unpack hook for type 'test'
  $p->tag('test', Hooks => {this_is_no_hook => \&id});          # (E) Invalid hook type 'this_is_no_hook'
  $p->tag('test', Hooks => {pack => sub {$_[0]}});              # no error
  $p->tag('test', Hooks => {unpack => [sub {$_[0]}]});          # no error
  $p->tag('test', Hooks => {pack => \&id, unpack => \&id});     # no error

  $p->tag('noway', Hooks => undef);                             # (E) Cannot find 'noway'
  $p->tag('test.bar', Hooks => undef);                          # no error
  $p->tag('int', Hooks => undef);                               # no error
  $p->tag('enumtype', Hooks => undef);                          # no error
  $p->tag('test', Hooks => undef);                              # no error

  $p->tag('test.foo', Dimension => 42);                         # no error
  $p->tag('test.foo', Dimension => '42');                       # no error
  $p->tag('test.foo', Dimension => '*');                        # no error
  $p->tag('test.foo', Dimension => sub { 42 });                 # no error
  $p->tag('test.foo', Dimension => [sub { 42 }]);               # no error
  $p->tag('test.foo', Dimension => 'ival');                     # no error

  $p->tag('array', Dimension => 'bar');                         # (E) Cannot use member expression 'bar' as Dimension tag for 'array' when not within a compound type
  $p->tag('array', Dimension => sub{42});                       # no error
  $p->tag('array', Dimension => [sub{42}]);                     # no error
  $p->tag('array', Dimension => [sub{42}, $p->arg('SELF')]);    # no error
  $p->tag('array', Dimension => [sub{42}, $p->arg('TYPE')]);    # (E) TYPE argument not allowed
  $p->tag('array', Dimension => [sub{42}, $p->arg('DATA')]);    # (E) DATA argument not allowed
  $p->tag('array', Dimension => [sub{42}, $p->arg('HOOK')]);    # no error
  $p->tag('test.foo', Dimension => 'ptr');                      # (E) Cannot use a pointer type in member 'ptr' to determine a dimension for 'test.foo'
  $p->tag('test.foo', Dimension => 'nonono');                   # (E) Cannot find struct member 'nonono'
  $p->tag('test.foo', Dimension => 'bar');                      # (E) Cannot use member 'bar' located behind 'test.foo' in layout to determine a dimension
  $p->tag('enumtype', Dimension => 'bar');                      # (E) Cannot use Dimension tag on an enum 'enumtype'
  $p->tag('enumtype', Dimension => undef);                      # (E) Cannot use Dimension tag on an enum 'enumtype'
  $p->untag('enumtype', 'Dimension');                           # (E) Cannot use Dimension tag on an enum 'enumtype'
  $p->tag('test.foo', Dimension => {});                         # (E) Invalid Dimension tag for 'test.foo'
  $p->tag('test.foo', Dimension => -1);                         # (E) Cannot use negative value -1 in Dimension tag for 'test.foo'
  $p->tag('test.foo', Dimension => '-2');                       # (E) Cannot use negative value -2 in Dimension tag for 'test.foo'
  $p->tag('test.foo', Dimension => 0);                          # no error
  $p->tag('test.foo', Dimension => '0');                        # no error
  $p->tag('test.foo', Dimension => '');                         # (E) Invalid Dimension tag for 'test.foo'
  $p->tag('test.foo', Dimension => sub{42});                    # no error
  $p->tag('test.foo', Dimension => [sub{42}]);                  # no error
  $p->tag('test.foo', Dimension => [sub{42}, $p->arg('SELF')]); # no error
  $p->tag('test.foo', Dimension => [sub{42}, $p->arg('TYPE')]); # (E) TYPE argument not allowed
  $p->tag('test.foo', Dimension => [sub{42}, $p->arg('DATA')]); # no error
  $p->tag('test.foo', Dimension => [sub{42}, $p->arg('HOOK')]); # no error

  $p->tag('test.ary', Dimension => 'foo[4][1].a');              # (E) Cannot use index 4 into array of size 2
  $p->tag('test.ary', Dimension => 'foo[1][3].a');              # (E) Cannot use index 3 into array of size 3
  $p->tag('test.ary', Dimension => 'foo[1][-2].a');             # (E) Cannot use negative index -2 into array
  $p->tag('test.ary', Dimension => 'foo[1][1].a+8');            # (E) Cannot use offset in compound member expression
  $p->tag('test.ary', Dimension => 'foo[1][1].a');              # no error
  $x = $p->unpack('test.ary', 'x'x$p->sizeof('test.ary'));      # (1) Missing parent to look up 'foo[1][1].a'

  $p->tag('test.foo', Dimension => undef);                      # no error

  $p->tag('dimtag_fail.array', Dimension => 'u.a.len[0]');      # no error (offset 1 + size 1 <= offset 3)
  $p->tag('dimtag_fail.array', Dimension => 'u.a.len[1]');      # no error (offset 2 + size 1 <= offset 3)
  $p->tag('dimtag_fail.array', Dimension => 'u.a.len[2]');      # (E) Cannot use member 'u.a.len[2]' located at same offset as 'dimtag_fail.array' in layout to determine a dimension
  $p->tag('dimtag_fail.array', Dimension => 'u.a.len[3]');      # (E) Cannot use member 'u.a.len[3]' located behind 'dimtag_fail.array' in layout to determine a dimension
  $p->tag('dimtag_fail.array', Dimension => 'u.b.len[0]');      # (E) Cannot use member 'u.b.len[0]' overlapping with 'dimtag_fail.array' in layout to determine a dimension
  $p->tag('dimtag_fail.array', Dimension => 'u.b.len[1]');      # (E) Cannot use member 'u.b.len[1]' located behind 'dimtag_fail.array' in layout to determine a dimension

  $p->tag('dimtag_fail.array', Dimension => undef);             # no error

  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # no error

  $p->tag('test.foo', Format => 'Binary');                      # no error, just to fool Dimension tag...
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Expected an array reference to look up index '1' in 'foo[1][1].a', not a string value
  $p->tag('test.foo', Format => undef);                         # no error
  $p->tag('test.foo', Hooks => {unpack=>sub{[]}});              # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot lookup index '1' in array of size '0' (in 'foo[1][1].a')
  $p->tag('test.foo', Hooks => undef);                          # no error

  $p->tag('inner_struct', Format => 'Binary');                  # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Expected a hash reference to look up member 'a' in 'foo[1][1].a', not a string value
  $p->tag('inner_struct', Format => undef);                     # no error
  $p->tag('inner_struct', Hooks => {unpack=>sub{{foo=>1}}});    # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot find member 'a' in hash (in 'foo[1][1].a')
  $p->tag('inner_struct', Hooks => undef);                      # no error

  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # no error (just to be safe)
  $p->tag('inner_struct.a', Hooks => {unpack=>sub{{}}});        # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot use a hash reference in 'foo[1][1].a' as dimension
  $p->tag('inner_struct.a', Hooks => {unpack=>sub{[]}});        # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot use an array reference in 'foo[1][1].a' as dimension
  $p->tag('inner_struct.a', Hooks => {unpack=>sub{sub{}}});     # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot use a code reference in 'foo[1][1].a' as dimension
  $p->tag('inner_struct.a', Hooks => {unpack=>sub{undef}});     # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot use an undefined value in 'foo[1][1].a' as dimension
  $p->tag('inner_struct.a', Hooks => {unpack=>sub{'foo'}});     # no error
  $x = $p->unpack('test', "\0"x$p->sizeof('test'));             # (1) Cannot use a string value ('foo') in 'foo[1][1].a' as dimension
  $p->tag('inner_struct.a', Hooks => undef);                    # no error

  $p->tag('test.ary', Dimension => sub {1});                    # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # no error
  $p->tag('test.ary', Dimension => sub {{}});                   # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # (1) Cannot use a hash reference as dimension
  $p->tag('test.ary', Dimension => sub {[]});                   # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # (1) Cannot use an array reference as dimension
  $p->tag('test.ary', Dimension => sub {sub{}});                # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # (1) Cannot use a code reference as dimension
  $p->tag('test.ary', Dimension => sub {undef});                # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # (1) Cannot use an undefined value as dimension
  $p->tag('test.ary', Dimension => sub {'foo'});                # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # (1) Cannot use a string value ('foo') as dimension
  $p->tag('test.ary', Dimension => sub {die "BOO!!!"});         # no error
  $x = $p->unpack('test', 'x'x$p->sizeof('test'));              # (E) BOO!!!

  $p->tag('test.ary', Dimension => undef);                      # no error

  $p->IntSize(4);
  $p->tag('char', Format => 'Binary');                          # no error
  $p->tag('int', Format => 'Binary');                           # no error
  $p->tag('array', Format => 'Binary');                         # no error
  $p->tag('inner.u.x', Format => 'String');                     # no error
  $x = $p->pack('char', 'xx');                                  # (1) Source string "xx" is longer (2 bytes) than 'char' (1 byte) while packing 'Binary' format
  $x = $p->pack('char', 'abcdefghijklmno');                     # (1) /Source string "abcdefghijklmno" is longer \(15 bytes\) than 'char' \(1 byte\) while packing 'Binary' format/
  $x = $p->pack('char', 'abcdefghijklmnop');                    # (1) /Source string "abcdefghijkl\.\.\." is longer \(16 bytes\) than 'char' \(1 byte\) while packing 'Binary' format/
  $x = $p->pack('char', 'abcdefghijklmnopq');                   # (1) /Source string "abcdefghijkl\.\.\." is longer \(17 bytes\) than 'char' \(1 byte\) while packing 'Binary' format/
  $x = $p->pack('char', 'abcdefghijklmnopqr');                  # (1) /Source string "abcdefghijkl\.\.\." is longer \(18 bytes\) than 'char' \(1 byte\) while packing 'Binary' format/
  $x = $p->pack('int', 'x'x5);                                  # (1) Source string "xxxxx" is longer (5 bytes) than 'int' (4 bytes) while packing 'Binary' format
  $x = $p->pack('int', 'x'x43);                                 # (1) /Source string "xxxxxxxxxxxx\.\.\." is longer \(43 bytes\) than 'int' \(4 bytes\) while packing 'Binary' format/
  $x = $p->pack('int', { hash => 1 });                          # (1) /Source string "HASH.*?" is longer \(\d+ bytes\) than 'int' \(4 bytes\) while packing 'Binary' format \(Are you sure you want to pack a reference type\?\)/
  $x = $p->pack('int', [ 1, 2, 3 ]);                            # (1) /Source string "ARRAY.*?" is longer \(\d+ bytes\) than 'int' \(4 bytes\) while packing 'Binary' format \(Are you sure you want to pack a reference type\?\)/
  $x = $p->pack('int', 'x'x4);                                  # no warning
  $x = $p->pack('inner', { u => { x => 'x'x5  } });             # (1) Source string "xxxxx" is longer (5 bytes) than 'inner.u.x' (4 bytes) while packing 'String' format
  $x = $p->pack('inner', { u => { x => 'x'x42 } });             # (1) /Source string "xxxxxxxxxxxx\.\.\." is longer \(42 bytes\) than 'inner\.u\.x' \(4 bytes\) while packing 'String' format/
  $x = $p->pack('inner', { u => { x => { hash => 1 } } });      # (1) /Source string "HASH.*?" is longer \(\d+ bytes\) than 'inner\.u\.x' \(4 bytes\) while packing 'String' format \(Are you sure you want to pack a reference type\?\)/
  $x = $p->pack('inner', { u => { x => [ 1, 2, 3 ] } });        # (1) /Source string "ARRAY.*?" is longer \(\d+ bytes\) than 'inner\.u\.x' \(4 bytes\) while packing 'String' format \(Are you sure you want to pack a reference type\?\)/
  $x = $p->pack('inner', { u => { x => 'x'x4  } });             # no warning
  $x = $p->unpack('int', '');                                   # (1) Data too short
  $x = $p->unpack('array', '');                                 # no warning
  $p->tag('char', Format => undef);                             # no error
  $p->tag('int', Format => undef);                              # no error
  $p->tag('array', Format => undef);                            # no error
  $p->tag('inner.u.x', Format => undef);                        # no error

  $p->tag('hasbf.bf.c', Format => 'Binary');                    # (E) Cannot use 'Format' tag on bitfields
  $p->tag('hasbf.bf.c', ByteOrder => 'BigEndian');              # (E) Cannot use 'ByteOrder' tag on bitfields

}, [0 .. 2], [qw( Convert::Binary::C Convert::Binary::C::Cached )]);

sub id { $_[0] }
sub rv0 { return () }
sub rv2 { return ($_[0], 42) }

sub eval_test
{
  my($test, $levels, $classes) = @_;
  my(@warn, $p);

  $SIG{__WARN__} = sub { push @warn, shift };

  my @tests;

  for (split $/, $test) {
    my $active = 1;
    print "# $_\n";
    /^\s*$/ and next;
    /^\s*\/\// and next;
    my($c, $f, $l, $w) = /^(.*;)?(?:\s*#(?:\s*\[\s*([^\]]*?)\s*\])?(?:\s*\(([E\d])\))?\s*(.*?))?\s*$/;
    print "# [$c] [$f] [$l] [$w] => ";
    for my $feat (split /\s*,\s*/, $f) {
      my($neg, $name) = $feat =~ /(!?)\s*([-\w]+)/;
      my $have = Convert::Binary::C::feature($name);
      print "($name=$have) ";
      ($neg xor $have) or $active = 0;
    }
    printf "%sactive\n", $active ? '' : 'in';
    if (defined $c) {
      push @tests, { code => $c, warnings => [] };
    }
    if ($active and @tests and defined $l) {
      if ($w =~ m[ ^ / (.*) / $ ]x) {
        $w = $1;
      }
      else {
        $w = quotemeta $w;
        $w =~ s/(?:\\\s)+(?:\\\.){3}(?:\\\s)+/.*/g;
      }
      if ($l eq 'E') {
        $tests[-1]{error} = qr/$w/;
      }
      else {
        push @{$tests[-1]{warnings}}, { level => $l, regex => qr/$w.*?\s+at\s+\(eval\s+\d+\)/ };
      }
    }
  }

  for $class (@$classes) {
    for $level (@$levels) {
      print <<END;
#----
#----  CLASS: $class
#----
#----  RUNNING IN WARNING LEVEL $level
#----
END

      $^W = $level ? 1 : 0;
      eval { $p = $class->new( Alignment => 1, Warnings => $level == 2 ) };
      ok($@, '', "failed to create $class object");

      for my $t (@tests) {
        my @warnings = map { $_->{level} <= $level ? $_->{regex} : () } @{$t->{warnings}};
        @warn = ();
        print "# evaluating code: $t->{code}\n";
        eval $t->{code};
        if ($@) {
          my $err = $@;
          $err =~ s/^/#     /gms;
          $err =~ s/[\r\n]+$//gms;
          print "#   error:\n$err\n";
        }
        if (exists $t->{error}) {
          ok($@, $t->{error}, "wrong error");
        }
        else {
          ok($@, '', "failed to evaluate code");
        }
        chomp @warn;
        if (@warn) {
          printf "#   got %d warning(s):\n", scalar @warn;
          for (@warn) {
            s/^/#     /gms;
            s/[\r\n]+$//gms;
            print "$_\n";
          }
        }
        else {
          print "#   got no warnings\n";
        }
        ok(scalar @warn, scalar @warnings, "got more/less warnings than expected");
        if (@warn != @warnings) {
          for (0 .. ($#warnings > $#warn ? $#warnings : $#warn)) {
            print "# (", $_+1, ") '", $warn[$_] || 'undef',
                  "' =~ /", $warnings[$_] || 'undef', "/\n";
          }
        }
        ok($warn[$_], $warnings[$_]) for 0 .. $#warnings;
      }
    }
  }

  $SIG{__WARN__} = 'DEFAULT';
}

__DATA__

#assert THIS(is) garbage
#assert TEST(assertion)

#if #TEST (assertion)
  typedef struct __nodef nodef;
#endif

#if #TEST (nothing)
#  error "boo!"
#endif

#ifdef FOO BLABLA
#endif

typedef union __hasbf hasbf;

typedef struct ptrstruct *ptrtype;

typedef int scalar;

typedef float nonnative;

typedef enum enu enumtype;

enum enu { A };

struct test {
  int        ival;
  enum yyy  *xxx;
  union xxx *yyy;
  ptrtype   *ptr;
  int      (*test[2])[3];
  struct inner_struct {
    int a;
    int b[2];
    int c[2][3];
  }          foo[2][3];
  struct {
    int a;
    union {
      enum enu a;
      struct {
        long *a;
        char b[10];
      }      str;
    }        uni[5];
  }          ary[3][4];
  int        bar;
};

union __hasbf {
  struct {
    int a:1;
    int b:2;
    int c:3;
    int :10;
  } bf;
  unsigned short nobf;
};

struct multiple {
  long       a;
  char       b;
  short      a;
  union {
    int      c;
    unsigned b;
  };
};

enum e_unsafe {
  SAFE = 42,
  GOOD,
  UNSAFE = &2,   /* pointer op makes it unsafe */
  BAD
};

typedef int t_unsafe[(char)600];  /* cast makes it unsafe */

struct s_unsafe {
  int foo[BAD];  /* uuuhhh!! */
};

typedef struct {
  enum {
    SAFE2 = 42,
    GOOD2,
    UNSAFE2 = *2,   /* pointer op makes it unsafe */
    BAD2
  } noname;
} e_unsafe_noname;

typedef short float fp_unsupp;

typedef struct {
  int b;
  struct {
    int x;
    char b[sizeof(int)];
  }   c;
  union {
    int x;
    char b[sizeof(int)];
  }   u;
} inner;

typedef struct {
  int a;
  inner;
  int d[6][6];
} stuff[12];

typedef int array[];

struct dimtag_fail {
  union {
    struct {
      char a;
      char len[];   /* starts at offset 1 */
    } a;
    struct {
      short a;
      short len[];  /* starts at offset 2 */
    } b;
  } u;
  char foo;
  int array[2];     /* starts at offset 3 */
};
