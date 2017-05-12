#
# Written by Travis Kent Beste
# Sat Aug  7 10:18:09 CDT 2010

package BT368i::NMEA::GP::GLL;

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
		log_fh               => '',
		log_filename         => '',

		latitude             => '',
		latitude_hemisphere  => '',
		longitude            => '',
		longitude_hemisphere => '',
		utc_time             => '',
		data_valid           => '',
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

	print "latitude             : " . $self->{latitude} . "\n";
	if ($self->{latitude_hemisphere} eq 'N') {
		print "latitude_hemisphere  : NORTH\n";
	} else {
		print "latitude_hemisphere  : SOUTH\n";
	}
	print "longitude            : " . $self->{longitude} . "\n";
	if ($self->{longitude_hemisphere} eq 'E') {
		print "longitude_hemisphere : EAST\n";
	} else {
		print "longitude_hemisphere : WEST\n";
	}
	print "longitude_hemisphere : " . $self->{longitude_hemisphere} . "\n";
	print "utc_time             : " . $self->{utc_time} . "\n";
	if ($self->{data_valid} == 'A') {
		print "data valid           : valid\n";
	} else {
		print "data valid           : in-valid\n";
	}
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

	$data    =~ s/\*..$//; # remove the last three bytes (checksum)
	my @args = split(/,/, $data);

	# 1) Latitude, ddmm.mm format
	$self->{latitude} = $args[1];

	# 2) Latitude hemisphere, N or S
	$self->{latitude_hemisphere} = $args[2];

	# 3) Longitude, dddmm.mm format
	$self->{longitude} = $args[3];

	# 4) Longitude hemisphere, E or W
	$self->{longitude_hemisphere} = $args[4];

	# 5) UTC time of position fix, hhmmss format
	my @utc_time = split(//, $args[5]);
	my $hh = $utc_time[0];
	$hh .= $utc_time[1];
	my $mm = $utc_time[2];
	$mm .= $utc_time[3];
	my $ss = $utc_time[4];
	$ss .= $utc_time[5];
	my $ms = $utc_time[7];
	$ms .= $utc_time[8];
	$ms .= $utc_time[9];
	$self->{utc_time} = $hh . ':' . $mm . ':' . $ss . '.' . $ms;

	# 6) Data valid, A=Valid
	$self->{data_valid} = $args[6];
}

1;

__END__
=head1 NAME

BT368i::NMEA::GP::GLL - The GLL sentance

=head1 SYNOPSIS

use BT368i::NMEA::GP::GLL;

my $gll = new BT368i::NMEA::GP::GLL();

$gll->parse();

$gll->print();

=head1 DESCRIPTION

Used to decode the GLL message.

=head2 Methods

=over 2

=item $gll->parse();

Parse a GPGLL sentance.

=item $gll->print();

Print a decoded output of a GPGLL sentance.

=item $gll->log($filename);

Log the GPGLL sentance to a file.

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
