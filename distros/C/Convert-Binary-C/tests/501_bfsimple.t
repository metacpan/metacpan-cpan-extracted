################################################################################
#
# Copyright (c) 2002-2020 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 8990;
use Convert::Binary::C @ARGV;
use strict;

$^W = 1;

my $BIN = $] < 5.006 ? '%x' : '%08b';

my $c = eval {
  Convert::Binary::C->new(
    Bitfields => { Engine => 'Simple', BlockSize => 4 },
    EnumType  => 'String'
  );
};

is($@, '', "failed to create Convert::Binary::C object");

eval { $c->parse(<<ENDC) };

struct bfu
{
  unsigned b1 : 1;
  unsigned b2 : 2;
  unsigned b3 : 3;
  unsigned b4 : 4;
  unsigned b5 : 5;
  unsigned b6 : 6;
  unsigned b7 : 7;
};

struct bfs
{
  signed b1 : 1;
  signed b2 : 2;
  signed b3 : 3;
  signed b4 : 4;
  signed b5 : 5;
  signed b6 : 6;
  signed b7 : 7;
};

enum ue1 { U10, U11 };
enum ue2 { U20, U21, U22 = 1 << 1, U2A = 3 };
enum ue3 { U30, U31, U32 = 1 << 1, U33 = 1 << 2, U3A = 7 };
enum ue4 { U40, U41, U42 = 1 << 1, U43 = 1 << 2, U44 = 1 << 3, U4A = 15 };
enum ue5 { U50, U51, U52 = 1 << 1, U53 = 1 << 2, U54 = 1 << 3, U55 = 1 << 4, U5A = 31 };
enum ue6 { U60, U61, U62 = 1 << 1, U63 = 1 << 2, U64 = 1 << 3, U65 = 1 << 4, U66 = 1 << 5, U6A = 63 };
enum ue7 { U70, U71, U72 = 1 << 1, U73 = 1 << 2, U74 = 1 << 3, U75 = 1 << 4, U76 = 1 << 5, U77 = 1 << 6, U7A = 127 };

enum se1 { S10, S11 = -1 };
enum se2 { S20, S21, S22 = -2, S2A = -1 };
enum se3 { S30, S31, S32 = 1 << 1, S33 = -4, S3A = -1 };
enum se4 { S40, S41, S42 = 1 << 1, S43 = 1 << 2, S44 = -8, S4A = -1 };
enum se5 { S50, S51, S52 = 1 << 1, S53 = 1 << 2, S54 = 1 << 3, S55 = -16, S5A = -1 };
enum se6 { S60, S61, S62 = 1 << 1, S63 = 1 << 2, S64 = 1 << 3, S65 = 1 << 4, S66 = -32, S6A = -1 };
enum se7 { S70, S71, S72 = 1 << 1, S73 = 1 << 2, S74 = 1 << 3, S75 = 1 << 4, S76 = 1 << 5, S77 = -64, S7A = -1 };

struct bfue
{
  enum ue1 b1 : 1;
  enum ue2 b2 : 2;
  enum ue3 b3 : 3;
  enum ue4 b4 : 4;
  enum ue5 b5 : 5;
  enum ue6 b6 : 6;
  enum ue7 b7 : 7;
};

struct bfse
{
  enum se1 b1 : 1;
  enum se2 b2 : 2;
  enum se3 b3 : 3;
  enum se4 b4 : 4;
  enum se5 b5 : 5;
  enum se6 b6 : 6;
  enum se7 b7 : 7;
};

ENDC

is($@, '');

is($c->sizeof('bfu'), 4);
is($c->sizeof('bfs'), 4);
is($c->sizeof('bfue'), 4);
is($c->sizeof('bfse'), 4);

for my $cfg ({ bo => 'BigEndian'    },
             { bo => 'BigEndian'    },
             { bo => 'LittleEndian' },
             { bo => 'LittleEndian' }) {

  $c->ByteOrder($cfg->{bo});

  my $bfu = $c->unpack('bfu', pack "C*", (255)x4);
  my $bfs = $c->unpack('bfs', pack "C*", (255)x4);
  my $bfue = $c->unpack('bfue', pack "C*", (255)x4);
  my $bfse = $c->unpack('bfse', pack "C*", (255)x4);

  for (1 .. 7) {
    is($bfu->{"b$_"}, (1 << $_) - 1);
    is($bfs->{"b$_"}, -1);
    is($bfue->{"b$_"}, "U$_" . ($_ == 1 ? '1' : 'A'));
    is($bfse->{"b$_"}, "S$_" . ($_ == 1 ? '1' : 'A'));
  }
}

