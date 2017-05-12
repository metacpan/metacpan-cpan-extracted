#
# Written by Travis Kent Beste
# Fri Aug  6 22:13:22 CDT 2010

package BT368i::NMEA::GP::VTG;

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
		log_fh                  => '',
		log_filename            => '',

		true_track              => '',
		magnetic_track          => '',
		ground_speed_knots      => '',
		ground_speed_kilometers => '',
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

	print "true track              : " . $self->{true_track} . "\n";
	print "magnetic track          : " . $self->{magnetic_track} . "\n";
	print "ground speed knots      : " . $self->{ground_speed_knots} . "\n";
	print "ground speed kilometers : " . $self->{ground_speed_kilometers} . "\n";
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

	# 1) 054.7,T      True track made good (degrees)
	$self->{true_track} = $args[1];

	# 2) 034.4,M      Magnetic track made good
	$self->{magnetic_track} = $args[3];

	# 3) 005.5,N      Ground speed, knots
	$self->{ground_speed_knots} = $args[5];

	# 4) 010.2,K      Ground speed, Kilometers per hour
	$self->{ground_speed_kilometers} = $args[7];
}

1;

__END__
=head1 NAME

BT368i::NMEA::GP::VTG - The VTG sentance

=head1 SYNOPSIS

use BT368i::NMEA::GP::VTG;

my $vtg = new BT368i::NMEA::GP::VTG();

$vtg->parse();

$vtg->print();

=head1 DESCRIPTION

Used to decode the VTG message.

=head2 Methods

=over 2

=item $vtg->parse();

Parse a GPVTG sentance.

=item $vtg->print();

Print a decoded output of a GPVTG sentance.

=item $vtg->log($filename);

Log the GPVTG sentance to a file.

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

