package Audio::Mad;
require 5.6.0;

use strict;
use warnings;
use Carp;

our $VERSION = '0.6';

require Exporter;
require DynaLoader;

our @ISA = qw(Exporter DynaLoader);

our @EXPORT    = qw();
our @EXPORT_OK = qw(
	MAD_DITHER_S8	  	  MAD_DITHER_U8
	MAD_DITHER_S16_LE	  MAD_DITHER_S16_BE
	MAD_DITHER_S24_LE	  MAD_DITHER_S24_BE
	MAD_DITHER_S32_LE	  MAD_DITHER_S32_BE
	
	MAD_ERROR_BADHUFFDATA     MAD_ERROR_LOSTSYNC       
	MAD_ERROR_BADCRC          MAD_ERROR_BADBITALLOC  
	MAD_ERROR_BADBITRATE      MAD_ERROR_BADSAMPLERATE
	MAD_ERROR_BADBLOCKTYPE    MAD_ERROR_BADHUFFTABLE   
	MAD_ERROR_BADSCFSI        MAD_ERROR_NOMEM        
	MAD_ERROR_BUFLEN          MAD_ERROR_BADFRAMELEN
	MAD_ERROR_BADPART3LEN     MAD_ERROR_BADSTEREO
	MAD_ERROR_BUFPTR          MAD_ERROR_BADLAYER
	MAD_ERROR_BADSCALEFACTOR  MAD_ERROR_BADDATAPTR
	MAD_ERROR_BADEMPHASIS     MAD_ERROR_BADBIGVALUES
	
	MAD_FLAG_COPYRIGHT        MAD_FLAG_FREEFORMAT
	MAD_FLAG_INCOMPLETE       MAD_FLAG_I_STEREO
	MAD_FLAG_LSF_EXT          MAD_FLAG_MS_STEREO
	MAD_FLAG_MC_EXT           MAD_FLAG_MPEG_2_5_EXT
	MAD_FLAG_NPRIVATE_III     MAD_FLAG_ORIGINAL
	MAD_FLAG_PROTECTION       MAD_FLAG_PADDING

	MAD_F_ONE                 MAD_F_MAX
	MAD_F_FRACBITS            MAD_F_MIN 
	
	MAD_LAYER_I               MAD_LAYER_II 
	MAD_LAYER_III
	
	MAD_MODE_SINGLE_CHANNEL   MAD_MODE_DUAL_CHANNEL 
	MAD_MODE_JOINT_STEREO     MAD_MODE_STEREO
	
	MAD_OPTION_IGNORECRC	  MAD_OPTION_HALFSAMPLERATE

	MAD_TIMER_RESOLUTION
	
	MAD_UNITS_8000_HZ         MAD_UNITS_MILLISECONDS
	MAD_UNITS_11025_HZ        MAD_UNITS_CENTISECONDS
	MAD_UNITS_12000_HZ        MAD_UNITS_DECISECONDS
	MAD_UNITS_16000_HZ        MAD_UNITS_SECONDS
	MAD_UNITS_22050_HZ        MAD_UNITS_MINUTES
	MAD_UNITS_24000_HZ        MAD_UNITS_HOURS
	MAD_UNITS_32000_HZ
	MAD_UNITS_44100_HZ
	MAD_UNITS_48000_HZ
);
our %EXPORT_TAGS = ( 
	all    => [@EXPORT_OK],
	dither => [qw(
		MAD_DITHER_S8	  	  MAD_DITHER_U8
		MAD_DITHER_S16_LE	  MAD_DITHER_S16_BE
		MAD_DITHER_S24_LE	  MAD_DITHER_S24_BE
		MAD_DITHER_S32_LE	  MAD_DITHER_S32_BE
	)],
	error  => [qw(
		MAD_ERROR_BADHUFFDATA  MAD_ERROR_LOSTSYNC       MAD_ERROR_BADCRC 
		MAD_ERROR_BADBITALLOC  MAD_ERROR_BADBITRATE     MAD_ERROR_BADSAMPLERATE
		MAD_ERROR_BADBLOCKTYPE MAD_ERROR_BADHUFFTABLE   MAD_ERROR_BADSCFSI
		MAD_ERROR_NOMEM        MAD_ERROR_BUFLEN         MAD_ERROR_BADFRAMELEN
		MAD_ERROR_BADPART3LEN  MAD_ERROR_BADSTEREO      MAD_ERROR_BUFPTR
		MAD_ERROR_BADLAYER     MAD_ERROR_BADSCALEFACTOR MAD_ERROR_BADDATAPTR
		MAD_ERROR_BADEMPHASIS  MAD_ERROR_BADBIGVALUES
	)],
	flag   => [qw(
		MAD_FLAG_COPYRIGHT       MAD_FLAG_FREEFORMAT
		MAD_FLAG_INCOMPLETE      MAD_FLAG_I_STEREO
		MAD_FLAG_LSF_EXT         MAD_FLAG_MS_STEREO
		MAD_FLAG_MC_EXT          MAD_FLAG_MPEG_2_5_EXT
		MAD_FLAG_NPRIVATE_III    MAD_FLAG_ORIGINAL
		MAD_FLAG_PROTECTION      MAD_FLAG_PADDING
	)],
	f      => [qw(MAD_F_ONE MAD_F_MIN MAD_F_MAX MAD_F_FRACBITS)],
	layer  => [qw(MAD_LAYER_I MAD_LAYER_II MAD_LAYER_III)],
	mode   => [qw(MAD_MODE_SINGLE_CHANNEL MAD_MODE_DUAL_CHANNEL MAD_MODE_JOINT_STEREO MAD_MODE_STEREO)],
	option => [qw(MAD_OPTION_HALFSAMPLERATE MAD_OPTION_IGNORECRC)],
	timer  => [qw(MAD_TIMER_RESOLUTION)],
	units  => [qw(
		MAD_UNITS_11025_HZ     MAD_UNITS_12000_HZ     MAD_UNITS_16000_HZ
	        MAD_UNITS_22050_HZ     MAD_UNITS_24000_HZ     MAD_UNITS_32000_HZ
	        MAD_UNITS_44100_HZ     MAD_UNITS_48000_HZ     MAD_UNITS_8000_HZ
	        MAD_UNITS_CENTISECONDS MAD_UNITS_DECISECONDS  MAD_UNITS_HOURS
	        MAD_UNITS_MINUTES      MAD_UNITS_MILLISECONDS MAD_UNITS_SECONDS
	)],
);



sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.  If a constant is not found then control is passed
    # to the AUTOLOAD in AutoLoader.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "& not defined" if $constname eq 'constant';
    my $val = constant($constname, @_ ? $_[0] : 0);
    if ($! != 0) {
    	if ($! =~ /Invalid/ || $!{EINVAL}) {
    		$AutoLoader::AUTOLOAD = $AUTOLOAD;
    		goto &AutoLoader::AUTOLOAD;
    	} else {
    		croak "Your vendor has not defined Audio::Mad macro $constname";
    	}
    }
    {
	no strict 'refs';
	*$AUTOLOAD = sub { $val };
    }
    goto &$AUTOLOAD;
}

##############################################################################
package Audio::Mad::Frame;

sub NCHANNELS  { $_[0]->mode() ? 2 : 1 }
sub NSBSAMPLES { 
	my ($self) = @_;
	
	return 12 if ($self->layer() == Audio::Mad::MAD_LAYER_I());
	return 18 if ($self->layer() == Audio::Mad::MAD_LAYER_III() && ($self->flags() & Audio::Mad::MAD_FLAG_LSF_EXT()));
	return 36;
}

##############################################################################
package Audio::Mad::Timer;

sub _expand {
	my $lh = $_[0]->count(Audio::Mad::MAD_UNITS_MILLISECONDS());

	my $ms = $lh % 1000;
	$lh    = ($lh - $ms) / 1000;
	
	my $se = $lh % 60;
	$lh    = ($lh - $se) / 60;
	
	my $mn = $lh % 60;
	$lh    = ($lh - $mn) / 60;
	
	return ($lh, $mn, $se, $ms);
}

use overload (
	'+'   => 'o_add',
	'++'  => 'o_inc',
	'-'   => 'o_subtract',
	'--'  => 'o_dec',
	'*'   => 'o_multiply',
	'/'   => 'o_divide',

	'>'   => 'o_gt',
	'>='  => 'o_ge',
	'<'   => 'o_lt',
	'<='  => 'o_le',
	'=='  => 'o_eq',
	'!='  => 'o_ne',
	'<=>' => 'o_cmp',

	'""'  => 'o_as_string',
	'0+'  => 'o_as_float',
	'${}' => 'o_as_stringref',
	'@{}' => 'o_as_arrayref',
	'%{}' => 'o_as_hashref'
);
	
