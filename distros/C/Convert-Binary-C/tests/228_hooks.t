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

BEGIN { plan tests => 420 }

eval { require Scalar::Util };
my $reason = $@ ? 'cannot load Scalar::Util' : '';
unless ($reason) {
  eval { Scalar::Util::dualvar(42, 'answer') eq 'answer' or die };
  $reason = 'cannot use dualvar()' if $@;
}

my $c = Convert::Binary::C->new(
  ByteOrder   => 'BigEndian',
  EnumType    => 'String',
  EnumSize    => 4,
  IntSize     => 4,
  PointerSize => 4
);

$c->parse(<<'ENDC');

enum Enum {
  Zero, One, Two, Three, Four, Five, Six, Seven
};

typedef unsigned int u_32;

typedef u_32   TextId;
typedef TextId SetTextId;

struct String {
  u_32 len;
  char buf[];
};

struct Date {
  u_32 year;
  u_32 month;
  u_32 day;
};

struct Test {
  u_32      header;
  SetTextId id;
};

struct PtrHookTest {
  struct Test *pTest;
  struct Date *pDate;
  enum   Enum *pEnum;
  TextId      *pText;
};

ENDC

my %TEXTID  = (          4 => 'perl',
                1179602721 => 'rules' );
my %RTEXTID = reverse %TEXTID;

my $d = pack("N", 4) . "FOO!";

no_hooks();

$c->tag('Enum',   Hooks => { pack   => \&enum_pack,
                             unpack => \&enum_unpack });
$c->tag('TextId', Hooks => { pack   => \&textid_pack,
                             unpack => \&textid_unpack });

$c->tag('String', Hooks => { pack   => \&string_pack,
                             unpack => \&string_unpack });

with_hooks();
$c = $c->clone;
with_hooks();

$c->tag($_, Hooks => undef) for qw(Enum String);

{
  my $hook = $reason
           ? sub { $_[0] }  # identity
           : sub { Scalar::Util::dualvar($_[0], $TEXTID{$_[0]}) };

  $c->tag('TextId', Hooks => { unpack => $hook, pack => undef });
}

with_single_hook();
$c = $c->clone;
with_single_hook();

# This should completely remove the 'TextId' hooks
$c->tag('TextId', Hooks => { unpack => undef });

no_hooks();
$c = $c->clone;
no_hooks();

$c->tag('Enum',   Hooks => undef)
  ->tag('TextId', Hooks => undef)
  ->tag('String', Hooks => undef)
  ->tag('Enum',   Hooks => { pack   => \&enum_pack     })
  ->tag('TextId', Hooks => { pack   => \&textid_pack   })
  ->tag('String', Hooks => { pack   => \&string_pack   })
  ->tag('Enum',   Hooks => { unpack => \&enum_unpack   })
  ->tag('TextId', Hooks => { unpack => \&textid_unpack })
  ->tag('String', Hooks => { unpack => \&string_unpack });

with_hooks();

$c = $c->tag('String', Hooks => undef)
       ->tag('Enum', Hooks => undef)
       ->tag('TextId', Hooks => undef)
       ->clone;

no_hooks();

test_args();

test_ptr_hooks();

sub test_ptr_hooks {
  my $pack = sub { $_[0] =~ /{(0x[^}]+)}/ ? hex $1 : '' };

  $c->tag('Test',   Hooks => { unpack_ptr => sub { sprintf "Test{0x%X}", $_[0] },
                               pack_ptr   => [$pack, $c->arg('DATA')] });
  $c->tag('Date',   Hooks => { unpack_ptr => [sub { sprintf "$_[1]\{0x%X}", $_[0] }, $c->arg('DATA', 'TYPE')],
                               pack_ptr   => $pack });
  $c->tag('Enum',   Hooks => { unpack_ptr => [sub { sprintf "$_[0]\{0x%X}", $_[1] }, $c->arg('TYPE', 'DATA')],
                               pack_ptr   => [$pack, $c->arg('DATA', 'SELF'), 'foo'] });
  $c->tag('TextId', Hooks => { unpack_ptr => [sub { sprintf "Text\{0x%X}", $_[0] }, $c->arg('DATA')],
                               pack_ptr   => $pack });

  my $str = pack('N*', 0xdeadbeef, 0x2badc0de, 0x12345678, 0xdeadc0de);

  my $u = $c->unpack('PtrHookTest', $str);

  ok($u->{pTest}, "Test{0xDEADBEEF}");
  ok($u->{pDate}, "struct Date{0x2BADC0DE}");
  ok($u->{pEnum}, "enum Enum{0x12345678}");
  ok($u->{pText}, "Text{0xDEADC0DE}");

  my $p = $c->pack('PtrHookTest', $u);

  ok($p, $str);

  $c->tag($_, Hooks => undef) for qw( Test Date Enum TextId );
}

