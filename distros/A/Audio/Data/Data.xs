//depot/Audio/Data/Data.xs#19 - edit change 2568 (text)
/*
  Copyright (c) 1996, 2001 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/
#define PERL_NO_GET_CONTEXT

#include <EXTERN.h>
#include <perl.h>
#include <XSUB.h>
#include "Audio_f.h"

#define AUDIO_CLASS(sv) (HvNAME(SvSTASH(SvRV(sv))))

float *
Audio_more(pTHX_ Audio *au, int n)
{
 STRLEN sz = n * sizeof(float) * AUDIO_WORDS(au);
 float  *p = (float *) (SvGROW(au->data,SvCUR(au->data)+sz) + SvCUR(au->data));
 SvCUR(au->data) += sz;
 Zero(p,n,float);
 return p;
}

Audio *
Audio_new(pTHX_ SV **svp, int rate, int flags, int samples, char *class)
{
 SV *sv = (svp) ? *svp : Nullsv;
 Audio tmp;
 Zero(&tmp,1,Audio);
 tmp.data  = newSVpvn("",0);
 tmp.rate  = rate;
 tmp.flags = flags;
 if (samples)
   Audio_more(aTHX_ &tmp,samples);
 if (!sv) {
  sv = sv_2mortal(newSV(0));
  if (svp)
   *svp = sv;
 }
 if (!class)
  class = "Audio::Data";
 sv_setref_pvn(sv,class,(char *)&tmp,sizeof(tmp));
 return (Audio *) SvPV_nolen((SV*)SvRV(sv));
}

float *
Audio_complex(Audio *au)
{
 if (!AUDIO_COMPLEX(au))
  {
   dTHX;
   int n = Audio_samples(au);
   float *r;
   float *c;
   Audio_more(aTHX_ au,n);
   r = AUDIO_DATA(au)+n-1;    /* Last old sample */
   c = AUDIO_DATA(au)+2*n-1;  /* Imaginary part of new last */
   while (c > r)
    {
     *c-- = 0.0;              /* Imaginary part is 0 */
     *c-- = *r--;             /* Copy real part */
    }
   au->flags |= AUDIO_F_COMPLEX;
  }
 return AUDIO_DATA(au);
}

static float *
Audio_pow2(pTHX_ Audio *au)
{
 STRLEN have = Audio_samples(au);
 STRLEN n = 1;
 while (n < have)
  n <<= 1;
 if (n > have)
  Audio_more(aTHX_ au,n-have);
 return Audio_complex(au);
}


/* Does not take pTHX_ to keep external API easy */
SV *
Audio_shorts(Audio *au)
{
 dTHX;
 SV *tmp = newSVpv("",0);
 STRLEN samp = Audio_samples(au);
 short *p    = (short *) SvGROW(tmp,samp*sizeof(short));
 float *data = AUDIO_DATA(au);
 int words = AUDIO_WORDS(au);
 SvCUR(tmp) = samp*sizeof(short);
 while (samp--)
  {
   *p++ = float2linear(*data,16);
   data += words;
  }
 return tmp;
}

void
Audio_tone(Audio *au, float freq, float dur, float amp)
{
 dTHX;
 unsigned samp = (int) (dur * au->rate);
 float *buf = Audio_more(aTHX_ au, samp);
 double th  = 0.0;
 double inc = 2*AUDIO_PI*freq/au->rate;
 int words = AUDIO_WORDS(au);
 while (samp > 0)
  {
   *buf = amp * sin(th);
   th += inc;
   buf += words;
   samp--;
  }
}

void
Audio_noise(Audio *au, float dur, float amp)
{
 dTHX;
 unsigned samp = (int) (dur * au->rate);
 float *buf = Audio_more(aTHX_ au, samp);
 int words = AUDIO_WORDS(au);
 while (samp > 0)
  {
   *buf = amp * (Drand01()-0.5);
   samp--;
   buf += words;
  }
}

