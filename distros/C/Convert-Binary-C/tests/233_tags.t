################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test;
use Convert::Binary::C @ARGV;

$^W = 1;

BEGIN { plan tests => 148 }

my $c = Convert::Binary::C->new;

eval {
  $c->parse(<<ENDC);

typedef char string[80];
typedef unsigned char u_8;

struct xxx {
  int x, y, z;
};

struct test {
  int version;
  string type;
  u_8 data[20];
  struct {
    int a;
    int b;
    int c;
  } binary;
  struct xxx yyy;
};

ENDC
};

ok($@, '', "Couldn't parse C code");

### first, some basic tag stuff including cloning

$rv = eval { $c->tag('string', 'Format') };
ok($@, '');
ok(not defined $rv);

eval { $c->tag('string', Format => 'String') };
ok($@, '');
$rv = eval { $c->tag('string', 'Format') };
ok($@, '');
ok($rv, 'String');
$rv = eval { $c->tag('string') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'String');

eval { $c->tag('test.data', Format => 'Binary') };
ok($@, '');
$rv = eval { $c->tag('test.data', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $c->tag('test.data') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

eval { $c->tag('xxx', Format => 'Binary') };
ok($@, '');
$rv = eval { $c->tag('xxx', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $c->tag('xxx') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

eval { $c->tag('test.binary', Format => 'Binary') };
ok($@, '');
$rv = eval { $c->tag('test.binary', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $c->tag('test.binary') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

my $d = $c->clone;

$rv = eval { $d->tag('test.binary', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $d->tag('test.binary') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

$rv = eval { $d->tag('string', 'Format') };
ok($@, '');
ok($rv, 'String');
$rv = eval { $d->tag('string') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'String');

$rv = eval { $d->tag('test.data', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $d->tag('test.data') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

$rv = eval { $d->tag('xxx', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $d->tag('xxx') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

eval { $d->tag('test.binary', Format => undef) };
ok($@, '');
$rv = eval { $d->tag('test.binary', 'Format') };
ok($@, '');
ok(not defined $rv);
$rv = eval { $d->tag('test.binary') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 0);

eval { $d->untag('string', 'Format') };
ok($@, '');
$rv = eval { $d->tag('string', 'Format') };
ok($@, '');
ok(not defined $rv);
$rv = eval { $d->tag('string') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 0);

eval { $d->untag('test.data', 'Format') };
ok($@, '');
$rv = eval { $d->tag('test.data', 'Format') };
ok($@, '');
ok(not defined $rv);
$rv = eval { $d->tag('test.data') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 0);

eval { $d->untag('xxx') };
ok($@, '');
$rv = eval { $d->tag('xxx', 'Format') };
ok($@, '');
ok(not defined $rv);
$rv = eval { $d->tag('xxx') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 0);

$rv = eval { $c->tag('test.binary', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $c->tag('test.binary') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

$rv = eval { $c->tag('string', 'Format') };
ok($@, '');
ok($rv, 'String');
$rv = eval { $c->tag('string') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'String');

$rv = eval { $c->tag('test.data', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $c->tag('test.data') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

$rv = eval { $c->tag('xxx', 'Format') };
ok($@, '');
ok($rv, 'Binary');
$rv = eval { $c->tag('xxx') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{Format}, 'Binary');

my $sub = sub { @_ };

eval { $c->tag('xxx', 'Hooks', { unpack => $sub, pack => [$sub, 42] }) };
ok($@, '');
$rv = eval { $c->tag('xxx', 'Hooks') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 2);
ok($rv->{unpack}, $sub);
ok(ref $rv->{pack}, 'ARRAY');
ok(@{$rv->{pack}}, 2);
ok($rv->{pack}[0], $sub);
ok($rv->{pack}[1], 42);

$rv = eval { $c->tag('xxx') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 2);
ok($rv->{Format}, 'Binary');
ok(ref $rv->{Hooks}, 'HASH');

eval { $c->tag('xxx', 'Hooks', { pack => undef }) };
ok($@, '');
$rv = eval { $c->tag('xxx', 'Hooks') };
ok($@, '');
ok(ref $rv, 'HASH');
ok(keys %$rv, 1);
ok($rv->{unpack}, $sub);

eval { $c->tag('xxx', 'Hooks', { unpack => undef }) };
ok($@, '');
$rv = eval { $c->tag('xxx', 'Hooks') };
ok($@, '');
ok(not defined $rv);

### test that tagging test.mc.x also tags c.x

$c->clean->parse(<<ENDC);

typedef int a;
typedef enum { FOO } b;
typedef struct { int x; } c;

struct test {
  a ma;
  b mb;
  c mc;
};

ENDC

# also tests tag chaining
eval {
  $c->tag('test.ma', Format => 'Binary')
    ->tag('test.mb', Format => 'Binary')
    ->tag('test.mc', Format => 'Binary');
};
ok($@, '');

for my $i (qw( a b c )) {
  $rv = eval { $c->tag($i, 'Format') };
  ok(not defined $rv);
}

eval {
  $c->tag('test.mc.x', Format => 'String');
  $c->tag('test.mc', Format => undef);
};
ok($@, '');

$rv = eval { $c->tag('test.mc', 'Format') };
ok(not defined $rv);

$rv = eval { $c->tag('test.mc.x', 'Format') };
ok($rv, 'String');

$rv = eval { $c->tag('c.x', 'Format') };
ok($rv, 'String');

### test multiple tags

$c->clean;

eval { $c->tag('int', Format => 'Binary', Hooks => { pack => sub { $_[0] } }, Format => 'String') };
ok($@, '');

$rv = eval { $c->tag('int') };
ok($@, '');
ok(join(',', sort keys %$rv), 'Format,Hooks');

$rv = eval { $c->untag('int') };
ok($@, '');

$rv = eval { $c->tag('int') };
ok($@, '');
ok(join(',', sort keys %$rv), '');

eval { $c->tag('int', Format => 'Binary', Hooks => { pack => sub { $_[0] } }, Format => 'String') };
ok($@, '');

$rv = eval { $c->tag('int') };
ok($@, '');
ok(join(',', sort keys %$rv), 'Format,Hooks');

$rv = eval { $c->untag('int', 'Format') };
ok($@, '');

$rv = eval { $c->tag('int') };
ok($@, '');
ok(join(',', sort keys %$rv), 'Hooks');

$rv = eval { $c->tag('int', Hooks => { pack => undef }) };
ok($@, '');

$rv = eval { $c->tag('int') };
ok($@, '');
ok(join(',', sort keys %$rv), '');
