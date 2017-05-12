################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 49 }

my $c = new Convert::Binary::C;

$c->parse(<<ENDC);

enum foo { FOO };
enum bar { BAR = -1 };

struct abc { int x; };

#pragma pack(push, 1)
struct def { int x; };

union u1 { int x; };
#pragma pack(pop)

union u2 { int x; };

typedef unsigned short u_16;
typedef unsigned int u_32;

#pragma pack(2)
struct pack2 { int x; };

#pragma pack(0)
struct pack0 { int x; };

ENDC

($foo, $ndef, $bar) = $c->enum('  foo', 'no', "enum \t  bar");

ok(defined $foo);
ok($foo->{identifier}, 'foo');
ok($foo->{sign}, 0);
ok(join(',', keys %{$foo->{enumerators}}), 'FOO');
ok($foo->{enumerators}{FOO}, 0);

ok(defined $bar);
ok($bar->{identifier}, 'bar');
ok($bar->{sign}, 1);
ok(join(',', keys %{$bar->{enumerators}}), 'BAR');
ok($bar->{enumerators}{BAR}, -1);

ok(not defined $ndef);

($abc, $ndef, $def) = $c->struct('  abc', 'union u1', "struct \t  def");
ok(defined $abc);
ok($abc->{identifier}, 'abc');
ok($abc->{type}, 'struct');
ok($abc->{pack}, 0);

ok(defined $def);
ok($def->{identifier}, 'def');
ok($def->{type}, 'struct');
ok($def->{pack}, 1);

ok(not defined $ndef);

($u1, $ndef, $u2) = $c->union('  u1', 'struct def', "union \t  u2");
ok(defined $u1);
ok($u1->{identifier}, 'u1');
ok($u1->{type}, 'union');
ok($u1->{pack}, 1);

ok(defined $u2);
ok($u2->{identifier}, 'u2');
ok($u2->{type}, 'union');
ok($u2->{pack}, 0);

ok(not defined $ndef);

($abc, $ndef, $u1) = $c->compound('  abc', 'union no', "union \t  u1");
ok(defined $abc);
ok($abc->{identifier}, 'abc');
ok($abc->{type}, 'struct');
ok($abc->{pack}, 0);

ok(defined $u1);
ok($u1->{identifier}, 'u1');
ok($u1->{type}, 'union');
ok($u1->{pack}, 1);
ok(not defined $ndef);

($u_16, $ndef, $u_32) = $c->typedef('u_16', '  u_32', "u_32");
ok(defined $u_16);
ok($u_16->{declarator}, 'u_16');
ok($u_16->{type}, 'unsigned short');

ok(defined $u_32);
ok($u_32->{declarator}, 'u_32');
ok($u_32->{type}, 'unsigned int');

ok(not defined $ndef);

($pk0, $pk2) = $c->struct('pack0', 'pack2');
ok(defined $pk0);
ok(defined $pk2);
ok($pk0->{pack}, 0);
ok($pk2->{pack}, 2);
