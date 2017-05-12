#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#define ALSA_PCM_NEW_HW_PARAMS_API
#define ALSA_PCM_NEW_SW_PARAMS_API
#include <alsa/asoundlib.h>

/* Nested dynamic loaded extension magic ... */
#include "../../Data/Audio.m"
AudioVtab     *AudioVptr;

#define SAMP_RATE 11025

#if 0
const char *pcm_name = "plughw:0,0";
#else
const char *pcm_name = "default";
#endif

static const char *
audio_statestr(snd_pcm_state_t state)
{
 switch(state)
  {
   case SND_PCM_STATE_OPEN:	return "open";
   case SND_PCM_STATE_SETUP:	return "setup";
   case SND_PCM_STATE_PREPARED:	return "prepared";
   case SND_PCM_STATE_RUNNING:	return "running";
   case SND_PCM_STATE_XRUN:	return "xrun";
   case SND_PCM_STATE_DRAINING:	return "draining";
   case SND_PCM_STATE_PAUSED:	return "paused";
   case SND_PCM_STATE_SUSPENDED:return "suspended";
   default:			return "unknown";
  }
}

typedef struct
{
 unsigned int samp_rate;
 snd_pcm_t *pcm;
 snd_pcm_hw_params_t *hwparams;
 float gain;
 snd_pcm_uframes_t chunk;
} play_audio_t;

static int
audio_prepare(play_audio_t *dev)
{
 if (dev)
  {
   int err;
   int dir = 0;
   unsigned int rate = dev->samp_rate;
   snd_pcm_state_t state = snd_pcm_state(dev->pcm);
#if 0
   warn("%s with state %s",__FUNCTION__,audio_statestr(state));
#endif
   /* ALSA lib is fussy - won't let you reset this struct
      even if setting to same value so we need to re-get the
      uncommitted values every time
    */
   if ((err = snd_pcm_hw_params_any(dev->pcm,dev->hwparams)) < 0)
    {
     warn("Cannot read hwparams:%s",snd_strerror(err));
    }
   if ((err = snd_pcm_hw_params_set_access(dev->pcm, dev->hwparams, SND_PCM_ACCESS_RW_INTERLEAVED)) < 0)
    {
     warn("Cannot set access %s:%s",pcm_name,snd_strerror(err));
     return 0;
    }
   /* Set sample format */
   if ((err=snd_pcm_hw_params_set_format(dev->pcm, dev->hwparams, SND_PCM_FORMAT_S16)) < 0)
    {
     warn("Error setting format %s:%s",pcm_name,snd_strerror(err));
     return(0);
    }
#ifdef ALSA_PCM_NEW_HW_PARAMS_API
   err = snd_pcm_hw_params_set_rate_near(dev->pcm, dev->hwparams, &rate, &dir);
#else
   rate = snd_pcm_hw_params_set_rate_near(dev->pcm, dev->hwparams, dev->samp_rate, &dir);
#endif
   if (dir || rate != dev->samp_rate)
    {
     unsigned int num;
     unsigned int den;
     if ((err = snd_pcm_hw_params_get_rate_numden(dev->hwparams,&num,&den)) < 0)
      {
       warn("Cannot get exact rate (%s) using %d", snd_strerror(err), rate);
      }
     else
      {
       warn("Wanted %ldHz, got(%d) %ld (%u/%u=%.10gHz",dev->samp_rate,dir,
             rate,num,den,1.0*num/den);

      }
     dev->samp_rate = rate;
    }
   if ((err=snd_pcm_hw_params_set_channels(dev->pcm, dev->hwparams, 1)) < 0)
    {
     warn("Error setting channels %s:%s",pcm_name,snd_strerror(err));
     return(0);
    }
   /* Apply HW parameter settings to */
   /* PCM device and prepare device  */
   if ((err=snd_pcm_hw_params(dev->pcm, dev->hwparams)) < 0)
    {
     warn("Error setting parameters %s:%s",pcm_name,snd_strerror(err));
     return(0);
    }
#ifdef ALSA_PCM_NEW_HW_PARAMS_API
   err = snd_pcm_hw_params_get_buffer_size (dev->hwparams, &dev->chunk);
#else
   dev->chunk = snd_pcm_hw_params_get_buffer_size (dev->hwparams);
#endif
   state = snd_pcm_state(dev->pcm);
#if 0
   warn("prepared now state %s",audio_statestr(state));
#endif
   return 1;
  }
 return 0;
}


