# Astro::Aladin::Lowlevel test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 2 };

unless ( defined $ENV{ALADIN_JAR} ) {
  for (1..2) {
    skip("Skiping environment variable \$ALADIN_JAR not defined", 1);
  }
  exit;
}

# load modules
use Astro::Aladin::LowLevel;

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my $aladin = new Astro::Aladin::LowLevel( );

$aladin->get( "SSS.cat", [""], "15 16 06.9 -60 57 26.1", "2arcmin" );
$aladin->status();
$aladin->sync();
ok( $aladin->status() );
$aladin->close();

#$aladin->get( "Aladin", ["DSS1"], "M8"  );
#$aladin->sync();

#$aladin->get( "simbad", "M8" );
#$aladin->status();
#$aladin->sync();

#$aladin->status();
#$aladin->sync();

#$aladin->close();
