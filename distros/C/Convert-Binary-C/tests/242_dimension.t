################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 1535;
use Convert::Binary::C @ARGV;
use strict;

$^W = 1;

my $c = Convert::Binary::C->new(
  CharSize  => 1,
  ShortSize => 2,
  IntSize   => 4,
  Alignment => 1,
  ByteOrder => 'BigEndian'
);

$c->parse(<<'ENDC');

struct string {
  char len;
  char data[3];
};

struct flex_string {
  char len;
  char data[];
};

typedef unsigned array[7];
typedef unsigned flex_array[];

ENDC

my (@types, @tests, $is_pack, $data);

$data = pack "C*", 42, 0 .. 100;

@types = (
  { type => 'string', raw_unpacked => { len => 42, data => [0 .. 2] },
                      raw_packed   => pack('C*', 42, 0 .. 2) },
  { type => 'flex_string', raw_unpacked => { len => 42, data => [0 .. 100] },
                      raw_packed   => pack('C*', 42, 0 .. 100) },
);

@tests = (
  { member => '.data', tag => { Dimension =>  23 },
    unpacked => { len => 42, data => [0 .. 22] }, packed => pack('C*', 42, 0 .. 22) },
  { member => '.data', tag => { Dimension => '*' }, unpacked => { len => 42, data => [0 .. 100] }, packed => pack('C*', 42, 0 .. 100) },
  { member => '.data', tag => { Dimension => 'len' }, unpacked => { len => 42, data => [0 .. 41] }, packed => pack('C*', 42, 0 ..  41) },
  { member => '.data', tag => { Dimension => sub { is_deeply(\@_, [{len => 42, ($is_pack ? (data => [0 .. 76]) : ())}], 'params'); 77 } },
    unpacked => { len => 42, data => [0 .. 76] }, packed => pack('C*', 42, 0 .. 76) },
  { member => '.data', tag => { Dimension => [sub { is_deeply(\@_, [], 'params'); 78 }] },
    unpacked => { len => 42, data => [0 .. 77] }, packed => pack('C*', 42, 0 .. 77) },
  { member => '.data', tag => { Dimension => [sub { is_deeply(\@_, [1, 2, 3], 'params'); 79 }, 1, 2, 3] },
    unpacked => { len => 42, data => [0 .. 78] }, packed => pack('C*', 42, 0 .. 78) },
  { member => '.data', tag => { Dimension => [sub { is_deeply(\@_, [$c, 42, {len => 42, ($is_pack ? (data => [0 .. 79]) : ())}], 'params'); 80 },
                                              $c->arg('SELF'), 42, $c->arg('DATA')] },
    unpacked => { len => 42, data => [0 ..  79] }, packed => pack('C*', 42, 0 .. 79) },
  { member => '.data', tag => { Format => 'Binary', Dimension =>  23   },
    unpacked => { len => 42, data => pack('C*', 0 ..  22) }, packed => pack('C*', 42, 0 .. 22) },
  { member => '.data', tag => { Format => 'Binary', Dimension => '*'   },
    unpacked => { len => 42, data => pack('C*', 0 .. 100) }, packed => pack('C*', 42, 0 .. 100) },
  { member => '.data', tag => { Format => 'Binary', Dimension => 'len' },
    unpacked => { len => 42, data => pack('C*', 0 ..  41) }, packed => pack('C*', 42, 0 .. 41) },
  { member => '.data', tag => { Dimension => sub { is_deeply(\@_, [{len => 42, ($is_pack ? (data => [0 .. 51]) : ())}], 'params'); '52' } },
    unpacked => { len => 42, data => [0 .. 51] }, packed => pack('C*', 42, 0 .. 51) },
  { member => '.data', tag => { Dimension => sub { is_deeply(\@_, [{len => 42, ($is_pack ? (data => [0 .. 56]) : ())}], 'params');
                                                   my $a = '7'x13 . '57'; substr $a, 13; } },
    unpacked => { len => 42, data => [0 .. 56] }, packed => pack('C*', 42, 0 .. 56) },
  { member => '.data', tag => { Dimension => sub { is_deeply(\@_, [{len => 42, ($is_pack ? (data => [0 .. 52]) : ())}], 'params');
                                                   my $a = '7'x42 . '53' . '9'x11; substr $a, 42, 2; } },
    unpacked => { len => 42, data => [0 .. 52] }, packed => pack('C*', 42, 0 .. 52) },
);

run_tests(\@types, \@tests);

$data = pack "N*", 0 .. 100;

@types = (
  { type => 'array', raw_unpacked => [0 .. 6],
                     raw_packed   => pack('N*', 0 .. 6) },
  { type => 'flex_array', raw_unpacked => [0 .. 100],
                          raw_packed   => pack('N*', 0 .. 100) },
);