sub o_add { 
	my ($lh, $rh, $how) = @_;

	$rh = new Audio::Mad::Timer (int($rh), ($rh - int($rh)) * 1000, Audio::Mad::MAD_UNITS_MILLISECONDS())
		if (!ref($rh));

	$lh = $lh->new_copy() if (defined($how));

	$lh->add($rh);
}

sub o_inc { $_[0]->add(Audio::Mad::Timer->new(1, 0, 0)) }

sub o_subtract { 
	my ($lh, $rh, $how) = @_;
	
	if (!ref($rh)) { $rh = Audio::Mad::Timer->new(int($rh), ($rh - int($rh)) * 1000, Audio::Mad::MAD_UNITS_MILLISECONDS()) } 
	else           { $rh = $rh->new_copy() }
	
	if (defined($how)) {
		($rh, $lh) = ($lh, $rh) if ($how);
		$lh = $lh->new_copy();
	}

	$lh->add($rh->negate());
}

sub o_dec { $_[0]->add(Audio::Mad::Timer->new(1, 0, 0)->negate()) }
	
sub o_multiply { 
	my ($lh, $rh, $how) = @_;
	
	$rh = $rh->count(&MAD_UNITS_SECONDS) if (ref($rh));

	$lh = $lh->new_copy() if (defined($how));

	$lh->multiply($rh);
}

sub o_divide {
	my ($lh, $rh, $how) = @_;
	
	$lh = 0 + $lh;
	$rh = 0 + $rh;
	
	($lh, $rh) = ($rh, $lh) if ($how);
	my $result = $lh / $rh;
	
	return new Audio::Mad::Timer (int($result), ($result - int($result)) * 1000, Audio::Mad::MAD_UNITS_MILLISECONDS());
}

sub o_gt { ($_[0] <=> $_[1]) >  0 ? 1 : 0 }
sub o_ge { ($_[0] <=> $_[1]) >= 0 ? 1 : 0 }

sub o_lt { ($_[0] <=> $_[1]) <  0 ? 1 : 0 }
sub o_le { ($_[0] <=> $_[1]) <= 0 ? 1 : 0 }

sub o_eq { ($_[0] <=> $_[1]) == 0 ? 1 : 0 }
sub o_ne { ($_[0] <=> $_[1]) != 0 ? 1 : 0 }

sub o_cmp {
	my ($lh, $rh, $how) = @_;
	
	$rh = new Audio::Mad::Timer (int($rh), ($rh - int($rh)) * 1000, Audio::Mad::MAD_UNITS_MILLISECONDS())
		if (!ref($rh));
	($rh, $lh) = ($lh, $rh) if ($how);
	
	return $lh->compare($rh);
}

sub o_as_string { sprintf('%02d:%02d:%02d.%03d', $_[0]->_expand())     }
sub o_as_float  { ($_[0]->count(Audio::Mad::MAD_UNITS_MILLISECONDS()) / 1000) }

sub o_as_arrayref  { [$_[0]->_expand()] }
sub o_as_stringref {
	my $temp = "$_[0]";
	return \$temp;
}
sub o_as_hashref {
	my ($hr, $mn, $se, $ms) = ($_[0]->_expand());
	return { hours => $hr, minutes => $mn, seconds => $se, milliseconds => $ms };
}

##############################################################################
package Audio::Mad;
bootstrap Audio::Mad $VERSION;
##############################################################################
1;
__END__

=head1 NAME

Audio::Mad - Perl interface to the mad MPEG decoder library

=head1 SYNOPSIS

  use Audio::Mad qw(:all);
  
  my $stream   = new Audio::Mad::Stream();
  my $frame    = new Audio::Mad::Frame();
  my $synth    = new Audio::Mad::Synth();
  my $timer    = new Audio::Mad::Timer();
  my $resample = new Audio::Mad::Resample(44100, 22050);
  my $dither   = new Audio::Mad::Dither();

  my $buffer = join('', <STDIN>);
  $stream->buffer($buffer);

  FRAME: {
  	if ($frame->decode($stream) == -1) {
  		last FRAME unless ($stream->err_ok());

  		warn "decoding error: " . $stream->error();
  		next FRAME;
  	}

  	$synth->synth($frame);
  	my $pcm = $dither->dither($resample->resample($synth->samples()));

  	print $pcm;
  	next FRAME;
  }
                             