static void
Audio_fft(pTHX_ Audio *au,fft_f *fft)
{
 float *data = Audio_pow2(aTHX_ au);
 (*fft)(Audio_samples(au),data);
}

#define AUDIO_r2_fft(au)    Audio_fft(aTHX_ au,&Audio_r2_fft)
#define AUDIO_r2_ifft(au)   Audio_fft(aTHX_ au,&Audio_r2_ifft)
#define AUDIO_r4_fft(au)    Audio_fft(aTHX_ au,&Audio_r4_fft)
#define AUDIO_r4_ifft(au)   Audio_fft(aTHX_ au,&Audio_r4_ifft)
#define AUDIO_conjugate(au,scale) Audio_conjugate(Audio_samples(au),Audio_complex(au),scale);
#define AUDIO_complex_debug(au,f) Audio_complex_debug(Audio_samples(au),Audio_complex(au),f);

#define IS_AUDIO(sv) (SvROK(sv) && sv_isobject(sv) && sv_derived_from(sv,"Audio::Data"))

Audio *
Audio_from_sv(pTHX_ SV *sv)
{
 if (SvGMAGICAL(sv))
  mg_get(sv);
 if (SvROK(sv) && sv_isobject(sv) && sv_derived_from(sv,"Audio::Data"))
  {
   STRLEN len;
   return (Audio *) SvPV(SvRV(sv),len);
  }
 return NULL;
}

float
Audio_FIR(Audio *au,float x0)
{
/* FIR filter is represented as an array of floats
   H(z) = b0 + b1*z**1 + b2*z**2 ... bN*z**N
   Thus next output sample is given by :
   y(n) = b0 * x(n) + b1 * x(n-1) ... + bN * x(n-N)
   The float vector has N+1 entries at the start for the b0..bN
   and then (N) entries for the storage elements.
   Thus Audio_samples(filter) == 2*N+1
*/
 int    N = (Audio_samples(au)-1)/2;
 float *b = AUDIO_DATA(au)+N;   /* last b */
 float *x = b+N;                /* last x */
 float y  = *b-- * *x--;
 int k;
 for (k = N-1; k > 0; k--)
  {
   x[1] = *x;
   y   += *b-- * *x--;
  }
 x[1] = x0;
 y   += *b * x0;
 return y;
}

float
Audio_AllPole(Audio *au,float x)
{
/* An AllPole filter is represented as an array of floats
   H(z) = 1/(a0 + a1*z**1 + a2*z**2 ... aN*z**N)
   Thus next output sample is given by :
   y(n) = a0 * x(n) + a1 * y(n-1) ... + aN * y(n-N)
   The float vector has N+1 entries at the start for the a0..aN
   and then (N) entries for the storage elements.
   Thus Audio_samples(filter) == 2*N+1
*/
 int    N = (Audio_samples(au)-1)/2;
 float *a = AUDIO_DATA(au)+N;   /* last b */
 float *y = a+N;                /* last x */
 float yn = *a-- * *y--;
 int k;
 for (k = N-1; k > 0; k--)
  {
   yn  += *a-- * *y;
   y[1] = *y;
   y--;
  }
 yn  += *a * x;
 y[1] = yn;
 return yn;
}

int
Audio_filter_sv(pTHX_ Audio *filter, float (*func)(Audio *,float), Audio *lau, SV *sv)
{
 int count = 0;
 Audio *rau = Audio_from_sv(aTHX_ sv);
 if (rau)
  {
   STRLEN n = Audio_samples(rau);
   float *s = AUDIO_DATA(rau);
   float *d = Audio_more(aTHX_ lau,n);
   while (n-- > 0)
    {
     *d++ = (*func)(filter,*s++);
    }
   count = n;
  }
 else if (SvROK(sv) && !sv_isobject(sv))
  {
   if (SvTYPE(SvRV(sv)) == SVt_PVAV)
    {
     AV *av = (AV *) SvRV(sv);
     int i;
     int l = av_len(av);
     for (i=0; i <= l; i++)
      {
       SV **svp = av_fetch(av,i,0);
       if (svp)
        count += Audio_filter_sv(aTHX_ filter,func,lau,*svp);
      }
    }
   else
    Perl_croak(aTHX_ "Cannot process reference");
  }
 else
  {
   float v = (*func)(filter,SvNV(sv));
   *(Audio_more(aTHX_ lau,1)) = v;
   count = 1;
  }
 return count;
}

