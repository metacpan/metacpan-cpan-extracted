# Astro::VO::VOEvent test harness

# strict
use strict;

#load test
use Test::More tests => 8;

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
is( $id, "ivo://gcn.gsfc/swift/16426867a", "comparing ID strings" );

my $role = $object->role( );
is( $role, "discovery", "comparing ROLE strings" );

my $version = $object->version( );
is( $version, "1.0", "comparing VERSION strings" );

my $description = $object->description( );
is( $description, undef, "comparing <Description>" );

my $ra = $object->ra( );
is( $ra, "228.3906", "Comparing RA" );

my $dec = $object->dec( );
is( $dec, "30.8728", "Comparing Dec" );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version = '1.0' encoding = 'UTF-8'?>
<VOEvent xmlns="http://www.ivoa.net/xml/VOEvent/v1.0" xmlns:schemaLocation="http://www.ivoa.net/xml/STC/stc-v1.20.xsd http://hea-www.harvard.edu/~arots/nvometa/v1.2/stc-v1.20.xsd http://www.ivoa.net/xml/STC/STCcoords/v1.20 http://hea-www.harvard.edu/~arots/nvometa/v1.2/coords-v1.20.xsd http://www.ivoa.net/xml/VOEvent/v1.0 http://www.ivoa.net/internal/IVOA/IvoaVOEvent/VOEvent-v1.0.xsd" role="discovery" xmlns:stc="http://www.ivoa.net/xml/STC/stc-v1.20.xsd" version="1.0" id="ivo://gcn.gsfc/swift/16426867a" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns:crd="http://www.ivoa.net/xml/STC/STCcoords/v1.20" >
 <Citations>
  <EventID cite="supersedes" >ivo://gcn.gsfc/swift/16426867</EventID>
  <EventID cite="supersedes" >ivo://gcn.gsfc/swift/16426861a</EventID>
  <EventID cite="supersedes" >ivo://gcn.gsfc/swift/16426861</EventID>
 </Citations>
 <Who>
  <PublisherID>ivo://gcn.gsfc/swift/</PublisherID>
  <Date>2005-11-17T03:53:44</Date>
 </Who>
 <What>
  <Param value="67" name="PACKET_TYPE" />
  <Param value="164268" name="TRIG_NO" />
  <Param value="13691" name="BURST_TJD" />
  <Param value="39187.500" name="BURST_SOD" />
  <Group name="X-Ray Telescope Trigger Details" >
   <Param units="pixel intesity" value="99.9999" name="burst flux" />
  </Group>
 </What>
 <WhereWhen type="simple" >
  <Ra units="deg" >
   <Coord>228.3906</Coord>
   <Error units="deg" value="0.0016" />
  </Ra>
  <Dec units="deg" >
   <Coord>30.8728</Coord>
   <Error units="deg" value="0.0016" />
  </Dec>
  <Epoch value="2000" />
  <Equinox value="J2000.0" />
  <Time>
   <Value>2005-11-17T10:53:07</Value>
   <Error units="sec" value="0.0" />
  </Time>
 </WhereWhen>
 <How>
   <Reference url="http://swift.gsfc.nasa.gov/docs/swift/swiftsc.html" />
 </How>
 <Why importance="0.3" >
  <Inference probability="0.3" >
   <Concept>Possible GRB</Concept>
   <Name>grb</Name>
   <Description>
Flight generated alert</Description>
  </Inference>
 </Why>
</VOEvent>
