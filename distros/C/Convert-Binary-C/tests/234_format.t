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

# TODO: different alignments

my $c = Convert::Binary::C->new(
  ByteOrder => 'LittleEndian',
  IntSize   => 4,
  CharSize  => 1,
  EnumSize  => 4
);

eval {
  $c->parse(<<ENDC);

typedef char string[10];
typedef char flexbin[];
typedef unsigned char u_8;

typedef unsigned int array[];
typedef unsigned int multi[][2][3];

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
  int version;
  string type;
  u_8 data[13];
  struct {
    int a;
    int b;
    int c;
  } binary;
  struct {
    int x;
    int y[];
  } flex;
  u_8 pad_it;
  struct xxx yyy;
};

ENDC
};

ok($@, '', "Couldn't parse C code");

for (qw( string test.flex )) {
  eval { $c->tag($_, Format => 'String') };
  ok($@, '');
}

for (qw( xxx flexbin )) {
  eval { $c->tag($_, Format => 'Binary') };
  ok($@, '');
}

ok($c->unpack('string', "Hello\0Worl"), "Hello");
ok($c->unpack('test.type', "Foo\0Bar!!!"), "Foo");

$data = "Hello World\0Flex Array";

ok($c->unpack('test.flex', $data), "Hell");
ok($c->unpack('flexbin', $data), $data);

eval {
  $c->tag('flexbin', Format => 'Binary');
  $c->tag('u_8', Format => 'String');
};
ok($@,'');
ok($c->pack('flexbin', undef), '');
ok($c->pack('u_8', undef), "\x00");
ok($c->pack('xxx', undef), "\x00"x12);

eval { $c->tag('u_8', Format => undef) };
ok($@,'');

eval { $c->tag('flexbin', Format => 'String') };
ok($@,'');
ok($c->unpack('flexbin', $data), "Hello World");
ok($c->pack('flexbin', undef), '');

eval { $c->tag('test.flex', Format => undef) };
ok($@,'');
eval { $c->tag('test.flex.y', Format => 'String') };
ok($@,'');

$data = "XXXXHello World\0Flex Array";
$rv = $c->unpack('test.flex', $data);
ok($rv->{x} != 0);
ok($rv->{y}, "Hello World");
eval { $c->tag('test.flex.y', Format => 'Binary') };
ok($@,'');
$rv = $c->unpack('test.flex', $data);
ok($rv->{x} != 0);
ok($rv->{y}, "Hello World\0Flex Arr");

$data = 'X' x $c->sizeof('test');
substr($data, $c->offsetof('test', 'type'), 8) = "String!\0";
substr($data, $c->offsetof('test', 'yyy'), 12) = "Hello,\0World";

$rv = $c->unpack('test', $data);

ok($rv->{type}, "String!");
ok($rv->{yyy}, "Hello,\0World");

eval { $c->tag('array', Format => 'String') };
ok($@, '');

$rv = $c->unpack('array', "Hello");
ok($rv, "Hell");

eval { $c->tag('array', Format => 'Binary') };
ok($@, '');

$rv = $c->unpack('array', "Hello\0W");
ok($rv, "Hell");

$c->Alignment(4);

eval { $c->tag('xxx', Format => 'String') };
ok($@, '');

$string = "The big brown fox jumps over the lazy dog.\0Just another Perl hacker,\n";
$data = pack("Vc10C13xVVVV", 123456789, 65 .. 74, 200 .. 212, 111111111, 222222222, 333333333, 444444444) . $string;

$rv = $c->unpack('test', $data);

ok($rv->{version}, 123456789);
ok($rv->{type}, join '', map chr, 65 .. 74);
ok(join(':', @{$rv->{data}}), join(':', 200 .. 212));
ok($rv->{binary}{a}, 111111111);
ok($rv->{binary}{b}, 222222222);
ok($rv->{binary}{c}, 333333333);
ok($rv->{flex}{x},   444444444);
ok($rv->{flex}{y},   "The big brown fox jumps over the lazy dog.\0Just another Perl hacker,");
ok($rv->{pad_it},    ord 'T');
ok($rv->{yyy},       'big brown fo');

eval { $c->tag('test.flex.y', Format => 'String') };
ok($@, '');

$old_rv = $rv = $c->unpack('test', $data);

ok($rv->{version}, 123456789);
ok($rv->{type}, join '', map chr, 65 .. 74);
ok(join(':', @{$rv->{data}}), join(':', 200 .. 212));
ok($rv->{binary}{a}, 111111111);
ok($rv->{binary}{b}, 222222222);
ok($rv->{binary}{c}, 333333333);
ok($rv->{flex}{x},   444444444);
ok($rv->{flex}{y},   'The big brown fox jumps over the lazy dog.');
ok($rv->{pad_it},    ord 'T');
ok($rv->{yyy},       'big brown fo');

eval { $c->tag('test.flex', Format => 'Binary') };
ok($@, '');

$rv = $c->unpack('test', $data);
ok($rv->{flex}, pack 'V', 444444444);

eval { $c->tag('test.flex', Format => undef) };
ok($@, '');

$rv = $c->pack('test', $old_rv);

$data =~ s/\x00[^\x00]+$/\x00\x00/;

ok($rv, $data);

eval {
  $c->tag('weekday', Format => 'Binary',
                     Hooks  => { pack   => sub { push @p, @_; pack   'V', $_[0] },
                                 unpack => sub { push @u, @_; $_[0] ? unpack 'V', $_[0] : undef } });
};
ok($@, '');

$rv = $c->pack('weekday', 2);
ok($rv, pack('V', 2));
ok(scalar @p, 1);
ok($p[0], 2);

$rv = $c->unpack('weekday', pack('V', 3));
ok($rv, 3);
ok(scalar @u, 1);
ok($u[0], pack('V', 3));

@p = (); @u = ();

{
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };

  $rv = $c->unpack('weekday', 'x');
  ok(scalar @w, 1);
  ok($w[0], qr/Data too short/);
  ok(not defined $rv);
  ok(scalar @u, 1);
  ok($u[0], '');

  @w = ();
  $rv = $c->unpack('array', 'x');
  ok(scalar @w, 0);
  ok($rv, '');
}

eval { $c->tag('multi', Format => 'Binary') };
ok($@, '');

for (0 .. 23) {
  $rv = $c->unpack('multi', 'x'x$_);
  ok($rv, '');
}

for (24 .. 47) {
  $rv = $c->unpack('multi', 'x'x$_);
  ok($rv, 'x'x24);
}

$rv = $c->unpack('multi', 'abcd'x12);
ok($rv, 'abcd'x12);

$rv = $c->pack('multi', '');
ok($rv, '');

for (1 .. 24) {
  $rv = $c->pack('multi', 'x'x$_);
  ok($rv, ('x'x$_).("\x00"x(24-$_)));
}

eval { $c->tag('multi', Format => 'String') };
ok($@, '');

$rv = $c->pack('multi', '');
ok($rv, "\x00"x24);

# -----------------

# bitfields cannot be tagged

eval { $c->tag('bits.y', Format => 'Binary'); };

ok($@, qr/Cannot use 'Format' tag on bitfields/);
