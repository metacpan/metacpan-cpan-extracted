package Audio::BASSXS;

use strict;
use warnings;
use Carp;
our $VERSION = '0.02';


require Exporter;
use AutoLoader;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

our @EXPORT = qw(
    BASS_SetConfig
    BASS_GetConfig

    BASS_Init
    BASS_Start
    BASS_Stop
    BASS_Pause
    BASS_ErrorGetCode
    BASS_GetVersion
    BASS_GetDeviceDescription
    BASS_SetDevice
    BASS_GetDevice
    BASS_Free
    BASS_GetDSoundObject
    BASS_GetInfo
    BASS_Update
    BASS_GetCPU
    BASS_SetVolume
    BASS_GetVolume

    BASS_StreamCreate        
    BASS_StreamCreateFile    
    BASS_StreamPlay          
    BASS_StreamCreateURL     
    BASS_StreamCreateFileUser
    BASS_StreamFree          
    BASS_StreamGetLength     
    BASS_StreamGetTags       
    BASS_StreamPreBuf        
    BASS_StreamGetFilePosition

	BASS_3DALG_DEFAULT
	BASS_3DALG_FULL
	BASS_3DALG_LIGHT
	BASS_3DALG_OFF
	BASS_3DMODE_NORMAL
	BASS_3DMODE_OFF
	BASS_3DMODE_RELATIVE
	BASS_ACTIVE_PAUSED
	BASS_ACTIVE_PLAYING
	BASS_ACTIVE_STALLED
	BASS_ACTIVE_STOPPED
	BASS_CONFIG_3DALGORITHM
	BASS_CONFIG_BUFFER
	BASS_CONFIG_CURVE_PAN
	BASS_CONFIG_CURVE_VOL
	BASS_CONFIG_FLOATDSP
	BASS_CONFIG_GVOL_MUSIC
	BASS_CONFIG_GVOL_SAMPLE
	BASS_CONFIG_GVOL_STREAM
	BASS_CONFIG_MAXVOL
	BASS_CONFIG_NET_BUFFER
	BASS_CONFIG_NET_TIMEOUT
	BASS_CONFIG_UPDATEPERIOD
	BASS_CTYPE_MUSIC_IT
	BASS_CTYPE_MUSIC_MO3
	BASS_CTYPE_MUSIC_MOD
	BASS_CTYPE_MUSIC_MTM
	BASS_CTYPE_MUSIC_S3M
	BASS_CTYPE_MUSIC_XM
	BASS_CTYPE_RECORD
	BASS_CTYPE_SAMPLE
	BASS_CTYPE_STREAM
	BASS_CTYPE_STREAM_MP1
	BASS_CTYPE_STREAM_MP2
	BASS_CTYPE_STREAM_MP3
	BASS_CTYPE_STREAM_OGG
	BASS_CTYPE_STREAM_WAV
	BASS_DATA_AVAILABLE
	BASS_DATA_FFT1024
	BASS_DATA_FFT2048
	BASS_DATA_FFT4096
	BASS_DATA_FFT512
	BASS_DATA_FFT_INDIVIDUAL
	BASS_DATA_FFT_NOWINDOW
	BASS_DEVICE_3D
	BASS_DEVICE_8BITS
	BASS_DEVICE_LATENCY
	BASS_DEVICE_MONO
	BASS_DEVICE_SPEAKERS
	BASS_ERROR_ALREADY
	BASS_ERROR_BUFLOST
	BASS_ERROR_CREATE
	BASS_ERROR_DECODE
	BASS_ERROR_DEVICE
	BASS_ERROR_DRIVER
	BASS_ERROR_DX
	BASS_ERROR_EMPTY
	BASS_ERROR_FILEFORM
	BASS_ERROR_FILEOPEN
	BASS_ERROR_FORMAT
	BASS_ERROR_FREQ
	BASS_ERROR_HANDLE
	BASS_ERROR_ILLPARAM
	BASS_ERROR_ILLTYPE
	BASS_ERROR_INIT
	BASS_ERROR_MEM
	BASS_ERROR_NO3D
	BASS_ERROR_NOCHAN
	BASS_ERROR_NOEAX
	BASS_ERROR_NOFX
	BASS_ERROR_NOHW
	BASS_ERROR_NONET
	BASS_ERROR_NOPAUSE
	BASS_ERROR_NOPLAY
	BASS_ERROR_NOTAVAIL
	BASS_ERROR_NOTFILE
	BASS_ERROR_PLAYING
	BASS_ERROR_POSITION
	BASS_ERROR_SPEAKER
	BASS_ERROR_START
	BASS_ERROR_TIMEOUT
	BASS_ERROR_UNKNOWN
	BASS_FILEPOS_DECODE
	BASS_FILEPOS_DOWNLOAD
	BASS_FILEPOS_END
	BASS_FILE_CLOSE
	BASS_FILE_LEN
	BASS_FILE_QUERY
	BASS_FILE_READ
	BASS_FILE_SEEK
	BASS_FX_PHASE_180
	BASS_FX_PHASE_90
	BASS_FX_PHASE_NEG_180
	BASS_FX_PHASE_NEG_90
	BASS_FX_PHASE_ZERO
	BASS_INPUT_LEVEL
	BASS_INPUT_OFF
	BASS_INPUT_ON
	BASS_INPUT_TYPE_ANALOG
	BASS_INPUT_TYPE_AUX
	BASS_INPUT_TYPE_CD
	BASS_INPUT_TYPE_DIGITAL
	BASS_INPUT_TYPE_LINE
	BASS_INPUT_TYPE_MASK
	BASS_INPUT_TYPE_MIC
	BASS_INPUT_TYPE_PHONE
	BASS_INPUT_TYPE_SPEAKER
	BASS_INPUT_TYPE_SYNTH
	BASS_INPUT_TYPE_UNDEF
	BASS_INPUT_TYPE_WAVE
	BASS_MP3_SETPOS
	BASS_MUSIC_3D
	BASS_MUSIC_AUTOFREE
	BASS_MUSIC_CALCLEN
	BASS_MUSIC_DECODE
	BASS_MUSIC_FLOAT
	BASS_MUSIC_FT2MOD
	BASS_MUSIC_FX
	BASS_MUSIC_LOOP
	BASS_MUSIC_MONO
	BASS_MUSIC_NONINTER
	BASS_MUSIC_NOSAMPLE
	BASS_MUSIC_POSRESET
	BASS_MUSIC_PT1MOD
	BASS_MUSIC_RAMP
	BASS_MUSIC_RAMPS
	BASS_MUSIC_STOPBACK
	BASS_MUSIC_SURROUND
	BASS_MUSIC_SURROUND2
	BASS_OBJECT_DS
	BASS_OBJECT_DS3DL
	BASS_OK
	BASS_RECORD_PAUSE
	BASS_SAMPLE_3D
	BASS_SAMPLE_8BITS
	BASS_SAMPLE_FLOAT
	BASS_SAMPLE_FX
	BASS_SAMPLE_LOOP
	BASS_SAMPLE_MONO
	BASS_SAMPLE_MUTEMAX
	BASS_SAMPLE_OVER_DIST
	BASS_SAMPLE_OVER_POS
	BASS_SAMPLE_OVER_VOL
	BASS_SAMPLE_SOFTWARE
	BASS_SAMPLE_VAM
	BASS_SLIDE_FREQ
	BASS_SLIDE_PAN
	BASS_SLIDE_VOL
	BASS_SPEAKER_CENLFE
	BASS_SPEAKER_CENTER
	BASS_SPEAKER_FRONT
	BASS_SPEAKER_FRONTLEFT
	BASS_SPEAKER_FRONTRIGHT
	BASS_SPEAKER_LEFT
	BASS_SPEAKER_LFE
	BASS_SPEAKER_REAR
	BASS_SPEAKER_REAR2
	BASS_SPEAKER_REAR2LEFT
	BASS_SPEAKER_REAR2RIGHT
	BASS_SPEAKER_REARLEFT
	BASS_SPEAKER_REARRIGHT
	BASS_SPEAKER_RIGHT
	BASS_STREAMPROC_END
	BASS_STREAM_AUTOFREE
	BASS_STREAM_BLOCK
	BASS_STREAM_DECODE
	BASS_STREAM_META
	BASS_STREAM_RESTRATE
	BASS_SYNC_DOWNLOAD
	BASS_SYNC_END
	BASS_SYNC_MESSAGE
	BASS_SYNC_META
	BASS_SYNC_MIXTIME
	BASS_SYNC_MUSICFX
	BASS_SYNC_MUSICINST
	BASS_SYNC_MUSICPOS
	BASS_SYNC_ONETIME
	BASS_SYNC_POS
	BASS_SYNC_SLIDE
	BASS_SYNC_STALL
	BASS_TAG_HTTP
	BASS_TAG_ICY
	BASS_TAG_ID3
	BASS_TAG_ID3V2
	BASS_TAG_META
	BASS_TAG_OGG
	BASS_UNICODE
	BASS_VAM_HARDWARE
	BASS_VAM_SOFTWARE
	BASS_VAM_TERM_DIST
	BASS_VAM_TERM_PRIO
	BASS_VAM_TERM_TIME
	DSCAPS_CERTIFIED
	DSCAPS_CONTINUOUSRATE
	DSCAPS_EMULDRIVER
	DSCAPS_SECONDARY16BIT
	DSCAPS_SECONDARY8BIT
	DSCAPS_SECONDARYMONO
	DSCAPS_SECONDARYSTEREO
	DSCCAPS_CERTIFIED
	DSCCAPS_EMULDRIVER
	EAX_PRESET_ALLEY
	EAX_PRESET_ARENA
	EAX_PRESET_AUDITORIUM
	EAX_PRESET_BATHROOM
	EAX_PRESET_CARPETEDHALLWAY
	EAX_PRESET_CAVE
	EAX_PRESET_CITY
	EAX_PRESET_CONCERTHALL
	EAX_PRESET_DIZZY
	EAX_PRESET_DRUGGED
	EAX_PRESET_FOREST
	EAX_PRESET_GENERIC
	EAX_PRESET_HALLWAY
	EAX_PRESET_HANGAR
	EAX_PRESET_LIVINGROOM
	EAX_PRESET_MOUNTAINS
	EAX_PRESET_PADDEDCELL
	EAX_PRESET_PARKINGLOT
	EAX_PRESET_PLAIN
	EAX_PRESET_PSYCHOTIC
	EAX_PRESET_QUARRY
	EAX_PRESET_ROOM
	EAX_PRESET_SEWERPIPE
	EAX_PRESET_STONECORRIDOR
	EAX_PRESET_STONEROOM
	EAX_PRESET_UNDERWATER
	WAVE_FORMAT_1M08
	WAVE_FORMAT_1M16
	WAVE_FORMAT_1S08
	WAVE_FORMAT_1S16
	WAVE_FORMAT_2M08
	WAVE_FORMAT_2M16
	WAVE_FORMAT_2S08
	WAVE_FORMAT_2S16
	WAVE_FORMAT_4M08
	WAVE_FORMAT_4M16
	WAVE_FORMAT_4S08
	WAVE_FORMAT_4S16
);