int
Audio_filter_process(pTHX_ Audio *au,float (*func)(Audio *,float),int items,SV **svp)
{
 dSP;
 int offset = svp - sp;
 int count  = 0;
 int i;
 SV *result = Nullsv;
 Audio *tmp = Audio_new(aTHX_ &result,au->rate,au->flags,0,0);
 for (i=1; i < items; i++)
  {
   SPAGAIN;
   svp = sp + offset;
   count += Audio_filter_sv(aTHX_ au,func,tmp,svp[i]);
  }
 SPAGAIN;
 svp = sp + offset;
 if (GIMME == G_ARRAY)
  {
   float *s = AUDIO_DATA(tmp);
   if (count > items)
    EXTEND(sp,count);
   for (i=0; i < count; i++)
    {
     svp[i] = sv_2mortal(newSVnv(*s++));
    }
   PUTBACK;
   return count;
  }
 else
  {
   svp[0] = result;
   PUTBACK;
   return 1;
  }
}

void
Audio_append_sv(pTHX_ Audio *lau, SV *sv)
{
 Audio *rau = Audio_from_sv(aTHX_ sv);
 if (rau && AUDIO_COMPLEX(rau) && !AUDIO_COMPLEX(lau))
  {
   warn("Upgrade to complex");
   Audio_complex(lau);
  }
 if (rau)
  {
   int wrds = AUDIO_WORDS(lau);
   STRLEN n = Audio_samples(rau);
   float *d = Audio_more(aTHX_ lau,n);
   if (lau->rate != rau->rate)
    {
     if (lau->rate)
      {
       if (rau->rate)
        {
         croak("Cannot append %dHz data to %dHZ Audio",rau->rate,lau->rate);
	}
      }
     else
      {
       lau->rate = rau->rate;
      }
    }
   if (wrds == AUDIO_WORDS(rau))
    {
     Copy(AUDIO_DATA(rau),d,n*wrds,float);
    }
   else
    {
     float *s = AUDIO_DATA(rau);
     while (n-- > 0)
      {
       *d++ = *s++;
       *d++ = 0.0;
      }
    }
  }
 else if (SvROK(sv) && !sv_isobject(sv))
  {
   if (SvTYPE(SvRV(sv)) == SVt_PVAV)
    {
     AV *av = (AV *) SvRV(sv);
     int i;
     int l = av_len(av);
     for (i=0; i <= l; i++)
      {
       SV **svp = av_fetch(av,i,0);
       if (svp)
        Audio_append_sv(aTHX_ lau,*svp);
      }
    }
   else
    Perl_croak(aTHX_ "Cannot process reference");
  }
 else
  {
   float *d = Audio_more(aTHX_ lau,1);
   *d = (float) SvNV(sv);
  }
}

Audio *
Audio_overload_init(pTHX_ Audio *lau, SV **argp,int dorev, SV *right, SV *rev)
{
 SV *left  = argp[0];
 if (SvOK(rev))
  {
   /* Not assignment form */
   char *type = AUDIO_CLASS(left);
   SV *tsv = Nullsv;
   Audio *tau = Audio_new(aTHX_ &tsv,lau->rate,lau->flags,0,type);
   if (dorev && SvTRUE(rev))
    {
     SV *tsv = left;
     left    = right;
     argp[1] = tsv;
    }
   Audio_append_sv(aTHX_ tau,left);
   argp[0] = tsv;
   return tau;
  }
 return lau;
}

MODULE = Audio::Data	PACKAGE = Audio::Data	PREFIX = Audio_

