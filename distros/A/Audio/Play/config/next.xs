/*
  Original written for 'rsynth' and placed in public domain by  
  by B. Stuyts <benstn@olivetti.nl> 21-feb-94.  
  Perl modifications Copyright (c) 1997 Nick Ing-Simmons. 
  All rights reserved. This program is free software; you can redistribute it 
  and/or modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#ifdef HAVE_LIBC_H
#include <libc.h>
#endif
#include <sound/sound.h>

/* Nested dynamic loaded extension magic ... */
#include "../../Data/Audio.m"  
AudioVtab     *AudioVptr;

/* Platform specific C level "object" data structure */
typedef struct
 {
  SNDSoundStruct *sound;
  long samp_rate;
  float gain; 
 } play_audio_t;

int
audio_init(play_audio_t *dev,int wait)
{
 dev->samp_rate = SND_RATE_CODEC;
 dev->sound     = NULL;
 dev->gain      = 1.0;
 return 1;
}

void
audio_play16(play_audio_t *dev, int n, short *data)
{
 if (n > 0)
  {
   SNDSoundStruct *sound = dev->sound;
   int err;
   if (!sound)
    {
     /* I hate these magic numbers - NI-S */
     err = SNDAlloc(&dev->sound, 1000000, SND_FORMAT_LINEAR_16, dev->samp_rate, 1, 0); 
     if (err)
      croak("SNDAlloc:%s",SNDSoundError(err));
     sound = dev->sound;
    }
   else
    {
     /* Wait for previous sound to finish before changing fields in sound */
     /* I hate these magic numbers - NI-S */
     err = SNDWait(0);
     if (err)
      croak("SNDWait:%s",SNDSoundError(err));
    }

   /* copying to buffer is a pain - should really convert into the buffer,
      unless "double buffer" means it it easier to keep up...
    */

   sound->dataSize = n * sizeof(short);
   /* Patch from  benstn@olivetti.nl (Ben Stuyts)
      Thanks to ugubser@avalon.unizh.ch for finding out why the NEXTSTEP
      version of rsynth didn't work on Intel systems. As suspected, it was a
      byte-order   problem. 
    */
#if i386
   swab((char *) data, (char *) sound + sound->dataLocation, n * sizeof(short));
#else /* i386 */
   bcopy(data, (char *) sound + sound->dataLocation, n * sizeof(short));
#endif

   /* I hate these magic numbers - NI-S */
   err = SNDStartPlaying(sound, 1, 5, 0, 0, 0);
   if (err)
    croak("SNDStartPlaying:%s",SNDSoundError(err));
  }
}

void
audio_flush(play_audio_t *dev)
{
 /* I hate these magic numbers - NI-S */
 inr err = SNDWait(0);
 if (err)
  croak("SNDWait:%s",SNDSoundError(err));
}

void
audio_DESTROY(play_audio_t *dev)
{
 SNDSoundStruct *sound = dev->sound;
 int err; 

 if (!sound)
  return;

 audio_flush(dev);

 if (err = SNDFree(sound))
  croak("SNDFree:%s",SNDSoundError(err));
 dev->sound = NULL;
}

IV
audio_rate(play_audio_t *dev,IV rate)
{
 IV old = dev->samp_rate;
 if (rate)
  {
   /* rate != 0 is setting the rate */
   if (dev->sound)
    {
     /* In progress - wait for it, and free that one - re-use DESTROY code */
     audio_DESTROY(dev); 
    }
   /* Note rate for allocation on next call to audio_play16() */
   dev->samp_rate = rate;
  }
 return old;
}

float
audio_gain(play_audio_t *dev,float gain)
{
 float prev_gain = dev->gain;
 if (gain >= 0.0)
  {
   if (gain != 1.0)
    warn("Cannot change audio gain");
   /* If you can tell me how,
      otherwise we could multiply out during conversion to short.
      ... NI-S 
   */
  }
 return prev_gain;
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

/* Methods to select speaker and/or headphones etc. need adding
   if possible ...

   List of "valid" sample rates would be good too.

*/


MODULE = Audio::Play::#OSNAME#	PACKAGE=Audio::Play::#OSNAME#	PREFIX = audio_

PROTOTYPES: DISABLE

play_audio_t *
audio_new(class,wait = 1)
char *	class
IV	wait
CODE:
 {static play_audio_t buf;
  if (!audio_init(RETVAL = &buf,wait))
   {
    XSRETURN_NO;
   }
 }
OUTPUT:
 RETVAL

void
audio_DESTROY(dev)
play_audio_t *	dev

void
audio_flush(dev)
play_audio_t *	dev

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
  /* Nested dynamic loaded extension magic ... */
  AudioVptr = (AudioVtab *) SvIV(perl_get_sv("Audio::Data::AudioVtab",5)); 
 }
