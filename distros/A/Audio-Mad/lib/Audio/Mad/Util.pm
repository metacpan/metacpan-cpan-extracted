package Audio::Mad::Util;
require 5.6.0;

use strict;
use warnings;

use Audio::Mad qw(:all);

use Exporter;
our @ISA = ('Exporter');

our @EXPORT_OK   = qw(mad_stream_info mad_parse_xing mad_cbr_seek mad_xing_seek);
our %EXPORT_TAGS = ( all => [@EXPORT_OK] );

sub mad_stream_info {
	my ($fh, $do_toc, $do_ex) = @_;
	my ($h, $buf) = ({}, '');

	$do_toc = 0 unless (defined($do_toc) && $do_toc ne '');
	$do_ex  = 1 unless (defined($do_ex)  && $do_ex  ne '');
	
	## fail if file is zero bytes in length
	return undef if (($h->{f_size} = (stat($fh))[7]) == 0);
	
	## get a new stream object and turn off crc 
	## checking,  as many encoders are broken
	## and it isn't too terribly useful in decoding but 
	## works nicely for checking stream validity.

	## creates a mad_stream structure
	my $stream = new Audio::Mad::Stream(MAD_OPTION_IGNORECRC);

	## creates a mad_frame structure
	my $frame  = new Audio::Mad::Frame;
	
	## setup some initial counter type things.
	$h->{s_frames}   = 0;
	$h->{s_vbr}      = 0;

	## s_size is the size of the stream,  and we attempt to
	## correct this key for ID3 tags and other extraneous
	## data -- in the case of a xing header,  we use it's
	## size variable if possible..
	$h->{s_size}     = $h->{f_size};

	## create a mad_timer structure
	$h->{s_duration} = new Audio::Mad::Timer;

	## we use these variables to calaculate a toc strucutre
	## when requested by the do_toc argument to this sub,
	## it provides an easy index for searching through the
	## stream.
	my $scale = $h->{s_size} / 100;
	my @toc   = ();
	
	## to start,  we cycle on a frame-by-frame basis..
	FRAME: while(1) {

		## calls mad_frame_decode,  and returns the
		## same value (-1 for error);
		if ($frame->decode_header($stream) == -1) {
			## corresponds to MAD_RECOVERABLE(stream->error),
			## if it is recoverable,  just skip to the next
			## frame.
			next FRAME if ($stream->err_ok());

			## otherwise,  if we get an error due to and
			## end of buffer condition (BUFLEN),  or because 
			## the buffer was never set (BUFPTR) take action
			## to fill the buffer.
			if (
			    $stream->error == MAD_ERROR_BUFLEN || 
			    $stream->error == MAD_ERROR_BUFPTR
			) {
				## this is to capture the frame fragment at
				## the end of the buffer,  if we don't do this
				## we lose the frame.
				$buf = substr($buf, $stream->next_frame);
			
				## attempt to read more data onto the end of
				## the buffer,  we drop out of our loop at
				## the end of the file.
				last FRAME if (sysread($fh, $buf, 128000, length($buf)) == 0);
				
				## call mad_stream_buffer on the newly created buffer.
				$stream->buffer($buf);
				
				## from here,  we restart our loop on the frame
				## we just failed to decode.
				redo FRAME;
			}
			
			## otherwise,  it's a fatal error that we're not 
			## prepared to deal with..
			return undef;
		}
	
		## keep a tally of the frames processed during 
		## this loop,  and evaluate this block only
		## during the first frame processed..
		unless ($h->{s_frames}++) {
			
			## this is some fairly obvious setup..
			
			$h->{s_bitrate}    = 
			$h->{s_avgrate}    = $frame->bitrate();
			
			$h->{s_samplerate} = $frame->samplerate();
			$h->{s_mode}       = $frame->mode();
			$h->{s_layer}      = $frame->layer();
			$h->{s_flags}      = $frame->flags();
			
			## try to parse a xing header out of the first frame.
			mad_parse_xing($h, substr($buf, $stream->this_frame, $stream->next_frame - $stream->this_frame));

			## if we got a xing header,  xing_flags will always
			## be defined.  next we do some vbr specific setup..
			if (defined($h->{xing_flags})) {
				$h->{s_vbr} = 1;

				## we try to believe the xing header is accurate
				## when possible,  but you can always use f_size
				## to get the true file size (possibly for seeking)
				if ($h->{xing_flags} & 0x0002) {
					$h->{s_size} = $h->{xing_bytes};
				}

				if ($h->{xing_flags} & 0x0001) {
					if ($do_toc) {
						## track that it's a vbr file that had it's own
						## xing header with a frame count,  but we were
						## requested to generate our own anyways..
						$h->{s_vbr} = 3;
					} else {
						## otherwise we just believe what the xing header
						## tells us,  note that we used the xing frame count
						## and skip out of further stream processing..
						$h->{s_frames} = $h->{xing_frames};
						$h->{s_vbr}    = 2;
						last FRAME;
					}
				}				
			}
		}
		
		## if it hasen't been found to be a vbr stream,  and
		## we are still in the first 20 frames,  check to see
		## that the bitrates actually match up.  this is a
		## primitive check,  but it works and dosen't fail
		## too horribly..
		if ($h->{s_vbr} == 0 && $h->{s_frames} < 20) {
			$h->{s_vbr} = 1 if ($frame->bitrate() != $h->{s_bitrate});
		} elsif ($h->{s_vbr} == 0 || $h->{s_vbr} == 2) {
			## otherwise,  after 20 frames if it hasn't found vbr
			## qualities -- or -- if it has found a xing_frame
			## count it can use,  just skip further frame processing.
			last FRAME;
		}
		
		## add up current frame duration..
		$h->{s_duration}->add($frame->duration());

		## keep a rolling average (mean,  maybe?) of the streams
		## bitrate.
		$h->{s_avgrate} = ($h->{s_avgrate} + $frame->bitrate()) / 2;
		
		## process the next frame unless we are asked to generate
		## a toc for this stream.
		next FRAME unless ($do_toc);

		## save the position of the next frame in our 
		## table of contents array for later processing..
		## fix:  this dosen't work,  ->this_frame points to
		## the offset of the frame relative to the beginning
		## of the buffer,  not the file..  we need a little
		## spiffy math here..
		push(@toc, $stream->this_frame());
	} ## end of FRAME loop
	
	## indicate an invalid mpeg stream if we didn't find ANY frames.
	return undef unless ($h->{s_frames});

	## track the duration of an individual frame,  which if I understand
	## things correctly will be uniform across an mpeg stream.
	$h->{s_frame_duration} = $frame->duration();
	
	## if we aren't dealing with a vbr stream,  it's pretty easy
	## to make some calculations.  these are a rough perlish estimate
	## of what I found in the madplay sources.
	if ($h->{s_vbr} == 0) {
		my $time = ($h->{s_size} * 8) / $h->{s_bitrate};
		my $frac = $time - int($time);
		my $samp = 32 * $frame->NSBSAMPLES;
		
		$h->{s_frames} = int($time * $h->{s_samplerate} / $samp);
		$h->{s_duration}->set(int($time), int($frac * 1000), MAD_UNITS_MILLISECONDS);
		
		$h->{s_avgrate} = $h->{s_bitrate};
	} elsif ($h->{s_vbr} == 1 || $h->{s_vbr} == 2) {
		## otherwise we're dealing with a vbr file,  and
		## we weren't asked to generate our own toc..
		if ($h->{s_vbr} == 2) {
			## using the uniform frame length assumption,  we just
			## take our frame length and multiply it by the number
			## of frames.
			$h->{s_duration}->add($h->{s_frame_duration});
			$h->{s_duration}->multiply($h->{s_frames});
		}

		## here,  we're just figuring out the average number of BITS per
		## second this stream runs at..
		$h->{s_avgrate} = int(($h->{s_size} * 8) / $h->{s_duration}->count(MAD_UNITS_SECONDS));
	} else {
		## we wanted a custom toc,  just take our mean average 
		## rate we've been generating,  and stuff out fake
		## toc in the xing_toc slot (this could be clearer,  but
		## it's easier to find that information in one spot).
		$h->{s_avgrate} = int($h->{s_avgrate});
		$h->{xing_toc}  = \@toc;
	}
	
	## give us back our information unless we were asked to 
	## generate some extended text information in our data..
	return $h unless ($do_ex);
	
	## this last section is pretty easy to grok..
	
	$h->{s_seconds} = $h->{s_duration}->count(MAD_UNITS_SECONDS);

	$h->{s_version} = (
	  ($h->{s_flags} & MAD_FLAG_MPEG_2_5_EXT) ? '2.5' :
	  ($h->{s_flags} & MAD_FLAG_LSF_EXT)      ? '2.0' :
	                                            '1.0'
	);
	
	$h->{s_modetext} = (
	  ($h->{s_mode} == MAD_MODE_SINGLE_CHANNEL) ? 'mono'         :
	  ($h->{s_mode} == MAD_MODE_DUAL_CHANNEL)   ? 'dual-channel' :
	  ($h->{s_mode} == MAD_MODE_JOINT_STEREO)   ? 'joint-stereo' :
	  ($h->{s_mode} == MAD_MODE_STEREO)         ? 'stereo'       :
	                                              'unknown'
	);	                                            
	
	$h->{s_flagtext} .= ($h->{s_vbr} > 0                      ? 'v' : '.');
	$h->{s_flagtext} .= ($h->{s_vbr} > 1                      ? 'x' : '.');
	$h->{s_flagtext} .= (($h->{s_flags} & MAD_FLAG_COPYRIGHT) ? 'c' : '.');
	$h->{s_flagtext} .= (($h->{s_flags} & MAD_FLAG_ORIGINAL)  ? 'o' : '.');
	$h->{s_flagtext} .= (($h->{s_flags} & MAD_FLAG_I_STEREO)  ? 'i' : '.');
	$h->{s_flagtext} .= (($h->{s_flags} & MAD_FLAG_MS_STEREO) ? 'm' : '.');
	

	## send back our info..
	return $h;	
}

