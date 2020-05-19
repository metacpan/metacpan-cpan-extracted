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

BEGIN { plan tests => 31 }

($code, $tests) = split /-{40,}/, do { local $/; <DATA> }, 2;
@tests = map { chomp; /^\s*(.*?)\s*=>\s*(.*?)\s*$/ ? { name => $1, type => $2 } : () }
         split $/, $tests;

$c = eval { Convert::Binary::C->new };
ok($@,'',"failed to create Convert::Binary::C object");

eval { $c->parse( $code ) };
ok($@,'',"failed to parse C code");

{
  my @warn;
  local $SIG{__WARN__} = sub { push @warn, $_[0] };

  for my $t ( @tests ) {
    ok( $c->typeof($t->{name}), $t->{type} );
  }

  ok( @warn == 0 );
}

__DATA__

typedef unsigned char u_8;
typedef unsigned int  u_32;
typedef unsigned int  ary[10];

struct foo {
  u_8 a;

  union {
    u_32 a, b[10];
    ary  c, d[10], e[4][6];
    char *f, *g[4][8], ****h[1][2][3];
  } b;

  struct {
    u_8            a:1, b:2, c:3;
    u_32           d:4;
    signed short   e:5;
  } c;

  struct {
    int d:16;
    int *e;
  };
};

-------------------------------------------------------------------------------

u_8                             =>  u_8
u_32                            =>  u_32
ary                             =>  ary
foo                             =>  struct foo
foo.a                           =>  u_8

foo.b                           =>  union
foo.b.a                         =>  u_32
foo.b.b                         =>  u_32 [10]
foo.b.b[5]                      =>  u_32
foo.b.c                         =>  ary

foo.b.d                         =>  ary [10]
foo.b.d[5]                      =>  ary
foo.b.e                         =>  ary [4][6]
foo.b.e[2]                      =>  ary [6]
foo.b.e[2][2]                   =>  ary

foo.b.f                         =>  char *
foo.b.g                         =>  char * [4][8]
foo.b.g[2]                      =>  char * [8]
foo.b.g[2][4]                   =>  char *
foo.b.h                         =>  char * [1][2][3]

struct foo.c                    =>  struct
struct foo.c.a                  =>  u_8 :1
struct foo.c.b                  =>  u_8 :2
struct foo.c.c                  =>  u_8 :3
struct foo.c.d                  =>  u_32 :4

struct foo.c.e                  =>  signed short :5
struct foo.d                    =>  int :16
struct foo.e                    =>  int *
