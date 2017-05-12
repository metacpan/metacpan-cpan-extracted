#
# Written by Travis Kent Beste
# Fri Aug  6 14:26:05 CDT 2010

package BT368i;

use strict 'refs';
use vars qw( );

use RingBuffer;
use BT368i::Serial;
use BT368i::NMEA::GP::GSA;
use BT368i::NMEA::GP::GLL;
use BT368i::NMEA::GP::GGA;
use BT368i::NMEA::GP::GSV;
use BT368i::NMEA::GP::RMC;
use BT368i::NMEA::GP::VTG;

use Data::Dumper;
use IO::File;

our @ISA     = qw(RingBuffer BT368i::Serial BT368i::NMEA::GP::RMC BT368i::NMEA::GP::GSA BT368i::NMEA::GP::GGA BT368i::NMEA::GP::GSV BT368i::NMEA::GP::GLL BT368i::NMEA::GP::VTG);

our $VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

#----------------------------------------#
# capture control-c
#----------------------------------------#
my $control_c_counter = 0;
$SIG{INT} = \&my_control_c;
sub my_control_c {
	$SIG{INT} = \&my_control_c;

	print "finishing up...";

	$control_c_counter++;
	if ($control_c_counter == 1) {
		print "done\n";
		exit();
	}
}

#----------------------------------------#
#
#----------------------------------------#
sub new {
	my $class = shift;
	my %args = @_;

	my %fields = (
		log_fh         => '',
		log_filename   => '',

		serial         => '',
		serialport     => $args{'Port'},
		serialbaud     => $args{'Baud'},
		serialtimeout  => 5,  # 5 second timeout
		serialline     => '', # the line that we're parsing, so it doesn't get lost

		ringbuffer     => '',
		ringbuffersize => 4096,
		verbose        => 1,
	);

	my $self = {
		%fields
	};
	bless $self, $class;

	# initialize the ringbuffer
	my $buffer            = [];
	my $ringsize          = $self->{ringbuffersize};
	my $overwrite         = 0;
	my $printextendedinfo = 0;
	my $r = new RingBuffer(
		Buffer            => $buffer,
		RingSize          => $ringsize,
		Overwrite         => $overwrite,
		PrintExtendedInfo => $printextendedinfo,
	);
	$r->ring_init();
	$r->ring_clear();
	$self->{ringbuffer} = $r;

	# connect to serial port
	$self->connect();

	return $self;
}

#----------------------------------------#
#
#----------------------------------------#
sub DESTROY {
	my $self = shift;

	if ($self->{serial}) {
		$self->{serial}->close || die "failed to close serialport";
		undef $self->{serial}; # frees memory back to perl
	}

	$self->SUPER::DESTROY if $self->can("SUPER::DESTROY");
}

#----------------------------------------#
#
#----------------------------------------#
sub log {
	my $self     = shift;
	my $filename = shift;

	# set the filename in the object
	$self->{log_filename} = $filename;

	# create a new file handle object because the other objects use this and 
	# they end up sharing the same handle if we use a glob
	my $fh = new IO::File->new;

	# generic open and unbuffered I/O
	open($fh, ">" . $self->{log_filename});
	select($fh), $| = 1; # set nonbuffered mode, gets the chars out NOW
	$self->{log_fh} = (*$fh);
	select(STDOUT);
}

#----------------------------------------#
#
#----------------------------------------#
sub get_sentances {
	my $self = shift;

	my $sentances = $self->BT368i::Serial::_readlines();

	# if we're logging, save data to filehandle
	if ($self->{log_fh}) {
		foreach my $sentance (@$sentances) {
			print { $self->{log_fh} } $sentance . "\n";
		}
	}

	return $sentances;
}

1;

__END__

=head1 NAME

BT368i - Perl interface to BT368i equipment that output data on a bluetooth serial port.

=head1 SYNOPSIS

use BT368i;

# BT368i object
my $bt368i = new BT368i( 'Port' => '/dev/ttyS0', 'Baud' => 115200 );

# gga object
my $gga = new BT368i::NMEA::GP::GGA;

while (1) {

	my $sentances = $bt368i->get_sentance();

	foreach my $sentance (@sentances) {

		if ($sentance =~ /^\$GPGGA/) {
			$gga->parse($sentance);
			$gga->print();
		}
	}
}

=head1 DESCRIPTION

BT368i allow the connection and use of of a GPS receiver in perl scripts.
Currently only the NMEA is implemented.

This module currently works with all gps devies that output a serial stream of
NMEA data

=head1 KNOWN LIMITATIONS

There is no port to Windows.

=head1 BUGS

none known

=head1 AUTHOR

Travis Kent Beste, travis@tencorners.com

=head1 COPYRIGHT

Copyright 2010 Tencorners, LLC.  All rights reserved.

This library is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
        
=head1 SEE ALSO

Travis Kent Beste's GPS www site
http://www.travisbeste.com/software/gps

perl(1).

RingBuffer.pm.

Device::SerialPort.pm.

=cut
