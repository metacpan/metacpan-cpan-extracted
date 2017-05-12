#define PERL_NO_GET_CONTEXT
#include <EXTERN.h>
#include <perl.h>
#include "Audio.h"

#define SUN_MAGIC 	0x2e736e64		/* Really '.snd' */
#define SUN_HDRSIZE	24			/* Size of minimal header */
#define SUN_UNSPEC	((unsigned)(~0))	/* Unspecified data size */
#define SUN_ULAW	1			/* u-law encoding */
#define SUN_LIN_8	2			/* Linear 8 bits */
#define SUN_LIN_16	3			/* Linear 16 bits */

static void
wblong(pTHX_ PerlIO *f, long x)
{
 int i;
 for (i = 24; i >= 0; i -= 8)
  {
   char byte = (char) ((x >> i) & 0xFF);
   PerlIO_write(f, &byte, 1);
  }
}

static long
rblong(pTHX_ PerlIO *f,int n)
{
 long x = 0;
 int i;
 for (i=0; i < n; i++)
  {
   long b = PerlIO_getc(f);
   x = (x << 8) + (b & 0xFF);
  }
 return x;
}

void
Audio_header(pTHX_ PerlIO *f,unsigned enc,unsigned rate,
                          unsigned size,char *comment)
{
 if (!comment)
  comment = "";
 wblong(aTHX_ f, SUN_MAGIC);
 wblong(aTHX_ f, SUN_HDRSIZE + strlen(comment));
 wblong(aTHX_ f, size);
 wblong(aTHX_ f, enc);
 wblong(aTHX_ f, rate);
 wblong(aTHX_ f, 1);                   /* channels */
 PerlIO_write(f, comment, strlen(comment));
}

static long Audio_write (pTHX_ PerlIO *f, int au_encoding, int n,float *data)
{
 long au_size = 0;
 if (n > 0)
  {
   if (au_encoding == SUN_LIN_16)
    {
     while (n--)
      {
       short s = float2linear(*data++,16);
       /* Write big-endian to match header code */
       char  b[2];
       b[0] = (s >> 8) & 0xFF;
       b[1] = (s >> 0) & 0xFF;
       if (PerlIO_write(f, b, 2) != 2)
    	 break;
       au_size += sizeof(s);
      }
    }
   else if (au_encoding == SUN_ULAW)
    {
     while (n--)
      {
       char s = float2ulaw(*data++);
       if (PerlIO_write(f, &s, sizeof(s)) != sizeof(s))
        break;
       au_size += sizeof(s);
      }
    }
   else if (au_encoding == SUN_LIN_8)
    {
     while (n--)
      {
       char s = float2linear(*data++,8);
       if (PerlIO_write(f, &s, sizeof(s)) != sizeof(s))
    	break;
       au_size += sizeof(s);
      }
    }
   else
    {
     croak("Unknown format");
    }
  }
 return au_size;
}

static void Audio_term (pTHX_ PerlIO *f,long au_size)
{
 off_t here = PerlIO_tell(f);
 PerlIO_flush(f);
 if (here >= 0)
  {
   /* can seek this file - truncate it */
#ifndef WIN32
   ftruncate(PerlIO_fileno(f), here);
#endif
   /* Now go back and overwite header with actual size */
   if (PerlIO_seek(f, 8L, SEEK_SET) == 8)
    {
     wblong(aTHX_ f, au_size);
    }
  }
}

static void
Audio_read(pTHX_ Audio *au, PerlIO *f,size_t dsize,long count,float (*proc)(long))
{
 SV *data = au->data;
 if (count > 0)
  {
   /* If we know how big it is to be get grow out of the way */
   SvGROW(data,SvCUR(data)+(count/dsize)*sizeof(float));
  }
 while (count && !PerlIO_eof(f))
  {
   STRLEN len = SvCUR(data);
   long  v  = rblong(aTHX_ f,dsize);
   float *p = (float *) (SvGROW(data,len+sizeof(float))+len);
   if (proc)
    *p = (*proc)(v);
   else
    *p = linear2float(v, dsize*8);
   len += sizeof(float);
   SvCUR(data) = len;
   count -= dsize;
  }
}

static void
sun_load(pTHX_ Audio *au, PerlIO *f, long magic)
{
 STRLEN hdrsz = rblong(aTHX_ f,sizeof(long));
 long size  = rblong(aTHX_ f,sizeof(long));
 long enc   = rblong(aTHX_ f,sizeof(long));
 long rate  = rblong(aTHX_ f,sizeof(long));
 unsigned chan = rblong(aTHX_ f,sizeof(long));
 assert(magic == SUN_MAGIC);
 au->rate   = rate;
 hdrsz -= SUN_HDRSIZE;
 if (!au->data)
  au->data    = newSVpv("",0);
 if (hdrsz)
  {
   if (!au->comment)
    au->comment = newSVpv("",0);
   sv_upgrade(au->comment,SVt_PV);
   PerlIO_read(f,SvGROW(au->comment,hdrsz),hdrsz);
   SvCUR(au->comment) = hdrsz;
  }
 switch(enc)
  {
   case SUN_ULAW:
    Audio_read(aTHX_ au,f,1,size,ulaw2float);
    break;
   case SUN_LIN_16:
    Audio_read(aTHX_ au,f,2,size,NULL);
    break;
   case SUN_LIN_8:
    Audio_read(aTHX_ au,f,1,size,NULL);
    break;
   default:
    croak("Unsupported au format");
    break;
  }
 /* For now we can only represent one channel so average all channels */
 if (chan > 1)
  {
   float *s = AUDIO_DATA(au);
   float *d = s;
   UV samples = Audio_samples(au);
   float *e = s+samples;
   if (samples % chan)
    {
     warn("%d channels but %lu samples",chan,samples);
     samples = (samples/chan)*chan;
     e = s+samples;
    }
   while (s < e)
    {
     unsigned i;
     float v = *s++;
     for (i = 1; i < chan; i++)
      {
       v += *s++;
      }
     *d++ = v / chan;
    }
   SvCUR_set(au->data,(d-AUDIO_DATA(au))*sizeof(float));
   if (!au->comment)
    au->comment = newSVpv("",0);
   sv_upgrade(au->comment,SVt_PV);
   sv_catpvf(au->comment,"averaged from %u channels",chan);
  }
}

void
Audio_Load(Audio *au, InputStream f)
{
 dTHX;
 long magic = rblong(aTHX_ f,sizeof(long));
 switch(magic)
  {
   case SUN_MAGIC:
    sun_load(aTHX_ au, f, magic);
    break;
   default:
    croak("Unknown file format");
    break;
  }
}

void
Audio_Save(Audio *au, OutputStream f, char *comment)
{
 dTHX;
 long encoding = (au->rate == 8000) ? SUN_ULAW : SUN_LIN_16;
 long bytes  = Audio_samples(au);
 if (encoding != SUN_ULAW)
  bytes *= 2;
 if (!comment && au->comment && SvOK(au->comment))
  {
   STRLEN len;
   comment = SvPV(au->comment,len);
  }
 Audio_header(aTHX_ f, encoding, au->rate, bytes, comment);
 bytes = Audio_write(aTHX_ f, encoding, Audio_samples(au), (float *) SvPVX(au->data));
 Audio_term(aTHX_ f, bytes);
}


