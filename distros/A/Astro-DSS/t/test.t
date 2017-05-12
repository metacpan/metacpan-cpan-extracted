# Astro::DSS test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 3 };

# load modules
use Astro::DSS;
use File::Spec qw / tmpdir /;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# declare file names
my ( $gif_file, $fit_file );

$ENV{"ESTAR_DATA"} = File::Spec->tmpdir();

my $dss_gif = new Astro::DSS( Target => 'HT Cas' );
print "# Connecting to ESO-ECF Archive\n";
$gif_file = $dss_gif->querydb();
print "# Continuing Tests\n";

ok( $gif_file, File::Spec->catfile( $ENV{"ESTAR_DATA"}, 
                                     "dss.01.10.12.9+60.04.35.9.gif" ) );
                                     
my $dss_fit = new Astro::DSS( Target => 'HT Cas',
                              Format => 'FITS' );
print "# Connecting to ESO-ECF Archive\n";
$fit_file = $dss_fit->querydb();
print "# Continuing Tests\n";

ok( $fit_file, File::Spec->catfile( $ENV{"ESTAR_DATA"}, 
                                     "dss.01.10.12.9+60.04.35.9.fits" ) );
                                     
END {
  # clean up after ourselves
  print "# Cleaning up temporary files\n";
  print "# Deleting: $gif_file\n";
  print "# Deleting: $fit_file\n";
  my @list = ( $gif_file, $fit_file );

  unlink(@list); 
}                                           