PROTOTYPES: DISABLE

SV *
Audio_shorts(au)
Audio *	au;

void
Audio_silence(au, time = 0.1)
Audio *	au;
float	time;

void
Audio_tone(au,freq,dur = 0.1, amp = 0.5)
Audio *	au;
float	freq;
float	dur
float	amp

void
Audio_noise(au,dur = 0.1, amp = 0.5)
Audio *	au;
float	dur
float	amp

void
DESTROY(au)
Audio *	au
PPCODE:
 {
  if (au->comment)
   SvREFCNT_dec(au->comment);
  if (au->data)
   SvREFCNT_dec(au->data);
 }

Audio *
create(class)
char *	class
PREINIT:
  Audio x;
CODE:
 {
  Zero(&x,1,Audio);
  x.comment = newSV(0);
  x.data    = newSVpv("",0);
  RETVAL    = &x;
 }
OUTPUT:
  RETVAL

void
Audio_clone(Audio *au)
CODE:
{
 SV *result = Nullsv;
 Audio *rau = Audio_new(aTHX_ &result,au->rate,au->flags,0,AUDIO_CLASS(ST(0)));
 Audio_append_sv(aTHX_ rau, ST(0));
 ST(0) = result;
 XSRETURN(1);
}

void
Audio_timerange(Audio *au, float t0, float t1)
CODE:
{
 SV *result = Nullsv;
 UV samples = Audio_samples(au);
 UV start = au->rate*t0;
 UV end   = au->rate*t1+0.5;
 Audio *rau = Audio_new(aTHX_ &result,au->rate,au->flags,end-start,AUDIO_CLASS(ST(0)));
 if (start < samples)
  {
   float *d   = AUDIO_DATA(rau);
   float *s   = AUDIO_DATA(au)+start;
   if (end > samples)
    end = samples;
   Copy(s,d,(end-start)*AUDIO_WORDS(au),float);
  }
 ST(0) = result;
 XSRETURN(1);
}

void
Audio_bounds(Audio *au, float t0 = 0.0, float t1 = Audio_duration(au))
CODE:
{
 UV samples = Audio_samples(au);
 UV start = au->rate*t0;
 UV end   = au->rate*t1+0.5;
 if (start < samples)
  {
   float *s   = AUDIO_DATA(au)+start;
   float *e;
   float max = *s++;
   float min = max;
   if (end > samples)
    end = samples;
   e = AUDIO_DATA(au)+end;
   while (s < e)
    {
     float v = *s++;
     if (v > max) max = v;
     if (v < min) min = v;
    }
   ST(0) = sv_2mortal(newSVnv(max));
   ST(1) = sv_2mortal(newSVnv(min));
   XSRETURN(2);
  }
 XSRETURN(0);
}

SV *
Audio_comment(au,...)
Audio *		au
CODE:
 {
  if (items > 1)
   {
    if (!au->comment)
     au->comment = newSV(0);
    sv_setsv(au->comment,ST(1));
   }
  RETVAL = SvREFCNT_inc(au->comment);
 }
OUTPUT:
 RETVAL

void
Audio_FETCH(au,index)
Audio *au
UV index
CODE:
 {
  if (index < Audio_samples(au))
   {
    float *src = AUDIO_DATA(au)+(index * AUDIO_WORDS(au));
    if (AUDIO_COMPLEX(au) && src[1] != 0.0)
     {
      SV *result = Nullsv;
      Audio *tau = Audio_new(aTHX_ &result,au->rate, au->flags, 1,0);
      tau->flags |= AUDIO_F_COMPLEX;
      Copy(src,AUDIO_DATA(tau),AUDIO_WORDS(au),float);
      ST(0) = result;
     }
    else
     {
      ST(0) = sv_2mortal(newSVnv(*src));
     }
   }
  else
   {
    ST(0) = &PL_sv_undef;
   }
  XSRETURN(1);
 }

