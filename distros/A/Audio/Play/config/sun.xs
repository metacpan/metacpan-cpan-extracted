/*
  Copyright (c) 1995,1996,1997 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include <fcntl.h>
#include <sys/file.h>
#include <sys/filio.h>
#include <signal.h>

#include "../../Data/Audio.m"

AudioVtab     *AudioVptr;

#include <sys/ioctl.h>

#ifdef HAVE_SYS_IOCCOM_H
#include <sys/ioccom.h>
#endif
#ifdef HAVE_SYS_AUDIOIO_H
#include <sys/audioio.h>
#endif
#ifdef HAVE_SUN_AUDIOIO_H
#include <sun/audioio.h>
#endif

#define SAMP_RATE 8000

typedef struct
{
 audio_info_t info;
 int fd;
 int kind;
} play_audio_t;

static char *dev_file = "/dev/audio";

audio_open(play_audio_t *dev, int Wait)
{
 /* Try it quickly, first */
 Zero(dev, 1, play_audio_t);
 dev->fd = open(dev_file, O_WRONLY | O_NDELAY);
 if ((dev->fd < 0) && (errno == EBUSY))
  {
   if (!Wait)
    {
     croak("%s is busy\n", dev_file);
    }
   /* Now hang until it's open */
   dev->fd = open(dev_file, O_WRONLY);
  }
 else if (dev->fd >= 0)
  {
   int flags = fcntl(dev->fd, F_GETFL, NULL);
   if (flags >= 0)
    fcntl(dev->fd, F_SETFL, flags & ~O_NDELAY);
   else
    perror("fcntl - F_GETFL");
  }
 if (dev->fd < 0)
  {
   return 0;
  }
 else
  {
#ifdef AUDIO_DEV_AMD
   /* Get the device output encoding configuration */
   if (ioctl(dev->fd, AUDIO_GETDEV, &dev->kind))
    {
     /* Old releases of SunOs don't support the ioctl,
        but can only be run on old machines which have AMD device...
      */
     dev->kind = AUDIO_DEV_AMD;
    }
#endif
   if (ioctl(dev->fd, AUDIO_GETINFO, &dev->info) != 0)
    {
     return 0;
    }
  }
 return 1;
}

static int
audio_setinfo(play_audio_t *dev)
{
 return (ioctl(dev->fd, AUDIO_SETINFO, &dev->info) != 0);
}

IV
audio_rate(play_audio_t *dev,IV rate)
{
 IV prev_rate = dev->info.play.sample_rate;
 if (rate)
  {
   dev->info.play.sample_rate = rate;
#ifdef AUDIO_ENCODING_LINEAR
   if (rate > 8000)
    {
     dev->info.play.encoding = AUDIO_ENCODING_LINEAR;
     dev->info.play.precision = 16;
    }
   else
    {
     dev->info.play.encoding = AUDIO_ENCODING_ULAW;
     dev->info.play.precision = 8;
    }
#endif
   audio_setinfo(dev);
  }
 return prev_rate;
}

float
audio_gain(play_audio_t *dev,float gain)
{
 float prev_gain = ((float) dev->info.play.gain)/AUDIO_MAX_GAIN;
 if (gain >= 0.0)
  {
   dev->info.play.gain = (unsigned) (AUDIO_MAX_GAIN * gain);
   audio_setinfo(dev);
  }
 return prev_gain;
}

IV
audio_speaker(play_audio_t *dev,int flag)
{
 IV old = (dev->info.play.port & AUDIO_SPEAKER) != 0;
 if (flag)
  {
   if (flag > 0)
    dev->info.play.port |= AUDIO_SPEAKER;
   else
    dev->info.play.port &= ~AUDIO_SPEAKER;
   audio_setinfo(dev);
  }
 return old;
}

IV
audio_headphone(play_audio_t *dev,int flag)
{
 IV old = (dev->info.play.port & AUDIO_HEADPHONE) != 0;
 if (flag)
  {
   if (flag > 0)
    dev->info.play.port |= AUDIO_HEADPHONE;
   else
    dev->info.play.port &= ~AUDIO_HEADPHONE;
   audio_setinfo(dev);
  }
 return old;
}

void
audio_flush(play_audio_t *dev)
{
 ioctl(dev->fd, AUDIO_DRAIN, 0);
}

void
audio_DESTROY(play_audio_t *dev)
{
 /* Close audio system  */
 if (dev->fd >= 0)
  {
   audio_flush(dev);
   close(dev->fd);
   dev->fd = -1;
  }
}

void
audio_play16(play_audio_t *dev, int n, short *data)
{
 if (n > 0 && dev->fd >= 0)
  {
#ifdef AUDIO_ENCODING_LINEAR
   if (dev->info.play.encoding == AUDIO_ENCODING_LINEAR)
    {
     unsigned size = n * sizeof(short);
     if (write(dev->fd, data, n * sizeof(short)) != size)
            perror("write");
    }
   else 
#endif
   if (dev->info.play.encoding == AUDIO_ENCODING_ULAW)
    {
     unsigned char *plabuf = (unsigned char *) malloc(n);
     if (plabuf)
      {
       int w;
       unsigned char *p = plabuf;
       unsigned char *e = p + n;
       while (p < e)
        {
         *p++ = short2ulaw(*data++);
        }
       p = plabuf;
       while ((w = write(dev->fd, p, n)) != n)
        {
         if (w == -1)
          {
           fprintf(stderr, "%d,%s:%d\n", errno, __FILE__, __LINE__);
           perror("audio");
           abort();
          }
         else
          {
           fprintf(stderr, "Writing %u, only wrote %u\n", n, w);
           p += w;
           n -= w;
          }
        }
       free(plabuf);
      }
     else
      {
       croak("No memory for ulaw data");
      }
    }
  }
}

void
audio_play(play_audio_t *dev, Audio *au, float volume)
{
 STRLEN samp = Audio_samples(au);
 SV *tmp = Audio_shorts(au);
 if (volume >= 0)
  audio_gain(dev, volume);
 if (au->rate != audio_rate(dev,0))
  audio_rate(dev, au->rate); 
 audio_play16(dev, samp, (short *) SvPVX(tmp));
 SvREFCNT_dec(tmp);
}

MODULE = Audio::Play::#OSNAME#	PACKAGE=Audio::Play::#OSNAME#	PREFIX = audio_

PROTOTYPES: DISABLE

play_audio_t *
audio_new(class,wait = 1)
char *	class
IV	wait
CODE:
 {static play_audio_t buf;
  if (!audio_open(RETVAL = &buf,wait))
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