=head1 DESCRIPTION

 This module is an attempt to provide a perl interface to the MAD
 (MPEG Audio Decoder) library,  written by Robert Leslie.  It has
 been designed to be 100% object oriented,  and to follow the MAD
 interface as closely as possible.

 So far,  most of the MAD library,  plus two companion modules
 are provided as part of the interface.  Seperate documentation 
 is provided in perldoc for all of the modules in the
 Audio::Mad framework.

=head1 EXPORT

=over 4

None by default.

=back

=head1 EXPORT_OK

=over 4

=item * :dither

	MAD_DITHER_S8	  	  MAD_DITHER_U8
	MAD_DITHER_S16_LE	  MAD_DITHER_S16_BE
	MAD_DITHER_S24_LE	  MAD_DITHER_S24_BE
	MAD_DITHER_S32_LE	  MAD_DITHER_S32_BE

=item * :error

	MAD_ERROR_BADHUFFDATA     MAD_ERROR_LOSTSYNC       
	MAD_ERROR_BADCRC          MAD_ERROR_BADBITALLOC  
	MAD_ERROR_BADBITRATE      MAD_ERROR_BADSAMPLERATE
	MAD_ERROR_BADBLOCKTYPE    MAD_ERROR_BADHUFFTABLE   
	MAD_ERROR_BADSCFSI        MAD_ERROR_NOMEM        
	MAD_ERROR_BUFLEN          MAD_ERROR_BADFRAMELEN
	MAD_ERROR_BADPART3LEN     MAD_ERROR_BADSTEREO
	MAD_ERROR_BUFPTR          MAD_ERROR_BADLAYER
	MAD_ERROR_BADSCALEFACTOR  MAD_ERROR_BADDATAPTR
	MAD_ERROR_BADEMPHASIS     MAD_ERROR_BADBIGVALUES
	
=item * :flag	
	
	MAD_FLAG_COPYRIGHT        MAD_FLAG_FREEFORMAT
	MAD_FLAG_INCOMPLETE       MAD_FLAG_I_STEREO
	MAD_FLAG_LSF_EXT          MAD_FLAG_MS_STEREO
	MAD_FLAG_MC_EXT           MAD_FLAG_MPEG_2_5_EXT
	MAD_FLAG_NPRIVATE_III     MAD_FLAG_ORIGINAL
	MAD_FLAG_PROTECTION       MAD_FLAG_PADDING

=item * :f

	MAD_F_ONE                 MAD_F_MAX
	MAD_F_FRACBITS            MAD_F_MIN 

=item * :layer
	
	MAD_LAYER_I               MAD_LAYER_III
	MAD_LAYER_II

=item * :mode
	
	MAD_MODE_SINGLE_CHANNEL   MAD_MODE_STEREO
	MAD_MODE_DUAL_CHANNEL     MAD_MODE_JOINT_STEREO

=item * :timer	

	MAD_TIMER_RESOLUTION

=item * :units
	
	MAD_UNITS_8000_HZ         MAD_UNITS_MILLISECONDS
	MAD_UNITS_11025_HZ        MAD_UNITS_CENTISECONDS
	MAD_UNITS_12000_HZ        MAD_UNITS_DECISECONDS
	MAD_UNITS_16000_HZ        MAD_UNITS_SECONDS
	MAD_UNITS_22050_HZ        MAD_UNITS_MINUTES
	MAD_UNITS_24000_HZ        MAD_UNITS_HOURS
	MAD_UNITS_32000_HZ
	MAD_UNITS_44100_HZ
	MAD_UNITS_48000_HZ
	
=back

=head1 AUTHOR

Mark McConnell E<lt>mischke@cpan.orgE<gt>

=head1 SEE ALSO

perl(1)  

Audio::Mad::Stream(3)
Audio::Mad::Frame(3)
Audio::Mad::Synth(3)
Audio::Mad::Resample(3)
Audio::Mad::Dither(3)
Audio::Mad::Timer(3)

=cut