sub test_args {
  my(@ap, @au, $x);

  my $sub_p = sub { push @ap, @_; shift };
  my $sub_u = sub { push @au, @_; shift };

  my @t = (
    { type => 'TextId', in_p => 4711, in_u => pack("N", 0x12345678),
      arg_u => [],  res_u => [],
      arg_p => [],  res_p => []  },

    { type => 'TextId', in_p => 4711, in_u => pack("N", 0x12345678),
      arg_u => [1], res_u => [1],
      arg_p => [2], res_p => [2] },

    { type => 'TextId', in_p => 4711, in_u => pack("N", 0x12345678),
      arg_u => [$c->arg('DATA')], res_u => [0x12345678],
      arg_p => [$c->arg('DATA', 'HOOK')], res_p => [4711, 'pack'] },

    { type => 'TextId', in_p => 4711, in_u => pack("N", 0x12345678),
      arg_u => [$c->arg('DATA', 'TYPE', 'SELF'), 123], res_u => [0x12345678, 'TextId', '{self}', 123],
      arg_p => [$c->arg('DATA', 'TYPE', 'SELF'), 456], res_p => [4711, 'TextId', '{self}', 456] },

    { type => 'TextId', in_p => 4711, in_u => pack("N", 0x12345678),
      arg_u => [$c->arg('DATA', 'TYPE'), 'foo', $c->arg('SELF', 'DATA')],
      res_u => [0x12345678, 'TextId', 'foo', '{self}', 0x12345678],
      arg_p => [$c->arg('DATA', 'TYPE'), 'bar', $c->arg('SELF')], res_p => [4711, 'TextId', 'bar', '{self}'] },

    { type => 'Enum', in_p => 'Seven', in_u => pack("N", 8),
      arg_u => [$c->arg('DATA', 'TYPE', 'HOOK')], res_u => ['<ENUM:8>', 'enum Enum', 'unpack'],
      arg_p => [$c->arg('DATA', 'TYPE', 'DATA')], res_p => ['Seven', 'enum Enum', 'Seven'] },

    { type => 'Date', in_p => {}, in_u => pack("N3", 4, 5, 6),
      arg_u => [$c->arg('DATA', 'TYPE')], res_u => [qr/HASH/, 'struct Date'],
      arg_p => [$c->arg('DATA', 'TYPE')], res_p => [qr/HASH/, 'struct Date'] },
  );

  for my $t (@t) {
    $c->tag($t->{type}, Hooks => {
                          pack   => [$sub_p, @{$t->{arg_p}}],
                          unpack => [$sub_u, @{$t->{arg_u}}],
                        });

    for my $cbc ($c, $c->clone) {

      $x = $cbc->pack($t->{type}, $t->{in_p});
      $x = $cbc->unpack($t->{type}, $t->{in_u});

      ok(scalar @ap, scalar @{$t->{res_p}});
      for (0 .. $#ap) {
        my $res = $t->{res_p}[$_] eq '{self}' ? $cbc : $t->{res_p}[$_];
        ok($ap[$_], $res);
      }

      ok(scalar @au, scalar @{$t->{res_u}});
      for (0 .. $#au) {
        my $res = $t->{res_u}[$_] eq '{self}' ? $cbc : $t->{res_u}[$_];
        ok($au[$_], $res);
      }

      $cbc->tag($t->{type}, Hooks => undef);

      @ap = (); @au = ();
    }
  }
}

sub no_hooks {
  my($u, $p);

  $u = $c->unpack('Enum', $d);
  ok($u, 'Four');
  $p = $c->pack('Enum', $u);
  ok($p, substr($d, 0, $c->sizeof('Enum')));

  $u = $c->unpack('u_32', $d);
  ok($u, 4);
  $p = $c->pack('u_32', $u);
  ok($p, substr($d, 0, $c->sizeof('u_32')));

  $u = $c->unpack('TextId', $d);
  ok($u, 4);
  $p = $c->pack('TextId', $u);
  ok($p, substr($d, 0, $c->sizeof('TextId')));

  $u = $c->unpack('SetTextId', $d);
  ok($u, 4);
  $p = $c->pack('SetTextId', $u);
  ok($p, substr($d, 0, $c->sizeof('SetTextId')));

  $u = $c->unpack('String', $d);
  ok($u->{len}, 4);
  ok("@{$u->{buf}}", "@{[unpack 'c*', 'FOO!']}");
  $p = $c->pack('String', $u);
  ok($p, $d);

  $u = $c->unpack('Test', $d);
  ok($u->{header}, 4);
  ok($u->{id}, unpack('N', 'FOO!'));
  $p = $c->pack('Test', $u);
  ok($p, substr($d, 0, $c->sizeof('Test')));
}

