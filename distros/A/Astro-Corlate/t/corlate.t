# Astro::Corlate test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 9 };

# load modules
use Astro::Corlate;

# debugging
#use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# Set the eSTAR data directory to point to /tmp
$ENV{"ESTAR_DATA"} = File::Spec->tmpdir();

# Catalogue Files
my $ref = File::Spec->catfile(File::Spec->curdir(),'t','archive.cat');
my $obs = File::Spec->catfile(File::Spec->curdir(),'t','new.cat');

my $corlate = new Astro::Corlate( Reference   =>  $ref,
                                  Observation =>  $obs );
$corlate->run_corlate();

# grab comparison data
my @info = <DATA>;
chomp @info;

# grab info file
open(FILE, $corlate->information());
my @file = <FILE>;
chomp @file;

# check info file has the right values
for my $i (0 .. $#info) {
   ok( $file[$i], $info[$i] );
}

# CLEAN UP
END {
  # get the log file
  my $log = $corlate->logfile();
  
  # get the variable star catalogue
  my $var = $corlate->variables();
  
  # fitted colour data catalogue
  my $dat = $corlate->data();
  
  # fit to the colour data
  my $fit = $corlate->fit();
  
  # get probability histogram file
  my $his = $corlate->histogram();
  
  # get the useful information file
  my $inf = $corlate->information();
  
  # clean up after ourselves
  print "# Cleaning up temporary files\n";
  print "# Deleting: " . $log ."\n";
  print "# Deleting: " . $var ."\n";
  print "# Deleting: " . $dat ."\n";
  print "# Deleting: " . $fit ."\n";
  print "# Deleting: " . $his ."\n";
  print "# Deleting: " . $inf ."\n";
 
  # unlink the files
  my @list = ( $log, $var, $dat, $fit, $his, $inf );
  unlink(@list); 
}         

exit;

# --------------------------------------------------------------------------

__DATA__
   0.0000000E+00 ! Mean separation in arcsec of stars successfully paired.
 !! Begining of new star description.
 K  ! Filter observed in.
  -1.1235368 ! Increase brightness in magnitudes.
   2.7586227E-02 ! Error in above.
   9.5367432E-06 ! False alarm probability.
 21 42  42.7999992 ! Target RA from archive catalogue.
 43 35   9.8999996 ! Target Declination from archive catalogue.
