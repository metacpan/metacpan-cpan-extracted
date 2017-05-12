#
# Written by Travis Kent Beste
# Fri Aug  6 22:13:22 CDT 2010

package BT368i::NMEA::GP::RMC;

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
		log_fh                       => '',
		log_filename                 => '',

		utc_time                     => '',
		status                       => '',
		latitude                     => '',
		latitude_hemisphere          => '',
		longitude                    => '',
		longitude_hemisphere         => '',
		speed                        => '',
		course                       => '',
		utc_date                     => '',
		magnetic_variation           => '',
		magnetic_variation_direction => '',
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
	if ($self->{status} eq 'A') {
		print "status                       : valid position\n";
	} elsif ($self->{status} eq 'V') {
		print "status                       : NAV receiver warning\n";
	}
	print "latitude                     : " . $self->{latitude} . "\n";
	if ($self->{latitude_hemisphere} eq 'N') {
		print "latitude hemisphere          : NORTH\n";
	} elsif ($self->{latitude_hemisphere} eq 'N') {
		print "latitude hemisphere          : SOUTH\n";
	}
	print "longitude                    : " . $self->{longitude} . "\n";
	if ($self->{longitude_hemisphere} eq 'E') {
		print "hemisphere                   : EAST\n";
	} elsif ($self->{longitude_hemisphere} eq 'W') {
		print "hemisphere                   : WEST\n";
	}
	print "course                       : " . $self->{course} . " degrees\n";
	print "speed                        : " . $self->{speed} . " knots\n";
	print "utc date                     : " . $self->{utc_date} . "\n";
	print "magnetic variation           : ";
	if ($self->{magnetic_variation} ne '') {
		print $self->{magnetic_variation} . " degrees\n";
	} else {
		print "\n";
	}
	print "magnetic variation direction : " . $self->{magnetic_variation_direction} . "\n";
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
	my $ms = $utc_time[7]; $ms .= $utc_time[8]; $ms .= $utc_time[9];
	#print "utc_time                     : $hh, $mm, $ss $ms - $args[1]\n";
	$self->{utc_time} = $hh . ':' . $mm . ':' . $ss . '.' . $ms;

	# 2) Status, A=Valid position, V=NAV receiver warning
	$self->{status} = $args[2];

	# 3) Latitude, ddmm.mmmm format (leading zeros sent)
	$self->{latitude} = $args[3];

	# 4) Latitude hemisphere, N or S
	$self->{latitude_hemisphere} = $args[4];

	# 5) Longitude, dddmm.mmmm format (leading zeros sent)
	$self->{longitude} = $args[5];

	# 6) Longitude hemisphere, E or W
	$self->{longitude_hemisphere} = $args[6];

	# 7) Speed over ground, 0.0 to 999.9 knots
	$self->{speed} = $args[7];

	# 8) Course over ground, 000.0 to 359.9 degrees, true (leading zeros sent)
	$self->{course} = $args[8];

	# 9) UTC date of position fix, ddmmyy format
	my @utc_date = split(//, $args[9]);
	my $dd = $utc_date[0]; $dd .= $utc_date[1];
	my $mm = $utc_date[2]; $mm .= $utc_date[3];
	my $yy = $utc_date[4]; $yy .= $utc_date[5];
	$self->{utc_date} = $yy . '-' . $mm . '-' . $dd;

	# 10) Magnetic variation, 000.0 to 180.0 degrees (leading zeros sent)
	$self->{magnetic_variation} = $args[10];

	# 11) Magnetic variation direction, E or W (westerly variation adds to true course)
	$self->{magnetic_variation_direction} = $args[11];
}

1;

__END__
=head1 NAME

BT368i::NMEA::GP::RMC - The RMC sentance

=head1 SYNOPSIS

use BT368i::NMEA::GP::RMC;

my $rmc = new BT368i::NMEA::GP::RMC();

$rmc->parse();

$rmc->print();

=head1 DESCRIPTION

Used to decode the RMC message.

=head2 Methods

=over 2

=item $rmc->parse();

Parse a GPRMC sentance.

=item $rmc->print();

Print a decoded output of a GPRMC sentance.

=item $rmc->log($filename);

Log the GPRMC sentance to a file.

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