sub mad_parse_xing {
	my ($h, $data) = @_;
	my ($len, $lp, $x) = (length($data), 0, {});
	
	## search through the data block looking for the
	## Xing header tag.
	for ($lp = 0; $lp <= $len; $lp++) { 
		next unless (substr($data, $lp, 4) eq 'Xing');
		last;
	}

	## if we don't have enough bytes,  we can't help you..
	return undef if ($lp > $len - 8);  # valid xing is at least 8 bytes

	## not sure if the unpack is cross-platform,  but it works 
	## for me on x86.  it decodes the four xing_flags bytes
	## from the data block..
	$x->{xing_flags} = unpack('N', substr($data, ($lp + 4)));
	$lp += 8;     # increment past 'Xing' and unpack,  above.
	$len -= $lp;  # keep track of relevant string length remaining.

	## these are pretty self evident,  again I'm not sure if
	## the unpacks are good enough for everyone.  each of
	## these will return undef if they run into a corrupted
	## or malformed xing header.

	if ($x->{xing_flags} & 0x0001) {
		return undef unless ($len >= 4);
		$x->{xing_frames} = unpack('N', substr($data, $lp));
		($lp, $len) = ($lp + 4, $len - 4);
	}
	
	if ($x->{xing_flags} & 0x0002) {
		return undef unless ($len >= 4);
		$x->{xing_bytes} = unpack('N', substr($data, $lp));
		($lp, $len) = ($lp + 4, $len - 4);
	}
	
	## why not make the toc last?  and let it have arbitrary
	## scale and length?  *shrug*
	if ($x->{xing_flags} & 0x0004) {
		return undef unless ($len >= 100);
		$x->{xing_toc} = [unpack('C100', substr($data, $lp))];
		($lp, $len) = ($lp + 100, $len - 100);
	}
	
	if ($x->{xing_flags} & 0x0008) {
		return undef unless ($len >= 4);
		$x->{xing_scale} = unpack('N', substr($data, $lp));
		($lp, $len) = ($lp + 4, $len - 4);
	}
	
	## take the cheap route of mapping our temporary
	## xing values in $x and smack them into $h,  on
	## the side it returns us a copy of just the xing
	## variables as a hash..
	map { $h->{$_} => $x->{$_} } keys(%{$x});
}