static int
audio_init(play_audio_t *dev,int wait)
{
 int err;
 if (!dev->gain)
  dev->gain = 1.0f;
 if (!dev->samp_rate)
  dev->samp_rate = SAMP_RATE;
 if ((err = snd_pcm_open(&dev->pcm,pcm_name,SND_PCM_STREAM_PLAYBACK,0)) < 0)
  {
   warn("Cannot open %s (%d):%s",pcm_name,wait,snd_strerror(err));
   return 0;
  }
 else
  {
   if ((err = snd_pcm_hw_params_malloc(&dev->hwparams)) < 0)
    {
     warn("Cannot allocate hwparams:%s",snd_strerror(err));
    }
   if ((err = snd_pcm_hw_params_any(dev->pcm,dev->hwparams)) < 0)
    {
     warn("Cannot read hwparams:%s",snd_strerror(err));
    }
   return 1;
  }
}

void
audio_flush(play_audio_t *dev)
{
 if (dev->pcm)
  {
   snd_pcm_state_t state = snd_pcm_state(dev->pcm);
   switch(state)
    {
     case SND_PCM_STATE_RUNNING:
      {
       /* Stop PCM device after pending frames have been played */
       int err = snd_pcm_drain(dev->pcm);
       if (err < 0)
        {
         warn(snd_strerror(err));
        }
        break;
      }
     default:
      warn("%s with state %s",__FUNCTION__,audio_statestr(state));
      break;
    }
  }
}

static void
audio_close(play_audio_t *dev)
{
 if (dev)
  {
   /* Close audio system  */
   if (dev->hwparams)
    {
     snd_pcm_hw_params_free(dev->hwparams);
     dev->hwparams = 0;
    }
   if (dev->pcm)
    {
     snd_pcm_close(dev->pcm);
     dev->pcm = 0;
    }
   dev->chunk = 0;
  }
}


UV
audio_rate(play_audio_t *dev, UV rate)
{unsigned int old = dev->samp_rate;
 if (rate && rate != dev->samp_rate)
  {
   snd_pcm_state_t state;
   int dir = 0;
   int err;
   audio_flush(dev);
   switch ((state = snd_pcm_state(dev->pcm)))
    {
     case SND_PCM_STATE_OPEN:
      break;
     case SND_PCM_STATE_SETUP:
     case SND_PCM_STATE_PREPARED:
     case SND_PCM_STATE_RUNNING:
     case SND_PCM_STATE_XRUN:
     case SND_PCM_STATE_DRAINING:
     case SND_PCM_STATE_PAUSED:
     case SND_PCM_STATE_SUSPENDED:
     default:
      audio_close(dev);
      if (!audio_init(dev,1))
       {
        croak("Cannot re-open %s");
       }
      break;
    }
#if 0
   warn("%s with state %s",__FUNCTION__,audio_statestr(state));
#endif

#ifdef ALSA_PCM_NEW_HW_PARAMS_API
   dev->samp_rate = rate;
   err = snd_pcm_hw_params_set_rate_near(dev->pcm, dev->hwparams, &dev->samp_rate, &dir);
#else
   dev->samp_rate = snd_pcm_hw_params_set_rate_near(dev->pcm, dev->hwparams, rate, &dir);
#endif
   if (dir || rate != dev->samp_rate)
    {
     unsigned int num;
     unsigned int den;
     if ((err = snd_pcm_hw_params_get_rate_numden(dev->hwparams,&num,&den)) < 0)
      {
       warn("Cannot get exact rate (%s) using %d", snd_strerror(err), dev->samp_rate);
      }
     else
      {
       warn("Wanted %ldHz, got(%d) %ld (%u/%u=%.10gHz",rate,dir,
             dev->samp_rate,num,den,1.0*num/den);

      }
    }
  }
 return old;
}

void
audio_DESTROY(play_audio_t *dev)
{
 audio_flush(dev);
 audio_close(dev);
}

void
audio_play16(play_audio_t *dev,int n, short *data)
{
 if (n > 0 && dev->pcm)
  {
   snd_pcm_sframes_t ret;
   while (n > 0)
    {
     size_t amount = ((size_t) n > dev->chunk) ? dev->chunk : (size_t) n;
     while ((ret = snd_pcm_writei(dev->pcm, data, amount)) < 0)
      {
       warn("%s:%s",pcm_name,snd_strerror(ret));
       snd_pcm_prepare(dev->pcm);
      }
     n -= ret;
     data += ret;
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
    warn("Cannot change audio gain yet");
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

 if (!dev->chunk)
  audio_prepare(dev);

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
