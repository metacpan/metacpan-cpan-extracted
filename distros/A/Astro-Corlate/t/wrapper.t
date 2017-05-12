# Astro::Corlate::Wrapper test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 10 };

# load modules
use Astro::Corlate::Wrapper qw / corlate /;
use File::Spec;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# define filenames
my $file_name_1 = File::Spec->catfile(File::Spec->curdir(),'t','archive.cat');
my $file_name_2 = File::Spec->catfile(File::Spec->curdir(),'t','new.cat');
my $file_name_3 = File::Spec->catfile(File::Spec->curdir(),'t','corlate.log');
my $file_name_4 = File::Spec->catfile(File::Spec->curdir(),'t','corlate.cat');
my $file_name_5 = File::Spec->catfile(File::Spec->curdir(),'t','colfit.cat');
my $file_name_6 = File::Spec->catfile(File::Spec->curdir(),'t','colfit.fit');
my $file_name_7 = File::Spec->catfile(File::Spec->curdir(),'t','hist.dat');
my $file_name_8 = File::Spec->catfile(File::Spec->curdir(),'t','info.dat');

my $status = corlate( $file_name_1, $file_name_2, $file_name_3,
                      $file_name_4, $file_name_5, $file_name_6, 
                      $file_name_7, $file_name_8 );

ok( $status, 0 );

# grab comparison data
my @info = <DATA>;
chomp @info;

# grab info file
open(FILE,$file_name_8);
my @file = <FILE>;
chomp @file;

for my $i (0 .. $#info) {
   ok( $file[$i], $info[$i] );
}
  
# clean up after ourselves
print "# Cleaning up temporary files\n";
print "# Deleting: " . $file_name_3 ."\n";
print "# Deleting: " . $file_name_4 ."\n";
print "# Deleting: " . $file_name_5 ."\n";
print "# Deleting: " . $file_name_6 ."\n";
print "# Deleting: " . $file_name_7 ."\n";
print "# Deleting: " . $file_name_8 ."\n";
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
