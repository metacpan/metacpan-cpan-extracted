/*
 * Audio::ESD - Perl interface to the Enlightened Sound Daemon
 *
 * Copyright (c) 2000 Cepstral LLC.
 *
 * This module is free software; you can redistribute it and/or modify
 * it under the same terms as Perl itself.
 *
 * Written by David Huggins-Daines <dhd@cepstral.com>
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <esd.h>

static int
not_here(char *s)
{
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
	if (strEQ(name, "ESD_ADPCM"))
#ifdef ESD_ADPCM
	    return ESD_ADPCM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_BITS16"))
#ifdef ESD_BITS16
	    return ESD_BITS16;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_BITS8"))
#ifdef ESD_BITS8
	    return ESD_BITS8;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_BUF_SIZE"))
#ifdef ESD_BUF_SIZE
	    return ESD_BUF_SIZE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_DEFAULT_PORT"))
#ifdef ESD_DEFAULT_PORT
	    return ESD_DEFAULT_PORT;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_DEFAULT_RATE"))
#ifdef ESD_DEFAULT_RATE
	    return ESD_DEFAULT_RATE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_ENDIAN_KEY"))
#ifdef ESD_ENDIAN_KEY
	    return ESD_ENDIAN_KEY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_KEY_LEN"))
#ifdef ESD_KEY_LEN
	    return ESD_KEY_LEN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_LOOP"))
#ifdef ESD_LOOP
	    return ESD_LOOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_MASK_BITS"))
#ifdef ESD_MASK_BITS
	    return ESD_MASK_BITS;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_MASK_CHAN"))
#ifdef ESD_MASK_CHAN
	    return ESD_MASK_CHAN;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_MASK_FUNC"))
#ifdef ESD_MASK_FUNC
	    return ESD_MASK_FUNC;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_MASK_MODE"))
#ifdef ESD_MASK_MODE
	    return ESD_MASK_MODE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_MONITOR"))
#ifdef ESD_MONITOR
	    return ESD_MONITOR;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_MONO"))
#ifdef ESD_MONO
	    return ESD_MONO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_NAME_MAX"))
#ifdef ESD_NAME_MAX
	    return ESD_NAME_MAX;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_PLAY"))
#ifdef ESD_PLAY
	    return ESD_PLAY;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_RECORD"))
#ifdef ESD_RECORD
	    return ESD_RECORD;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_SAMPLE"))
#ifdef ESD_SAMPLE
	    return ESD_SAMPLE;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_STEREO"))
#ifdef ESD_STEREO
	    return ESD_STEREO;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_STOP"))
#ifdef ESD_STOP
	    return ESD_STOP;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_STREAM"))
#ifdef ESD_STREAM
	    return ESD_STREAM;
#else
	    goto not_there;
#endif
	if (strEQ(name, "ESD_VOLUME_BASE"))
#ifdef ESD_VOLUME_BASE
	    return ESD_VOLUME_BASE;
#else
	    goto not_there;
#endif
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

typedef int SysRet;
typedef int my_esd_t;

MODULE = Audio::ESD		PACKAGE = Audio::ESD		

double
constant(name,arg)
	char *		name
	int		arg

SysRet
esd_open_sound(host=NULL)
	char *		host

SysRet
esd_play_stream(format, rate, host=NULL, name=NULL)
	int		format
	int		rate
	char *		host
	char *		name

SysRet
esd_play_stream_fallback(format, rate, host=NULL, name=NULL)
	int		format
	int		rate
	char *		host
	char *		name

SysRet
esd_monitor_stream(format, rate, host=NULL, name=NULL)
	int		format
	int		rate
	char *		host
	char *		name

SysRet
esd_record_stream(format, rate, host=NULL, name=NULL)
	int		format
	int		rate
	char *		host
	char *		name

SysRet
esd_record_stream_fallback(format, rate, host=NULL, name=NULL)
	int		format
	int		rate
	char *		host
	char *		name

SysRet
esd_filter_stream(format, rate, host=NULL, name=NULL)
	int		format
	int		rate
	char *		host
	char *		name

MODULE = Audio::ESD		PACKAGE = Audio::ESD		PREFIX = esd_

SysRet
esd_send_auth(esd)
	my_esd_t	esd

SysRet
esd_lock(esd)
	my_esd_t	esd

SysRet
esd_unlock(esd)
	my_esd_t	esd

SysRet
esd_standby(esd)
	my_esd_t	esd

SysRet
esd_resume(esd)
	my_esd_t	esd

SysRet
esd_sample_cache(esd, format, rate, length, name=NULL)
	my_esd_t	esd
	int		format
	int		rate
	int		length
	char *		name

SysRet
esd_confirm_sample_cache(esd)
	my_esd_t	esd

SysRet
esd_sample_getid(esd, name)
	my_esd_t	esd
	char *		name

SysRet
esd_sample_free(esd, sample)
	my_esd_t	esd
	int		sample

SysRet
esd_sample_play(esd, sample)
	my_esd_t	esd
	int		sample

SysRet
esd_sample_loop(esd, sample)
	my_esd_t	esd
	int		sample

SysRet
esd_sample_stop(esd, sample)
	my_esd_t	esd
	int		sample

SysRet
esd_close(esd)
	my_esd_t	esd

SysRet
esd_get_latency(esd)
	my_esd_t	esd

esd_server_info_t *
esd_get_server_info(esd)
	my_esd_t	esd

esd_info_t *
esd_get_all_info(esd)
	my_esd_t	esd

SysRet
esd_set_stream_pan(esd, stream_id, left_scale, right_scale)
	my_esd_t	esd
	int		stream_id
	int		left_scale
	int		right_scale

SysRet
esd_set_default_sample_pan(esd, stream_id, left_scale, right_scale)
	my_esd_t	esd
	int		stream_id
	int		left_scale
	int		right_scale

int
esd_get_standby_mode(esd)
	my_esd_t	esd

MODULE = Audio::ESD		PACKAGE = esd_server_info_tPtr		PREFIX = esd_

void
esd_print_server_info(server_info)
	esd_server_info_t *	server_info

void
DESTROY(server_info)
	esd_server_info_t *	server_info
	CODE:
		esd_free_server_info(server_info);

MODULE = Audio::ESD		PACKAGE = esd_info_tPtr		PREFIX = esd_

void
esd_print_all_info(info)
	esd_info_t *	info

void
DESTROY(info)
	esd_info_t *	info
	CODE:
		esd_free_all_info(info);

