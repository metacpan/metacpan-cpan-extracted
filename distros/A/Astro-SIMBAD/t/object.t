# Astro::SIMBAD::Result::Object test harness

# strict
use strict;

#load test
use Test;
BEGIN { plan tests => 25 };

# load modules
use Astro::SIMBAD::Result::Object;
#use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

my( $name, $type, $long_type, @system, $ra, $dec, $spec, $url );

# HT Cas FK5 2000/2000
$name = "V* HT Cas";
$type = "DN*";
$long_type = "Dwarf Nova";
$system[0] = "FK5";
$system[1] = 2000.0;
$system[2] = 2000.0;
$ra = "01 10 12.98";
$dec = "+60 04 35.9";
$spec = "M5.2";
$url="http://simbad.u-strasbg.fr/sim-id.pl?Ident=V%2A%20HT%20Cas&Epoch1=2000%2E0&Epoch2=1950%2E0&Epoch3=2000%2E0&output%2Emes=o%2Ecatall%2C&NbIdent=1&output%2Emax=all&Equi1=2000%2E0&Equi2=1950%2E0&FrameList=FK5&Equi3=2000%2E0&Radius=10&EpochList=2000&CooFrame=FK5&Bibyear1=1983&EquiList=2000&CooEpoch=2000&Bibyear2=2001&protocol=html&output%2Emesdisp=A&CooEqui=2000&Radius%2Eunit=arcsec&Frame1=FK5&Frame2=FK4&%2Dsource=simbad&Frame3=none";

my $htcas = new Astro::SIMBAD::Result::Object( Name   => $name,
                                               Type   => $type,
                                               Long   => $long_type,
                                               Frame => \@system,
                                               RA     => $ra,
                                               Dec    => $dec,
                                               Spec   => $spec,
                                               URL    => $url );

#print Dumper($htcas);

# compare stuff
ok( $htcas->name(), $name );
ok( $htcas->type(), $type );
ok( $htcas->long(), $long_type );
ok( $htcas->frame(), "FK5 2000/2000" );
ok( $htcas->ra(), $ra );
ok( $htcas->dec(), $dec );
ok( $htcas->spec(), $spec );
ok( $htcas->url(), $url );

# IP Peg FK4 1950/1950
$name = "V* IP Peg";
$type = "DN*";
$long_type = "Dwarf Nova";
$system[0] = "FK4";
$system[1] = 1950.0;
$system[2] = 1950.0;
$ra = "23 20 38.48";
$dec = "+18 08 31.0";
$spec = "M2";
$url="http://simbad.u-strasbg.fr/sim-id.pl?Ident=V%2A%20IP%20Peg&Epoch1=2000%2E0&Epoch2=1950%2E0&Epoch3=2000%2E0&output%2Emes=o%2Ecatall%2C&NbIdent=1&output%2Emax=all&Equi1=2000%2E0&Equi2=1950%2E0&FrameList=FK5&Equi3=2000%2E0&Radius=10&EpochList=2000&CooFrame=FK5&Bibyear1=1983&EquiList=2000&CooEpoch=2000&Bibyear2=2001&protocol=html&output%2Emesdisp=A&CooEqui=2000&Radius%2Eunit=arcsec&Frame1=FK5&Frame2=FK4&%2Dsource=simbad&Frame3=none";

my $ippeg1950 = new Astro::SIMBAD::Result::Object( Name   => $name,
                                                   Type   => $type,
                                                   Long   => $long_type,
                                                   Frame => \@system,
                                                   RA     => $ra,
                                                   Dec    => $dec,
                                                   Spec   => $spec,
                                                   URL    => $url );


#print Dumper($ippeg1950);

# compare stuff
ok( $ippeg1950->name(), $name );
ok( $ippeg1950->type(), $type );
ok( $ippeg1950->long(), $long_type );
ok( $ippeg1950->frame(), "FK4 1950/1950" );
ok( $ippeg1950->ra(), $ra );
ok( $ippeg1950->dec(), $dec );
ok( $ippeg1950->spec(), $spec );
ok( $ippeg1950->url(), $url );

# IP Peg FK5 2000/2000
$name = "V* IP Peg";
$type = "DN*";
$long_type = "Dwarf Nova";
$system[0] = "FK5";
$system[1] = 2000.0;
$system[2] = 2000.0;
$ra = "23 23 08.60";
$dec = "+18 24 59.4";
$spec = "M2";
$url="http://simbad.u-strasbg.fr/sim-id.pl?Ident=V%2A%20IP%20Peg&Epoch1=2000%2E0&Epoch2=1950%2E0&Epoch3=2000%2E0&output%2Emes=o%2Ecatall%2C&NbIdent=1&output%2Emax=all&Equi1=2000%2E0&Equi2=1950%2E0&FrameList=FK5&Equi3=2000%2E0&Radius=10&EpochList=2000&CooFrame=FK5&Bibyear1=1983&EquiList=2000&CooEpoch=2000&Bibyear2=2001&protocol=html&output%2Emesdisp=A&CooEqui=2000&Radius%2Eunit=arcsec&Frame1=FK5&Frame2=FK4&%2Dsource=simbad&Frame3=none";

my $ippeg2000 = new Astro::SIMBAD::Result::Object( Name   => $name,
                                                   Type   => $type,
                                                   Long   => $long_type,
                                                   Frame => \@system,
                                                   RA     => $ra,
                                                   Dec    => $dec,
                                                   Spec   => $spec,
                                                   URL    => $url );

#print Dumper($ippeg2000);

# compare stuff
ok( $ippeg2000->name(), $name );
ok( $ippeg2000->type(), $type );
ok( $ippeg2000->long(), $long_type );
ok( $ippeg2000->frame(), "FK5 2000/2000" );
ok( $ippeg2000->ra(), $ra );
ok( $ippeg2000->dec(), $dec );
ok( $ippeg2000->spec(), $spec );
ok( $ippeg2000->url(), $url );


# Time at the bar...

exit;
