use Config;
$file = @ARGV ? shift : 'examples/convert.pl';
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
#   Parse a C struct and use 'pack', 'unpack', 'sizeof' and 'offsetof'.
#
#===============================================================================

use Convert::Binary::C;
use Data::Dumper;
use strict;

#--------------------------------------------------------------
# Create an object, configure it, and parse some embedded code.
#--------------------------------------------------------------

my $c = Convert::Binary::C->new( LongSize => 4, ShortSize => 2 )
                          ->Alignment( 4 )
                          ->ByteOrder( 'BigEndian' )
                          ->parse( <<'ENDC' );

typedef signed   long  i_32;
typedef unsigned long  u_32;
typedef signed   short i_16;
typedef unsigned short u_16;
typedef signed   char  i_8;
typedef unsigned char  u_8;

struct convert {
  i_8  byte;
  i_16 word[2];
  i_32 dword;
  union {
    u_32 dword;
    u_8  bytes[ sizeof( u_32 ) ];
  }    c32;
};

ENDC

#-----------------------------------------------------------
# Print the offsets and sizes of some of the struct members.
#-----------------------------------------------------------

for( qw( byte word dword ) ) {
  print "offsetof( 'convert', '$_' ) = ", $c->offsetof( 'convert', $_ );
  print ", sizeof( 'convert.$_' ) = ", $c->sizeof( "convert.$_" ), "\n";
}

#-------------------------------------------------
# Pack a Perl data structure into a binary string.
# Note that not all members need to be specified.
#-------------------------------------------------

my $binary = $c->pack( 'convert', {
  word => [-30000, 4711],
  c32  => { dword => 0x01020304 }
} );

#-------------------------------------------------------
# Just a demonstration that pack does the right thing...
#-------------------------------------------------------

if( $c->sizeof( 'convert' ) == length $binary ) {
  print "\nYup, the size matches!\n";
}

#-------------------------------------------------------
# Hexdump the binary string.
# Note that all padding regions are initialized to zero.
#-------------------------------------------------------

print "\nBinary: ", hexdump( $binary ), "\n\n";

#---------------------------------------------------------------
# Unpack the binary string and dump the returned data structure.
#---------------------------------------------------------------

my $data = $c->unpack( 'convert', $binary );
print Data::Dumper->Dump( [$data], ['data'] );

#------------------------------------------------------
# You can modify selected elements in the binary string
# using the 3-argument version of 'pack'.
#------------------------------------------------------

# only 'dword' will be modified
$c->pack( 'convert', { dword => -559038737 }, $binary );
print "\nBinary: ", hexdump( $binary ), "\n\n";
print Dumper( $c->unpack( 'convert', $binary ) );

#--------------------------------------------------
# You can also use pack/unpack on compound members.
#--------------------------------------------------

my $array = $c->unpack( 'convert.c32.bytes', 'ABCD' );
print "\n\$array = [ @$array ]\n";

#==========================================================
#                     SUBROUTINES
#==========================================================

sub hexdump
{
  join ' ', map { sprintf "%02X", $_ } unpack "C*", $_[0];
}
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";

