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

BEGIN { plan tests => 275 }

eval {
  $p = new Convert::Binary::C ByteOrder     => 'BigEndian'
                            , UnsignedChars => 0
};
ok($@,'',"failed to create Convert::Binary::C object");

eval {
$p->parse(<<'EOF');
enum _enum { FOO };
struct _struct { int foo[1]; };
typedef struct _struct _typedef;
typedef int scalar;
typedef int array[1];
typedef struct { array foo; } hash;
typedef struct { int foo[1]; } hash2;
typedef char c_8;
typedef unsigned char u_8, v_8[];
typedef signed char i_8;
typedef long double ldbl;
typedef struct { char a; int b[3][3]; } undef_test[3];
struct zero { int :0; };
typedef int incomplete[];
struct flexarray { int a; u_8 b[]; };
EOF
};
ok($@,'',"parse() failed");

# catch all warnings for further checks

$SIG{__WARN__} = sub { push @warn, $_[0] };
sub chkwarn {
  my $fail = 0;
  if( @warn != @_ ) {
    print "# wrong number of warnings (got ", scalar @warn,
                               ", expected ", scalar @_, ")\n";
    $fail++;
  }
  for my $ix ( 0 .. $#_ ) {
    my $e = $_[$ix];
    my $w = $warn[$ix];
    unless( $w =~ ref($e) ? $e : qr/\Q$e\E/ ) {
      print "# wrong warning, expected $e, got $w\n";
      $fail++;
    }
  }
  if( $fail ) { print "# $_" for @warn }
  ok( $fail, 0, "warnings check failed" );
  @warn = ();
}

#===================================================================
# check errors (2 tests)
#===================================================================

eval { $packed = $p->unpack( 'foo', 0 ) };
ok( $@, qr/Type of arg 2 to unpack must be string/ ); chkwarn;

eval { $packed = $p->pack( 'foo', 0, 0 ) };
ok( $@, qr/Type of arg 3 to pack must be string/ ); chkwarn;

#===================================================================
# check scalars
#===================================================================

$val  = 1234567890;
$data = pack 'N', $val;

eval { $packed = $p->unpack( 'scalar', $data ) };
ok($@,'',"failed in unpack"); chkwarn;
ok($packed,$val);

eval { $packed = $p->unpack( 'scalar', 'foo' ) };
ok($@,'',"failed in unpack");
chkwarn( qr/Data too short/ );
ok(not defined $packed);

eval { $packed = $p->pack( 'scalar', $val ) };
ok($@,'',"failed in pack"); chkwarn;
ok($packed,$data);

eval { $packed = $p->pack( 'scalar', [4711] ) };
ok($@,'',"failed in pack");
chkwarn( qr/'scalar' should be a scalar value/ );
ok($packed,pack('N',0));

$packed = $data;
eval { $p->pack( 'scalar', undef, $packed ) };
ok($@,'',"failed in pack"); chkwarn;
ok($packed,$data);

$packed = $data;
eval { $p->pack( 'scalar', [4711], $packed ) };
ok($@,'',"failed in pack");
chkwarn( qr/'scalar' should be a scalar value/ );
ok($packed,$data);

$packed = $data;
eval { $p->pack( 'scalar', {foo=>4711}, $packed ) };
ok($@,'',"failed in pack");
chkwarn( qr/'scalar' should be a scalar value/ );
ok($packed,$data);

#===================================================================
# check arrays
#===================================================================

eval { $packed = $p->unpack( 'array', $data ) };
ok($@,'',"failed in unpack"); chkwarn;
ok(ref $packed, 'ARRAY');
ok(scalar @$packed, 1);
ok($packed->[0], $val);

eval { $packed = $p->unpack( 'array', 'foo' ) };
ok($@,'',"failed in unpack");
chkwarn( qr/Data too short/ );
ok(ref $packed, 'ARRAY');
ok(scalar @$packed, 1);
ok(not defined $packed->[0]);

eval { $packed = $p->pack( 'array', [$val] ) };
ok($@,'',"failed in pack"); chkwarn;
ok($packed,$data);

eval { $packed = $p->pack( 'array', $val ) };
ok($@,'',"failed in pack");
chkwarn( qr/'array' should be an array reference/ );
ok($packed, pack('N',0));

eval { $packed = $p->pack( 'array', {foo=>4711} ) };
ok($@,'',"failed in pack");
chkwarn( qr/'array' should be an array reference/ );
ok($packed, pack('N',0));

$packed = '12345678';
eval { $p->pack( 'array', [$val], $packed ) };
ok($@,'',"failed in pack"); chkwarn;
ok($packed,$data.'5678');

