/* 
 * audio_dec.c from Hans Schwengeler's (schweng@astro.unibas.ch) 
 */

#include <sys/types.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>
#include <mme/mme_api.h>
#include "mpg123.h"

/* Written by Oskar Enoksson (osken393@student.liu.se) */

    /* Max n.o. shared memory blocks to use at the same time */
#define MAX_BLOCKS 6
#define LPSTRLEN 256

static HWAVEOUT dev = NULL;

static LPSTR Str = NULL;
static LPPCMWAVEFORMAT oForm = NULL;
static LPWAVEHDR wHdr = NULL;
static LPWAVEOUTCAPS Caps = NULL;

static const WAVEHDR WAVEHDRTemplate = 
{ NULL, 0, 0, 0, 0, 0, NULL, 0 };

static void * deposit[MAX_BLOCKS];
static int depcount=0;
static int nBlocks = 0;


static void
wave_callback(HANDLE hWave,
	      UINT uMsg,
	      DWORD dwInstance,
	      LPARAM dwParam1,
	      LPARAM dwParam2)
{
  WAVEHDR *wh;

  if(uMsg == WOM_DONE) {
    wh = (WAVEHDR *)dwParam1;
    deposit[depcount]=wh->lpData;
    depcount++;
  }
}

int process_callback(void) {
  MMRESULT res;
  mmeProcessCallbacks();
  while(depcount>0) {
    depcount--;
    if(!mmeFreeBuffer(deposit[depcount])) {
      fprintf(stderr,"mmeFreeBuffer failed!\n",depcount,deposit[depcount]);
      return 0;
    }
    nBlocks--;
  }
  return 1;
}

int audio_open(struct audio_info_struct *ai)
{
  MMRESULT res;

  if(!waveOutGetNumDevs()) {
    fprintf(stderr,"No audio devices present!\n");
    return -1;
  }
      
  oForm=mmeAllocMem(sizeof(PCMWAVEFORMAT));
  Str=mmeAllocMem(LPSTRLEN*sizeof(char));
  wHdr=mmeAllocMem(sizeof(WAVEHDR));
  Caps=mmeAllocMem(sizeof(WAVEOUTCAPS));

  if(!Str || !oForm || !wHdr || !Caps) {
    fprintf(stderr,"mmeAllocMem failed!\n");
    return -1;
  }

  res=waveOutGetDevCaps((UINT) ai->device,
			Caps,
			sizeof(WAVEOUTCAPS));
  if(res != MMSYSERR_NOERROR) {
    waveOutGetErrorText(res,Str,LPSTRLEN);
    fprintf(stderr,"Error in waveOutGetDevCaps:\n %s\n",Str);
    return -1;
  } else {
    fprintf(stderr,"Using device %d: %s version %d.%d\n",
	    ai->device,
	    Caps->szPname,
	    (int)(Caps->vDriverVersion&0xff),
	    (int)((Caps->vDriverVersion>>8)&0xff));
  }  
  if(ai->rate == -1)
    return(0);

  switch(ai->format) {
  case AUDIO_FORMAT_SIGNED_16:
    oForm->wBitsPerSample = 16;
    oForm->wf.wFormatTag = WAVE_FORMAT_PCM;
    break;
  case AUDIO_FORMAT_SIGNED_8:
    oForm->wBitsPerSample = 8;
    oForm->wf.wFormatTag = WAVE_FORMAT_PCM;
    break;
  case AUDIO_FORMAT_ULAW_8:
    oForm->wBitsPerSample = 8;
    oForm->wf.wFormatTag = WAVE_FORMAT_MULAW;
  default:
    fprintf(stderr,"Unrecogniced sample format %d!\n",ai->format);
    return -1;
  }

  oForm->wf.nChannels = ai->channels;
  oForm->wf.nSamplesPerSec = ai->rate;
  oForm->wf.nAvgBytesPerSec = 
    oForm->wf.nSamplesPerSec * oForm->wf.nChannels * oForm->wBitsPerSample/8;
  oForm->wf.nBlockAlign = oForm->wf.nChannels * oForm->wBitsPerSample/8;

  res = waveOutOpen((LPHWAVEOUT)&dev, 
		    (UINT)ai->device,
		    &(oForm->wf),
		    wave_callback, 
		    NULL, 
		    (CALLBACK_FUNCTION | WAVE_OPEN_SHAREABLE));
  if(res != MMSYSERR_NOERROR) {
    waveOutGetErrorText(res,Str,LPSTRLEN);
    fprintf(stderr,"Error in waveOutOpen:\n %s\n",Str);
    return -1;
  }

  if(waveOutReset(dev)!=MMSYSERR_NOERROR) {
    fprintf(stderr,"Error calling waveOutReset\n");
    return -1;
  }

  if(ai->gain>=0) {
    if(Caps->dwSupport & WAVECAPS_VOLUME) {
      res=waveOutSetVolume((UINT)ai->device,
			   (DWORD)ai->gain);
      if(res != MMSYSERR_NOERROR) {
	waveOutGetErrorText(res,Str,LPSTRLEN);
	fprintf(stderr,"Error in waveOutSetVolume (ignoring):\n %s\n",Str);
      }
    } else {
      fprintf(stderr,"Volume change not supported by device (ignoring)\n");
    }
  }
  return 0;
}

int audio_reset_parameters(struct audio_info_struct *ai)
{
  fprintf(stderr,"Unimplemented audio_reset_parameters called\n");
  return 0;
}