sub Bass_ErrorString
{
    my $code = shift;
    my %errors = ( 
                    BASS_OK()			=> "all is OK",
                    BASS_ERROR_MEM()		=> "memory error",
                    BASS_ERROR_FILEOPEN()	=> "can't open the file",
                    BASS_ERROR_DRIVER()	        => "can't find a free/valid driver",
                    BASS_ERROR_BUFLOST()	=> "the sample buffer was lost",
                    BASS_ERROR_HANDLE()	        => "invalid handle",
                    BASS_ERROR_FORMAT()	        => "unsupported sample format",
                    BASS_ERROR_POSITION()	=> "invalid playback position",
                    BASS_ERROR_INIT()		=> "BASS_Init has not been successfully called",
                    BASS_ERROR_START()	        => "BASS_Start has not been successfully called",
                    BASS_ERROR_ALREADY()	=> "already initialized",
                    BASS_ERROR_NOPAUSE()	=> "not paused",
                    BASS_ERROR_NOCHAN()	        => "can't get a free channel",
                    BASS_ERROR_ILLTYPE()	=> "an illegal type was specified",
                    BASS_ERROR_ILLPARAM()	=> "an illegal parameter was specified",
                    BASS_ERROR_NO3D()		=> "no 3D support",
                    BASS_ERROR_NOEAX()	        => "no EAX support",
                    BASS_ERROR_DEVICE()	        => "illegal device number",
                    BASS_ERROR_NOPLAY() 	=> "not playing",
                    BASS_ERROR_FREQ()		=> "illegal sample rate",
                    BASS_ERROR_NOTFILE()	=> "the stream is not a file stream",
                    BASS_ERROR_NOHW()		=> "no hardware voices available",
                    BASS_ERROR_EMPTY()	        => "the MOD music has no sequence data",
                    BASS_ERROR_NONET()	        => "no internet connection could be opened",
                    BASS_ERROR_CREATE()	        => "couldn't create the file",
                    BASS_ERROR_NOFX()		=> "effects are not available",
                    BASS_ERROR_PLAYING()	=> "the channel is playing",
                    BASS_ERROR_NOTAVAIL()	=> "requested data is not available",
                    BASS_ERROR_DECODE()	        => "the channel is a \"decoding channel\"",
                    BASS_ERROR_DX()		=> "a sufficient DirectX version is not installed",
                    BASS_ERROR_TIMEOUT()	=> "connection timedout",
                    BASS_ERROR_FILEFORM()	=> "unsupported file format",
                    BASS_ERROR_SPEAKER()	=> "unavailable speaker",
                    BASS_ERROR_UNKNOWN()	=> "some other mystery error",
                  );
    return $errors{$code};
}

