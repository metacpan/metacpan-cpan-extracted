#!/usr/bin/perl
#
# Written by Travis Kent Beste
# Fri Aug  6 07:53:53 CDT 2010

use lib qw( ./lib ../lib );
use BT368i;

use strict;
use warnings;
use Data::Dumper;

$|++; # unbuffered i/o

#----------------------------------------#
# new objects
#----------------------------------------#
my $bt368i = new BT368i(
	Port => '/dev/tty.BT-GPS-38BD5D-BT-GPSCOM',
	Baud => '115200',
);
my $rmc = new BT368i::NMEA::GP::RMC();
my $gsa = new BT368i::NMEA::GP::GSA();
my $gga = new BT368i::NMEA::GP::GGA();
my $gsv = new BT368i::NMEA::GP::GSV();
my $gll = new BT368i::NMEA::GP::GLL();
my $vtg = new BT368i::NMEA::GP::VTG();

$bt368i->BT368i::log('./log/all.log');
$rmc->BT368i::log('./log/rmc.log');
$gsa->BT368i::log('./log/gsa.log');
$gsv->BT368i::log('./log/gsv.log');
$gll->BT368i::log('./log/gll.log');
$vtg->BT368i::log('./log/vtg.log');
$gga->BT368i::log('./log/gga.log');

#----------------------------------------#
# parse...
#----------------------------------------#
while(1) {
	my $sentances = $bt368i->get_sentances();

	foreach my $sentance (@$sentances) {
		if ($sentance =~ /^\$GPGSA/) {
			$gsa->parse($sentance);
			#$gsa->print();
		} elsif ($sentance =~ /^\$GPRMC/) {
			$rmc->parse($sentance);
			#$rmc->print();
		} elsif ($sentance =~ /^\$GPGGA/) {
			$gga->parse($sentance);
			#$gga->print();
		} elsif ($sentance =~ /^\$GPGSV/) {
			$gsv->parse($sentance);
			#$gsv->print();
		} elsif ($sentance =~ /^\$GPGLL/) {
			$gll->parse($sentance);
			#$gll->print();
		} elsif ($sentance =~ /^\$GPVTG/) {
			$vtg->parse($sentance);
			#$vtg->print();
		} else {
			#print "sentance : $sentance\n";
		}
	}

}

exit(0);
