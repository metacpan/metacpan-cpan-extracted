
#include <sys/types.h>
#include <stdio.h>
#include <fcntl.h>
#include <stdlib.h>

#include "mpg123.h"

#include <windows.h>

static CRITICAL_SECTION        cs;

static HWAVEOUT dev    = NULL;
static int nBlocks             = 0;

#define MAX_BLOCKS 6

static int fi = -1;			/* free index */
WAVEHDR *wh[MAX_BLOCKS + 1];

static _inline void wait(void)
{
   while(nBlocks)
       Sleep(77);
}

static void CALLBACK wave_callback(HWAVE hWave, UINT uMsg, DWORD dwInstance, DWORD dwParam1, DWORD dwParam2)
{

   if(uMsg == WOM_DONE)
   {
       EnterCriticalSection( &cs );

       wh[++fi] = (WAVEHDR *)dwParam1;

       // decrease the number of USED blocks
       nBlocks--;

       LeaveCriticalSection( &cs );
   }
}

void free_res(void)
{
  WAVEHDR *whfi;
  HGLOBAL hg;

  EnterCriticalSection( &cs );
  whfi = wh[fi--];
  LeaveCriticalSection( &cs );

  waveOutUnprepareHeader(dev, whfi, sizeof (WAVEHDR));

  //Deallocate the buffer memory
  hg = GlobalHandle(whfi->lpData);
  GlobalUnlock(hg);
  GlobalFree(hg);
  
  //Deallocate the header memory
  hg = GlobalHandle(whfi);
  GlobalUnlock(hg);
  GlobalFree(hg);
}

int audio_open(struct audio_info_struct *ai)
{
   MMRESULT res;
   WAVEFORMATEX outFormatex;

   if(ai->rate == -1)
   {
       InitializeCriticalSection(&cs);
       return(0);
   }

   if(!waveOutGetNumDevs())
   {
       MessageBox(NULL, "No audio devices present!", "Error...", MB_OK);
       return -1;
   }

   outFormatex.wFormatTag      = WAVE_FORMAT_PCM;
   outFormatex.wBitsPerSample  = 16;
   outFormatex.nChannels       = 2;
   outFormatex.nSamplesPerSec  = ai->rate;
   outFormatex.nAvgBytesPerSec = outFormatex.nSamplesPerSec * outFormatex.nChannels * outFormatex.wBitsPerSample/8;
   outFormatex.nBlockAlign     = outFormatex.nChannels * outFormatex.wBitsPerSample/8;

   res = waveOutOpen(&dev, (UINT)ai->device, &outFormatex, (DWORD)wave_callback, 0, CALLBACK_FUNCTION);

   if(res != MMSYSERR_NOERROR)
   {
       switch(res)
       {
           case MMSYSERR_ALLOCATED:
               MessageBox(NULL, "Device Is Already Open", "Error...", MB_OK);
               break;
           case MMSYSERR_BADDEVICEID:
               MessageBox(NULL, "The Specified Device Is out of range", "Error...", MB_OK);
               break;
           case MMSYSERR_NODRIVER:
               MessageBox(NULL, "There is no audio driver in this system.", "Error...", MB_OK);
               break;
           case MMSYSERR_NOMEM:
              MessageBox(NULL, "Unable to allocate sound memory.", "Error...", MB_OK);
               break;
           case WAVERR_BADFORMAT:
               MessageBox(NULL, "This audio format is not supported.", "Error...", MB_OK);
               break;
           case WAVERR_SYNC:
               MessageBox(NULL, "The device is synchronous.", "Error...", MB_OK);
               break;
           default:
               MessageBox(NULL, "Unknown Media Error", "Error...", MB_OK);
               break;
       }
       return -1;
   }

   waveOutReset(dev);
   InitializeCriticalSection(&cs);

   return 0;
}

int audio_reset_parameters(struct audio_info_struct *ai)
{
  return 0;
}

int audio_rate_best_match(struct audio_info_struct *ai)
{
  return 0;
}

int audio_set_rate(struct audio_info_struct *ai)
{
  return 0;
}

int audio_set_channels(struct audio_info_struct *ai)
{
  return 0;
}

int audio_set_format(struct audio_info_struct *ai)
{
  return 0;
}

int audio_get_formats(struct audio_info_struct *ai)
{
  return AUDIO_FORMAT_SIGNED_16;
}

int audio_play_samples(struct audio_info_struct *ai,unsigned char *buf,int len)
{
   HGLOBAL hg, hg2;
   LPWAVEHDR wh;
   MMRESULT res;
   void *b;

   /* first, free used blocks */
   while (fi >= 0) {
     free_res();
   }

   ///////////////////////////////////////////////////////
   //  Wait for a few FREE blocks...
   ///////////////////////////////////////////////////////
   while(nBlocks > MAX_BLOCKS)
       Sleep(77);

   ////////////////////////////////////////////////////////
   // FIRST allocate some memory for a copy of the buffer!
   ////////////////////////////////////////////////////////
   hg2 = GlobalAlloc(GMEM_MOVEABLE, len);
   if(!hg2)
   {
       MessageBox(NULL, "GlobalAlloc failed!", "Error...",  MB_OK);
       return(-1);
   }
   b = GlobalLock(hg2);


   //////////////////////////////////////////////////////////
   // Here we can call any modification output functions we want....
   ///////////////////////////////////////////////////////////
   CopyMemory(b, buf, len);

   ///////////////////////////////////////////////////////////
   // now make a header and WRITE IT!
   ///////////////////////////////////////////////////////////
   hg = GlobalAlloc (GMEM_MOVEABLE | GMEM_ZEROINIT, sizeof (WAVEHDR));
   if(!hg)
   {
       return -1;
   }
   wh = GlobalLock(hg);
   wh->dwBufferLength = len;
   wh->lpData = b;


   res = waveOutPrepareHeader(dev, wh, sizeof (WAVEHDR));
   if(res)
   {
       GlobalUnlock(hg);
       GlobalFree(hg);

       return -1;
   }

   res = waveOutWrite(dev, wh, sizeof (WAVEHDR));
   if(res)
   {
       GlobalUnlock(hg);
       GlobalFree(hg);

       return (-1);
   }

   EnterCriticalSection( &cs );

   nBlocks++;

   LeaveCriticalSection( &cs );

   return(len);
}

int audio_close(struct audio_info_struct *ai)
{
   if(dev)
   {
       wait();

       waveOutReset(dev);      //reset the device
       waveOutClose(dev);      //close the device
       dev=NULL;
   }

   DeleteCriticalSection(&cs);

   nBlocks = 0;
   return(0);
}
