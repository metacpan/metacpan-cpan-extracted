################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 32;
use Convert::Binary::C @ARGV;

my $c = Convert::Binary::C->new(
  ByteOrder => 'LittleEndian',
  IntSize   => 4,
  EnumSize  => 4
);

eval {
  $c->parse(<<ENDC);

typedef char string[12];
typedef unsigned int array[];

enum weekday {
  MONDAY, TUESDAY, WEDNESDAY, THURSDAY
};

struct xxx {
  int x, y, z;
};

struct bits {
  int a;
  int y : 15;
  int z : 17;
  int b;
};

struct test {
  enum weekday day;
  int version;
  string type;
  struct {
    int a;
    int b;
    int c;
  } binary;
  struct {
    int x;
    int y[];
  } flex;
  struct xxx yyy;
  struct bits bit;
};

ENDC
};
is($@, '', 'parse C code');

my $c_le = $c->clone->ByteOrder('LittleEndian');
my $c_be = $c->clone->ByteOrder('BigEndian');
my $data = $c->pack('test', $c->unpack('test', pack("C*", 1 .. $c->sizeof('test'))));
my($t,$l,$b);

# -----------------

$c->tag('bits', ByteOrder => 'BigEndian');
$c->tag('weekday', ByteOrder => 'BigEndian');
$c->tag('array', ByteOrder => 'BigEndian');

$t = $c->unpack('test', $data);
$l = $c_le->unpack('test', $data);
$b = $c_be->unpack('test', $data);

is($t->{bits}{a}, $b->{bits}{a}, 'bits.a');
is($t->{bits}{x}, $l->{bits}{x}, 'bits.a');
is($t->{bits}{y}, $l->{bits}{y}, 'bits.a');
is($t->{bits}{b}, $b->{bits}{b}, 'bits.a');
is($t->{day}, $b->{day}, 'enum weekday');

is($c->pack('test', $t), $data, 'pack test');

$t = $c->unpack('array', $data);
$b = $c_be->unpack('array', $data);

is_deeply($t, $b, 'array');

# -----------------

for (qw( bits weekday array )) {
  $c->untag($_, 'ByteOrder');
}

$t = $c->unpack('test', $data);
$l = $c_le->unpack('test', $data);

is($t->{bits}{a}, $l->{bits}{a}, 'bits.a');
is($t->{bits}{x}, $l->{bits}{x}, 'bits.a');
is($t->{bits}{y}, $l->{bits}{y}, 'bits.a');
is($t->{bits}{b}, $l->{bits}{b}, 'bits.a');
is($t->{day}, $l->{day}, 'enum weekday');

is($c->pack('test', $t), $data, 'pack test');

# -----------------

$t = $c->unpack('array', $data);
$l = $c_le->unpack('array', $data);

is_deeply($t, $l, 'array');

is($c->pack('array', $t), $data, 'pack array');

# -----------------

$c->tag('test', ByteOrder => 'BigEndian');
$t = $c->unpack('test', $data);
$b = $c_be->unpack('test', $data);

delete $t->{bit};
delete $b->{bit};

is_deeply($t, $b, 'test');

# -----------------

$c->tag('test.bit', ByteOrder => 'LittleEndian');

$t = $c->unpack('test', $data);
$b = $c_be->unpack('test', $data);
$l = $c_le->unpack('test', $data);

$b->{bit} = $l->{bit};

is_deeply($t, $b, 'test');

is($c->pack('test', $t), $data, 'pack test');

# -----------------

$c->tag('test.bit.a', ByteOrder => 'BigEndian');

$t = $c->unpack('test', $data);
$b = $c_be->unpack('test', $data);
$l = $c_le->unpack('test', $data);

$l->{bit}{a} = $b->{bit}{a};
$b->{bit} = $l->{bit};

is_deeply($t, $b, 'test');

is($c->pack('test', $t), $data, 'pack test');

# -----------------

# test precedence of 'struct bits' over 'test.bit'

$c->tag('bits', ByteOrder => 'BigEndian');

$t = $c->unpack('test', $data);
$b = $c_be->unpack('test', $data);
$l = $c_le->unpack('test', $data);

$b->{bit}{y} = $l->{bit}{y};
$b->{bit}{z} = $l->{bit}{z};

is_deeply($t, $b, 'test');

is($c->pack('test', $t), $data, 'pack test');

# -----------------

for (qw( test test.bit test.bit.a bits )) {
  $c->untag($_, 'ByteOrder');
}

$t = $c->unpack('test', $data);
$l = $c_le->unpack('test', $data);
is_deeply($t, $l, 'test');

is($c->pack('test', $t), $data, 'pack test');

# -----------------

# test that hooks work correctly

$b = $c_be->unpack('test', $data);
my $phc = 0;
my $uhc = 0;

sub unpack_xxx
{
  my $xxx = shift;
  is_deeply($xxx, $b->{yyy}, 'unpack_xxx');
  $uhc++;
  return $xxx;
}

sub pack_xxx
{
  my $xxx = shift;
  is_deeply($xxx, $b->{yyy}, 'pack_xxx');
  $phc++;
  return $xxx;
}

$c->tag('xxx', ByteOrder => 'BigEndian',
               Hooks     => { unpack => \&unpack_xxx, pack => \&pack_xxx });

$t = $c->unpack('test', $data);
$l = $c_le->unpack('test', $data);
$l->{yyy} = $b->{yyy};

is($uhc, 1, 'unpack hook calls');
is_deeply($t, $l, 'test');

is($c->pack('test', $t), $data, 'pack test');
is($phc, 1, 'pack hook calls');

# -----------------

# bitfields cannot be tagged

eval { $c->tag('bits.y', ByteOrder => 'BigEndian'); };

like($@, qr/Cannot use 'ByteOrder' tag on bitfields/, 'tagging bitfield');
