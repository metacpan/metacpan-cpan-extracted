BEGIN {
	$VERSION = '0.01';
}
########################################### main pod documentation begin ##

=head1 NAME

Audio::Radio::V4L 

=head1 SYNOPSIS

  use Audio::Radio::V4L;
  my $radio = Audio::Radio::V4L->new;
  $radio->open("/dev/radio");
  $radio->set_frequency( 88800 ); # frequency in khz
  
  sleep( 10 );
  
  $radio->close();

=head1 DESCRIPTION

Audio::Radio::V4L uses the Video4Linux interface to control radio receivers (eg. internal radio cards or USB receivers).

=head1 USAGE 

Open the device via open().
Get the highest and lowest supported frequency of the radio: get_freq_min() and get_freq_max().
Set the frequency with set_frequency().
Listen or record.
Close with close().

=head1 PUBLIC METHODS

Each public function/method is described here.
These are how you should interact with this module.

=cut

############################################# main pod documentation end ##
package Audio::Radio::V4L;
use strict;
use Carp;

################################################ subroutine header begin ## 

=head2 new()

 Usage     : new Audio::Radio::V4L
 Purpose   : creates a new radio object
 Returns   : the new object
 Argument  : none

=cut

################################################## subroutine header end ##
sub new() {
	my $class = shift;
	my $self  = bless {}, $class;
	$self;
}

################################################ subroutine header begin ## 

=head2 open()

 Usage     : $radio->open("/dev/radio")
 Purpose   : opens the radio-device, initializes values (max-freq, min-freq)
 Returns   : self
 Argument  : the device
 Throws    : croaks on problems

=cut

################################################## subroutine header end ##
sub open() {
	my $self = shift;
	my $devicename = shift || "/dev/radio";
	my $devicenumber = shift;
	(defined $devicenumber) || ($devicenumber = 0);
	$self->{ _devicenumber } = $devicenumber;
	$self->{ _fh } && $self->close();
	open($self->{ _fh }, $devicename)
		or croak "Could not open radio $devicename: $!";
	$self->_initialize_values_from_device();
	$self;
}

sub _initialize_values_from_device() {
	my $self = shift;
	# struct from linux/videodev.h
	my $videotuner = pack("iZ32LLLss",$self->{ _devicenumber },"",0,0,0,0);
	ioctl( 
		$self->{ _fh },
		$self->_get_VIDIOCGTUNER,
		$videotuner 
	);
	$self->{ _vt } = $videotuner;
	my @values = unpack("iZ32LLLss", $videotuner);
	$self->{ _devicename   } = $values[ 1 ];
	$self->{ _rangelow     } = $values[ 2 ];
	$self->{ _rangehigh    } = $values[ 3 ];
	$self->{ _deviceflags  } = $values[ 4 ];
	$self->{ _devicemode   } = $values[ 5 ];
	$self->{ _devicesignal } = $values[ 5 ];
	$self;
}

################################################ subroutine header begin ## 

=head2 get_devicename()

 Usage     : $radio->get_devicename()
 Returns   : returns the devicename of the opened radio
 Argument  : none

=cut

################################################## subroutine header end ##
sub get_devicename() {
	my $self = shift;
	$self->{ _fh } or croak "No device opened!";
	$self->{ _devicename };
}

################################################ subroutine header begin ## 

=head2 get_freq_min()

 Usage     : $radio->get_freq_min()
 Returns   : the minimal supported frequency of the radio
 Argument  : none

=cut

################################################## subroutine header end ##
sub get_freq_min() {
	my $self = shift;
	$self->{ _fh } or croak "No device opened!";
	$self->{ _rangelow } / $self->_get_frequency_factor();
}

################################################ subroutine header begin ## 

=head2 get_freq_max()

 Usage     : $radio->get_freq_max()
 Returns   : the maximal supported frequency of the radio
 Argument  : none

=cut

################################################## subroutine header end ##
sub get_freq_max() {
	my $self = shift;
	$self->{ _fh } or croak "No device opened!";
	$self->{ _rangehigh } / $self->_get_frequency_factor();
}

################################################ subroutine header begin ## 

=head2 close()

 Usage     : $radio->close()
 Purpose   : closes the device
 Returns   : self
 Argument  : none
 Throws    : croaks on problems

=cut

################################################## subroutine header end ##
sub close() {
	my $self = shift;
	croak "No radio to close" unless $self->{ _fh };
	close( $self->{ _fh } )
		or croak "Could not close radio: $!";
	delete $self->{ _fh };
	$self;
}

################################################ subroutine header begin ## 

=head2 set_frequency()

 Usage     : $radio->set_frequency( 106500 );
 Purpose   : sets the frequency of the device
 Returns   : self
 Argument  : the frequency in khz

=cut

################################################## subroutine header end ##
sub set_frequency() {
	my $self = shift;
	my $frequency = shift;
	croak "Open the radio first!" unless $self->{ _fh };
	ioctl( 
		$self->{ _fh }, 
		$self->_get_VIDIOCSFREQ, 
		pack(
		   "L", 
		   int( $frequency * $self->_get_frequency_factor() ) 
		) 
	)
		or croak "Could not set frequency: $!";
	$self;
}

sub _get_VIDIOCSFREQ() {
	return  0x4004760f;
	# return __get_VIDIOCSFREQ();
}

#use Inline C => <<'END_OF_C';
#		#include <linux/videodev.h>
#		long __get_VIDIOCSFREQ() {
#			return VIDIOCSFREQ;
#		}
#	
#END_OF_C

sub _get_VIDIOCGTUNER() {
	return 0xC0347604;
	# return __get_VIDIOCGTUNER();
}

#use Inline C => <<'END_OF_C';
#		#include <linux/videodev.h>
#		long __get_VIDIOCGTUNER() {
#			return VIDIOCGTUNER;
#		}
#	
#END_OF_C

sub _get_VIDEO_TUNER_LOW() {
	return 8;
	# return __get_VIDEO_TUNER_LOW;
}

#use Inline C => <<'END_OF_C';
#		#include <linux/videodev.h>
#		long __get_VIDEO_TUNER_LOW() {
#			return VIDEO_TUNER_LOW;
#		}
#	
#END_OF_C

sub _get_frequency_factor() {
	my $self = shift;
	$self->{ _deviceflags } & _get_VIDEO_TUNER_LOW() ?
		16
	:	.016;
}

1;

#
=head1 BUGS 
Many, but none known :)

=head1 SUPPORT 

=head1 AUTHOR

	Nathanael Obermayer
	natom-cpan@smi2le.net
	http://neuronenstern.de 

=head1 COPYRIGHT

Copyright (c) 2003 Nathanael Obermayer. All rights reserved.
This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.  

=head1 SEE ALSO

Video::Capture::V4l
 
=cut