void
Audio_STORE(au,index,sv)
Audio * au
IV  	index
SV *	sv
CODE:
 {
  IV n = Audio_samples(au);
  IV len = 1;
  float v[2];
  float *src = v;
  float *dst;
  /* If value stored is an Audio */
  if (SvROK(sv) && sv_isobject(sv) && sv_derived_from(sv,"Audio::Data"))
   {
    Audio *auv = (Audio *) SvPV_nolen(SvRV(sv));
    if (AUDIO_COMPLEX(auv))
     Audio_complex(au);
    len  = Audio_samples(auv);
    if (len > 1 && auv->rate != au->rate)
     {
      croak("Cannot store %dHz data in %dHZ Audio",auv->rate,au->rate);
     }
    src  = AUDIO_DATA(auv);
   }
  else
   {
    v[0] = SvNV(sv);
    v[1] = 0.0;
   }
  if (index+len-1 > n)
   Audio_more(aTHX_ au,(index-n));
  dst = AUDIO_DATA(au)+(index*AUDIO_WORDS(au));
  Copy(src,dst,len*AUDIO_WORDS(au),float);
 }

IV
Audio_samples(au,...)
Audio *		au

IV
Audio_length(au,...)
Audio *		au
CODE:
 {
  RETVAL = Audio_samples(au);
  if (items > 1)
   {
    IV want = SvIV(ST(1));
    if (want > RETVAL)
     Audio_more(aTHX_ au,want-RETVAL);
    else if (want < RETVAL)
     {
      STRLEN sz = want * sizeof(float) * AUDIO_WORDS(au);
      SvCUR_set(au->data,sz);
     }
   }
 }
OUTPUT:
 RETVAL

float
Audio_duration(au)
Audio *		au

IV
Audio_rate(au,rate = 0)
Audio *	au
IV	rate

void
Audio_concat(lau,right,rev)
Audio *		lau
SV *		right
SV *		rev
CODE:
 {
  Audio *dau = Audio_overload_init(aTHX_ lau, &ST(0),1,right,rev);
  Audio_append_sv(aTHX_ dau, ST(1));
  XSRETURN(1);
 }

void
Audio_add(lau,right,rev)
Audio *		lau
SV *		right
SV *		rev
CODE:
 {
  Audio *rau;
  lau = Audio_overload_init(aTHX_ lau, &ST(0),0,right,rev);
  rau = Audio_from_sv(aTHX_ ST(1));
  if (rau)
   {
    int n = Audio_samples(rau);
    int m = Audio_samples(lau);
    float *d = AUDIO_DATA(rau);
    float *s;
    int skip = 0;
    if (m < n)
     Audio_more(aTHX_ lau,n-m);
    s = (AUDIO_COMPLEX(rau)) ? Audio_complex(lau) : AUDIO_DATA(lau);
    if (AUDIO_COMPLEX(lau) && !AUDIO_COMPLEX(rau))
     skip = 1;
    while (n-- > 0)
     {
      *s++ += *d++;
      s += skip;
     }
   }
  else
   {
    int m = Audio_samples(lau);
    float *s = AUDIO_DATA(lau);
    float v = SvNV(ST(1));
    int skip = (AUDIO_COMPLEX(lau)) ? 2 : 1;
    while (m-- > 0)
     {
      *s += v;
      s += skip;
     }
   }
  XSRETURN(1);
 }