sub with_hooks {
  my($u, $p);

  $u = $c->unpack('Enum', $d);
  ok($u, 'FOUR');
  $p = $c->pack('Enum', $u);
  ok($p, substr($d, 0, $c->sizeof('Enum')));

  $u = $c->unpack('u_32', $d);
  ok($u, 4);
  $p = $c->pack('u_32', $u);
  ok($p, substr($d, 0, $c->sizeof('u_32')));

  $u = $c->unpack('TextId', $d);
  ok($u, 'perl');
  $p = $c->pack('TextId', $u);
  ok($p, substr($d, 0, $c->sizeof('TextId')));

  $u = $c->unpack('SetTextId', $d);
  ok($u, 'perl');
  $p = $c->pack('SetTextId', $u);
  ok($p, substr($d, 0, $c->sizeof('SetTextId')));

  $u = $c->unpack('String', $d);
  ok($u, 'FOO!');
  $p = $c->pack('String', $u);
  ok($p, $d);

  $u = $c->unpack('Test', $d);
  ok($u->{header}, 4);
  ok($u->{id}, 'rules');
  $p = $c->pack('Test', $u);
  ok($p, substr($d, 0, $c->sizeof('Test')));
}

sub with_single_hook {
  my($u, $p);

  $u = $c->unpack('Enum', $d);
  ok($u, 'Four');
  $p = $c->pack('Enum', $u);
  ok($p, substr($d, 0, $c->sizeof('Enum')));

  $u = $c->unpack('u_32', $d);
  ok($u, 4);
  $p = $c->pack('u_32', $u);
  ok($p, substr($d, 0, $c->sizeof('u_32')));

  $u = $c->unpack('TextId', $d);
  skip($reason, $u, 'perl');
  $p = $c->pack('TextId', $u);
  ok($p, substr($d, 0, $c->sizeof('TextId')));

  $u = $c->unpack('SetTextId', $d);
  skip($reason, $u, 'perl');
  $p = $c->pack('SetTextId', $u);
  ok($p, substr($d, 0, $c->sizeof('SetTextId')));

  $u = $c->unpack('String', $d);
  ok($u->{len}, 4);
  ok("@{$u->{buf}}", "@{[unpack 'c*', 'FOO!']}");
  $p = $c->pack('String', $u);
  ok($p, $d);

  $u = $c->unpack('Test', $d);
  ok($u->{header}, 4);
  skip($reason, $u->{id}, 'rules');
  $p = $c->pack('Test', $u);
  ok($p, substr($d, 0, $c->sizeof('Test')));
}

# the hooks
sub enum_pack   { ucfirst lc $_[0] }
sub enum_unpack { uc $_[0] }

sub textid_pack   { $RTEXTID{$_[0]} }
sub textid_unpack { $TEXTID{$_[0]} }

sub string_pack {
  { len => length $_[0], buf => [unpack 'c*', $_[0]] }
}
sub string_unpack {
  pack "c$_[0]->{len}", @{$_[0]->{buf}}
}

# dying hooks used to leak memory
# we cannot really test that they don't leak, but we test if dying works
# any remaining leaks will hopefully show up with valgrind...

$c->clean->EnumType('Integer')->parse(<<ENDC);

typedef int foo;

enum NUM { ZERO, ONE, TWO, THREE };

struct inlined {
  foo a[2][2];
};

typedef struct {
  struct {
    struct inlined;
    enum NUM num, *pnum;
    foo b, *pb;
  } a;
  struct inlined b, *pb;
  struct {
    struct inlined;
    enum NUM num, *pnum;
    foo b[2], *pb;
  } c[2][2];
} test;

ENDC

my $bd = 'x' x $c->sizeof('test');
my $pd = eval { $c->unpack('test', $bd) };

for my $t (['foo' => 40], ['enum NUM' => 10], ['struct inlined' => 4]) {
  $c->tag($t->[0], Hooks => { pack       => sub { rand($t->[1]) < 1 and die "($t->[0]) pack\n";       shift },
                              unpack     => sub { rand($t->[1]) < 1 and die "($t->[0]) unpack\n";     shift },
                              pack_ptr   => sub { rand($t->[1]) < 1 and die "($t->[0]) pack_ptr\n";   shift },
                              unpack_ptr => sub { rand($t->[1]) < 1 and die "($t->[0]) unpack_ptr\n"; shift } });
}

for (1 .. 100) {
  my $x = eval { $c->pack('test', $pd) };
  $@ and print "# $@";
  ok($@ =~ /pack/ xor defined $x);
  my $y = eval { $c->unpack('test', $bd) };
  $@ and print "# $@";
  ok($@ =~ /unpack/ xor defined $y);
}

#### TODO: is there a way to check for leaking scalars? (Devel::Arena ?)
