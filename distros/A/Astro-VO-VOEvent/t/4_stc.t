# Astro::VO::VOEvent test harness

# strict
use strict;

#load test
use Test::More tests => 14;

# load modules
BEGIN {
   use_ok("Astro::VO::VOEvent");
}

# debugging
use Data::Dumper;

# T E S T   H A R N E S S --------------------------------------------------

# test the test system
ok(1);

# read from data block
my @buffer = <DATA>;
chomp @buffer;  

my $xml = "";
foreach my $i ( 0 ... $#buffer ) {
   $xml = $xml . $buffer[$i];
}   

my $object = new Astro::VO::VOEvent( XML => $xml );

my $id = $object->id( );
is( $id, "ivo://raptor.lanl/VOEvent#23565", "comparing ID strings" );

my $role = $object->role( );
is( $role, "observation", "comparing ROLE strings" );

my $version = $object->version( );
is( $version, "1.0", "comparing VERSION strings" );


my $description = $object->description( );
is( $description, undef, "comparing <Description>" );

my $ra = $object->ra( );
is( $ra, "148.88", "Comparing RA" );

my $dec = $object->dec( );
is( $dec, "69.06", "Comparing Dec" );

my $ra_return = "\$VAR1 = 'value';\n".
		"\$VAR2 = '148.88';\n".
		"\$VAR3 = 'units';\n".
		"\$VAR4 = 'deg';\n";
		
my %ra = $object->ra( );
is( Dumper(%ra), $ra_return, "Comparing RA in list context" );


my $dec_return = "\$VAR1 = 'value';\n".
		"\$VAR2 = '69.06';\n".
		"\$VAR3 = 'units';\n".
		"\$VAR4 = 'deg';\n";
		
my %dec = $object->dec( );
is( Dumper(%dec), $dec_return, "Comparing Dec in list context" );

my $epoch = $object->epoch( );
is( $epoch, "J2000.0", "Comparing Epoch" );

my $equinox = $object->equinox( );
is( $equinox, "2000.0", "Comparing Equinox" );

my $what_return = 
     "\$VAR1 = 'Param';\n".
     "\$VAR2 = {\n".
     "          'unit' => 'arcsec',\n".
     "          'value' => '2',\n".
     "          'name' => 'seeing',\n".
     "          'ucd' => 'instr.obsty.site.seeing'\n".
     "        };\n".
     "\$VAR3 = 'Reference';\n".
     "\$VAR4 = {\n".
     "          'uri' => 'http://raptor.lanl.gov/data/lightcurves/235649409'\n".
     "        };\n".
     "\$VAR5 = 'Description';\n".
     "\$VAR6 = 'This is the light curve associated with the observation.';\n".
     "\$VAR7 = 'Group';\n".
     "\$VAR8 = {\n".
     "          'Param' => {\n".
     "                     'peak' => {\n".
     "                               'unit' => 'ct/s',\n".
     "                               'value' => '1310',\n".
     "                               'ucd' => 'arith.rate;phot.count'\n".
     "                             },\n".
     "                     'counts' => {\n".
     "                                 'unit' => 'ct',\n".
     "                                 'value' => '73288',\n".
     "                                 'ucd' => 'phot.count'\n".
     "                               }\n".
     "                   },\n".
     "          'name' => 'SQUARE_GALAXY_FLUX'\n".
     "        };\n";
		
my %what = $object->what( );
is( Dumper(%what), $what_return, "Comparing <What> in list context" );