sub AUTOLOAD {
    # This AUTOLOAD is used to 'autoload' constants from the constant()
    # XS function.

    my $constname;
    our $AUTOLOAD;
    ($constname = $AUTOLOAD) =~ s/.*:://;
    croak "&Audio::BASSXS::constant not defined" if $constname eq 'constant';
    my ($error, $val) = constant($constname);
    if ($error) { croak $error; }
    {
	no strict 'refs';
	# Fixed between 5.005_53 and 5.005_61
#XXX	if ($] >= 5.00561) {
#XXX	    *$AUTOLOAD = sub () { $val };
#XXX	}
#XXX	else {
	    *$AUTOLOAD = sub { $val };
#XXX	}
    }
    goto &$AUTOLOAD;
}

require XSLoader;
XSLoader::load('Audio::BASSXS', $VERSION);

# Preloaded methods go here.

# Autoload methods go after =cut, and are processed by the autosplit program.

1;
__END__
# Below is stub documentation for your module. You'd better edit it!

=head1 NAME

Audio::BASSXS - Interface for the BASS Audio library (Win32 only)

=head1 SYNOPSIS

  use Audio::BASSXS;
  blah blah blah

=head1 DESCRIPTION

This is an XS wrapper for the BASS audio library. Not all functions
are wrapped yet, all constants are. The functions that are wrapped
can be found below.

