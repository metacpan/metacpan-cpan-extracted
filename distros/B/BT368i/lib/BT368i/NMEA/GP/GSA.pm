#
# Written by Travis Kent Beste
# Fri Aug  6 22:48:49 CDT 2010

package BT368i::NMEA::GP::GSA;

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

		mode                 => '',
		fix_type             => '',
		prn_00               => '',
		prn_01               => '',
		prn_02               => '',
		prn_03               => '',
		prn_04               => '',
		prn_05               => '',
		prn_06               => '',
		prn_07               => '',
		prn_08               => '',
		prn_10               => '',
		prn_11               => '',
		position_diliution   => '',
		horizontal_diliution => '',
		vertical_diliution   => '',
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

	if ($self->{mode} eq 'M') {
		print "mode                 : manual\n";
	} elsif ($self->{mode} eq 'A') {
		print "mode                 : automatic\n";
	}

	if ($self->{fix_type} == 1) {
		print "fix                  : no fix\n";
	} elsif ($self->{fix_type} == 2) {
		print "fix                  : 2D\n";
	} elsif ($self->{fix_type} == 3) {
		print "fix                  : 3D\n";
	}

	print "prn 00               : " . $self->{prn_00} . "\n";
	print "prn 01               : " . $self->{prn_01} . "\n";
	print "prn 02               : " . $self->{prn_02} . "\n";
	print "prn 03               : " . $self->{prn_03} . "\n";
	print "prn 04               : " . $self->{prn_04} . "\n";
	print "prn 05               : " . $self->{prn_05} . "\n";
	print "prn 06               : " . $self->{prn_06} . "\n";
	print "prn 07               : " . $self->{prn_07} . "\n";
	print "prn 08               : " . $self->{prn_08} . "\n";
	print "prn 09               : " . $self->{prn_09} . "\n";
	print "prn 10               : " . $self->{prn_10} . "\n";
	print "prn 11               : " . $self->{prn_11} . "\n";

	print "position diliution   : " . $self->{position_diliution} . "\n";
	print "horizontal diliution : " . $self->{horizontal_diliution} . "\n";
	print "vertical diliution   : " . $self->{vertical_diliution} . "\n";
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

	# 1) Mode, M=Manual, A=Automatic
	$self->{mode} = $args[1];

	# 2) Fix type, 1=no fix, 2=2D, 3=3D
	$self->{fix_type} = $args[2];

	# 3) PRN number, 01 to 32, of satellites used in solution (leading zeroes sent)
	$self->{prn_00} = $args[3];
	$self->{prn_01} = $args[4];
	$self->{prn_02} = $args[5];
	$self->{prn_03} = $args[6];
	$self->{prn_04} = $args[7];
	$self->{prn_05} = $args[8];
	$self->{prn_06} = $args[9];
	$self->{prn_07} = $args[10];
	$self->{prn_08} = $args[11];
	$self->{prn_09} = $args[12];
	$self->{prn_10} = $args[13];
	$self->{prn_11} = $args[14];

	# 4) Position dilution of precision, 1.0 to 99.9
	$self->{position_diliution} = $args[15];

	# 5) Horizontal dilution of precision, 1.0 to 99.9
	$self->{horizontal_diliution} = $args[16];

	# 6) Vertical dilution of precision, 1.0 to 99.9
	$self->{vertical_diliution} = $args[17];
}

1;

__END__

=head1 NAME

BT368i::NMEA::GP::GSA - The GSA sentance

=head1 SYNOPSIS

use BT368i::NMEA::GP::GSA;

my $gsa = new BT368i::NMEA::GP::GSA();

$gsa->parse();

$gsa->print();

=head1 DESCRIPTION

Used to decode the GSA message.

=head2 Methods

=over 2

=item $gsa->parse();

Parse a GPGSA sentance.

=item $gsa->print();

Print a decoded output of a GPGSA sentance.

=item $gsa->log($filename);

Log the GPGSA sentance to a file.

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
