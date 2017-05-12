#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

/*****************************************************************/
/***                                                           ***/
/***    Play out a file on Linux                               ***/
/***                                                           ***/
/***                H.F. Silverman 1/4/91                      ***/
/***    Modified:   H.F. Silverman 1/16/91 for amax parameter  ***/
/***    Modified:   A. Smith 2/14/91 for 8kHz for klatt synth  ***/
/***    Modified:   Rob W. W. Hooft (hooft@EMBL-Heidelberg.DE) ***/
/***                adapted for linux soundpackage Version 2.0 ***/
/***    Merged FreeBSD version - 11/11/94 NIS                  ***/
/***    Perl Port - 27/01/97 NIS                               ***/
/***                                                           ***/
/*****************************************************************/


#include <fcntl.h>
#include <sys/file.h>
#include <sys/stat.h>
#include <sys/param.h>
#include <sys/ioctl.h>

#ifdef HAVE_SYS_SOUNDCARD_H      /* linux style */
#include <sys/soundcard.h>
#endif

#ifdef HAVE_MACHINE_SOUNDCARD_H  /* FreeBSD style */
#include <machine/soundcard.h>
#endif

/* Nested dynamic loaded extension magic ... */
#include "../../Data/Audio.m"
AudioVtab     *AudioVptr;

#ifndef AFMT_S16_LE
#define AFMT_S16_LE	16
#endif

#ifndef AFMT_U8
#define AFMT_U8		8
#endif

#ifndef AFMT_MU_LAW
#define AFMT_MU_LAW	1
#endif

#if defined(HAVE_DEV_DSP)
 char *dev_file = "/dev/dsp";
 static int dev_fmt = AFMT_U8;
#else /* DSP */
 #if defined(HAVE_DEV_AUDIO)
  char *dev_file = "/dev/audio";
  static int dev_fmt = AFMT_MU_LAW;
 #else
  #if defined(HAVE_DEV_DSPW) || !defined(HAVE_DEV_SBDSP)
   char *dev_file = "/dev/dspW";
   static int dev_fmt = AFMT_S16_LE;
  #else
   #if defined(HAVE_DEV_SBDSP)
    char *dev_file = "/dev/sbdsp";
    static int dev_fmt = AFMT_U8;
   #endif  /* SBDSP */
  #endif /* DSPW */
 #endif /* AUDIO */
#endif /* DSP */


#define SAMP_RATE 8000

typedef struct
{
 long samp_rate;
 int fd;
 int fmt;
 float gain;
} play_audio_t;

static const short endian = 0x1234;

static int
audio_init(play_audio_t *dev,int wait)
{
 int try;
 int flags = (wait) ? 0 : O_NDELAY;
 for (try = 0; try < 5; try++)
  {
   dev->fd = open(dev_file, O_WRONLY | O_EXCL | flags);
   if (dev->fd >= 0 || errno != EBUSY || wait)
    break;
   usleep(10000);
  }
 if (dev->fd >= 0)
  {
   /* Modern /dev/dsp honours O_NONBLOCK and O_NDELAY for write which
      leads to data being dropped if we try and write and device isn't ready
      we would either have to retry or we can just turn it off ...
    */
   int fl = fcntl(dev->fd,F_GETFL,0);
   if (fl != -1)
    {
     if (fcntl(dev->fd,F_SETFL,fl & ~(O_NONBLOCK|O_NDELAY)) == 0)
      {
       dev->samp_rate = SAMP_RATE;
#ifdef SNDCTL_DSP_RESET
       if (ioctl(dev->fd, SNDCTL_DSP_RESET, 0) != 0)
        {
	 return 0;
	}
#endif	
#ifdef SOUND_PCM_READ_RATE
       if (ioctl(dev->fd, SOUND_PCM_READ_RATE, &dev->samp_rate) != 0)
        {
	 return 0;
	}
#else	
#ifdef SNDCTL_DSP_SPEED
       if (ioctl(dev->fd, SNDCTL_DSP_SPEED, &dev->samp_rate) != 0)
        {
	 return 0;
	}
#endif
#endif /* can read rate */
#ifdef SNDCTL_DSP_GETFMTS
       if (ioctl(dev->fd,SNDCTL_DSP_GETFMTS,&fl) == 0)
        {
         int fmts = fl;
         if (*((const char *)(&endian)) == 0x34)
          {
           if ((fl = fmts & AFMT_S16_LE) && ioctl(dev->fd,SNDCTL_DSP_SETFMT,&fl) == 0)
            {
             dev->fmt = fl;
             return 1;
            }
           }
         else
          {
           if ((fl = fmts & AFMT_S16_BE) && ioctl(dev->fd,SNDCTL_DSP_SETFMT,&fl) == 0)
            {
             dev->fmt = fl;
             return 1;
            }
          }
         if ((fl = fmts & AFMT_MU_LAW) && ioctl(dev->fd,SNDCTL_DSP_SETFMT,&fl) == 0)
          {
           dev->fmt = fl;
           return 1;
          }
        }
#endif
       warn("Using %s on %d fl=%X\n",dev_file,dev->fd,fl);
       return 1;
      }
    }
  }
 perror(dev_file);
 return 0;
}

IV
audio_rate(play_audio_t *dev, IV rate)
{IV old = dev->samp_rate;
 if (rate)
  {
   int want = dev->samp_rate = rate;
   ioctl(dev->fd, SNDCTL_DSP_SPEED, &dev->samp_rate);
   if (dev->samp_rate != want)
    printf("Actual sample rate: %ld\n", dev->samp_rate);
  }
 return old;
}

void
audio_flush(play_audio_t *dev)
{
 if (dev->fd >= 0)
  {
   int dummy;
   ioctl(dev->fd, SNDCTL_DSP_SYNC, &dummy);
  }
}

void
audio_DESTROY(play_audio_t *dev)
{
 audio_flush(dev);
 /* Close audio system  */
 if (dev->fd >= 0)
  {
   close(dev->fd);
   dev->fd = -1;
  }
}

void
audio_play16(play_audio_t *dev,int n, short *data)
{
 if (n > 0)
  {
   if (dev->fmt == AFMT_S16_LE || dev->fmt == AFMT_S16_BE)
    {
     n *= 2;
     if (dev->fd >= 0)
      {
       if (write(dev->fd, data, n) != n)
        perror("write");
      }
    }
   else if (dev->fmt == AFMT_U8)
    {
     unsigned char *converted = (unsigned char *) malloc(n);
     int i;

     if (converted == NULL)
      {
       croak("Could not allocate memory for conversion\n");
      }

     for (i = 0; i < n; i++)
      converted[i] = (data[i] - 32767) / 256;

     if (dev->fd >= 0)
      {
       if (write(dev->fd, converted, n) != n)
        perror("write");
      }
     free(converted);
    }
   else if (dev->fmt == AFMT_MU_LAW)
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
         if (w == -1 && errno != EINTR)
          {
           croak("%d,%s:%d\n", errno, __FILE__, __LINE__);
          }
         else
          {
           warn("Writing %u, only wrote %u\n", n, w);
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
   else
    {
     croak("unknown audio format");
    }
  }
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

double
audio_gain(dev,val = -1.0)
play_audio_t *	dev
double	val

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