void
Audio_sub(lau,right,rev)
Audio *		lau
SV *		right
SV *		rev
CODE:
 {
  Audio *rau;
  lau = Audio_overload_init(aTHX_ lau, &ST(0),0,right,rev);
  rau = Audio_from_sv(aTHX_ ST(1));
  if (rau)
   {
    int n = Audio_samples(rau);
    int m = Audio_samples(lau);
    float *d = AUDIO_DATA(rau);
    float *s;
    int skip = 0;
    if (m < n)
     Audio_more(aTHX_ lau,n-m);
    s = (AUDIO_COMPLEX(rau)) ? Audio_complex(lau) : AUDIO_DATA(lau);
    if (AUDIO_COMPLEX(lau) && !AUDIO_COMPLEX(rau))
     skip = 1;
    while (n-- > 0)
     {
      *s++ -= *d++;
      s += skip;
     }
   }
  else
   {
    int r = SvTRUE(rev);
    int m = Audio_samples(lau);
    float *s = AUDIO_DATA(lau);
    float v = SvNV(ST(1));
    int skip = (AUDIO_COMPLEX(lau)) ? 2 : 1;
    while (m-- > 0)
     {
      if (r)
       {
        *s = v - *s;
        if (AUDIO_COMPLEX(lau))
         s[1] = -s[1];
       }
      else
       *s -= v;
      s += skip;
     }
   }
  XSRETURN(1);
 }

void
Audio_mpy(lau,right,rev)
Audio *		lau
SV *		right
SV *		rev
CODE:
 {
  Audio *rau;
  lau = Audio_overload_init(aTHX_ lau, &ST(0),0,right,rev);
  rau = Audio_from_sv(aTHX_ ST(1));
  if (rau)
   {
    Perl_croak(aTHX_ "Convolution not implemented yet");
   }
  else
   {
    int m = Audio_samples(lau);
    float *s = AUDIO_DATA(lau);
    float v = SvNV(ST(1));
    m *= AUDIO_WORDS(lau);
    while (m-- > 0)
     {
      *s++ *= v;
     }
   }
  XSRETURN(1);
 }

void
Audio_div(lau,right,rev)
Audio *		lau
SV *		right
SV *		rev
CODE:
 {
  Audio *rau;
  lau = Audio_overload_init(aTHX_ lau, &ST(0),0,right,rev);
  rau = Audio_from_sv(aTHX_ ST(1));
  if (rau)
   {
    Perl_croak(aTHX_ "Divide not two Audios not given meaning yet");
   }
  else
   {
    int r = SvTRUE(rev);
    int n = Audio_samples(lau);
    int m = n;
    float *s = AUDIO_DATA(lau);
    float v = SvNV(ST(1));
    int skip = (AUDIO_COMPLEX(lau) && r) ? 2 : 1;
    m *= AUDIO_WORDS(lau)/skip;
    while (m-- > 0)
     {
      if (r)
       {
        if (AUDIO_COMPLEX(lau))
         {float a = s[0];
          float b = s[1];
          float d = a*a + b*b;
          s[0] = v*a/d;
          s[1] = -b*v/d;
         }
        else
         *s = v / *s;
       }
      else
       {
        *s /= v;
       }	
      s += skip;
     }
   }
  XSRETURN(1);
 }

void
hamming(au,N,start = 0,k = 0.46)
Audio *	au
IV	N
IV	start
double	k
CODE:
 {
  Audio tmp;
  float *s = AUDIO_DATA(au)+start;
  float *e = AUDIO_DATA(au)+Audio_samples(au);
  float *d;
  IV i;
  int complex = AUDIO_COMPLEX(au);
  double half_N = (double)N / 2.0;
  Zero(&tmp,1,Audio);
  tmp.data = newSVpvn("",0);
  tmp.rate = au->rate;
  if (complex)
   tmp.flags = AUDIO_F_COMPLEX;
  d = Audio_more(aTHX_ &tmp,N);
  for (i=0; i < N && s < e; i++)
   {double x = ((double) i - half_N)/half_N;
    double w = ((1.0-k)+k*cos(x*AUDIO_PI));
    *d++ = *s++ * w;
    if (complex)
     *d++ = *s++ * w;
   }
  sv_setref_pvn((ST(0) = sv_2mortal(newSV(0))),"Audio::Data",(char *)&tmp,sizeof(tmp));
  XSRETURN(1);
 }