@tests = (
  { tag => { Dimension =>  21 }, unpacked => [0 .. 20], packed => pack('N*', 0 ..  20) },
  { tag => { Dimension => '*' }, unpacked => [0 .. 100], packed => pack('N*', 0 .. 100) },
  { tag => { Dimension => sub { is_deeply(\@_, [], 'params'); 77 } },
    unpacked => [0 .. 76], packed => pack('N*', 0 .. 76) },
  { tag => { Dimension => [sub { is_deeply(\@_, [], 'params'); 78 }] },
    unpacked => [0 .. 77], packed => pack('N*', 0 .. 77) },
  { tag => { Dimension => [sub { is_deeply(\@_, [1, 2, 3], 'params'); 79 }, 1, 2, 3] },
    unpacked => [0 .. 78], packed => pack('N*', 0 .. 78) },
  { tag => { Dimension => [sub { is_deeply(\@_, [$c, 42], 'params'); 80 }, $c->arg('SELF'), 42] },
    unpacked => [0 .. 79], packed => pack('N*', 0 .. 79) },
  { tag => { Format => 'Binary', Dimension => 23 },
    unpacked => pack('N*', 0 .. 22), packed => pack('N*', 0 .. 22) },
  { tag => { Format => 'Binary', Dimension => '*' },
    unpacked => pack('N*', 0 .. 100), packed => pack('N*', 0 .. 100) },
  { tag => { Dimension => sub { is_deeply(\@_, [], 'params'); '52' } },
    unpacked => [0 .. 51], packed => pack('N*', 0 .. 51) },
  { tag => { Dimension => sub { is_deeply(\@_, [], 'params'); my $a = '7'x13 . '57'; substr $a, 13; } },
    unpacked => [0 .. 56], packed => pack('N*', 0 .. 56) },
  { tag => { Dimension => sub { is_deeply(\@_, [], 'params'); my $a = '7'x42 . '53' . '9'x11; substr $a, 42, 2; } },
    unpacked => [0 .. 52], packed => pack('N*', 0 .. 52) },
);

run_tests(\@types, \@tests);

$c->clean->parse(<<'ENDC');

struct outer {
  struct inner {
    struct {
      char c;
    } a;
    char b[2];
  } i;
  char array[];
};

ENDC

