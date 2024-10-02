use Config;
$file = @ARGV ? shift : 'examples/memmap.pl';
open OUT, ">$file" or die "Can't create $file: $!";
print OUT <<"!GROK!THIS!";
$Config{startperl} -w
!GROK!THIS!
print OUT <<'!NO!SUBS!';
################################################################################
#
# Copyright (c) 2002-2024 Marcus Holland-Moritz. All rights reserved.
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
################################################################################

#===============================================================================
#
#   Print a simple memory map of a structure.
#
#===============================================================================

use Convert::Binary::C;
use Data::Dumper;
use strict;

#-----------------------------------------------------
# Create an object, configure it, and parse some code.
#-----------------------------------------------------

my $c = Convert::Binary::C->new( PointerSize => 4,
                                 LongSize    => 4,
                                 ShortSize   => 2,
                                 Alignment   => 4 )
                          ->parse( <<'ENDC' );

typedef unsigned long u_32;

typedef struct _LinkedList * LinkedList;
typedef struct _HashTable * HashTable;

typedef struct {
  enum {
    BO_BIG_ENDIAN,
    BO_LITTLE_ENDIAN
  } bo;
} ArchSpecs;

typedef struct {
  char *buffer;
  long  pos, length;
} Buffer;

typedef struct {
  unsigned    alignment;
  unsigned    int_size;
  unsigned    short_size;
  unsigned    long_size;
  unsigned    long_long_size;
  int         enum_size;
  unsigned    ptr_size;
  unsigned    float_size;
  unsigned    double_size;
  unsigned    long_double_size;
  u_32        flags;
  u_32        keywords;
  LinkedList  disabled_keywords;
  LinkedList  includes;
  LinkedList  defines;
  LinkedList  assertions;
  HashTable   keyword_map;
} CParseConfig;

typedef struct {
  LinkedList  enums;
  LinkedList  structs;
  LinkedList  typedef_lists;
  HashTable   htEnumerators;
  HashTable   htEnums;
  HashTable   htStructs;
  HashTable   htTypedefs;
  HashTable   htFiles;
  char       *errstr;
} CParseInfo;

typedef struct {
  char         *bufptr;
  unsigned      alignment;
  unsigned      align_base;
  int           dataTooShortFlag;
  Buffer        buf;
  CParseConfig  cfg;
  CParseInfo    cpi;
  ArchSpecs     as;
  enum {
    ET_INTEGER, ET_STRING, ET_BOTH
  }             enumType;
} CBC;

ENDC

#-------------------------------------------------
# Print the memory map for type 'CBC' with a base
# address of 0x01500000.
#-------------------------------------------------

memmap( $c, 'CBC', 0x01500000 );

#==========================================================
#                     SUBROUTINES
#==========================================================

sub memmap
{
  my($c, $type, $start) = @_;
  $start ||= 0;

  my $afmt = '%0' . 2*$c->PointerSize . 'X';

  for my $offset ( 0 .. $c->sizeof( $type ) - 1 ) {
    my $m = $c->member( $type, $offset );
    rindex( $m, '+' ) < 0 or next;
    my $t = $c->typeof( $type.$m );
    printf "$afmt  %-16s  %s\n", $start+$offset, $t, $m;
  }
}
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";

