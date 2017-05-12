package Audio::MikMod;

# $Id: MikMod.pm,v 1.3 1999/07/29 18:56:30 daniel Exp $
use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS $AUTOLOAD);

require Exporter;
require DynaLoader;

@ISA = qw(Exporter DynaLoader);
@EXPORT_OK = qw(
	DMODE_16BITS DMODE_HQMIXER DMODE_INTERP DMODE_REVERSE
	DMODE_SOFT_MUSIC DMODE_SOFT_SNDFX DMODE_STEREO DMODE_SURROUND
	LIBMIKMOD_REVISION LIBMIKMOD_VERSION LIBMIKMOD_VERSION_MAJOR
	LIBMIKMOD_VERSION_MINOR
	PAN_CENTER PAN_LEFT PAN_RIGHT PAN_SURROUND
	SFX_CRITICAL

	MikMod_Active MikMod_DisableOutput MikMod_EnableOutput MikMod_Exit
	MikMod_GetVersion MikMod_InfoDriver MikMod_InfoLoader MikMod_Init
	MikMod_InitThreads MikMod_Lock MikMod_RegisterAllDrivers
	MikMod_RegisterAllLoaders MikMod_RegisterDriver MikMod_RegisterErrorHandler
	MikMod_RegisterLoader MikMod_RegisterPlayer MikMod_Reset MikMod_SetNumVoices
	MikMod_Unlock MikMod_Update MikMod_md_mode MikMod_strerror

	Player_Active Player_Free Player_GetChannelPeriod Player_GetChannelVoice
	Player_GetModule Player_Load Player_LoadFP Player_LoadGeneric Player_LoadTitle
	Player_Mute Player_Muted Player_NextPosition Player_Paused Player_PrevPosition
	Player_SetPosition Player_SetSpeed Player_SetTempo Player_SetVolume Player_Start
	Player_Stop Player_ToggleMute Player_TogglePause Player_Unmute

	Sample_Free Sample_Load Sample_LoadFP Sample_LoadGeneric Sample_Play

	Voice_GetFrequency Voice_GetPanning Voice_GetPosition Voice_GetVolume
	Voice_Play Voice_RealVolume Voice_SetFrequency Voice_SetPanning 
	Voice_SetVolume Voice_Stop Voice_Stopped
);

%EXPORT_TAGS = (
	'CONSTANTS' => [ grep /^(?:DMODE_|LIB|PAN_|SFX)/, @EXPORT_OK ],
	'MikMod'    => [ grep /^MikMod_/, @EXPORT_OK ],
	'Player'    => [ grep /^Player_/, @EXPORT_OK ],
	'Sample'    => [ grep /^Sample_/, @EXPORT_OK ],
	'Voice'     => [ grep /^Voice_/ , @EXPORT_OK ],
	'all'	    => [ @EXPORT_OK],
);

####################################################################
# The constant autoloading doesn't work right because of prototyping
# problems, when I want to hand a constant to a function. If there is a
# better way to do this, let me know!

use constant DMODE_16BITS     => 0x0001; # enable 16 bit output
use constant DMODE_STEREO     => 0x0002; # enable stereo output
use constant DMODE_SOFT_SNDFX => 0x0004; # Process sound effects via software mixer 
use constant DMODE_SOFT_MUSIC => 0x0008; # Process music via software mixer
use constant DMODE_HQMIXER    => 0x0010; # Use high-quality (slower) software mixer
use constant DMODE_SURROUND   => 0x0100; # enable surround sound
use constant DMODE_INTERP     => 0x0200; # enable interpolation
use constant DMODE_REVERSE    => 0x0400; # reverse stereo

use constant PAN_LEFT	      => 0;
use constant PAN_CENTER       => 128;
use constant PAN_RIGHT        => 255;
use constant PAN_SURROUND     => 512; # panning value for Dolby Surround 

$VERSION = '0.5';

bootstrap Audio::MikMod $VERSION;

sub AUTOLOAD {
	my $constname;
	($constname = $AUTOLOAD) =~ s/.*:://;
	croak "& not defined" if $constname eq 'constant';
	my $val = constant($constname, @_ ? $_[0] : 0);

	if ($! != 0) {
		if ($! !~ /Invalid/) {
			croak "Your vendor has not defined Audio::MikMod macro $constname : $!";
		}
		$AutoLoader::AUTOLOAD = $AUTOLOAD;
		goto &AutoLoader::AUTOLOAD;
	}
	no strict 'refs';
	*$AUTOLOAD = sub () { $val };
	goto &$AUTOLOAD;
}

1;
__END__

=head1 NAME

Audio::MikMod - Perl extension for libmikmod.

=head1 SYNOPSIS

  use Audio::MikMod qw(:all);
  use Time::HiRes;

  MikMod_RegisterAllDrivers();
  MikMod_RegisterAllLoaders();
  MikMod_Init();

  my $module = Player_Load('filename', 64, 0);
  Player_Start($module);

  while(Player_Active()) {
	usleep(10000);
	MikMod_Update();
  }

  Player_Stop();
  Player_Free($module);
  MikMod_Exit();

=head1 DESCRIPTION

This module provides an interface to the libmikmod library for playing
MOD, IT, XM, S3M, MTM, 669, STM, ULT, FAR, MED, AMF, DSM, IMF, GDM, and
STX tracker files. In addition, manipulation of WAV samples is supported.

Please see the extensive libmikmod info documentation included with that package.

libmikmod is required, and can be obtained at http://mikmod.darkorb.net/

=head1 AUTHOR

Daniel Sully <daniel-cpan-mikmod@electricrain.com>

=head1 SEE ALSO

info mikmod, perl(1).

=cut