{
  my($u, @warn);
  local $SIG{__WARN__} = sub { push @warn, @_ };

  # --- test normal case ---

  $c->tag('outer.array', Dimension => 'i.b[0]');
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is_deeply(\@warn, [], 'unpack outer warnings');
  is_deeply($u, { i => { a => { c => 13 }, b => [ 42, 7 ] }, array => [0 .. 41] }, 'unpack outer results');

  # --- test for missing parent ---

  @warn = ();

  $u = eval { $c->unpack('outer.array', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer.array');
  is(scalar @warn, 1, 'unpack outer.array warnings');
  like($warn[0], qr/^Missing parent to look up 'i\.b\[0\]'/, 'unpack outer.array warnings');
  is_deeply($u, [], 'unpack outer.array results');

  # --- test for unexpectedly wrong type ---

  @warn = ();

  $c->tag('outer.i.b', Format => 'Binary');
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is(scalar @warn, 1, 'unpack outer warnings');
  like($warn[0], qr/^Expected an array reference to look up index '0' in 'i\.b\[0\]'/, 'unpack outer warnings');
  is_deeply($u, { i => { a => { c => 13 }, b => pack("C*", 42, 7) }, array => [] }, 'unpack outer results');
  $c->untag('outer.i.b', 'Format');

  @warn = ();

  $c->tag('outer.array', Dimension => 'i.a.c');
  $c->tag('outer.i.a', Format => 'Binary');
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is(scalar @warn, 1, 'unpack outer warnings');
  like($warn[0], qr/^Expected a hash reference to look up member 'c' in 'i\.a\.c'/, 'unpack outer warnings');
  is_deeply($u, { i => { a => pack("C", 13), b => [ 42, 7 ] }, array => [] }, 'unpack outer results');
  $c->untag('outer.i.a', 'Format');

  # --- test for non-existent keys/indices ---

  @warn = ();

  $c->tag('outer.i.a', Hooks => { unpack => sub { return { d => 77 } } });
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is(scalar @warn, 1, 'unpack outer warnings');
  like($warn[0], qr/^Cannot find member 'c' in hash \(in 'i\.a\.c'\)/, 'unpack outer warnings');
  is_deeply($u, { i => { a => { d => 77 }, b => [ 42, 7 ] }, array => [] }, 'unpack outer results');
  $c->untag('outer.i.a', 'Hooks');

  @warn = ();

  $c->tag('outer.array', Dimension => 'i.b[1]');
  $c->tag('outer.i.b', Hooks => { unpack => sub { return [ 33 ] } });
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is(scalar @warn, 1, 'unpack outer warnings');
  like($warn[0], qr/^Cannot lookup index '1' in array of size '1' \(in 'i\.b\[1\]'\)/, 'unpack outer warnings');
  is_deeply($u, { i => { a => { c => 13 }, b => [ 33 ] }, array => [] }, 'unpack outer results');
  $c->untag('outer.i.a', 'Hooks');

  # --- check for invalid type ---

  @warn = ();

  $c->tag('outer.i.b', Hooks => { unpack => sub { return [ 33, 'foobar' ] } });
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is(scalar @warn, 1, 'unpack outer warnings');
  like($warn[0], qr/^Cannot use a string value \('foobar'\) in 'i\.b\[1\]' as dimension/, 'unpack outer warnings');
  is_deeply($u, { i => { a => { c => 13 }, b => [ 33, 'foobar' ] }, array => [] }, 'unpack outer results');

  @warn = ();

  $c->tag('outer.i.b', Hooks => { unpack => sub { return [ 33, undef ] } });
  $u = eval { $c->unpack('outer', pack('C*', 13, 42, 7, 0 .. 100)) };
  is($@, '', 'unpack outer');
  is(scalar @warn, 1, 'unpack outer warnings');
  like($warn[0], qr/^Cannot use an undefined value in 'i\.b\[1\]' as dimension/, 'unpack outer warnings');
  is_deeply($u, { i => { a => { c => 13 }, b => [ 33, undef ] }, array => [] }, 'unpack outer results');

  $c->untag('outer.i.b', 'Hooks');
}

sub run_tests
{
  my($types, $tests) = @_;

  for my $type (@$types) {
    for my $t (@$tests) {
      my($tag, $u, $p);
      my $member = $t->{member} || '';

      $tag = eval { $c->tag("$type->{type}$member", 'Dimension') };
      is($@, '', 'get dimension tag');
      is($tag, undef, 'compare dimension tag');

      $is_pack = 0;
      $u = eval { $c->unpack($type->{type}, $data) };
      is($@, '', 'unpack untagged');
      is_deeply($u, $type->{raw_unpacked}, 'unpack raw');

      $is_pack = 1;
      $p = eval { $c->pack($type->{type}, $u) };
      is($@, '', 'pack untagged');
      is($p, $type->{raw_packed}, 'pack raw');

      eval { $c->tag("$type->{type}$member", %{$t->{tag}}) };
      is($@, '', 'set tags');

      $tag = eval { $c->tag("$type->{type}$member", 'Dimension') };
      is($@, '', 'get dimension tag');
      is_deeply($tag, $t->{tag}{Dimension}, 'compare dimension tag');

      $tag = eval { $c->tag("$type->{type}$member") };
      is($@, '', 'get all tags');
      is_deeply($tag, $t->{tag}, 'compare tags');

      $is_pack = 0;
      $u = eval { $c->unpack($type->{type}, $data) };
      is($@, '', 'unpack tagged');
      is_deeply($u, $t->{unpacked}, 'unpack');

      $is_pack = 1;
      $p = eval { $c->pack($type->{type}, $u) };
      is($@, '', 'pack tagged');
      is($p, $t->{packed}, 'pack');

      $c = eval { $c->clone };
      is($@, '', 'clone tags');

      $tag = eval { $c->tag("$type->{type}$member", 'Dimension') };
      is($@, '', 'get dimension tag after clone');
      is_deeply($tag, $t->{tag}{Dimension}, 'compare dimension tag after clone');

      $tag = eval { $c->tag("$type->{type}$member") };
      is($@, '', 'get all tags after clone');
      is_deeply($tag, $t->{tag}, 'compare tags after clone');

      $is_pack = 0;
      $u = eval { $c->unpack($type->{type}, $data) };
      is($@, '', 'unpack tagged after clone');
      is_deeply($u, $t->{unpacked}, 'unpack after clone');

      $is_pack = 1;
      $p = eval { $c->pack($type->{type}, $u) };
      is($@, '', 'pack tagged after clone');
      is($p, $t->{packed}, 'pack after clone');

      eval { $c->tag("$type->{type}$member", map { ($_ => undef) } keys %{$t->{tag}}) };
      is($@, '', 'unset tags');

      $tag = eval { $c->tag("$type->{type}$member", 'Dimension') };
      is($@, '', 'get dimension tag');
      is($tag, undef, 'compare dimension tag');

      $is_pack = 0;
      $u = eval { $c->unpack($type->{type}, $data) };
      is($@, '', 'unpack untagged');
      is_deeply($u, $type->{raw_unpacked}, 'unpack raw');
    }
  }
}
