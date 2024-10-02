use Config;
$file = @ARGV ? shift : 'examples/perltypes.pl';
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
#   Parse perl's header files and play around with the types they define.
#
#===============================================================================

use Convert::Binary::C;
use Data::Dumper;
use File::Spec::Functions qw(rel2abs);
use strict;

my $base;
-d "$_/include" and $base = rel2abs("$_/include") and last for qw( tests ../tests );
defined $base or die <<MSG;
Please run this script from either the 'examples' directory
or the distribution base directory.
MSG

#-------------------------------------
# Create an object, set configuration.
#-------------------------------------

my $cfg = require "$base/config.pl";
my $c = new Convert::Binary::C %$cfg;

#------------------
# Parse the C file.
#------------------

eval { $c->parse_file( "$base/include.c" ) };

#-----------------------
# Check for parse error.
#-----------------------

if( $@ ) {
  die "Parse error: $@";
}

#----------------------------
# Dump out the configuration.
#----------------------------

print Dumper( $c->configure );

#----------------------------
# Print all the enumerations.
#----------------------------

my @enums = $c->enum_names;
print "\nenums: @enums\n\n";

#---------------------------------------------------------------------------
# Print all structs, sorted by size; skip all structs smaller than 50 bytes.
#---------------------------------------------------------------------------

print "large structs:\n\n";

my @structs = sort { $c->sizeof( $b ) <=> $c->sizeof( $a ) }
              grep { $c->sizeof( $_ ) >= 50 }
              $c->struct_names;

for my $struct ( @structs ) {
  printf "struct %-20s => %4d bytes\n", $struct, $c->sizeof( $struct );
}

print "\n";

#-----------------------------------------------
# Dump the definition of the __socket_type enum
#-----------------------------------------------

print Data::Dumper->Dump( [$c->enum('__socket_type')], ['__socket_type'] );
!NO!SUBS!

close OUT or die "Can't close $file: $!";
chmod 0755, $file or die "Can't reset permissions for $file: $!\n";

