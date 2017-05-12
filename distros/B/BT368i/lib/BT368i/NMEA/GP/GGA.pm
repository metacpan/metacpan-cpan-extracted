#
# Written by Travis Kent Beste
# Fri Aug  6 22:59:56 CDT 2010

package BT368i::NMEA::GP::GGA;

use strict;
use vars qw( );

use Data::Dumper;

our @ISA     = qw( );

our $VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

#----------------------------------------#
#
#----------------------------------------#
sub new {
	my $class = shift;
	my %args  = shift;

	my %fields = (
		log_fh                    => '',
		log_filename              => '',

		utc_time                  => '',
		latitude                  => '',
		latitude_hemisphere       => '',
		longitude                 => '',
		longitude_hemisphere      => '',
		fix_type                  => '',
		satilites_in_use          => '',
		horizontal_dilution       => '',
		antenna_height            => '',
		geoidal_height            => '',
		dgps_data_age             => '',
		dgps_reference_station_id => '',
	);

	my $self = {
		%fields,
	};
	bless $self, $class;

	return $self;
}

#----------------------------------------#
#
#----------------------------------------#
sub print {
	my $self = shift;

	print "utc_time                     : " . $self->{utc_time} . "\n";
	print "latitude                     : " . $self->{latitude} . "\n";
	if ($self->{latitude_hemisphere} eq 'N') {
		print "hemisphere                   : NORTH\n";
	} elsif ($self->{latitude_hemisphere} eq 'N') {
		print "hemisphere                   : SOUTH\n";
	}
	print "longitude                    : " . $self->{longitude} . "\n";
	if ($self->{longitude_hemisphere} eq 'E') {
		print "hemisphere                   : EAST\n";
	} elsif ($self->{longitude_hemisphere} eq 'W') {
		print "hemisphere                   : WEST\n";
	}
	if ($self->{fix_type} == 0) {
		print "fix_type                     : no fix\n";
	} elsif ($self->{fix_type} == 1) {
		print "fix_type                     : non-DGPS\n";
	} elsif ($self->{fix_type} == 2) {
		print "fix_type                     : DGPS\n";
	}
	print "satilites in use             : " . $self->{satilites_in_use} . "\n";
	print "horizontal dilution of prec. : " . $self->{horizontal_dilution} . "\n";
	print "height above/below mean sea  : " . $self->{antenna_height} . " meters\n";
	print "height above/below mean sea  : " . $self->{geoidal_height} . " meters\n";
	print "DGPS data age                : ";
	if ($self->{dgps_data_age} ne '') {
		print $self->{dgps_data_age} . " seconds\n";
	} else {
		print "\n";
	}
	print "DGPS reference station id    : " . $self->{dgps_reference_station_id} . "\n";
}

#----------------------------------------#
#
#----------------------------------------#
sub parse {
	my $self = shift;
	my $data = shift;

	# if we're logging, save data to filehandle
	if ($self->{log_fh}) {
		print { $self->{log_fh} } $data . "\n";
	}

	$data    =~ s/\*..$//; # remove the last three bytes
	my @args = split(/,/, $data);

	# 1) UTC time of position fix, hhmmss format
	my @utc_time = split(//, $args[1]);
	my $hh = $utc_time[0]; $hh .= $utc_time[1];
	my $mm = $utc_time[2]; $mm .= $utc_time[3];
	my $ss = $utc_time[4]; $ss .= $utc_time[5];
	my $ms = $utc_time[7]; $ms .= $utc_time[8]; $ms .= $utc_time[1];
	$self->{utc_time} = $hh . ':' . $mm . ':' . $ss . '.' . $ms;

	# 2) Latitude, ddmm.mmmm format (leading zeroes will be transmitted)
	$self->{latitude} = $args[2];

	# 3) Latitude hemisphere, N or S
	$self->{latitude_hemisphere} = $args[3];

	# 4) Longitude, dddmm.mmmm format (leading zeros will be transmitted)
	$self->{longitude} = $args[4];

	# 5) Longitude hemisphere, E or W
	$self->{longitude_hemisphere} = $args[5];

	# 6) GPS quality indication, 0=no fix, 1=non-DGPS fix, 2=DGPS fix
	$self->{fix_type} = $args[6];

	# 7) Number of sats in use, 00 to 12
	$self->{satilites_in_use} = $args[7];

	# 8) Horizontal Dilution of Precision 1.0 to 99.9
	$self->{horizontal_dilution} = $args[8];

	# 9) Antenna height above/below mean sea level, -9999.9 to 99999.9 meters
	$self->{antenna_height} = $args[9];

	# 10) Geoidal height, -999.9 to 9999.9 meters
	$self->{geoidal_height} = $args[11];

	# 11) DGPS data age, number of seconds since last valid RTCM transmission (null if non-DGPS)
	$self->{dgps_data_age} = $args[13];

	# 12) DGPS reference station ID, 0000 to 1023 (leading zeros will be sent, null if non-DGPS)
	$self->{dgps_reference_sation_id} = $args[14];
}

1;

__END__

=head1 NAME

BT368i::NMEA::GP::GGA - The GGA sentance

=head1 SYNOPSIS

use BT368i::NMEA::GP::GGA;

my $gga = new BT368i::NMEA::GP::GGA();

$gga->parse();

$gga->print();

=head1 DESCRIPTION

Used to decode the GGA message.

=head2 Methods

=over 2

=item $gga->parse();

Parse a GPGGA sentance.

=item $gga->print();

Print a decoded output of a GPGGA sentance.

=item $gga->log($filename);

Log the GPGGA sentance to a file.

=back

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