my $time = $object->time( );
is( $time, "2005-04-15T23:59:59", "Comparing time stamp" );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="UTF-8"?>
<VOEvent id="ivo://raptor.lanl/VOEvent#23565" role="observation" version="1.0"
  xmlns="http://www.ivoa.net/xml/VOEvent/v1.0"
  xmlns:stc="http://www.ivoa.net/xml/STC/stc-v1.20.xsd"
  xmlns:crd="http://www.ivoa.net/xml/STC/STCcoords/v1.20"
    
  xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"  xsi:schemaLocation=
    "http://www.ivoa.net/xml/STC/stc-v1.20.xsd    http://hea-www.harvard.edu/~arots/nvometa/v1.2/stc-v1.20.xsd
    http://www.ivoa.net/xml/STC/STCcoords/v1.20   http://hea-www.harvard.edu/~arots/nvometa/v1.2/coords-v1.20.xsd
    http://www.ivoa.net/xml/VOEvent/v1.0          http://www.ivoa.net/internal/IVOA/IvoaVOEvent/VOEvent-v1.0.xsd">
    
  <Citations>
    <EventID cite="followup">ivo://raptor.lanl/VOEvent#23563</EventID>
    <Description>
      An observation that follows up an earlier event with
      improved square-galaxy discrimination
    </Description>
  </Citations>
    
  <Who>
      <PublisherID>ivo://raptor.lanl/organization</PublisherID>
      <Contact principalContact="true">
	<Name>Robert White</Name>
	<Institution>LANL</Institution>
	<Communication>
	  <AddressLine> Los Alamos National Laboratory PO Box 1663 ISR-1,
	    MS B244 Los Alamos, NM 87545 </AddressLine>
	  <Telephone>+1-505-665-3025</Telephone>
	  <Email>rwhite@lanl.gov</Email>
	</Communication>
      </Contact>
      <Date>2005-04-15T14:34:16</Date>
  </Who>
    
  <What>
    <Group name="SQUARE_GALAXY_FLUX">
      <Param name="counts" value="73288" unit="ct" ucd="phot.count"/>
      <Param name="peak" value="1310" unit="ct/s" ucd="arith.rate;phot.count"/>
    </Group>
    <Param name="seeing" value="2" unit="arcsec" ucd="instr.obsty.site.seeing"/>
    <Reference uri="http://raptor.lanl.gov/data/lightcurves/235649409"/>
    <Description>This is the light curve associated with the observation.</Description>
  </What>
    
  <WhereWhen>
    <stc:ObservationLocation>
      <stc:AstroCoordSystem ID="FK5-UTC-TOPO">
	<stc:TimeFrame>
	  <stc:Name>Time</stc:Name>
	  <stc:TimeScale>UTC</stc:TimeScale>
	  <stc:TOPOCENTER/>
	</stc:TimeFrame>
	<stc:SpaceFrame>
	  <stc:Name>Equatorial</stc:Name>
	  <stc:FK5><stc:Equinox>J2000.0</stc:Equinox></stc:FK5>
	  <stc:TOPOCENTER/>
	  <stc:SPHERICAL coord_naxes="2"/>
	</stc:SpaceFrame>
      </stc:AstroCoordSystem>
      <crd:AstroCoords coord_system_id="FK5-UTC-TOPO">
	<crd:Time unit="s">
	  <crd:TimeInstant>
	    <crd:ISOTime>2005-04-15T23:59:59</crd:ISOTime>
	  </crd:TimeInstant>
	  <crd:Error>1.0</crd:Error>
	</crd:Time>
	<crd:Position2D unit="deg">
	  <crd:Value2>148.88 69.06</crd:Value2>
	  <crd:Error2PA>
	    <crd:Size>0.02 0.01</crd:Size>
	    <crd:PosAngle reference="North">15</crd:PosAngle>
	  </crd:Error2PA>
	</crd:Position2D>
      </crd:AstroCoords>
    </ObservationLocation>
  </WhereWhen>
    
  <How>
    <Reference uri="http://www.raptor.lanl.gov/documents/phase_zero.rtml"
      type="rtml" name="Raptor AB"/>
    <Description>
      This VOEvent resulted from observations made with Raptor AB at Los Alamos.
    </Description>
  </How>
    
  <Why importance="0.8" expires="2005-04-16T02:34:16">
    <Concept>Fast Orphan Optical Transient</Concept>
    <Inference relation="associated">
      <Name>NGC1234</Name>
    </Inference>
  </Why>
</VOEvent>