$packed = '12';
eval { $p->pack( 'array', $val, $packed ) };
ok($@,'',"failed in pack");
chkwarn( qr/'array' should be an array reference/ );
ok($packed,'12'.pack('n',0));

#===================================================================
# check hashes (structs)
#===================================================================

eval { $packed = $p->unpack( 'hash', $data ) };
ok($@,'',"failed in unpack"); chkwarn;
ok(ref $packed,'HASH');
ok(scalar keys %$packed, 1);
ok(ref $packed->{foo},'ARRAY');
ok(scalar @{$packed->{foo}},1);
ok($packed->{foo}[0],$val);

eval { $packed = $p->unpack( 'hash', 'foo' ) };
ok($@,'',"failed in unpack");
chkwarn( qr/Data too short/ );
ok(ref $packed,'HASH');
ok(scalar keys %$packed, 1);
ok(ref $packed->{foo},'ARRAY');
ok(scalar @{$packed->{foo}},1);
ok(not defined $packed->{foo}[0]);

eval { $packed = $p->pack( 'hash', {foo => [$val]} ) };
ok($@,'',"failed in pack"); chkwarn;
ok($packed,$data);

eval { $packed = $p->pack( 'hash', [4711] ) };
ok($@,'',"failed in pack");
chkwarn( qr/'hash' should be a hash reference/ );
ok($packed,pack('N',0));

eval { $packed = $p->pack( 'hash', {foo => 4711} ) };
ok($@,'',"failed in pack");
chkwarn( qr/'foo' should be an array reference/ );
ok($packed,pack('N',0));

eval { $packed = $p->pack( 'hash2', {foo => 4711} ) };
ok($@,'',"failed in pack");
chkwarn( qr/'foo' should be an array reference/ );
ok($packed,pack('N',0));

$packed = '12345678';
eval { $p->pack( 'hash', {foo => [$val]}, $packed ) };
ok($@,'',"failed in pack"); chkwarn;
ok($packed,$data.'5678');

$packed = '12';
eval { $packed = $p->pack( 'hash', [4711], $packed ) };
ok($@,'',"failed in pack");
chkwarn( qr/'hash' should be a hash reference/ );
ok($packed,'12'.pack('n',0));

$packed = '1234';
eval { $packed = $p->pack( 'hash', {foo => 4711}, $packed ) };
ok($@,'',"failed in pack");
chkwarn( qr/'foo' should be an array reference/ );
ok($packed,'1234');

$packed = '1234';
eval { $packed = $p->pack( 'hash2', {foo => 4711}, $packed ) };
ok($@,'',"failed in pack");
chkwarn( qr/'foo' should be an array reference/ );
ok($packed,'1234');

#===================================================================
# check unsigned chars (72 tests)
#===================================================================

my %tests = (
  c_8             => {
                       pack   => { in => 255, out => pack('C', 255) },
                       unpack => { in => pack('C', 255), out => -1 },
                     },
  i_8             => {
                       pack   => { in => 255, out => pack('C', 255) },
                       unpack => { in => pack('C', 255), out => -1 },
                     },
  u_8             => {
                       pack   => { in => 255, out => pack('C', 255) },
                       unpack => { in => pack('C', 255), out => 255 },
                     },
  'char'          => {
                       pack   => { in => 255, out => pack('C', 255) },
                       unpack => { in => pack('C', 255), out => -1 },
                     },
  'signed char'   => {
                       pack   => { in => 255, out => pack('C', 255) },
                       unpack => { in => pack('C', 255), out => -1 },
                     },
  'unsigned char' => {
                       pack   => { in => 255, out => pack('C', 255) },
                       unpack => { in => pack('C', 255), out => 255 },
                     },
);

uchar_test( %tests );
$p->UnsignedChars(1);
$tests{$_}{unpack}{out} = 255 for qw( c_8 char );
uchar_test( %tests );

#===================================================================
# check unsigned 16-bit chars (36 tests)
#===================================================================

%tests = (
  'char'          => {
                       pack   => { in => 65535, out => pack('n', 65535) },
                       unpack => { in => pack('n', 65535), out => -1 },
                     },
  'signed char'   => {
                       pack   => { in => 65535, out => pack('n', 65535) },
                       unpack => { in => pack('n', 65535), out => -1 },
                     },
  'unsigned char' => {
                       pack   => { in => 65535, out => pack('n', 65535) },
                       unpack => { in => pack('n', 65535), out => 65535 },
                     },
);

