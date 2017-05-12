#
# Written by Travis Kent Beste
# Fri Aug  6 23:35:11 CDT 2010

package BT368i::NMEA::GP::GSV;

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

		gsv_sentance_count   => '',
		current_gsv_sentance => '',
		number_of_satilites  => '',
		sentance_1           => {
			prn_0 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_1 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_2 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_3 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
		},
		sentance_2           => {
			prn_0 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_1 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_2 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_3 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
		},
		sentance_3           => {
			prn_0 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_1 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_2 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
			prn_3 => { id => '', elevation => '', azimuth => '', signal_to_noise => '', },
		},
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

	print "number of gsv sentances        : " . $self->{gsv_sentance_count} . "\n";
	print "number of current gsv sentance : " . $self->{current_gsv_sentance} . "\n";
	print "number of satellites in view   : " . $self->{number_of_satilites} . "\n";

	printf "| id |  elevation | azimuth | sNr |\n";
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_1}->{prn_0}->{id}, $self->{sentance_1}->{prn_0}->{elevation}, $self->{sentance_1}->{prn_0}->{azimuth}, $self->{sentance_1}->{prn_0}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_1}->{prn_1}->{id}, $self->{sentance_1}->{prn_1}->{elevation}, $self->{sentance_1}->{prn_1}->{azimuth}, $self->{sentance_1}->{prn_1}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_1}->{prn_2}->{id}, $self->{sentance_1}->{prn_2}->{elevation}, $self->{sentance_1}->{prn_2}->{azimuth}, $self->{sentance_1}->{prn_2}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_1}->{prn_3}->{id}, $self->{sentance_1}->{prn_3}->{elevation}, $self->{sentance_1}->{prn_3}->{azimuth}, $self->{sentance_1}->{prn_3}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_2}->{prn_0}->{id}, $self->{sentance_2}->{prn_0}->{elevation}, $self->{sentance_2}->{prn_0}->{azimuth}, $self->{sentance_2}->{prn_0}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_2}->{prn_1}->{id}, $self->{sentance_2}->{prn_1}->{elevation}, $self->{sentance_2}->{prn_1}->{azimuth}, $self->{sentance_2}->{prn_1}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_2}->{prn_2}->{id}, $self->{sentance_2}->{prn_2}->{elevation}, $self->{sentance_2}->{prn_2}->{azimuth}, $self->{sentance_2}->{prn_2}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_2}->{prn_3}->{id}, $self->{sentance_2}->{prn_3}->{elevation}, $self->{sentance_2}->{prn_3}->{azimuth}, $self->{sentance_2}->{prn_3}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_3}->{prn_0}->{id}, $self->{sentance_3}->{prn_0}->{elevation}, $self->{sentance_3}->{prn_0}->{azimuth}, $self->{sentance_3}->{prn_0}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_3}->{prn_1}->{id}, $self->{sentance_3}->{prn_1}->{elevation}, $self->{sentance_3}->{prn_1}->{azimuth}, $self->{sentance_3}->{prn_1}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_3}->{prn_2}->{id}, $self->{sentance_3}->{prn_2}->{elevation}, $self->{sentance_3}->{prn_2}->{azimuth}, $self->{sentance_3}->{prn_2}->{signal_to_noise};
	printf "| %2d | %10.2f | %7d | %3d |\n", $self->{sentance_3}->{prn_3}->{id}, $self->{sentance_3}->{prn_3}->{elevation}, $self->{sentance_3}->{prn_3}->{azimuth}, $self->{sentance_3}->{prn_3}->{signal_to_noise};
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

	# 1) Total number of GSV sentences to be transmitted
	$self->{gsv_sentance_count} = $args[1];

	# 2) Number of current GSV sentence
	$self->{current_gsv_sentance} = $args[2];

	# 3) Total number of satellites in view, 00 to 12 (leading zeros sent)
	$self->{number_of_satilites} = $args[3];

	
	# 4) Satellite PRN number, 01 to 32 (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{'prn_0'}->{'id'} = $args[4];

	# 5) Satellite elevation, 00 to 90 degrees (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{'prn_0'}->{'elevation'} = $args[5];

	# 6) Satellite azimuth, 000 to 359 degrees, true (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{'prn_0'}->{'azimuth'} = $args[6];

	# 7) Signal to Noise ratio (C/No) 00 to 99 dB, null when not tracking (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{'prn_0'}->{'signal_to_noise'} = $args[7];


	# 4) Satellite PRN number, 01 to 32 (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_1}->{id} = $args[8];

	# 5) Satellite elevation, 00 to 90 degrees (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_1}->{elevation} = $args[9];

	# 6) Satellite azimuth, 000 to 359 degrees, true (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_1}->{azimuth} = $args[10];

	# 7) Signal to Noise ratio (C/No) 00 to 99 dB, null when not tracking (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_1}->{signal_to_noise} = $args[11];


	# 4) Satellite PRN number, 01 to 32 (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_2}->{id} = $args[12];

	# 5) Satellite elevation, 00 to 90 degrees (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_2}->{elevation} = $args[13];

	# 6) Satellite azimuth, 000 to 359 degrees, true (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_2}->{azimuth} = $args[14];

	# 7) Signal to Noise ratio (C/No) 00 to 99 dB, null when not tracking (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_2}->{signal_to_noise} = $args[15];


	# 4) Satellite PRN number, 01 to 32 (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_3}->{id} = $args[16];

	# 5) Satellite elevation, 00 to 90 degrees (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_3}->{elevation} = $args[17];

	# 6) Satellite azimuth, 000 to 359 degrees, true (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_3}->{azimuth} = $args[18];

	# 7) Signal to Noise ratio (C/No) 00 to 99 dB, null when not tracking (leading zeros sent)
	$self->{'sentance_' . $self->{current_gsv_sentance}}->{prn_3}->{signal_to_noise} = $args[19];
}

1;

__END__

=head1 NAME

BT368i::NMEA::GP::GSV - The GSV sentance

=head1 SYNOPSIS

use BT368i::NMEA::GP::GSV;

my $gsv = new BT368i::NMEA::GP::GSV();

$gsv->parse();

$gsv->print();

=head1 DESCRIPTION

Used to decode the GSV message.

=head2 Methods

=over 2

=item $gsv->parse();

Parse a GPGSV sentance.

=item $gsv->print();

Print a decoded output of a GPGSV sentance.

=item $gsv->log($filename);

Log the GPGSV sentance to a file.

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