$c->ByteOrder('LittleEndian');

my @ru = ();
my @rs = ();
my @rue = ();
my @rse = ();
for my $b (1 .. 7) {
  for my $i (0 .. ($b-1)) {
    for (\@ru, \@rs) {
      push @$_, { map { ("b$_" => 0) } 1 .. 7 };
    }
    push @rue, { map { ("b$_" => "U${_}0") } 1 .. 7 };
    push @rse, { map { ("b$_" => "S${_}0") } 1 .. 7 };
    $ru[-1]{"b$b"} = 1 << $i;
    $rs[-1]{"b$b"} = $i == ($b-1) ? -(1 << $i) : 1 << $i;
    $rue[-1]{"b$b"} = "U$b" . ($i+1);
    $rse[-1]{"b$b"} = "S$b" . ($i+1);
  }
}
while (@ru < 32) {
  for (\@ru, \@rs) {
    push @$_, { map { ("b$_" => 0) } 1 .. 7 };
  }
  push @rue, { map { ("b$_" => "U${_}0") } 1 .. 7 };
  push @rse, { map { ("b$_" => "S${_}0") } 1 .. 7 };
}

for my $bit (0 .. 31) {
  debug("LittleEndian, Bit=$bit\n");
  my $pk = pack "V", 1<<$bit;
  my $bfu = $c->unpack('bfu', $pk);
  my $bfs = $c->unpack('bfs', $pk);
  my $bfue = $c->unpack('bfue', $pk);
  my $bfse = $c->unpack('bfse', $pk);

  is(join(',', map { qq/b$_=$bfu->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$ru[$bit]{"b$_"}/ } 1 .. 7));

  is(join(',', map { qq/b$_=$bfs->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$rs[$bit]{"b$_"}/ } 1 .. 7));

  is(join(',', map { qq/b$_=$bfue->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$rue[$bit]{"b$_"}/ } 1 .. 7));

  is(join(',', map { qq/b$_=$bfse->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$rse[$bit]{"b$_"}/ } 1 .. 7));

  $pk = pack "V", 0 if $bit >= 28;
  my $pu = $c->pack('bfu', $ru[$bit]);
  my $ps = $c->pack('bfs', $rs[$bit]);
  my $pue = $c->pack('bfue', $rue[$bit]);
  my $pse = $c->pack('bfse', $rse[$bit]);
  debug(sprintf "pk =%s\npu =%s\nps =%s\npue=%s\npse=%s\n",
                map { showbits($_) } $pk, $pu, $ps, $pue, $pse);
  is($pu, $pk);
  is($ps, $pk);
  is($pue, $pk);
  is($pse, $pk);
}

$c->ByteOrder('BigEndian');

@ru = ();
@rs = ();
@rue = ();
@rse = ();
for my $b (1 .. 7) {
  for my $i (reverse(0 .. ($b-1))) {
    for (\@ru, \@rs) {
      unshift @$_, { map { ("b$_" => 0) } 1 .. 7 };
    }
    unshift @rue, { map { ("b$_" => "U${_}0") } 1 .. 7 };
    unshift @rse, { map { ("b$_" => "S${_}0") } 1 .. 7 };
    $ru[0]{"b$b"} = 1 << $i;
    $rs[0]{"b$b"} = $i == ($b-1) ? -(1 << $i) : 1 << $i;
    $rue[0]{"b$b"} = "U$b" . ($i+1);
    $rse[0]{"b$b"} = "S$b" . ($i+1);
  }
}
while (@ru < 32) {
  for (\@ru, \@rs) {
    unshift @$_, { map { ("b$_" => 0) } 1 .. 7 };
  }
  unshift @rue, { map { ("b$_" => "U${_}0") } 1 .. 7 };
  unshift @rse, { map { ("b$_" => "S${_}0") } 1 .. 7 };
}

