package Astro::GCN::Util::SWIFT;

=head1 NAME

GCN::Util - utility routines

=head1 SYNOPSIS

  use GCN::Util::SWIFT
    
=head1 DESCRIPTION

This module contains a simple utility routines specific to the SWIFT mission.

=cut

use strict;
use warnings;

require Exporter;

use vars qw/$VERSION @EXPORT_OK @ISA /;

@ISA = qw/Exporter/;
@EXPORT_OK = qw/ convert_soln_status convert_trig_obs_num /;

'$Revision: 1.1.1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


sub convert_soln_status {
   my $soln_status = shift;
   print "Converting soln_status...\n";
        
   print "Repacking into a big-endian long...\n";
   my $bit_string = pack("N", $soln_status );
   
   print "Unpacking to bit string...\n";
   $bit_string = unpack( "B32", $bit_string );

   print "Chopping up the bit string...\n";
   my @bits;
   foreach my $i ( 0 ... 5 ) {
      my $bit = chop( $bit_string );
      push @bits, $bit;
   }
   
   print "Setting status flags...\n";
   
   my %status;
   if ( $bits[0] == 1 ) {
       $status{"point_src"} = 1;
       
   } elsif ( $bits[1] == 1 ) {  
       $status{"grb"} = 1;
       
   } elsif ( $bits[2] == 1 ) { 
       $status{"interesting"} = 1;
       
   } elsif ( $bits[3] == 1 ) { 
       $status{"catalog_src"} = 1;
       
   } elsif ( $bits[4] == 1 ) { 
       $status{"image_trig"} = 1;
       
   } elsif ( $bits[5] == 1 ) {   
       $status{"def_not_grb"} = 1;
   }          

   return %status;
}

sub convert_trig_obs_num {
   my $trig_obs_num = shift;
   print "Converting trig_obs_num...\n";
        
   print "Repacking into a big-endian long...\n";
   my $bit_string = pack("N", $trig_obs_num );
   
   print "Unpacking to bit string...\n";
   $bit_string = unpack( "B32", $bit_string );
   #print "bit_string = $bit_string\n";

   print "Chopping up the bit string...\n";
   my @bits;
   foreach my $i ( 0 ... 32 ) {
      my $bit = chop( $bit_string );
      push @bits, $bit;
   }   
   
   # TRIGGER NUMBER
   # --------------
   print "Repacking first 24 bits into a bit string..\n";
   my ( $lower_24_byte1, $lower_24_byte2, $lower_24_byte3 );
   foreach my $j ( 0 ... 7 ) {
      $lower_24_byte1 = $lower_24_byte1 . "$bits[$j]";
      $lower_24_byte2 = $lower_24_byte2 . "$bits[$j+8]";
      $lower_24_byte3 = $lower_24_byte3 . "$bits[$j+16]";
   }   
   
   print "Lower 3 bytes: $lower_24_byte1 $lower_24_byte2 $lower_24_byte3\n";

   $lower_24_byte1 = pack("b8", $lower_24_byte1 );
   $lower_24_byte2 = pack("b8", $lower_24_byte2 );
   $lower_24_byte3 = pack("b8", $lower_24_byte3 );

   $lower_24_byte1 = unpack( "C", $lower_24_byte1 );
   $lower_24_byte2 = unpack( "C", $lower_24_byte2 );
   $lower_24_byte3 = unpack( "C", $lower_24_byte3 );
   
   my $trig_num = $lower_24_byte1 + ( $lower_24_byte2*256) + 
               ( $lower_24_byte3*256*256 );

   print "Trigger Num. = $trig_num\n";

   # OBS NUMBER
   # ----------
   print "Repacking upper 8 bits into a bit string..\n";
   my $upper_8;
   foreach my $j ( 24 ... 32 ) {
      $upper_8 = $upper_8 . "$bits[$j]";
   } 
   
   print "Upper byte: $upper_8\n";  
   my $obs_num = pack("b8", $upper_8 );
   $obs_num = unpack( "C", $obs_num );

   print "Obs. Num. = $obs_num\n";
 
   # RETURN results  
   return ( $trig_num, $obs_num );
}
   
   
=back

=head1 REVISION

$Id: SWIFT.pm,v 1.1.1.1 2005/05/03 19:23:00 voevent Exp $

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Particle Physics and Astronomy Research
Council. All Rights Reserved.

=cut

1;
