/*

   TiMidity -- Experimental MIDI to WAVE converter
   Copyright (C) 1995 Tuukka Toivonen <toivonen@clinet.fi>

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.

   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.

   win_audio.c

   Functions to play sound on the Win32 audio driver (Win 95 or Win NT).

 */
#include <windows.h>

#ifdef __MINGW32__
#include "../config/mmsystem.h"
#endif
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#include "../../Data/Audio.m"

AudioVtab *AudioVptr;

typedef long int32;

static void output_data(int32 * buf, int32 count);

/* export the playback mode */

#define PE_MONO      1
#define PE_SIGNED    2
#define PE_16BIT     4
#define PE_ULAW      8
#define PE_BYTESWAP 16
#define DEFAULT_RATE 8000

typedef struct
 {
  CRITICAL_SECTION critSect;
  int32 rate;
  int32 encoding;
  int32 extra_param[1]; /* Max audio blocks waiting to be played */
  LPHWAVEOUT dev;
  int nBlocks;
 }
play_audio_t;

#pragma argsused
static void CALLBACK 
wave_callback(HWAVE hWave, UINT uMsg,
              DWORD dwInstance, DWORD dwParam1, DWORD dwParam2)
{
 WAVEHDR *wh;
 HGLOBAL hg;
 if (uMsg == WOM_DONE)
  {
   play_audio_t *dev = (play_audio_t *) dwInstance;
   EnterCriticalSection(&dev->critSect);
   wh = (WAVEHDR *) dwParam1;
   waveOutUnprepareHeader(dev, wh, sizeof(WAVEHDR));
   hg = GlobalHandle(wh->lpData);
   GlobalUnlock(hg);
   GlobalFree(hg);
   hg = GlobalHandle(wh);
   GlobalUnlock(hg);
   GlobalFree(hg);
   dev->nBlocks--;
   LeaveCriticalSection(&dev->critSect);
  }
}

static int 
open_output(play_audio_t *dev)
{
 int i = dev->rate;
 int j = 1;
 int mono = (dev->encoding & PE_MONO);
 int eight_bit = !(dev->encoding & PE_16BIT);
 int warnings = 0;
 PCMWAVEFORMAT pcm;
 MMRESULT res;

 /* Check if there is at least one audio device */
 if (!waveOutGetNumDevs())
  {
   fprintf(stderr, "No audio devices present!");
   return -1;
  }

 /* They can't mean these */
 dev->encoding &= ~(PE_ULAW | PE_BYTESWAP);

 if (dev->encoding & PE_16BIT)
  dev->encoding |= PE_SIGNED;
 else
  dev->encoding &= ~PE_SIGNED;

 mono = (dev->encoding & PE_MONO);
 eight_bit = !(dev->encoding & PE_16BIT);

 pcm.wf.wFormatTag = WAVE_FORMAT_PCM;
 pcm.wf.nChannels = mono ? 1 : 2;
 pcm.wf.nSamplesPerSec = dev->rate;
 j = 1;
 if (!mono)
  {
   i *= 2;
   j *= 2;
  }
 if (!eight_bit)
  {
   i *= 2;
   j *= 2;
  }
 pcm.wf.nAvgBytesPerSec = i;
 pcm.wf.nBlockAlign = j;
 pcm.wBitsPerSample = eight_bit ? 8 : 16;

 res = waveOutOpen(NULL, 0, (LPWAVEFORMAT) & pcm, (DWORD) NULL, (DWORD) 0, WAVE_FORMAT_QUERY);
 if (res)
  {
   fprintf(stderr, "Format not supported!\n");
   return -1;
  }
 res = waveOutOpen(&dev->dev, 0, (LPWAVEFORMAT) & pcm, (DWORD) 
                   (DWORD) wave_callback, (DWORD) dev, CALLBACK_FUNCTION);
 if (res)
  {
   fprintf(stderr, "Can't open audio device");
   return -1;
  }
 dev->nBlocks = 0;
 return warnings;
}


int
audio_open(play_audio_t *dev,int dowait)
{
 InitializeCriticalSection(&dev->critSect);
 dev->rate = DEFAULT_RATE;
 dev->encoding = PE_16BIT | PE_SIGNED | PE_MONO;
 dev->extra_param[0] = 16;
 open_output(dev);
 return 1;
}

static void 
audio_wait(play_audio_t *dev)
{
 while (dev->nBlocks)
  Sleep(0);
}