There's one function available that is not part of the BASS library:
BASS_ErrorString. This function takes a BASS_ErorGetCode value, and
returns the appropiate errorstring.

Unless I provide information on a function, you can call every function
like described in the Helpfile distributed with the BASS library.

=head1 USAGE

=head2 Only in this Perl module

=over 4

=item BASS_ErrorString(code)

This function takes an errorcode like BASS_ErrorGetCode provides and
returns a string describing that error.

=back

=head2 Config

=over 4

=item BASS_SetConfig

see BASS documentation

=item BASS_GetConfig

see BASS documentation

=back

=head2 Initialization, info, etc

=over 4

=item BASS_Init

see BASS documentation

=item BASS_Start

see BASS documentation

=item BASS_Stop

see BASS documentation

=item BASS_Pause

see BASS documentation

=item BASS_ErrorGetCode

see BASS documentation and BASS_ErrorString

=item BASS_GetVersion

see BASS documentation

=item BASS_GetDeviceDescription

see BASS documentation

=item BASS_SetDevice

see BASS documentation

=item BASS_GetDevice

see BASS documentation

=item BASS_Free

see BASS documentation

=item BASS_GetDSoundObject

see BASS documentation

=item BASS_GetInfo

This function doesn't take any parameters and returns a hashref wit the
following keys:
    size
    flags
    hwsize
    hwfree
    freesam
    free3d
    minrate
    maxrate
    eax
    minbuf
    dsver
    latency
    initflags
    speakers
    driver
See the BASS documentation on the BASS_INFO structure for more information.

=item BASS_Update

see BASS documentation

=item BASS_GetCPU

see BASS documentation

=item BASS_SetVolume

see BASS documentation

=item BASS_GetVolume

=back

=head2 Streams

=over 4

=item BASS_StreamCreate        

see BASS documentation

=item BASS_StreamCreateFile    

see BASS documentation

=item BASS_StreamPlay          

see BASS documentation

=item BASS_StreamCreateURL     

see BASS documentation

=item BASS_StreamCreateFileUser

see BASS documentation

=item BASS_StreamFree          

see BASS documentation

=item BASS_StreamGetLength     

see BASS documentation

=item BASS_StreamGetTags       

see BASS documentation

=item BASS_StreamPreBuf        

see BASS documentation

=item BASS_StreamGetFilePosition

=back


=head1 SEE ALSO

BASS documentation, available in Microsoft Help format at
http://www.un4seen.com/bass.html

=head1 AUTHOR

Jouke Visser, E<lt>jouke@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2004 by Jouke Visser

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself,.


=cut