sub mad_cbr_seek {
	my %args = @_;
	
	my ($pos, $range, $frames, $size) = @args{qw(position range frames size)};

	## exit out if we are in an impossible situation..
	return undef unless ($pos >= 0 && $pos <= $range);
	
	## there's only one answer for zero range..
	return (0, 0) if ($range == 0);
	
	## otherwise,  calculation is easy as pie.
	return wantarray 
		? (int(($size / $range) * $pos), int(($frames / $range) * $pos))
		: int(($size / $range) * $pos)
	;
}

sub mad_xing_seek {
	my %args = @_;
	
	my ($pos, $range, $frames, $toc) = @args{qw(position range frames toc)};
	
	## exit out if we can't do that..
	return undef unless ($pos >= 0 && $pos <= $range);
	
	## there's only one answer for zero range..
	return 0 if ($range == 0);
	
	## calculating which frame is the easy part..
	my $frame = int(($frames / $range) * $pos);
	
	## telling us where that frame is requires us
	## to have the toc built..  handy thing that is..
	return wantarray
		? ($toc->[$frame], $frame)
		: $toc->[$frame]
	;
}


##############################################################################
1;
__END__
=pod

=head1 NAME

Audio::Mad::Util - a utility class for working with mpeg streams

=head1 DESCRIPTION
	
  This module provides some support functions for gathering
  information out of an mpeg stream.  Currently this module
  is intended for learning and internal purposes only,  it
  will have better documentation and a cleaner interface 
  in future versions.
  
=head1 AUTHOR

Mark McConnell E<lt>mischke@cpan.orgE<gt>	

=cut
