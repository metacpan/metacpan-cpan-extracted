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
is( $id, "ivo://uk.org.estar/estar.ex#test/6821.3", "comparing ID strings" );

my $role = $object->role( );
is( $role, "test", "comparing ROLE strings" );

my $version = $object->version( );
is( $version, "1.1x", "comparing VERSION strings" );

my $description = $object->description( );
is( $description, undef, "comparing <Description>" );

my $ra = $object->ra( );
is( $ra, "30.2", "Comparing RA" );

my $dec = $object->dec( );
is( $dec, "75.2", "Comparing Dec" );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version = '1.0' encoding = 'UTF-8'?>
<VOEvent role="test" version= "1.1x" ivorn="ivo://uk.org.estar/estar.ex#test/6821.3" xmlns="http://www.ivoa.net/xml/VOEvent/v1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:schemaLocation="http://www.ivoa.net/xml/VOEvent/v1.1 http://www.ivoa.net/internal/IVOA/IvoaVOEvent/VOEvent-v1.1-060425.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance">
<Citations>
  <EventIVORN cite="supersedes">ivo://uk.org.estar/estar.ex#test/6821.2</EventIVORN>
</Citations>
<Who>
  <AuthorIVORN>ivo://uk.org.estar/estar.ex#</AuthorIVORN>
  <Date>2006-05-16T18:52:24</Date>
</Who>
<WhereWhen>
  <ObsDataLocation xmlns="http://www.ivoa.net/xml/STC/stc-v1.30.xsd" xmlns:xlink="http://www.w3.org/1999/xlink">
    <ObservatoryLocation id="GEOLUN" xlink:type="simple" xlink:href="ivo://STClib/Observatories#GEOLUN">
      <ObservationLocation>
        <AstroCoordSystem id="UTC-FKC-GEO" xlink:type="simple" xlink:href="ivo://STClib/CoordSys#UTC-FK5-GEO/">
          <AstroCoords coord_system_id="UTC-FK5-GEO">
            <Time unit="s">
              <TimeInstant>
                <ISOTime>2006-05-16T18:52:24</ISOTime>
              </TimeInstant>
            </Time>
            <Position2D unit="deg">
              <Value2>
                <C1>30.2</C1>
                <C2>75.2</C2>
              </Value2>
              <Error2Radius>0.01</Error2Radius>
            </Position2D>
          </AstroCoords>
        </AstroCoordSystem>
      </ObservationLocation>
    </ObservatoryLocation>
  </ObsDataLocation>
</WhereWhen>
<What>
  <Param value="test" name="TYPE" />
  <Param value="3" name="COUNTER" />
  <Group name="Test Server Parameters" >
    <Param value="6821" name="PID" />
    <Param value="144.173.229.20" name="HOST" />
    <Param value="9999" name="PORT" />
  </Group>
</What>
<Why importance="0.0">
  <Inference probability="1.0" >
    <Concept>Test Packet</Concept>
    <Name>test</Name>
    <Description>An eSTAR test packet</Description>
  </Inference>
</Why>
</VOEvent>