$p->CharSize(2)->UnsignedChars(0);
uchar_test( %tests );
$p->UnsignedChars(1);
$tests{char}{unpack}{out} = 65535;
uchar_test( %tests );
$p->CharSize(1);

sub uchar_test
{
  my %tests = @_;
  for my $t ( keys %tests ) {
    for my $m ( keys %{$tests{$t}} ) {
      my $res = eval { $p->$m( $t, $tests{$t}{$m}{in} ) };
      ok($@,'',"failed in $m"); chkwarn;
      ok($res, $tests{$t}{$m}{out}, "$m( '$t', $tests{$t}{$m}{in} ) != $tests{$t}{$m}{out}");
    }
  }
}

#===================================================================
# check long doubles (2 tests)
#===================================================================

eval { $packed = $p->pack('ldbl', 3.14159) };
ok($@,'',"failed in pack");
my $null = pack 'C*', (0) x length($packed);
if( $packed eq $null ) {
  chkwarn( qr/Cannot pack long doubles/ );
  eval { $packed = $p->unpack('ldbl', $packed) };
  ok($@,'',"failed in unpack");
  chkwarn( qr/Cannot unpack long doubles/ );
  ok($packed,0.0);
}
else {
  chkwarn();
  eval { $packed = $p->unpack('ldbl', $packed) };
  ok($@,'',"failed in unpack");
  chkwarn();
  ok( $packed-3.14159 < 0.0001 );
}

#===================================================================
# check for warnings when explicitly passing undef (1 test)
#===================================================================

$val = [ undef, { b => [undef, [undef, 2]] } ];  # undef_test[1].b[1][1] = 2
eval { $packed = $p->pack('undef_test', $val) };
ok($@,'',"failed in pack");
chkwarn;

#===================================================================
# check for existence of members with undef values
#===================================================================

$val = $p->sizeof( 'undef_test[0]' );
chkwarn();

$packed = 'x' x $val;
eval { $val = $p->unpack( 'undef_test', $packed ) };
ok($@,'',"failed in unpack");
chkwarn( qr/Data too short/ );

ok(reccmp_keys($val->[0], $val->[1]), '', 'deep compare failed');
ok(reccmp_keys($val->[0], $val->[2]), '', 'deep compare failed');
ok(reccmp_keys($val->[1], $val->[2]), '', 'deep compare failed');
chkwarn();

ok(rec_write($val->[0]), '', 'write check failed');
ok(rec_write($val->[1]), '', 'write check failed');
ok(rec_write($val->[2]), '', 'write check failed');
chkwarn();

#===================================================================
# bug #3753 - pack() on zero size type caused segfault / bus error
#===================================================================

ok($p->pack('zero', {}), '', 'pack on zero size type (bug #3753)');
ok(reccmp_keys({}, $p->unpack('zero', '')), '', 'unpack on zero size type');

#===================================================================
# check unpack in list context
#===================================================================

{
  for my $t (qw( u_8 incomplete flexarray )) {
    print "# --- $t ---\n";

    my $s = $p->sizeof($t);

    my $n = $s || 42;

    my $d1 = pack "C*", 2 .. 3*$n;
    my $d2 = pack "C*", 1 .. 3*$n;
    my $d3 = pack "C*", 0 .. 3*$n;

    my $x1 = $p->unpack($t, $d1);
    my @x1 = $p->unpack($t, $d1);
    my $x2 = $p->unpack($t, $d2);
    my @x2 = $p->unpack($t, $d2);
    my $x3 = $p->unpack($t, $d3);
    my @x3 = $p->unpack($t, $d3);

    ok(scalar @x1, $s ? int(length($d1)/$s) : 1);
    ok(scalar @x2, $s ? int(length($d2)/$s) : 1);
    ok(scalar @x3, $s ? int(length($d3)/$s) : 1);

    ok($p->pack($t, $x1), $p->pack($t, $x1[0]));
    ok($p->pack($t, $x2), $p->pack($t, $x2[0]));
    ok($p->pack($t, $x3), $p->pack($t, $x3[0]));

    if ($s > 0) {
      my $p1 = $p->pack($t, $x1[1]);
      my $p2 = $p->pack($t, $x2[1]);
      my $p3 = $p->pack($t, $x3[1]);
      ok($p1, substr($d1, $s, length $p1));
      ok($p2, substr($d2, $s, length $p2));
      ok($p3, substr($d3, $s, length $p3));
    }
  }
}

#===================================================================
# pack() should \0 terminate its return value to make the regex
# engine happy. This is rather a bug in Perl, but we fix it here.
#===================================================================

$val = "\x42";
$packed = $p->pack('u_8', 0x42);
ok($packed, $val);
ok($packed =~ /^$val$/);
ok($packed =~ /^$val.*$/);

