#
# Written by Travis Kent Beste
# Fri Aug  6 14:29:27 CDT 2010

package BT368i::Serial;

use strict;
use vars qw( $has_serialport );

use Data::Dumper;

our @ISA     = qw( );
our $VERSION = sprintf("%d.%02d", q$Revision: 1.00 $ =~ /(\d+)\.(\d+)/);

$|++;

#----------------------------------------#
#
#----------------------------------------#
BEGIN {
	if (eval q{ use Device::SerialPort; 1 }) {
		$has_serialport++;
	} else {
		die "Missing Device::SerialPort";
	}
}

#----------------------------------------#
#
#----------------------------------------#
$SIG{ALRM} = sub { 
	print "\nserial port timed out.\n";
	exit -1;
};

#----------------------------------------#
#
#----------------------------------------#
sub connect {
	my $self = shift;
	return $self->{serial} if $self->{serial};

	# set a timeout
	alarm($self->{serialtimeout});

	print "connecting to serial port..." if ($self->{verbose});

	my $PortObj = new Device::SerialPort($self->{serialport});
	$PortObj->baudrate($self->{serialbaud});
	$PortObj->parity("none");
	$PortObj->databits(8);
	$PortObj->stopbits(1);
	$self->{serial} = $PortObj;

	# remove timeout
	alarm(0);

	print "done\n" if ($self->{verbose});
}

#----------------------------------------#
#
#----------------------------------------#
sub usleep {
	my $l = shift;
	$l = ref($l) && shift;
	select( undef,undef,undef,($l/1000) );
}

#----------------------------------------#
#
#----------------------------------------#
sub _read {
	my $self      = shift;
	my $sub_debug = 0;
	my $cnt       = 0;

	my $count = 0;
	my $byte  = '';
	($count, $byte) = $self->{serial}->read(1);
	if ($count == 0) {
		return 0;
	}
	printf "$byte" if ($sub_debug);
	$self->{ringbuffer}->ring_add(ord($byte));

	while ($count > 0) {
		($count, $byte) = $self->{serial}->read(1);
		if ($count > 0) {
			printf "$byte" if ($sub_debug);
			$self->{ringbuffer}->ring_add(ord($byte));
		}
		$cnt += $count;
	}

	# wow, just adding this here totaly sped things up
	$self->{serial}->lookclear();

	return $cnt;
}

#----------------------------------------#
#
#----------------------------------------#
sub _have_telegram {
	my $self  = shift;
	my $size  = $self->{ringbuffer}->ring_size();
	my $j     = $self->{ringbuffer}->{tail};
	my $count = 0;
	my @rv    = ();

	for(my $i = 0; $i < $size; $i++) {
		if ($j == $self->{ringbuffersize}) {
			$j = 0;
		}
		#printf "->%s\n", $self->{ringbuffer}->{buffer}[$j];

		# count the dollar signs '$'
		if ($self->{ringbuffer}->{buffer}[$j] eq '$') {
			$count++;
			if ($count == 1) {
				push(@rv, $j); # get the start
			} elsif ($count == 2) {
				push(@rv, $j); # get the end
			}
		}

		$j++;
	}

	return ($count, \@rv);
}

#----------------------------------------#
#
#----------------------------------------#
sub _readlines {
	my $self   = shift;
	my $done   = 0;
	my @lines  = ();

	#local $SIG{ALRM} = sub {die "BT368i bluetooth connection has timed out\n"};
	#eval { alarm($self->{timeout}) };
	
	while (! $done) {
		my $count    = $self->_read();
		my $ringsize = $self->{ringbuffer}->ring_size();

		if ($ringsize || $count) {
			my $loop_stop = $count;
			if ($loop_stop == 0) {
				$loop_stop = $ringsize;
			}

			for(my $i = 0; $i < $loop_stop; $i++) {
				my $byte = $self->{ringbuffer}->ring_remove();

				# start character is a '$'
				if ($byte == 0x24) {
					$self->{serialline} = sprintf("%c", $byte);
					#printf("%c", $byte);

				} elsif ($byte == 0x0d) {

					#printf("%02x ", $byte);

				} elsif ($byte == 0x0a) {

					if ($self->{serialline} =~ /\$GPGLL/) {
						#print "->" . $self->{serialline} . "\n";
					} elsif ($self->{serialline} =~ /\$GPGSV/) {
						#print "->" . $self->{serialline} . "\n";
					} elsif ($self->{serialline} =~ /\$GPGGA/) {
						#print "->" . $self->{serialline} . "\n";
					} elsif ($self->{serialline} =~ /\$GPGSA/) {
						#print "->$self->{serialline} . "\n";
					} elsif ($self->{serialline} =~ /\$GPRMC/) {
						#print "->" . $self->{serialline} . "\n";
					} elsif ($self->{serialline} =~ /\$GPVTG/) {
						#print "->" . $self->{serialline} . "\n";
					} else {
						#print "GARBAGE:" . $self->{serialline} . "\n";
					}

					#printf("%02x ", $byte);
					my $checksum = substr ($self->{serialline}, -3);
					# verify that it starts with '$GP...' and ends with '*..'
					if ( ($self->{serialline} =~ /^\$GP...\,/) && ($checksum =~ /\*..$/) ) {
						#print "-->$self->{serialline}<--\n";
						#$i = $count; # stop for loop
						#$done = 1; # stop while loop
						push(@lines, $self->{serialline});
					}

				} else {

					if ( ($byte => 0x20) && ($byte <= 0x7f) ){
						$self->{serialline} .= sprintf("%c", $byte);
						#printf("%c", $byte);
					} else {
						#printf("[%02x]", $byte);
					}
				}
			}
		} else {
			$done = 1;
		}

		#eval { alarm($self->{timeout}) }; # set new timeout
	}

	return \@lines;
}

#----------------------------------------#
#
#----------------------------------------#
sub _write {
	#$self->_write(buffer,length)
	#syswrite wrapper for the serial device
	#length defaults to buffer length

	my ($self,$buf,$len,$offset) = @_;
	$self->connect() or die "Write to an uninitialized handle";

	$len ||= length($buf);

	if ($self->{verbose}) {
		print STDERR "W:(",join(" ", map {$self->Pid_Byte($_)}unpack("C*",$buf)),")\n";
	}

	$self->{serial} or die "Write to an uninitialized handle";

	if ($self->{serialtype} eq 'FileHandle') {
		syswrite($self->serial,$buf,$len,$offset||0);
	} else {
		my $out_len = $self->serial->write($buf);
		warn "Write incomplete ($len != $out_len)\n" if	 ( $len != $out_len );
	}
}

1;

__END__

=head1 NAME

BT368i::Serial - Access to the serial port for the BT368i::* modules

=head1 SYNOPSIS

reads the serial port and parse out a sentance at a time.  each sentances starts
with the character '$' and ends with <CR> <LF>

=head1 DESCRIPTION

useed internally to the BT368i module

=head2 Methods

=over 2

=item none

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