void
Audio_autocorrelation(au,p)
Audio * au
int 	p
CODE:
 {
  char *type = AUDIO_CLASS(ST(0));
  SV *result = Nullsv;
  Audio *tmp = Audio_new(aTHX_ &result,au->rate, 0, p+1,type);
  float *x = AUDIO_DATA(au);
  float *d = AUDIO_DATA(tmp);
  Audio_autocorrelation(Audio_samples(au),x,p,d);
  ST(0) = result;
  XSRETURN(1);
 }

void
Audio_difference(au)
Audio * au
CODE:
 {
  Audio tmp;
  int n = Audio_samples(au)-1;
  float *x = AUDIO_DATA(au);
  float *d;
  Zero(&tmp,1,Audio);
  tmp.data = newSVpvn("",0);
  tmp.rate = au->rate;
  d = Audio_more(aTHX_ &tmp,n);
  Audio_difference(n,x,d);
  sv_setref_pvn((ST(0) = sv_2mortal(newSV(0))),"Audio::Data",(char *)&tmp,sizeof(tmp));
  XSRETURN(1);
 }

void
Audio_lpc(Audio *au,int order,SV *ac = 0, SV *rf = 0)
CODE:
{
 char *type = AUDIO_CLASS(ST(0));
 SV *result = Nullsv;
 Audio *lpc = Audio_new(aTHX_ &result,au->rate, 0, order+1,type);
 float *acf = AUDIO_DATA(Audio_new(aTHX_ &ac, au->rate, 0, order+1,type));
 float *ref = AUDIO_DATA(Audio_new(aTHX_ &rf, au->rate, 0, order+1,type));
 int length = Audio_samples(au);
 float *sig = AUDIO_DATA(au);
 if (AUDIO_COMPLEX(au))
  croak("Cannot process complex data");
 order = Audio_lpc(length,sig,order,acf,ref,AUDIO_DATA(lpc));
 ST(0) = result;
 XSRETURN(1);
}


void
Audio_durbin(au)
Audio * au
CODE:
 {
  int n = Audio_samples(au);
  SV *result = Nullsv;
  Audio *tmp = Audio_new(aTHX_ &result,au->rate,au->flags,n,AUDIO_CLASS(ST(0)));
  float *x = AUDIO_DATA(au);
  float *d = AUDIO_DATA(tmp);
  if (AUDIO_COMPLEX(au))
   croak("Cannot process complex data");
  Audio_durbin(n-1,x,d);
  ST(0) = result;
  XSRETURN(1);
 }

void
Audio_conjugate(au,right,rev)
Audio *		au
SV *		right
SV *		rev
CODE:
 {
  ST(2) = &PL_sv_no;
  au = Audio_overload_init(aTHX_ au, &ST(0),0,right,rev);
  Audio_conjugate(Audio_samples(au),Audio_complex(au),1.0);
 }

void
Audio_data(au,...)
Audio *		au
PPCODE:
 {
  int gimme = GIMME_V;
  if (items > 1)
   {
    int i;
    au->flags &= ~AUDIO_F_COMPLEX;
    SvCUR(au->data) = 0;
    for (i=1; i < items; i++)
     {
      Audio_append_sv(aTHX_ au,ST(i));
     }
   }
  if (gimme == G_VOID)
   {
    XSRETURN(0);
   }
  else if (gimme == G_ARRAY)
   {
    STRLEN sz;
    int count = 0;
    float *p = (float *) SvPV(au->data,sz);
    while (sz >= sizeof(float))
     {
      double d = *p++;
      XPUSHs(sv_2mortal(newSVnv(d)));
      sz -= sizeof(float);
      count++;
     }
    XSRETURN(count);
   }
  else
   {
    XPUSHs(SvREFCNT_inc(au->data));
    XSRETURN(1);
   }
 }

