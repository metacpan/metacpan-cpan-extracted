################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Test::More tests => 39;
use Convert::Binary::C @ARGV;
use strict;

BEGIN { $^W = 1 }

my $c = eval {
  Convert::Binary::C->new(Define  => ['b=a'],
                          Include => ['tests/include/files', 'include/files']);
};
is($@, '', "create Convert::Binary::C::Cached object");

#--------------------
# check of ucpp bugs
#--------------------

eval {
  $c->parse(<<'END');
#define a int
b x;
END
};
is($@, '', "parse code");

# eval {
#   $c->parse( <<'END' );
# #include "ifnonl.h"
# typedef int foo;
# END
# };
# is($@, '', "failed to parse code");


#----------------------------
# check if #ident is ignored
#----------------------------

my $s = eval {
  $c->parse(<<'END');
#ident "bla bla"
typedef int xxx;
END
  $c->sizeof('xxx');
};
is($@, '', "parse code with #ident correctly");
is($s, $c->sizeof('int'));

#------------------------------
# check #warn / #warning
#------------------------------

$s = $c->clean->parse('#warning "A #warning!"');
ok($s, qr/#warn/);
$s = $c->clean->parse('#warn "A #warn!"');
ok($s, qr/#warning/);

#----------------
# various checks
#----------------

$c->clean;

eval {
  $c->parse(<<'END');
#include "unmatched.h"
END
};

like($@, qr/unterminated #if construction/);
like($@, qr/included from \[buffer\]:1/);

$c->clean->CharSize(1)->Warnings(1);

my @warn;
$s = eval {
  local $SIG{__WARN__} = sub { push @warn, @_ };
  $c->parse(<<'END');
??=include "trigraph.h"
END
  $c->sizeof('array');
};

is($@, '');
is($s, 42);
is(scalar @warn, 5);
like($warn[0], qr/^\[buffer\], line 1: \(warning\) trigraph \?\?= encountered/);
like($warn[1], qr/trigraph\.h, line 1: \(warning\) trigraph \?\?= encountered/);
like($warn[1], qr/included from \[buffer\]:1/);
like($warn[2], qr/trigraph\.h, line 3: \(warning\) trigraph \?\?\( encountered/);
like($warn[2], qr/included from \[buffer\]:1/);
like($warn[3], qr/trigraph\.h, line 3: \(warning\) trigraph \?\?\) encountered/);
like($warn[3], qr/included from \[buffer\]:1/);
like($warn[4], qr/^\[buffer\]: \(warning\) 4 trigraph\(s\) encountered/);

#--------------------------------------------
# promotion of conditional operator operands
#--------------------------------------------

$c->clean;

eval {
  $c->parse(<<'END');

enum test {

#if 1 > (0 ? (~1) : (~1))
  SS0 = 1,
#else
  SS0 = 0,
#endif

#if 1 > (1 ? (~1) : (~1))
  SS1 = 1,
#else
  SS1 = 0,
#endif

#if 1 > (0 ? (~1U) : (~1))
  US0 = 1,
#else
  US0 = 0,
#endif

#if 1 > (1 ? (~1U) : (~1))
  US1 = 1,
#else
  US1 = 0,
#endif

#if 1 > (0 ? (~1) : (~1U))
  SU0 = 1,
#else
  SU0 = 0,
#endif

#if 1 > (1 ? (~1) : (~1U))
  SU1 = 1,
#else
  SU1 = 0,
#endif

#if 1 > (0 ? (~1U) : (~1U))
  UU0 = 1,
#else
  UU0 = 0,
#endif

#if 1 > (1 ? (~1U) : (~1U))
  UU1 = 1,
#else
  UU1 = 0,
#endif

};

END
};

is($@, '');
is_deeply($c->enum('test')->{enumerators}, {
  SS0 => 1,
  SS1 => 1,
  US0 => 0,
  US1 => 0,
  SU0 => 0,
  SU1 => 0,
  UU0 => 0,
  UU1 => 0,
}, 'operands of conditional operator promoted correctly');

#---------------------------------------------------------
# make sure that the promotion fix doesn't break anything
#---------------------------------------------------------

$c->clean;

eval {
  $c->parse(<<'END');

#if 1 ? 0 : 1/0
#  error broken
#else
#  define OK
#endif

END
};

is($@, '');
ok($c->defined('OK'), 'branch of conditional operator not evaluated');

#---------------------------------------------------------

$c->clean;

eval {
  $c->parse(<<'END');

#if (1 || 1/0) && !(0 && 2/0)
#  define OK
#else
#  error broken
#endif

END
};

is($@, '');
ok($c->defined('OK'), 'branch of short-circuiting operator not evaluated');

#---------------------------------------------------------

$c->clean;

eval {
  $c->parse(<<'END');

#if 1 + 2 + 3 / 3 == 6 - (1 << 1)
#  define OK
#else
#  error broken
#endif

END
};

is($@, '');
ok($c->defined('OK'), 'arithmetic expressions evaluated correctly');

#---------------------------------------------------------

$c->clean;

eval {
  $c->parse(<<'END');

#if (1 && 3 == 4 - 1 ? 5 - 3 : 7) == 2
#  define OK
#else
#  error broken
#endif

END
};

is($@, '');
ok($c->defined('OK'), 'arithmetic expressions evaluated correctly');

#-------------------------
# tests arithmetic errors
#-------------------------

$c->clean;

eval {
  $c->parse(<<'END');
#if 18446744073709551615U
#endif
END
};

is($@, '');

$c->clean;

eval {
  $c->parse(<<'END');
#if 18446744073709551616U
#endif
END
};

like($@, qr/constant too large/);

#------------------------------
# test StdCVersion and HostedC
#------------------------------

$c = Convert::Binary::C->new;

is($c->StdCVersion, 199901, "StdCVersion default");
is($c->HostedC, 1, "HostedC default");

my $code = <<ENDC;
enum test {
  STDC =
#ifdef __STDC_VERSION__
  __STDC_VERSION__
#else
  -1
#endif
  ,
  HOSTED =
#ifdef __STDC_VERSION__
  __STDC_HOSTED__
#else
  -1
#endif
};
ENDC

$c->clean
  ->configure(StdCVersion => undef, HostedC => undef)
  ->parse($code);

is($c->unpack('test', $c->pack('test', 'STDC')), -1);
is($c->unpack('test', $c->pack('test', 'HOSTED')), -1);

$c->clean
  ->configure(StdCVersion => '4711', HostedC => 0)
  ->parse($code);

is($c->unpack('test', $c->pack('test', 'STDC')), 4711);
is($c->unpack('test', $c->pack('test', 'HOSTED')), 0);

$c->clean
  ->configure(StdCVersion => '199901', HostedC => 1)
  ->parse($code);

is($c->unpack('test', $c->pack('test', 'STDC')), 199901);
is($c->unpack('test', $c->pack('test', 'HOSTED')), 1);


# TODO: more arith checks (errors/warnings)
