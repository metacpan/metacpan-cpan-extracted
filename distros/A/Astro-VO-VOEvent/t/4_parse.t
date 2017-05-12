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
is( $id, "ivo://raptor.lanl/23456789/", "Comparing ID strings" );

my $role = $object->role( );
is( $role, "test", "Comparing ROLE strings" );

my $version = $object->version( );
is( $version, "HTN/0.1", "Comparing VERSION strings" );

my $description = $object->description( );
is( $description, "This is some human readable text.", "comparing <Description>" );

my $ra = $object->ra( );
is( $ra, "148.888", "Comparing RA" );

my $dec = $object->dec( );
is( $dec, "69.065", "Comparing Dec" );

my $ra_return = "\$VAR1 = 'value';\n".
		"\$VAR2 = '148.888';\n".
		"\$VAR3 = 'error';\n".
		"\$VAR4 = {\n".
		"          'value' => '4',\n".
		"          'units' => 'arcmin'\n".
		"        };\n".
		"\$VAR5 = 'units';\n".
		"\$VAR6 = 'deg';\n";
		
my %ra = $object->ra( );
is( Dumper(%ra), $ra_return, "Comparing RA in list context" );

my $dec_return = "\$VAR1 = 'value';\n".
		"\$VAR2 = '69.065';\n".
		"\$VAR3 = 'error';\n".
		"\$VAR4 = {\n".
		"          'value' => '4',\n".
		"          'units' => 'arcmin'\n".
		"        };\n".
		"\$VAR5 = 'units';\n".
		"\$VAR6 = 'deg';\n";
		
my %dec = $object->dec( );
is( Dumper(%dec), $dec_return, "Comparing Dec in list context" );

my $epoch = $object->epoch( );
is( $epoch, "J2000.0", "Comparing Epoch" );

my $equinox = $object->equinox( );
is( $equinox, "2000.0", "Comparing Equinox" );

my $what_return = 
    "\$VAR1 = 'Param';\n" .
    "\$VAR2 = {\n" .
    "          'seeing' => {\n" .
    "                      'value' => '2',\n" .
    "                      'ucd' => 'instr.obsty.site.seeing',\n" .
    "                      'units' => 'arcsec'\n" .
    "                    },\n" .
    "          'misc' => {\n" .
    "                    'value' => 'unknown',\n" .
    "                    'ucd' => 'misc.junk'\n" .
    "                  }\n" .
    "        };\n" .
    "\$VAR3 = 'Group';\n" .
    "\$VAR4 = [\n" .
    "          {\n" .
    "            'Param' => {\n" .
    "                       'magnitude' => {\n" .
    "                                      'value' => '13.2',\n" .
    "                                      'ucd' => 'phot.mag:em.opt.R',\n" .
    "                                      'units' => 'mag'\n" .
    "                                    },\n" .
    "                       'error' => {\n" .
    "                                  'value' => '0.1',\n" .
    "                                  'ucd' => 'phot.mag:stat.error',\n" .
    "                                  'units' => 'mag'\n" .
    "                                }\n" .
    "                     }\n" .
    "          },\n" .
    "          {\n" .
    "            'Param' => {\n" .
    "                       'magnitude' => {\n" .
    "                                      'value' => '12.5',\n" .
    "                                      'ucd' => 'phot.mag:em.opt.V',\n" .
    "                                      'units' => 'mag'\n" .
    "                                    },\n" .
    "                       'error' => {\n" .
    "                                  'value' => '0.1',\n" .
    "                                  'ucd' => 'phot.mag:stat.error',\n" .
    "                                  'units' => 'mag'\n" .
    "                                }\n" .
    "                     }\n" .
    "          }\n" .
    "        ];\n";
		
my %what = $object->what( );
is( Dumper(%what), $what_return, "Comparing <What> in list context" );

my $time = $object->time( );
is( $time, "2005-04-15T23:59:59", "Comparing time stamp" );

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
