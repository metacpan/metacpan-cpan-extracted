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

my $object = new Astro::VO::VOEvent();

my $document = $object->build( 
                Role => 'test',
                ID   => 'ivo://raptor.lanl/23456789/',
                Description => 'This is a bit of human readable text',
                Reference  => { 
                  URL => 'http://www.raptor.lanl.gov/documents/event233.xml', 
                  Type =>  'voevent'} );
                  
my @xml = split( /\n/, $document );

foreach my $i ( 0 ... $#buffer ) {
   is( $xml[$i], $buffer[$i], "comparing line $i in XML document" );
}

# T I M E   A T   T H E   B A R ---------------------------------------------

exit;  

# D A T A   B L O C K --------------------------------------------------------

__DATA__
<?xml version="1.0" encoding="UTF-8"?>

<voe:VOEvent role="test" ivorn="ivo://raptor.lanl/23456789/" version="1.1" xmlns:voe="http://www.ivoa.net/xml/VOEvent/v1.1" xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xsi:schemaLocation="http://www.ivoa.net/xml/VOEvent/v1.1 http://www.ivoa.net/xml/VOEvent/VOEvent-v1.1.xsd">
    <Description>This is a bit of human readable text</Description>
    <Reference uri="http://www.raptor.lanl.gov/documents/event233.xml" type="voevent" />
</voe:VOEvent>