for my $bit (0 .. 31) {
  debug("BigEndian, Bit=$bit\n");
  my $pk = pack "N", 1<<$bit;
  my $bfu = $c->unpack('bfu', $pk);
  my $bfs = $c->unpack('bfs', $pk);
  my $bfue = $c->unpack('bfue', $pk);
  my $bfse = $c->unpack('bfse', $pk);

  is(join(',', map { qq/b$_=$bfu->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$ru[$bit]{"b$_"}/ } 1 .. 7));

  is(join(',', map { qq/b$_=$bfs->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$rs[$bit]{"b$_"}/ } 1 .. 7));

  is(join(',', map { qq/b$_=$bfue->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$rue[$bit]{"b$_"}/ } 1 .. 7));

  is(join(',', map { qq/b$_=$bfse->{"b$_"}/   } 1 .. 7),
     join(',', map { qq/b$_=$rse[$bit]{"b$_"}/ } 1 .. 7));

  $pk = pack "N", 0 if $bit <= 3;
  my $pu = $c->pack('bfu', $ru[$bit]);
  my $ps = $c->pack('bfs', $rs[$bit]);
  my $pue = $c->pack('bfue', $rue[$bit]);
  my $pse = $c->pack('bfse', $rse[$bit]);
  debug(sprintf "pk =%s\npu =%s\nps =%s\npue=%s\npse=%s\n",
                map { showbits($_) } $pk, $pu, $ps, $pue, $pse);
  is($pu, $pk);
  is($ps, $pk);
  is($pue, $pk);
  is($pse, $pk);
}


$c->clean->parse(<<ENDC);

struct sbf {
  unsigned b1 : 1;
  unsigned    : 2;
  unsigned b2 : 2;
  unsigned    : 0;
  unsigned b3 : 3;
};

union ubf {
  unsigned b1 : 1;
  unsigned    : 2;
  unsigned b2 : 2;
  unsigned    : 0;
  unsigned b3 : 3;
};

ENDC

is($c->sizeof('sbf'), 8);
is($c->sizeof('ubf'), 4);


$c->ByteOrder('BigEndian');

my $us = $c->unpack('sbf', pack "NN", 0xF0FFFFFF, 0x4FFFFFFF);

is($us->{b1}, 1);
is($us->{b2}, 2);
is($us->{b3}, 2);

my $uu = $c->unpack('ubf', pack "N", 0x4FFFFFFF);

is($uu->{b1}, 0);
is($uu->{b2}, 1);
is($uu->{b3}, 2);

my $ps = $c->pack('sbf', { b1 => 1, b2 => 2, b3 => 3 });
my $pu = $c->pack('ubf', { b1 => 0, b2 => 1, b3 => 2 });

is($ps, pack "NN", 0x90000000, 0x60000000);
is($pu, pack "N", 0x40000000);


$c->ByteOrder('LittleEndian');

$us = $c->unpack('sbf', pack "VV", 0xFFFFFF0F, 0xFFFFFFF4);

is($us->{b1}, 1);
is($us->{b2}, 1);
is($us->{b3}, 4);

$uu = $c->unpack('ubf', pack "V", 0xFFFFFFFA);

is($uu->{b1}, 0);
is($uu->{b2}, 2);
is($uu->{b3}, 2);

$ps = $c->pack('sbf', { b1 => 1, b2 => 2, b3 => 3 });
$pu = $c->pack('ubf', { b1 => 0, b2 => 1, b3 => 2 });

is($ps, pack "VV", 0x00000011, 0x00000003);
is($pu, pack "V", 0x00000002);


my @shlone = qw( 1 2 4 8 16 32 64 128 256 512 1024 2048 4096 8192 16384 32768 65536
131072 262144 524288 1048576 2097152 4194304 8388608 16777216 33554432 67108864
134217728 268435456 536870912 1073741824 2147483648 4294967296 8589934592 17179869184
34359738368 68719476736 137438953472 274877906944 549755813888 1099511627776
2199023255552 4398046511104 8796093022208 17592186044416 35184372088832 70368744177664
140737488355328 281474976710656 562949953421312 1125899906842624 2251799813685248
4503599627370496 9007199254740992 18014398509481984 36028797018963968 72057594037927936
144115188075855872 288230376151711744 576460752303423488 1152921504606846976
2305843009213693952 4611686018427387904 9223372036854775808 );

my @allbit = qw( 0 1 3 7 15 31 63 127 255 511 1023 2047 4095 8191 16383 32767 65535 131071
262143 524287 1048575 2097151 4194303 8388607 16777215 33554431 67108863 134217727
268435455 536870911 1073741823 2147483647 4294967295 8589934591 17179869183 34359738367
68719476735 137438953471 274877906943 549755813887 1099511627775 2199023255551
4398046511103 8796093022207 17592186044415 35184372088831 70368744177663 140737488355327
281474976710655 562949953421311 1125899906842623 2251799813685247 4503599627370495
9007199254740991 18014398509481983 36028797018963967 72057594037927935 144115188075855871
288230376151711743 576460752303423487 1152921504606846975 2305843009213693951
4611686018427387903 9223372036854775807 18446744073709551615 );

