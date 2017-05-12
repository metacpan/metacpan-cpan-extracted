#include <EXTERN.h>
#include <perl.h>
#include "Audio.h"

/*
 * Derived from
 * Sound Tools rate change effect file.
 * July 5, 1991
 * Copyright 1991 Lance Norskog And Sundry Contributors
 * This source code is freely redistributable and may be used for
 * any purpose.  This copyright notice must be maintained.
 * Lance Norskog And Sundry Contributors are not responsible for
 * the consequences of using this software.
 */
/*
 * Least Common Multiple Linear Interpolation
 *
 * Find least common multiple of the two sample rates.
 * Construct the signal at the LCM by interpolating successive
 * input samples as straight lines.  Pull output samples from
 * this line at output rate.
 *
 * Of course, actually calculate only the output samples.
 *
 * LCM must be 32 bits or less.  Two prime number sample rates
 * between 32768 and 65535 will yield a 32-bit LCM, so this is
 * stretching it.
 */

/*
 * Algorithm:
 *
 *  Generate a master sample clock from the LCM of the two rates.
 *  Interpolate linearly along it.  Count up input and output skips.
 *
 *  Input:   |inskip |       |       |       |       |
 *
 *
 *
 *  LCM:     |   |   |   |   |   |   |   |   |   |   |
 *
 *
 *
 *  Output:  |  outskip  |           |           |
 *
 *
 */

/* here for linear interp.  might be useful for other things */
static long
gcd(long a, long b)
{
 if (b == 0)
  return a;
 else
  return gcd(b, a % b);
}

static long
lcm(long a, long b)
{
 return (a * b) / gcd(a, b);
}

IV
Audio_rate(Audio * au, IV rate)
{
 if (rate > 0)
  {
   unsigned long orate = rate;
   unsigned long irate = au->rate;
   unsigned long isamp = Audio_samples(au);

   if (irate != 0 && irate != orate && isamp != 0)
    {
     unsigned long lcmrate        /* least common multiple of rates */
     = lcm(irate, orate);
     unsigned long inskip         /* LCM increments for I & O rates */
     = lcmrate / irate;
     unsigned long outskip        /* LCM increments for I & O rates */
     = lcmrate / orate;

     unsigned long intot = 0;
     unsigned long outtot = 0;    /* total samples in terms of LCM rate */
     float last;
     dTHX;
     SV *odata = newSVpv("", 0);
     float *ibuf = (float *) SvPVX(au->data);
     float *iend = ibuf + isamp;
     /* number of output samples the input can feed */
     int osamp = (isamp * inskip) / outskip;
     float *obuf = (float *) SvGROW(odata, osamp * sizeof(float));
     float *oend = obuf + osamp;
     float lastsamp = 0;

     /* Cursory check for LCM overflow.
      * If both rate are below 65k, there should be no problem.
      * 16 bits x 16 bits = 32 bits, which we can handle.
      */

     /* Count up until have right input samples */
     lastsamp = *ibuf++;
     /* advance to second output */
     outtot += outskip;
     /* advance input range to span next output */
     while ((intot + inskip) <= outtot)
      {
       last = *ibuf++;
       intot += inskip;
      }

     /* Emit first sample.  We know the fence posts meet. */
     *obuf++ = lastsamp;
     SvCUR(odata) = sizeof(float);
     last = lastsamp;
     while (obuf < oend && ibuf < iend)
      {
       *obuf++ = last + ((*ibuf - last) * ((float) outtot - intot)) / inskip;
       /* advance to next output */
       SvCUR(odata) += sizeof(float);
       outtot += outskip;
       /* advance input range to span next output */
       while ((intot + inskip) <= outtot)
        {
         last = *ibuf++;
         intot += inskip;
         if (ibuf >= iend)
          break;
        }
       /* long samples with high LCM's overrun counters!
        * so reset when we can.
        */
       if (outtot == intot)
        outtot = intot = 0;
      }
     SvREFCNT_dec(au->data);
     au->data = odata;
    }
   au->rate = orate;
  }
 return au->rate;
}

/*
 * Derived from Sound Tools Low-Pass effect file.
 * July 5, 1991
 * Copyright 1991 Lance Norskog And Sundry Contributors
 * This source code is freely redistributable and may be used for
 * any purpose.  This copyright notice must be maintained.
 * Lance Norskog And Sundry Contributors are not responsible for
 * the consequences of using this software.
 *
 * Algorithm:  2nd order filter.
 * From Fugue source code:
 *
 *                                                                                                  output[N] = input[N] * A + input[N-1] * B
 *
 *                                                                                                  A = 2.0 * pi * center
 *                                                                                                  B = exp(-A / frequency)
 */

void
Audio_lowpass(Audio * au, float freq)
{
 float *buf = (float *) SvPVX(au->data);
 float *end = buf + Audio_samples(au);
 float A = (AUDIO_PI * 2.0 * freq) / au->rate;
 float B = exp(-A / au->rate);
 float in1 = 0.0;
 if (freq > au->rate * 2)
  croak("lowpass: center must be < minimum data rate*2\n");

 while (buf < end)
  {
   float l = *buf;
   *buf++ = (A * l + B * in1) * 0.8;
   in1 = l;
  }
}

/*
 * Derived from Sound Tools High-Pass effect file.
 * July 5, 1991
 * Copyright 1991 Lance Norskog And Sundry Contributors
 * This source code is freely redistributable and may be used for
 * any purpose.  This copyright notice must be maintained.
 * Lance Norskog And Sundry Contributors are not responsible for
 * the consequences of using this software.
 *
 * Algorithm:  1nd order filter.
 * From Fugue source code:
 *
 *                                                                                                  output[N] = B * (output[N-1] - input[N-1] + input[N])
 *
 *                                                                                                  A = 2.0 * pi * center
 *                                                                                                  B = exp(-A / frequency)
 */

void
Audio_highpass(Audio * au, float freq)
{
 float *buf = (float *) SvPVX(au->data);
 float *end = buf + Audio_samples(au);
 float A = (AUDIO_PI * 2.0 * freq) / au->rate;
 float B = exp(-A / au->rate);
 float in1 = 0.0;
 float out1 = 0.0;

 if (freq > au->rate * 2)
  croak("lowpass: center must be < minimum data rate*2\n");

 while (buf < end)
  {
   float l = *buf;
   out1 = B * ((out1 - in1) + l) * 0.8;
   *buf++ = out1;
   in1 = l;
  }
}