static int 
play(play_audio_t *dev,void *mem, int len)
{
 HGLOBAL hg;
 LPWAVEHDR wh;
 MMRESULT res;

 while (dev->nBlocks >= dev->extra_param[0])
  Sleep(0);

 hg = GlobalAlloc(GMEM_MOVEABLE | GMEM_ZEROINIT, sizeof(WAVEHDR));
 if (!hg)
  {
   fprintf(stderr, "GlobalAlloc failed!");
   return FALSE;
  }
 wh = GlobalLock(hg);
 wh->dwBufferLength = len;
 wh->lpData = mem;

 res = waveOutPrepareHeader(dev->dev, wh, sizeof(WAVEHDR));
 if (res)
  {
   fprintf(stderr, "waveOutPrepareHeader: %d", res);
   GlobalUnlock(hg);
   GlobalFree(hg);
   return TRUE;
  }
 res = waveOutWrite(dev->dev, wh, sizeof(WAVEHDR));
 if (res)
  {
   fprintf(stderr, "waveOutWrite: %d", res);
   GlobalUnlock(hg);
   GlobalFree(hg);
   return TRUE;
  }
 EnterCriticalSection(&dev->critSect);
 dev->nBlocks++;
 LeaveCriticalSection(&dev->critSect);
 return FALSE;
}

void
conv8bit(short *lp, int c)
{
 unsigned char *cp = (unsigned char *) lp;
 short l;
 while (c--)
  {
   short l = (*lp++) >> (16 - 8);
   if (l > 127)
    l = 127;
   else if (l < -128)
    l = -128;
   *cp++ = 0x80 ^ ((unsigned char) l);
  }
}


void
audio_play16(play_audio_t * dev, int count, short *buf)
{
 int len = count;
 HGLOBAL hg;
 void *b;

 if (!(dev->encoding & PE_MONO))  /* Stereo sample */
  {
   count *= 2;
   len *= 2;
  }

 if (dev->encoding & PE_16BIT)
  len *= 2;

 hg = GlobalAlloc(GMEM_MOVEABLE, len);
 if (!hg)
  {
   fprintf(stderr, "GlobalAlloc failed!");
   return;
  }
 b = GlobalLock(hg);

 if (!(dev->encoding & PE_16BIT))
  /* Convert to 8-bit unsigned. */
  conv8bit(buf, count);

#ifdef __MINGW32__
 memcpy(b, buf, len);
#else
 CopyMemory(b, buf, len);
#endif
 if (play(dev, b, len))
  {
   GlobalUnlock(hg);
   GlobalFree(hg);
  }
}

close_output(play_audio_t * dev)
{
 audio_wait(dev);
 waveOutClose(dev->dev);
}

static void
audio_flush(play_audio_t * dev)
{
 audio_wait(dev);
}

static void
audio_purge(play_audio_t * dev)
{
 waveOutReset(dev->dev);
 audio_wait(dev);
}

void
audio_term(play_audio_t * dev)
{
 close_output(dev);
}

void
audio_DESTROY(play_audio_t *dev)
{
 close_output(dev);
 DeleteCriticalSection(&dev->critSect);
}

IV
audio_rate(play_audio_t *dev, IV new)
{
 return dev->rate;
}

float
audio_gain(play_audio_t *dev, float new)
{
 return 1.0;
}

/*
   API level Play function 
    - volume may go from the interface - it is un-natural
    - convert to 'short' should be done at Audio::Play level 
    - likewise rate-matching needs to be higher level
*/
void
audio_play(play_audio_t *dev, Audio *au, float volume)
{
 STRLEN samp = Audio_samples(au);
 SV *tmp = Audio_shorts(au);
 if (volume >= 0)
  audio_gain(dev, volume);

 if (au->rate != audio_rate(dev,0))
  audio_rate(dev, au->rate);           /* Or re-sample to dev's rate ??? */

 audio_play16(dev, samp, (short *) SvPVX(tmp));
 SvREFCNT_dec(tmp);
}                

IV
audio_speaker(play_audio_t *dev,IV flag)
{
 return flag;
}

IV
audio_headphone(play_audio_t *dev,IV flag)
{
 return flag;
}


MODULE = Audio::Play::#OSNAME#	PACKAGE=Audio::Play::#OSNAME#	PREFIX = audio_

PROTOTYPES: DISABLE

void
audio_new(class,wait = 1)
char *	class
IV	wait
CODE:
 {static play_audio_t buf;
  play_audio_t *p;
  /* We cannot use the normal typemap scheme in ../Data/typemap as
   * the open process passes address of elements of the buffer to Win32
   */
  ST(0) = sv_newmortal();
  sv_setref_pvn(ST(0), class, (char *) &buf, sizeof(buf));
  p = (play_audio_t *)SvPVX(SvRV(ST(0)));
  if (!audio_open(p,wait))
   {
    XSRETURN_NO;
   }
 }

void
audio_DESTROY(dev)
play_audio_t *	dev

void
audio_flush(dev)
play_audio_t *	dev

IV
audio_speaker(dev,flag = 0)
play_audio_t *	dev
IV	flag

IV
audio_headphone(dev,flag = 0)
play_audio_t *	dev
IV	flag

float
audio_gain(dev,val = -1.0)
play_audio_t *	dev
float	val

IV
audio_rate(dev,rate = 0)
play_audio_t *	dev
IV	rate

void
audio_play(dev, au, vol = -1.0)
play_audio_t *	dev
Audio *		au;
float		vol

BOOT:
 {
  AudioVptr = (AudioVtab *) SvIV(perl_get_sv("Audio::Data::AudioVtab",5)); 
 }

