# Astro::VO::VOEvent test harness

# strict
use strict;

#load test
use Test::More tests => 3;

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
my $version = $object->version( );

is( $version, "HTN/0.1", "comparing VERSION strings" );


# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<VOEvent role="test" id="ivo://raptor.lanl/23456789/" version="HTN/0.1">
    <Description>This is some human readable text.</Description>
    <Who>
        <Publisher>ivo://raptor.lanl</Publisher>
        <Contact>
            <Name>Robert White</Name>
            <Institution>LANL</Institution>
            <Address>Los Alamos National Laboratory,
PO Box 1663,
ISR-1, MS B244,
Los Alamos, NM 87545</Address>
            <Telephone>+1-505-665-3025</Telephone>
            <Email>rwhite@lanl.gov</Email>
        </Contact>
        <Date>2005-04-15T14:34:16</Date>
    </Who>
    <Citations>
        <EventID cite="supercedes">ivo://raptor.lanl/98765432/</EventID>
        <EventID cite="associated">ivo://estar.org/1234567/aa/</EventID>
    </Citations>
    <WhereWhen type="simple">
        <RA units="deg">
            <Coord>148.888</Coord>
            <Error value="4" units="arcmin" />
        </RA>
        <Dec units="deg">
            <Coord>69.065</Coord>
            <Error value="4" units="arcmin" />
        </Dec>
        <Epoch value="J2000.0" />
        <Equinox value="2000.0" />
        <Time>
            <Value>2005-04-15T23:59:59</Value>
            <Error value="30" units="s" />
        </Time>
    </WhereWhen>
    <How>
        <Reference uri="http://www.raptor.lanl.gov/documents/phase_zero.html" type="rtml" />
    </How>
    <What>
        <Group>
            <Param name="magnitude" ucd="phot.mag:em.opt.R" value="13.2" units="mag" />
            <Param name="error" ucd="phot.mag:stat.error" value="0.1" units="mag" />
        </Group>
        <Group>
            <Param name="magnitude" ucd="phot.mag:em.opt.V" value="12.5" units="mag" />
            <Param name="error" ucd="phot.mag:stat.error" value="0.1" units="mag" />
        </Group>
        <Param name="seeing" ucd="instr.obsty.site.seeing" value="2" units="arcsec" />
        <Param name="misc" ucd="misc.junk" value="unknown" />
    </What>
    <Why>
        <Classification probability="30" units="percent" type="ot">Fast Orphan Optical Transient</Classification>
        <Identification type="associated">NGC1234</Identification>
    </Why>
</VOEvent>
