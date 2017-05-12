/* $Id: MikMod.xs,v 1.2 1999/07/28 02:00:33 daniel Exp $ */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <mikmod.h>

static int
not_here(char *s) {
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int arg)
{
    errno = 0;
    switch (*name) {
    case 'A':
	break;
    case 'B':
	break;
    case 'C':
	break;
    case 'D':
	break;
    case 'E':
	break;
    case 'F':
	break;
    case 'G':
	break;
    case 'H':
	break;
    case 'I':
	break;
    case 'J':
	break;
    case 'K':
	break;
    case 'L':
	if (strEQ(name, "LIBMIKMOD_REVISION"))
#ifdef LIBMIKMOD_REVISION
	    return LIBMIKMOD_REVISION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LIBMIKMOD_VERSION"))
#ifdef LIBMIKMOD_VERSION
	    return LIBMIKMOD_VERSION;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LIBMIKMOD_VERSION_MAJOR"))
#ifdef LIBMIKMOD_VERSION_MAJOR
	    return LIBMIKMOD_VERSION_MAJOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "LIBMIKMOD_VERSION_MINOR"))
#ifdef LIBMIKMOD_VERSION_MINOR
	    return LIBMIKMOD_VERSION_MINOR;
#else
	    goto not_there;
#endif
	break;
    case 'M':
	break;
    case 'N':
	break;
    case 'O':
	break;
    case 'P':
	break;
    case 'Q':
	break;
    case 'R':
	break;
    case 'S':
	if (strEQ(name, "SFX_CRITICAL"))
#ifdef SFX_CRITICAL
	    return SFX_CRITICAL;
#else
	    goto not_there;
#endif
	break;
    case 'T':
	break;
    case 'U':
	break;
    case 'V':
	break;
    case 'W':
	break;
    case 'X':
	break;
    case 'Y':
	break;
    case 'Z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}

MODULE = Audio::MikMod		PACKAGE = Audio::MikMod

double
constant(name,arg)
	char *		name
	int		arg

UWORD
MikMod_md_mode(...)
	PROTOTYPE: ;$
	CODE:
	{
		if (items == 1)
			md_mode |= SvUV(ST(0));

		RETVAL = md_mode;
	}
	OUTPUT:
	RETVAL

BOOL
MikMod_Active()

BOOL
MikMod_EnableOutput()

void
MikMod_DisableOutput()

void
MikMod_Exit()

long
MikMod_GetVersion()

CHAR *
MikMod_InfoDriver()

CHAR *
MikMod_InfoLoader()

BOOL
MikMod_Init(...)
	PROTOTYPE: ;$
	PREINIT:
	CHAR	*parameters = NULL;
	STRLEN  len;

	CODE:
	{
		if (items == 1)
			parameters = (CHAR *)SvPV(ST(0), len);

		RETVAL = MikMod_Init(parameters);
	}
	OUTPUT:
	RETVAL

BOOL
MikMod_InitThreads()

void
MikMod_Lock()

void
MikMod_RegisterAllDrivers()

void
MikMod_RegisterAllLoaders()

void
MikMod_RegisterDriver(newdriver)
	struct MDRIVER		*newdriver

MikMod_handler_t
MikMod_RegisterErrorHandler(newhandler)
	MikMod_handler_t	newhandler

void
MikMod_RegisterLoader(newloader)
	struct MLOADER 		*newloader

MikMod_player_t
MikMod_RegisterPlayer(newplayer)
	MikMod_player_t		newplayer

BOOL
MikMod_Reset(...)
	PROTOTYPE: ;$
	PREINIT:
	CHAR	*parameters = NULL;
	STRLEN  len;

	CODE:
	{
		if (items == 1)
			parameters = (CHAR *)SvPV(ST(0), len);

		RETVAL = MikMod_Init(parameters);
	}
	OUTPUT:
	RETVAL

BOOL
MikMod_SetNumVoices(musicvoices, samplevoices)
	int	musicvoices
	int	samplevoices

void
MikMod_Unlock()

void
MikMod_Update()

char *
MikMod_strerror()
	CODE:
	{
		RETVAL = MikMod_strerror(MikMod_errno);
	}
	OUTPUT:
	RETVAL

#####################################################

BOOL
Player_Active()

void
Player_Free(module)
	MODULE 		*module

int
Player_GetChannelVoice(channel)
	UBYTE	channel

MODULE *
Player_GetModule()

MODULE *
Player_Load(filename, maxchan, curious)
	CHAR 	*filename
	int	maxchan
	BOOL	curious

MODULE *
Player_LoadFP(file, maxchan, curious)
	FILE	*file
	int	maxchan
	BOOL	curious

CHAR *
Player_LoadTitle(filename)
	CHAR	*filename

void
Player_Mute(operation, ...)
	SLONG	operation

BOOL
Player_Muted(channel)
	UBYTE	channel

void
Player_NextPosition()

BOOL
Player_Paused()

void
Player_PrevPosition()

void
Player_SetPosition(position)
	UWORD	position

void
Player_SetSpeed(speed)
	UWORD	speed

void
Player_SetTempo(tempo)
	UWORD	tempo

void
Player_SetVolume(volume)
	SWORD	volume

void
Player_Start(module)
	MODULE	*module

void
Player_Stop()

void
Player_ToggleMute(operation, ...)
	SLONG	operation

void
Player_TogglePause()

void
Player_Unmute(operation, ...)
	SLONG	operation

#######################################################

void
Sample_Free(sample)
	SAMPLE		*sample

SAMPLE *
Sample_Load(filename)
	CHAR 		*filename

SAMPLE *
Sample_LoadFP(file)
	FILE		*file

SBYTE
Sample_Play(sample, start, flags)
	SAMPLE		*sample
	ULONG		start
	UBYTE		flags

########################################################

ULONG
Voice_GetFrequency(voice)
	SBYTE	voice

ULONG
Voice_GetPanning(voice)
	SBYTE	voice

SLONG
Voice_GetPosition(voice)
	SBYTE	voice

UWORD
Voice_GetVolume(voice)
	SBYTE	voice

void
Voice_Play(voice, sample, start)
	SBYTE		voice
	SAMPLE		*sample
	ULONG		start

ULONG
Voice_RealVolume(voice)
	SBYTE	voice

void
Voice_SetFrequency(voice, frequency)
	SBYTE	voice
	ULONG	frequency

void
Voice_SetPanning(voice, panning)
	SBYTE	voice
	ULONG	panning

void
Voice_SetVolume(voice, volume)
	SBYTE	voice
	UWORD	volume

void
Voice_Stop(voice)
	SBYTE	voice

BOOL
Voice_Stopped(voice)
	SBYTE	voice
