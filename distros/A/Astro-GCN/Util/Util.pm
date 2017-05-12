package Astro::GCN::Util;

=head1 NAME

GCN::Util - utility routines

=head1 SYNOPSIS

  use GCN::Util
    
=head1 DESCRIPTION

This module contains a simple utility routines which are mission independant.

=cut

use strict;
use warnings;

require Exporter;

use vars qw/$VERSION @EXPORT_OK @ISA /;

@ISA = qw/Exporter/;
@EXPORT_OK = qw/ convert_ra_to_sextuplets 
                 convert_dec_to_sextuplets 
                 convert_burst_error_to_arcmin
                 convert_ra_to_degrees 
                 convert_dec_to_degrees 
                 convert_burst_error_to_degrees /;

'$Revision: 1.1.1.1 $ ' =~ /.*:\s(.*)\s\$/ && ($VERSION = $1);


sub convert_ra_to_sextuplets {
   my $ra = shift;   
      
   # convert RA to sextuplets
   print "Converting R.A. to sextuplets...\n";
   my $ra_deg = $ra/10000.0;
   $ra_deg = $ra_deg/15.0;
   my $period = index( $ra_deg, ".");
   my $length = length( $ra_deg );
   my $ra_min = substr( $ra_deg, -($length-$period-1));
   $ra_min = "0." . $ra_min;
   $ra_min = $ra_min*60.0;  
   $ra_deg = substr( $ra_deg, 0, $period);
   $period = index( $ra_min, ".");
   $length = length( $ra_min );         
   my $ra_sec = substr( $ra_min, -($length-$period-1));
   $ra_sec = "0." . $ra_sec;
   $ra_sec = $ra_sec*60.0;
   $ra_min = substr( $ra_min, 0, $period); 
   
   $ra = "$ra_deg $ra_min $ra_sec";
 
   return $ra;
}
   
sub convert_dec_to_sextuplets {
   my $dec = shift;   

   print "Converting Declination to sextuplets...\n";
      
   # repack Dec
   print "Repacking declination into a big-endian long...\n";
   $dec = pack("N", $dec );
   print "Repacking declination into a small-endian long...\n";
   $dec = pack("V", unpack( "N", $dec ) );
   
   $dec = unpack( "l", $dec);
   print "Unpacking to signed long integer ($dec)...\n";   
   
   # convert Dec to sextuplets
   print "Converting to sextuplets...\n";
   my $dec_deg = $dec;
   $dec_deg = $dec_deg/10000.0;
   my $sign = "pos";
   if ( $dec_deg =~ "-" ) {
      $dec_deg =~ s/-//;
      $sign = "neg";
   }
   my $period = index( $dec_deg, ".");
   my $length = length( $dec_deg );
   my $dec_min = substr( $dec_deg, -($length-$period-1));
   $dec_min = "0." . $dec_min;
   $dec_min = $dec_min*60.0;
   $dec_deg = substr( $dec_deg, 0, $period);
   $period = index( $dec_min, ".");
   $length = length( $dec_min );
   my $dec_sec = substr( $dec_min, -($length-$period-1));
   $dec_sec = "0." . $dec_sec;
   $dec_sec = $dec_sec*60.0;
   $dec_min = substr( $dec_min, 0, $period);
   if( $sign eq "neg" ) {
      $dec_deg = "-" . $dec_deg;
   }
   
   $dec = "$dec_deg $dec_min $dec_sec";                 
  
   return $dec;
}

sub convert_burst_error_to_arcmin {
   my $error = shift;   
      
   print "Converting error to arcminutes...\n";
   $error = ($error*60.0)/10000.0;  
  
   return $error;
} 

sub convert_ra_to_degrees {
   my $ra = shift;   
      
   # convert RA to sextuplets
   print "Converting R.A. to sextuplets...\n";
   my $ra_deg = $ra/10000.0;
   $ra_deg = $ra_deg/15.0;

 
   return $ra_deg;
}
   
sub convert_dec_to_degrees {
   my $dec = shift;   

   print "Converting Declination to sextuplets...\n";
      
   # repack Dec
   print "Repacking declination into a big-endian long...\n";
   $dec = pack("N", $dec );
   print "Repacking declination into a small-endian long...\n";
   $dec = pack("V", unpack( "N", $dec ) );
   
   $dec = unpack( "l", $dec);
   print "Unpacking to signed long integer ($dec)...\n";   
   
   # convert Dec to sextuplets
   print "Converting to sextuplets...\n";
   my $dec_deg = $dec;
   $dec_deg = $dec_deg/10000.0;
  
   return $dec_deg;
}

sub convert_burst_error_to_degrees {
   my $error = shift;   
      
   print "Converting error to arcminutes...\n";
   $error = $error/10000.0;  
  
   return $error;
} 

  
=back

=head1 REVISION

$Id: Util.pm,v 1.1.1.1 2005/05/03 19:23:00 voevent Exp $

=head1 AUTHORS

Alasdair Allan E<lt>aa@astro.ex.ac.ukE<gt>

=head1 COPYRIGHT

Copyright (C) 2003 Particle Physics and Astronomy Research
Council. All Rights Reserved.

=cut

1;
