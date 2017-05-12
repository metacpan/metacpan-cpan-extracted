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
is( $id, "ivo://nvo.caltech/voeventnet#gcn.gsfc/SWIFT_BAT_GRB_Position_Source_2006-05-15T02:28:44_210084-0", "comparing ID strings" );

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
is( $time, "2006-05-15T02:28:44", "Comparing time stamp" );

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version = '1.0' encoding = 'UTF-8'?>
<VOEvent ivorn="ivo://nvo.caltech/voeventnet#gcn.gsfc/SWIFT_BAT_GRB_Position_Source_2006-05-15T02:28:44_210084-0" role="observation" version= "1.0" xmlns="http://www.ivoa.net/xml/VOEvent/v1.1" xmlns:xlink="http://www.w3.org/1999/xlink" xsi:schemaLocation="http://www.ivoa.net/xml/VOEvent/v1.1 http://www.ivoa.net/internal/IVOA/IvoaVOEvent/VOEvent-v1.1-060425.xsd" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"> 
<Citations>
 <EventIVORN cite="supersedes">ivo://gcn.gsfc/210084</EventIVORN>
 <Description>This supersedes an earlier GCN Notice</Description>
</Citations>
<Who>
 <AuthorIVORN>ivo://nvo.caltech/voeventnet#gcn.gsfc/SWIFT_BAT_GRB_Position_Source/</AuthorIVORN>
 <Author >
 <contactName>Scott Barthelmy</contactName>
  <contactEmail>scott@milkyway.gsfc.nasa.gov  </contactEmail>
 </Author>
 <Date>2006-05-15T02:28:44</Date>
</Who>
<What>
 <Param value="61" name="PACKET_TYPE"/>
 <Param value="1" name="PKT_SERNUM"/>
 <Param value="210084" name="TrigID"/>
 <Param value="0" name="TrigSegNumID"/>
 <Param unit="days" value="13870" name="BURST_TJD"/>
 <Param unit="sec" value="8872.91" name="BURST_SOD"/>
 <Param unit="cts" value="30443" name="BURST_INTEN"/>
 <Param unit="cts" value="397" name="BURST_PEAK"/>
 <Param unit="arcmin" value="3.00" name="LocationError"/>
 <Param unit="sec" value="8.192" name="Int_Time"/>
 <Param unit="deg" value="-125.64" name="Phi"/>
 <Param unit="deg" value="36.30" name="Theta"/>
 <Param value="343" name="Trig_Index"/>
 <Param value="0x3" name="Soln_Status"/>
 <Param unit="sigma" value="16.61" name="Rate_Signif"/>
 <Param unit="sigma" value="7.76" name="Image_Signif"/>
 <Param unit="cts" value="205445" name="Bkg_Inten"/>
 <Param unit="sec" value="8782.80" name="Bkg_Time"/>
 <Param unit="sec" value="64.00" name="Bkg_Dur"/>
 <Group name="MeritValues">
  <Param value="1" name="Merit_Val0"/>
  <Param value="0" name="Merit_Val1"/>
  <Param value="0" name="Merit_Val2"/>
  <Param value="4" name="Merit_Val3"/>
  <Param value="3" name="Merit_Val4"/>
  <Param value="7" name="Merit_Val5"/>
  <Param value="0" name="Merit_Val6"/>
  <Param value="0" name="Merit_Val7"/>
  <Param value="-37" name="Merit_Val8"/>
  <Param value="1" name="Merit_Val9"/>
 </Group>
</What>
<WhereWhen>
 <ObsDataLocation xmlns="http://www.ivoa.net/xml/STC/stc-v1.30.xsd" xmlns:xlink="http://www.w3.org/1999/xlink">
  <ObservatoryLocation id="CenterOfTheEarth" xlink:href="ivo://STClib/Observatories#CenterOfTheEarth"/>
   <ObservationLocation>
    <AstroCoordSystem ID="FK5-UTC-TOPO" xlink:type="simple" xlink:href="ivo://STClib/CoordSys#FK5-UTC-TOPO"/>
 <AstroCoords coord_system_id="FK5-UTC-TOPO">
  <Time unit="s">
   <TimeInstant>
    <ISOTime>2006-05-15T02:28:44</ISOTime>
   </TimeInstant>
   <Error>2657.14</Error>
  </Time>
    <Position2D unit="deg">
    <Name1>RA</Name1>
      <Name2>Dec</Name2>
      <Value2>
      <C1>127.2875</C1>
       <C2>73.5508</C2>
        </Value2>
      <Error2Radius>0.0500</Error2Radius>
    </Position2D>
   </AstroCoords>
  </ObservationLocation>
</ObsDataLocation>
</WhereWhen>
<How>
 <Description> SWIFT_BAT_GRB_Position_Source </Description>
 <Reference uri="http://gcn.gsfc.nasa.gov/swift.html" />
 <Description>
 This is a rate trigger.
 </Description>
</How>
<Why>
 <Concept>This is a GRB.</Concept>
 <Name>
 <Description>
 </Description>
</Name>
</Why>
</VOEvent>