void
Audio_dB(au,start = 0, count = (GIMME == G_ARRAY) ? Audio_samples(au)-start : 1)
Audio *		au
int		start
int		count
PPCODE:
 {
  int n = Audio_samples(au);
  float *p = AUDIO_DATA(au)+start*AUDIO_WORDS(au);
  /* Min noticable value in 16bit is 1/(2**15) - call that 100dB */
  float min = 1.0/(1 << 15);
  float dB0 = 10*log10(min);
  if (start+count > n)
   count = n - start;
  if (AUDIO_COMPLEX(au))
   {
    for (n=0; n < count; n++)
     {
      float r = *p++;
      float i = *p++;
      r = sqrt(r*r+i*i);
      /* hack to avoid log10(0) yielding NaN or fault */
      if (r < min)
       r = min;
      XPUSHs(sv_2mortal(newSVnv(10*log10(r)-dB0)));
     }
   }
  else
   {
    for (n=0; n < count; n++)
     {
      float r = *p++;
      if (r < 0)
       r = -r;
      /* hack to avoid log10(0) yielding NaN or fault */
      if (r < min)
       r = min;
      XPUSHs(sv_2mortal(newSVnv(10*log10(r)-dB0)));
     }
   }
  XSRETURN(count);
 }

void
Audio_amplitude(au,start = 0, count = (GIMME == G_ARRAY) ? Audio_samples(au)-start : 1)
Audio *		au
int		start
int		count
PPCODE:
 {
  int n = Audio_samples(au);
  float *p = AUDIO_DATA(au)+start*AUDIO_WORDS(au);
  if (start+count > n)
   count = n - start;
  if (AUDIO_COMPLEX(au))
   {
    for (n=0; n < count; n++)
     {
      float r = *p++;
      float i = *p++;
      XPUSHs(sv_2mortal(newSVnv(sqrt(r*r+i*i))));
     }
   }
  else
   {
    for (n=0; n < count; n++)
     {
      float r = *p++;
      XPUSHs(sv_2mortal(newSVnv(r)));
     }
   }
  XSRETURN(count);
 }

void
Audio_phase(au,start = 0, count = (GIMME == G_ARRAY) ? Audio_samples(au)-start : 1)
Audio *		au
int		start
int		count
PPCODE:
 {
  int n = Audio_samples(au);
  float *p = AUDIO_DATA(au)+start*AUDIO_WORDS(au);
  if (start+count > n)
   count = n - start;
  if (AUDIO_COMPLEX(au))
   {
    for (n=0; n < count; n++)
     {
      float r = *p++;
      float i = *p++;
      XPUSHs(sv_2mortal(newSVnv(atan2(i,r))));
     }
   }
  else
   {
    for (n=0; n < count; n++)
     {
      XPUSHs(sv_2mortal(newSVnv(0)));
     }
   }
  XSRETURN(count);
 }


void
Audio_Load(au,fh)
Audio *		au
InputStream	fh

void
Audio_Save(au,fh,comment = NULL)
Audio *		au
OutputStream	fh
char *		comment

MODULE = Audio::Data	PACKAGE = Audio::Filter::AllPole	PREFIX = AllPole_

void
AllPole_process(au,...)
Audio *		au
PPCODE:
 {
  XSRETURN(Audio_filter_process(aTHX_ au,&Audio_AllPole,items,&ST(0)));
 }

MODULE = Audio::Data	PACKAGE = Audio::Filter::FIR	PREFIX = FIR_

void
FIR_process(au,...)
Audio *		au
PPCODE:
 {
  XSRETURN(Audio_filter_process(aTHX_ au,&Audio_FIR,items,&ST(0)));
 }


MODULE = Audio::Data	PACKAGE = Audio::Data	PREFIX = AUDIO_

void
AUDIO_r2_fft(au)
Audio *		au

void
AUDIO_r2_ifft(au)
Audio *		au

void
AUDIO_r4_fft(au)
Audio *		au

void
AUDIO_r4_ifft(au)
Audio *		au

void
AUDIO_complex_debug(au,f = PerlIO_stdout())
Audio *		au
OutputStream	f

BOOT:
 {
  sv_setiv(perl_get_sv("Audio::Data::AudioVtab",1),(IV) AudioVGet());
 }