for my $block_size (1, 2, 4, 8) {
  my $max_bits = 8*$block_size;

  $c->Bitfields({ BlockSize => $block_size });

  for my $bits (1 .. $max_bits) {

    for my $shift (0 .. $max_bits-$bits) {
      my $shm = $shift ? "unsigned : $shift;" : '';

      $c->clean->parse(<<ENDC);
struct bfu {
  $shm
  unsigned b : $bits;
};
struct bfs {
  $shm
  signed b : $bits;
};
ENDC

      is($c->sizeof('bfu'), $block_size);
      is($c->sizeof('bfs'), $block_size);

      my @test = (
        { bo => 'LittleEndian',
          pk => sub { my $bit = shift; scalar reverse packbits($block_size, 1, $shift + $bit) },
          pkall => sub { scalar reverse packbits($block_size, $bits, $shift) } },
        { bo => 'BigEndian',
          pk => sub { my $bit = shift; packbits($block_size, 1, 8*$block_size - ($shift + $bits) + $bit) },
          pkall => sub { packbits($block_size, $bits, 8*$block_size - ($shift + $bits)) } },
      );

      my $fail = 0;

      for my $t (@test) {
        $c->ByteOrder($t->{bo});

        for my $bit (0 .. $bits-1) {
          my $pk = $t->{pk}->($bit);
          my $pu = $c->pack('bfu', { b => $shlone[$bit] });
          my $ps = $c->pack('bfs', { b => ($bit == $bits-1 ? "-$shlone[$bit]" : $shlone[$bit]) });
          my $uu = $c->unpack('bfu', $pk);
          my $us = $c->unpack('bfs', $pk);
          my $f = 0;

          $pu eq $pk or $f++;
          $ps eq $pk or $f++;

          $uu->{b} eq $shlone[$bit] or $f++;
          $us->{b} eq ($bit == $bits-1 ? "-$shlone[$bit]" : $shlone[$bit]) or $f++;

          if ($f > 0) {
            diag("[$t->{bo}/ONE] block_size=$block_size, bits=$bits, shift=$shift, bit=$bit\n",
                 sprintf("pk = %s\npu = %s\nps = %s\n", map { showbits($_) } $pk, $pu, $ps),
                 "1 << \$bit = $shlone[$bit]\n",
                 "\$uu->{b} = $uu->{b}\n",
                 "\$us->{b} = $us->{b}\n");
          }

          $fail += $f;
        }

        my $pk = $t->{pkall}->();
        my $pu = $c->pack('bfu', { b => $allbit[$bits] });
        my $ps = $c->pack('bfs', { b => -1 });
        my $uu = $c->unpack('bfu', $pk);
        my $us = $c->unpack('bfs', $pk);
        my $f = 0;

        $pu eq $pk or $f++;
        $ps eq $pk or $f++;

        $uu->{b} eq $allbit[$bits] or $f++;
        $us->{b} == -1 or $f++;

        if ($f > 0) {
          diag("[$t->{bo}/ALL] block_size=$block_size, bits=$bits, shift=$shift\n",
               sprintf("pk = %s\npu = %s\nps = %s\n", map { showbits($_) } $pk, $pu, $ps),
               "allbits = $allbit[$bits]\n",
               "\$uu->{b} = $uu->{b}\n",
               "\$us->{b} = $us->{b}\n");
        }

        $fail += $f;
      }

      is($fail, 0);
    }
  }
}

### test UnsignedBitfields option

$c->clean->Bitfields({ BlockSize => 1 })->parse(<<ENDC);

struct bf {
  int x : 8;
};

ENDC

my $bf = $c->unpack('bf', pack('C', 255));
is($bf->{x}, -1);

$c->UnsignedBitfields(1);

$bf = $c->unpack('bf', pack('C', 255));
is($bf->{x}, 255);

sub debug
{
  $ENV{CBC_TEST_DEBUG} and diag(@_);
}

sub showbits
{
  join ' ', map { sprintf $BIN, $_ } unpack "C*", shift;
}

sub packbits
{
  my($width, $bits, $offs) = @_;
  my @b = (0) x $width;
  for my $bit ($offs .. $offs + $bits - 1) {
    @b[$bit/8] |= 1 << ($bit%8);
  }
  pack "C*", reverse @b;
}