$packed = $p->pack('u_8', 0x42, "");
ok($packed, $val);
ok($packed =~ /^$val$/);
ok($packed =~ /^$val.*$/);

$packed = "";
$p->pack('u_8', 0x42, $packed);
ok($packed, $val);
ok($packed =~ /^$val$/);
ok($packed =~ /^$val.*$/);

$val = "\x42"x100;
$packed = $p->pack('v_8', [(0x42)x100]);
ok($packed, $val);
ok($packed =~ /^$val$/);
ok($packed =~ /^$val.*$/);

#===================================================================
# some tests for the 3-arg version of pack()
#===================================================================

{
  my @res;

  my $c = new Convert::Binary::C;
  $c->parse(<<ENDC);
typedef unsigned char u;
typedef struct {
  u a, b, c, d;
} s;
ENDC

  eval {
    $packed = pack 'C*', 1 .. 2;
    push @res, $c->pack('s', { a => 42, d => 13 }, $packed);
    push @res, $packed;
    $c->pack('s', { b => 42, c => 13 }, $packed);
    push @res, $packed;
    $packed = pack 'C*', 1 .. 6;
    push @res, $c->pack('s', { a => 42, d => 13 }, $packed);
    push @res, $packed;
    $c->pack('s', { b => 42, c => 13 }, $packed);
    push @res, $packed;
  };

  ok($@, '', "failed during 3-arg pack test");
  ok(@res == 6);

  ok($res[0], pack('C*',42,2,0,13));
  ok($res[1], pack('C*',1,2));
  ok($res[2], pack('C*',1,42,13,0));
  ok($res[3], pack('C*',42,2,3,13,5,6));
  ok($res[4], pack('C*',1,2,3,4,5,6));
  ok($res[5], pack('C*',1,42,13,4,5,6));

  @res = ();
  $val = $c->unpack('u', '+');
  $packed = "mhx";
  eval {
    push @res, $c->pack('u', $val, $packed);
    push @res, $packed;
    $c->pack('u', $val, $packed);
    push @res, $packed;
    push @res, $c->pack('u', $val, substr $packed, 1, 2);
    push @res, $packed;
    $c->pack('u', $val, substr $packed, 1, 2);
    push @res, $packed;
  };

  ok($@, '', "failed during 3-arg pack test");
  ok(@res == 6);

  ok($res[0], "+hx");
  ok($res[1], "mhx");
  ok($res[2], "+hx");
  ok($res[3], "+x");
  ok($res[4], "+hx");
  ok($res[5], "++x");

  @res = ();
  $packed = "xxxx";
  $packed =~ s/xxx$//;
  eval {
    push @res, $c->pack('s', {}, $packed);
    push @res, $packed;
    $c->pack('s', $val, $packed);
    push @res, $packed;
  };

  ok($@, '', "failed during 3-arg pack test");
  ok(@res == 3);

  ok($res[0], "x\0\0\0");
  ok($res[1], "x");
  ok($res[2], "x\0\0\0");
}

sub rec_write
{
  my $ref = shift;
  my $r = ref $ref;
  if( $r eq 'HASH' ) {
    for my $k ( keys %$ref ) {
      if( ref $ref->{$k} ) {
        $r = rec_write( $ref->{$k} );
        $r and return $r;
      }
      else {
        eval { $ref->{$k} = 42 };
        $@ and return $@;
      }
    }
  }
  elsif( $r eq 'ARRAY' ) {
    for my $i ( 0 .. $#$ref ) {
      if( ref $ref->[$i] ) {
        $r = rec_write( $ref->[$i] );
        $r and return $r;
      }
      else {
        eval { $ref->[$i] = 42 };
        $@ and return $@;
      }
    }
  }
  return '';
}

sub reccmp_keys
{
  my($ref,$chk) = @_;
  my $r = ref $ref;
  if( $r eq 'HASH' ) {
    defined $chk or return "undefined hash reference";
    keys(%$ref) == keys(%$chk) or return "key counts differ";
    for my $k ( keys %$ref ) {
      exists $chk->{$k} or return "reference key '$k' not found";
      $r = reccmp_keys( $ref->{$k}, $chk->{$k} );
      $r and return $r;
    }
  }
  elsif( $r eq 'ARRAY' ) {
    defined $chk or return "undefined array reference";
    @$ref == @$chk or return "array lengths differ";
    for my $i ( 0 .. $#$ref ) {
      $r = reccmp_keys( $ref->[$i], $chk->[$i] );
      $r and return $r;
    }
  }
  return '';
}
