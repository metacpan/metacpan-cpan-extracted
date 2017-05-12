/*
  Copyright (c) 1996 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/
#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>

#ifdef CAN_PROTOTYPE
#define NeedFunctionPrototypes 1
#define NeedNestedPrototypes 1
#else
#define NeedFunctionPrototypes 0
#define NeedNestedPrototypes 0
#endif

#include <audio/audiolib.h>
#include <audio/soundlib.h>

#include "../../Data/Audio.m"

AudioVtab     *AudioVptr;

#define AuFixedPointFromFloat(nnn) \
    ((AuInt32) ((nnn) * AU_FIXED_POINT_SCALE))


static void
done(AuServer *aud, AuEventHandlerRec *handler, AuEvent *ev,AuPointer data)
{
 switch (ev->auany.type)
  {
   case AuEventTypeElementNotify:
    {
     int *d = (int *) data;
     *d = (ev->auelementnotify.cur_state == AuStateStop);
     if (!*d || ev->auelementnotify.reason != AuReasonEOF)
      {
       fprintf(stderr, "curr_state=%d reason=%d\n",
               ev->auelementnotify.cur_state,
               ev->auelementnotify.reason);
      }
    }
    break;
   case AuEventTypeMonitorNotify:
    break;
   default:
    fprintf(stderr, "type=%d serial=%ld time=%ld id=%ld\n",
            ev->auany.type, ev->auany.serial, ev->auany.time, ev->auany.id);
    break;
  }
}

static void
AuDESTROY(AuServer *aud)
{
 AuFlush(aud);      
 AuCloseServer(aud);
}

void
AuPlay(AuServer *aud, Audio *au, float volume)
{
 int endian = 1;
#define little_endian ((*((char *)&endian) == 1))
 int priv = 0;
 AuEvent ev;
 STRLEN samp = Audio_samples(au);
 Sound s = SoundCreate(SoundFileFormatNone,
                       little_endian ? AuFormatLinearSigned16LSB : AuFormatLinearSigned16MSB,
                       1, au->rate, samp, SvPV_nolen(au->comment)); 
 SV *tmp = Audio_shorts(au);
 if (!AuSoundPlayFromData(aud, s, (short *) SvPVX(tmp), AuNone,
                            AuFixedPointFromFloat(volume),
                            done, &priv,
                            NULL, NULL, NULL, NULL))
  {
   perror("problems playing data");
  }
 else
  {
   while (1)
    {
     AuNextEvent(aud, AuTrue, &ev);
     AuDispatchEvent(aud, &ev);
     if (priv)
      break;
    }
  }
 SvREFCNT_dec(tmp);
 SoundDestroy(s);
}

MODULE = Audio::Play::Net	PACKAGE = Audio::Play::Net	PREFIX = Au

PROTOTYPES: DISABLE

void
AuPlay(aud,au,vol = 0.5)
AuServer *	aud
Audio *		au;
float		vol

void
AuDESTROY(aud)
AuServer *	aud

void
AuFlush(aud)
AuServer *	aud

AuServer *
AuOpenServer(class, server = NULL, proto = NULL, data = NULL)
char *	class
char *	server
SV *	proto
SV *	data
CODE:
 {
  STRLEN plen = 0;
  char *pstr  = (proto && SvOK(proto)) ? SvPV(proto,plen) : NULL;
  STRLEN dlen = 0;
  char *dstr  = (data && SvOK(data)) ? SvPV(data,dlen) : NULL;
  char *error = "Cannot open";
  RETVAL = AuOpenServer(server,plen,pstr,dlen,dstr,&error); 
  if (!RETVAL)
   croak("Error %s",error);
 }
OUTPUT:
 RETVAL

BOOT:
 {
  AudioVptr = (AudioVtab *) SvIV(perl_get_sv("Audio::Data::AudioVtab",5));
 }
