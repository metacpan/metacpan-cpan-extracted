# Astro::VO::VOEvent test harness

# strict
use strict;

#load test
use Test::More tests => 12;

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
is( $id, "ivo://talons.lanl/gcn.gsfc#swift/21008463", "comparing ID strings" );

my $role = $object->role( );
is( $role, "observation", "comparing ROLE strings" );

my $version = $object->version( );
is( $version, "1.0", "comparing VERSION strings" );

my $ra = $object->ra( );
is( $ra, "127.2875", "Comparing RA" );

my $dec = $object->dec( );
is( $dec, "73.5508", "Comparing Dec" );

my $ra_return = "\$VAR1 = 'value';\n".
		"\$VAR2 = '127.2875';\n".
		"\$VAR3 = 'units';\n".
		"\$VAR4 = 'deg';\n";
		
my %ra = $object->ra( );
is( Dumper(%ra), $ra_return, "Comparing RA in list context" );


my $dec_return = "\$VAR1 = 'value';\n".
		"\$VAR2 = '73.5508';\n".
		"\$VAR3 = 'units';\n".
		"\$VAR4 = 'deg';\n";
		
my %dec = $object->dec( );
is( Dumper(%dec), $dec_return, "Comparing Dec in list context" );

my $epoch = $object->epoch( );
is( $epoch, "J2000.0", "Comparing Epoch" );

my $equinox = $object->equinox( );
is( $equinox, "2000.0", "Comparing Equinox" );

my $time = $object->time( );
is( $time, "2006-05-15T02:27:52", "Comparing time stamp" );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version = '1.0' encoding = 'UTF-8'?>
<VOEvent xmlns:xlink="http://www.w3.org/1999/xlink" xmlns="http://www.ivoa.net/xml/VOEvent/v1.1" xmlns:schemaLocation=" http://www.ivoa/net/xml/STC/stc-v1.30.xsd http://hea-www.harvard.edu/~arots/nvometa/v1.30/stc-v1.30.xsd http://www.ivoa.net/xml/VOEvent/v1.1 http://www.ivoa.net/internal/IVOA/IvoaVOEvent/VOEvent-v1.1.xsd" role="observation" xmlns:stc="http://www.ivoa.net/xml/STC/stc-v1.30.xsd" version="1.0" id="ivo://talons.lanl/gcn.gsfc#swift/21008463" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" >
 <Citations>
  <EventID cite="followup" >ivo://talons.lanl/gcn.gsfc#swift/21008461</EventID>
 </Citations>
 <Who>
  <PublisherID>ivo://gcn.gsfc/swift/</PublisherID>
  <Date>2006-05-14T20:31:34</Date>
 </Who>
 <What>
  <Param value="63" name="PACKET_TYPE" />
  <Param value="210084" name="TRIG_NO" />
  <Param value="13870" name="BURST_TJD" />
  <Param value="8872.910" name="BURST_SOD" />
  <Group name="Burst Alert Telescope Trigger Details" >
   <Param unit="centi-secs" value="-51.00" name="delta time" />
   <Param url="http://gcn.gsfc.nasa.gov/swift_grbs.html" name="BAT Light curve" />
  </Group>
 </What>
 <WhereWhen>
  <stc:ObsDataLocation>
   <stc:ObservatoryLocation id="CenterOfTheEarth" />
   <stc:ObservationLocation>
    <stc:AstroCoordSystem id="FK5-UTC-TOPO" />
    <stc:AstroCoords coord_system_id="FK5-UTC-TOPO" >
     <stc:Time unit="s" >
      <stc:TimeInstant>
       <stc:ISOTime>2006-05-15T02:27:52</stc:ISOTime>
      </stc:TimeInstant>
     </stc:Time>
     <stc:Position2D unit="deg" >
      <stc:Value2>
       <stc:C1>127.2875</stc:C1>
       <stc:C2>73.5508</stc:C2>
      </stc:Value2>
      <stc:Error2Radius>0.0000</stc:Error2Radius>
     </stc:Position2D>
    </stc:AstroCoords>
   </stc:ObservationLocation>
  </stc:ObsDataLocation>
 </WhereWhen>
 <How>
  <Description>Swift Satellite</Description>
  <Reference uri="http://swift.gsfc.nasa.gov/docs/swift/swiftsc.html" type="url" />
 </How>
 <Why importance="0.0" >
  <Inference probability="0.0" >
   <Concept></Concept>
   <Name>unknown</Name>
  </Inference>
 </Why>
 <Description>
	</Description>
</VOEvent>