int audio_rate_best_match(struct audio_info_struct *ai)
{
  fprintf(stderr,"Unimplemented audio_rate_best_match called\n");
  return 0;
}

int audio_set_rate(struct audio_info_struct *ai)
{
  fprintf(stderr,"Unimplemented audio_set_rate called\n");
  return 0;
}

int audio_set_channels(struct audio_info_struct *ai)
{
  fprintf(stderr,"Unimplemented audio_set_channels called\n");
  return 0;
}

int audio_set_format(struct audio_info_struct *ai)
{
  fprintf(stderr,"Unimplemented audio_set_format called\n");
  return 0;
}

int audio_get_formats(struct audio_info_struct *ai)
{
  int ret;

  if(!Caps) {
    fprintf(stderr,"Strange, no format data?\n");
    return 0;
  }
  switch(ai->channels) {
  case 1:
    switch(ai->rate) {
    case 8000:
      return 
	(Caps->dwFormats & WAVE_FORMAT_08M08_MULAW) ? AUDIO_FORMAT_ULAW_8:0;
    case 11025:
      return 
	((Caps->dwFormats & WAVE_FORMAT_1M08) ? AUDIO_FORMAT_SIGNED_8:0) |
	((Caps->dwFormats & WAVE_FORMAT_1M16) ? AUDIO_FORMAT_SIGNED_16:0);
    case 22050:
      return 
	((Caps->dwFormats & WAVE_FORMAT_2M08) ? AUDIO_FORMAT_SIGNED_8:0) |
	((Caps->dwFormats & WAVE_FORMAT_2M16) ? AUDIO_FORMAT_SIGNED_16:0);
    case 44100:
      return 
	((Caps->dwFormats & WAVE_FORMAT_4M08) ? AUDIO_FORMAT_SIGNED_8:0) |
	((Caps->dwFormats & WAVE_FORMAT_4M16) ? AUDIO_FORMAT_SIGNED_16:0);
    default:
      return 0;
    }
    break;
  case 2:
    switch(ai->rate) {
    case 11025:
      return 
	((Caps->dwFormats & WAVE_FORMAT_1S08) ? AUDIO_FORMAT_SIGNED_8:0) |
	((Caps->dwFormats & WAVE_FORMAT_1S16) ? AUDIO_FORMAT_SIGNED_16:0);
    case 22050:
      return 
	((Caps->dwFormats & WAVE_FORMAT_2S08) ? AUDIO_FORMAT_SIGNED_8:0) |
	((Caps->dwFormats & WAVE_FORMAT_2S16) ? AUDIO_FORMAT_SIGNED_16:0);
    case 44100:
      return 
	((Caps->dwFormats & WAVE_FORMAT_4S08) ? AUDIO_FORMAT_SIGNED_8:0) |
	((Caps->dwFormats & WAVE_FORMAT_4S16) ? AUDIO_FORMAT_SIGNED_16:0);
    default:
      return 0;
    }
    break;
  default:
    return 0;
  }
}

int audio_play_samples(struct audio_info_struct *ai,unsigned char *buf,int len)
{
  MMRESULT res;
  void *b;

  /*
    /////////////////////////////////////////////////////
    //  Wait for a FREE block 
    /////////////////////////////////////////////////////
  */
  if(nBlocks >= MAX_BLOCKS) {
    mmeWaitForCallbacks();
    process_callback();
  }

  /*
    //////////////////////////////////////////////////////
    // Allocate some memory for the buffer
    //////////////////////////////////////////////////////
  */
  b=mmeAllocBuffer(len*sizeof(char));

  if(!b) {
    fprintf(stderr,"mmeAllocBuffer failed!\nError...\n");
    return(-1);
  }

  /*
    ////////////////////////////////////////////////////////
    // Here we can call any modification output functions we want....
    /////////////////////////////////////////////////////////
  */
  memcpy(b,buf,len);
       
  /*
    /////////////////////////////////////////////////////////
    // Write the header.
    /////////////////////////////////////////////////////////
  */

  *wHdr=WAVEHDRTemplate;
  wHdr->lpData = b;
  wHdr->dwBufferLength = len;
  wHdr->dwFlags = 0;

  res = waveOutWrite(dev, wHdr, sizeof(WAVEHDR));
  if(res) {
    mmeFreeBuffer(b);
    waveOutGetErrorText(res,Str,LPSTRLEN);
    fprintf(stderr,"Error calling waveOutWrite\n %s\n",(int)dev,(int)wHdr,Str);
    return (-1);
  } else
    nBlocks++;

  return(len);
}

int audio_close(struct audio_info_struct *ai)
{
  MMRESULT res;

  if(dev) {
    while(nBlocks>0) {
      mmeWaitForCallbacks();
      process_callback();
    }

    if(waveOutReset(dev)!=MMSYSERR_NOERROR)      /* reset the device */
      fprintf(stderr,"Error calling waveOutReset(%d)",(int)dev);
    res=waveOutClose(dev);      /* close the device */
    if(res!=MMSYSERR_NOERROR) {
      waveOutGetErrorText(res,Str,LPSTRLEN);
      fprintf(stderr,"Error closing device: %s\n",Str);
      return -1;
    }
    dev=NULL;
  }
      
  mmeFreeMem(Caps);
  mmeFreeMem(wHdr);
  mmeFreeMem(Str);
  mmeFreeMem(oForm);

  nBlocks = 0;
  return(0);
}
