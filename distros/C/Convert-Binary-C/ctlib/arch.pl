################################################################################
#
# PROGRAM: arch.pl
#
################################################################################
#
# DESCRIPTION: Generate header file for architecture specific definitions
#
################################################################################
#
# Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

use Config;

$file = @ARGV ? shift : 'ctlib/arch.h';
open OUT, ">$file" or die "$file: $!\n";

%cfg = %Config;  # because we modify some values in %cfg

%use = (
  '64BIT'      => 1,
  'LONGLONG'   => 1,
  'LONGDOUBLE' => 1,
);

if( $Config{osname} eq 'hpux' and $Config{cc} eq 'cc' and
    $Config{osvers} =~ /(\d+)\.(\d+)/ and $1 < 11 ) {
  # At least some versions of HP's cc compiler have a broken
  # preprocessor/compiler implementation of 64-bit data types.
  $use{'64BIT'}    = 0;
  $use{'LONGLONG'} = 0;
}

for( keys %use ) {
  exists $ENV{"CBC_USE$_"} and $use{$_} = $ENV{"CBC_USE$_"};
}

# <HACK> required to support perl < 5.6.0

unless( exists $cfg{i8type} ) {
  $b8 = 'char';

  for( qw( int short long ) ) {
    if( not defined $b16 and $cfg{"${_}size"} == 2 ) { $b16 = $_ }
    if( not defined $b32 and $cfg{"${_}size"} == 4 ) { $b32 = $_ }
  }

  defined $b16 and defined $b32 or die "cannot determine integer sizes";

  $cfg{i8type}  = "signed $b8";
  $cfg{u8type}  = "unsigned $b8";
  $cfg{i16type} = "signed $b16";
  $cfg{u16type} = "unsigned $b16";
  $cfg{i32type} = "signed $b32";
  $cfg{u32type} = "unsigned $b32";
}

# </HACK>

# make the i_8 explicitly signed
# (i8type was plain 'char' on an IPAQ system where 'char' was unsigned)
if( $cfg{i8type} eq 'char' ) {
  $cfg{i8type} = 'signed char';
}

sub is_big_endian ()
{
  my $byteorder = $cfg{byteorder}
               || unpack( "a*", pack "L", 0x34333231 );

  die "Native byte order ($byteorder) not supported!\n"
      if   $byteorder ne '1234'     and $byteorder ne '4321'
       and $byteorder ne '12345678' and $byteorder ne '87654321';

  $byteorder eq '4321' or $byteorder eq '87654321';
}

sub config ($) {
  local $_ = shift;
  s/\$\{([^}]+)\}/$cfg{$1}/g;
  print OUT;
}

$long_double = $use{LONGDOUBLE} && $cfg{d_longdbl} eq 'define' ? 1 : 0;
print "DISABLED long double support\n" if $use{LONGDOUBLE} == 0;

$long_long = $use{LONGLONG} && $cfg{d_longlong} eq 'define' ? 1 : 0;
print "DISABLED long long support\n" if $use{LONGLONG} == 0;

config <<ENDCFG;
#ifndef _CTLIB_ARCH_H
#define _CTLIB_ARCH_H

#define ARCH_HAVE_LONG_DOUBLE        $long_double
#define ARCH_HAVE_LONG_LONG          $long_long
ENDCFG

if( $use{'64BIT'} && $cfg{d_quad} eq 'define' ) {
config <<'ENDCFG';
#define ARCH_NATIVE_64_BIT_INTEGER   1

/* 64-bit integer data types */
typedef ${i64type} i_64;
typedef ${u64type} u_64;

ENDCFG
}
elsif( $use{'64BIT'} && $cfg{d_longlong} eq 'define' and $cfg{longlongsize} == 8 ) {
config <<'ENDCFG';
#define ARCH_NATIVE_64_BIT_INTEGER   1

/* 64-bit integer data types */
typedef signed long long i_64;
typedef unsigned long long u_64;

ENDCFG
}
else {
  print "DISABLED 64-bit support\n" if $use{'64BIT'} == 0;
config <<'ENDCFG';
#define ARCH_NATIVE_64_BIT_INTEGER   0

/* no native 64-bit support */
typedef struct {
  ${u32type} h;
  ${u32type} l;
} u_64;

typedef struct {
  ${i32type} h;
  ${u32type} l;
} i_64;

ENDCFG
}

$byteorder = is_big_endian ? 'BIG' : 'LITTLE';

config <<"ENDCFG";
#define ARCH_BYTEORDER_BIG_ENDIAN    1
#define ARCH_BYTEORDER_LITTLE_ENDIAN 2
#define ARCH_NATIVE_BYTEORDER        ARCH_BYTEORDER_${byteorder}_ENDIAN 

ENDCFG

config <<'ENDCFG';
/* 32-bit integer data types */
typedef ${i32type} i_32;
typedef ${u32type} u_32;

/* 16-bit integer data types */
typedef ${i16type} i_16;
typedef ${u16type} u_16;

/* 8-bit integer data types */
typedef ${i8type} i_8;
typedef ${u8type} u_8;

ENDCFG

config <<'ENDCFG';
#endif
ENDCFG

close OUT;
