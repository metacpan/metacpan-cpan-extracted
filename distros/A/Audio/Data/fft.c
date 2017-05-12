/*
  Copyright (c) 2001 Nick Ing-Simmons. All rights reserved.
  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.
*/

#include <EXTERN.h>
#include <perl.h>
#include <math.h>
#include "Audio.h"

#ifndef M_PI
#define M_PI 3.14159265358979
#endif

#define xReal(x,i) x[2*i]
#define xImag(x,i) x[2*i+1]
#define SQR(x) ((x)*(x))
#define wSCALE(x)  (x)
#define wSIN(w,i)  w[2*i]
#define wCOS(w,i)  w[2*i+1]

#define fsin(i) w[2*i]
#define fcos(i) w[2*i+1]


typedef struct tcache_s
{
 struct tcache_s *link;
 int    N;
 float  *w;
 int    *rev;
} tcache_t, *tcache_ptr;

static tcache_ptr tcache = NULL;

static tcache_ptr
tcache_find(int N)
{
 tcache_ptr *r = &tcache;
 tcache_ptr *l = r;
 tcache_ptr p;
 while ((p = *l))
  {
   if (p->N == N)
    {
     *l = p->link;
     break;
    }
   l = &p->link;
  }
 if (!p)
  {
   Newz('T',p,1,tcache_t);
   p->N = N;
  }
 p->link = *r;
 *r = p;
 return p;
}

static int *
find_rev(int N)
{
 tcache_ptr c = tcache_find(N);
 if (!c->rev)
  {
   int *index;
   int i;
   int bits = 1;
   Newz('R',index,N,int);
   c->rev = index;
   while ((1 << bits) < N)
    bits++;
   if ((1 << bits) != N)
    {
     dTHX;
     Perl_warn(aTHX_ "%d is not a power of 2\n",N);
    }
   for (i = 0; i < N; i++)
    {
     int v = i;
     int r = 0;
     int bit = 1 << (bits-1);
     int j;
     for (j = 0; j < bits; j++)
      {
       if (v & 1)
        r |= bit;
       v >>= 1;
       bit >>= 1;
      }
     index[i] = r;
    }
  }
 return c->rev;
}

static void
bit_rev(int N, float *x)
{
 int i;
 int *rev = find_rev(N);
 for (i = 0; i < N; i++)
  {
   int j = rev[i];
   if (i > j)
    {
     float t = xReal(x,j);
     xReal(x,j) = xReal(x,i);
     xReal(x,i) = t;
     t = xImag(x,j);
     xImag(x,j) = xImag(x,i);
     xImag(x,i) = t;
    }
  }
}

float *
Audio_w(int N)
{
 tcache_ptr c = tcache_find(N);
 if (!c->w)
  {
   float *w;
   int i;
   New('W',w,2*N,float);
   c->w = w;
   for (i = 0; i < N; i++)
    {
     wSIN(w,i) = (float) sin(2*AUDIO_PI*i/N);
     wCOS(w,i) = (float) cos(2*AUDIO_PI*i/N);
    }
  }
 return c->w;
}

void
Audio_conjugate(int N,float *x,float scale)
{
 int i;
 for (i = 0; i < N; i++)
  {
   xReal(x,i) =  xReal(x,i)*scale;
   xImag(x,i) = -xImag(x,i)*scale;
  }
}

static void
ifft(fft_f *fft, int N,float *data)
{
 Audio_conjugate(N,data,1.0);
 (*fft)(N,data);
 Audio_conjugate(N,data,(float)(1.0/N));
}

/*
 *  Radix-2 FFT
 */

void
Audio_r2_fft(int n,float *data)
{
 float *w = Audio_w(n);
 int dist = n;
 int num_blks = 1;
 int st;
 for (st = 0; (1 << st) < n; st++)
  {int bf;
   for (bf = 0; bf < (dist >> 1); bf++)
    {int d = bf * num_blks;
     float c = wCOS(w,d);
     float s = wSIN(w,d);
     int b;
     for (b = 0; b < num_blks; b++)
      {int i = (dist * b + bf) << 1;
       int l = i + dist;
       float temp_r1 = data[i] - data[l];
       float temp_r2 = data[i + 1] - data[l + 1];
       data[i]       = data[i] + data[l];
       data[i + 1]   = data[i + 1] + data[l + 1];
       data[l]       = wSCALE((temp_r1 * c) + (temp_r2 * s));
       data[l + 1]   = wSCALE((temp_r2 * c) - (temp_r1 * s));
      }
    }
   dist = dist >> 1;
   num_blks = num_blks << 1;
  }
 bit_rev(n,data);
}

void
Audio_r2_ifft(int n,float *data)
{
 ifft(&Audio_r2_fft,n,data);
}

/*
 *  Radix-4 FFT
 */

void
Audio_r4_fft(int n, float *x)
{
 float *w = Audio_w(n);
 int n2 = n;
 int ie = 1;
 int k;
 for (k = n; k > 1; k >>= 2)
  {                               /* number of stages */
   int n1 = n2;
   int ia1 = 0;
   int j;
   n2 >>= 2;
   for (j = 0; j < n2; j++)
    {                             /* number of butterflies */
     int ia2 = ia1 + ia1;
     int ia3 = ia2 + ia1;
     float co1 = wCOS(w,ia1);
     float si1 = wSIN(w,ia1);
     float co2 = wCOS(w,ia2);
     float si2 = wSIN(w,ia2);
     float co3 = wCOS(w,ia3);
     float si3 = wSIN(w,ia3);
     int i0;
     ia1 = ia1 + ie;
     for (i0 = j; i0 < n; i0 += n1)
      {                           /* loop for butterfly */
       int i1 = i0 + n2;
       int i2 = i1 + n2;
       int i3 = i2 + n2;
       float r1 = xReal(x,i0) + xReal(x,i2);
       float r2 = xReal(x,i0) - xReal(x,i2);
       float s1 = xImag(x,i0) + xImag(x,i2);
       float s2 = xImag(x,i0) - xImag(x,i2);
       float tr = xReal(x,i1) + xReal(x,i3);
       float ts = xImag(x,i1) + xImag(x,i3);
       xReal(x,i0) = r1 + tr;
       xImag(x,i0) = s1 + ts;
       r1 = r1 - tr;
       s1 = s1 - ts;
       tr = xImag(x,i1) - xImag(x,i3);
       ts = xReal(x,i1) - xReal(x,i3);
       xReal(x,i1) = wSCALE(r1 * co2 + s1 * si2);
       xImag(x,i1) = wSCALE(s1 * co2 - r1 * si2);
       r1 = r2 + tr;
       r2 = r2 - tr;
       s1 = s2 - ts;
       s2 = s2 + ts;
       xReal(x,i2) = wSCALE(r1 * co1 + s1 * si1);
       xImag(x,i2) = wSCALE(s1 * co1 - r1 * si1);
       xReal(x,i3) = wSCALE(r2 * co3 + s2 * si3);
       xImag(x,i3) = wSCALE(s2 * co3 - r2 * si3);
      }
    }
   ie <<= 2;
  }
 bit_rev(n,x);
}

void
Audio_r4_ifft(int n,float *data)
{
 ifft(&Audio_r4_fft,n,data);
}

void
Audio_complex_debug(int N,float *x,PerlIO *f)
{
 int i;
 for (i = 0; i < N; i++)
  {
   PerlIO_printf(f,"%3d %8.4f+%8.4fi, %8.4f @ %6.1f\n",i,
           xReal(x,i),xImag(x,i),
           sqrt(SQR(xReal(x,i))+SQR(xImag(x,i))),
           180*(atan2(xImag(x,i),xReal(x,i)))/M_PI);
  }
}

void
Audio_difference(int n, float *a, float *b)
{
 int i;
 for (i=0; i < n; i++)
  b[i] = a[i+1] - a[i];
}


#ifdef ORIGINAL
void
Audio_autocorrelation(int N, float *x,unsigned p,float *r)
{
 int k;
 for (k=0; k <= p; k++)
  {int n;
   r[k] = 0.0;
   for (n=0; n < N-k; n++)
    r[k] += x[n]*x[n+k];
   /* What the heck is this doing ? ! 
      - well it is normalizing each entry which makes a kind 
        of sense when using it to spot period
	but makes result useless for LPC via Audio_durbin() below.
    */
   r[k] /= (float) (N-k);  
  }
}

#else 

void
Audio_autocorrelation(int N, float *x,unsigned p,float *r)
{
 unsigned i; 
 for (i = 0; i <= p; i++) 
  {
   unsigned j;
   float sum = 0.0;
   for(j = 0; j < N - i; j++) 
    sum += x[j] * x[j + i];
   r[i]= sum;
  }
}

#endif

#ifdef __GNUC__

void
Audio_durbin(int NUM_POLES, float *R,float *aa)
{double E[NUM_POLES+1];
 double k[NUM_POLES+1];
 double a[NUM_POLES+1][NUM_POLES+1];
 double G = R[0];
 int i;
 /* Set everything to NaN */
 memset(a,-1,sizeof(a));
 memset(k,-1,sizeof(k));
 memset(E,-1,sizeof(E));
 E[0] = R[0];
 for (i=1; i <= NUM_POLES; i++)
  {int j;
   k[i] = 0.0;
   for (j=1; j < i; j++)
    k[i] += a[j][i-1]*R[i-j];
   k[i] -= R[i];
   k[i] /= E[i-1];
   a[i][i] = -k[i];
   for (j=1; j < i; j++)
    {
     a[j][i] = a[j][i-1]+k[i]*a[i-j][i-1];
    }
   E[i] = (1.0 - k[i]*k[i])*E[i-1];
  }
 for (i=1; i <= NUM_POLES; i++)
  {
   aa[i] = a[i][NUM_POLES];
   G -= aa[i]*R[i];
  }
 /* Return gain as element zero */
 if (G < 0.0)
  G = -G;
 aa[0] = sqrt(G);
}


#else
#define a(I,J) *(A+N*(I)+(J))
void
Audio_durbin(int NUM_POLES, float *R,float *aa)
{
 int N = NUM_POLES+1;
 double *E;
 double *k;
 double *A;
 double G = R[0];
 int i;
 Newz('D',E,N,double);
 Newz('D',k,N,double);
 Newz('D',A,N*N,double);
 E[0] = R[0];
 for (i=1; i <= NUM_POLES; i++)
  {int j;
   k[i] = 0.0;
   for (j=1; j < i; j++)
    k[i] += a(j,i-1)*R[i-j];
   k[i] -= R[i];
   k[i] /= E[i-1];
   a(i,i) = -k[i];
   for (j=1; j < i; j++)
    {
     a(j,i) = a(j,i-1)+k[i]*a(i-j,i-1);
    }
   E[i] = (1.0 - k[i]*k[i])*E[i-1];
  }
 for (i=1; i <= NUM_POLES; i++)
  {
   aa[i] = (float) a(i,NUM_POLES);
   G -= aa[i]*R[i];
  }
 /* Return gain as element zero */
 if (G < 0.0)
  G = -G;
 aa[0] = (float) sqrt(G);
 Safefree(E);
 Safefree(k);
 Safefree(A);
}
#undef a 
#endif  /* GNUC */


/* This is lifted from EST */

int 
Audio_lpc(int length, const float *sig, int order, float *acf, 
	float *ref, float *lpc)
{

    int i, j;
    float e, ci, sum;
#ifdef __GCC__
    float tmp[order];
#else
    float *tmp = (float*) calloc(order,sizeof(float));
#endif
    int stableorder=-1;

    /* compute autocorellation */
    
    for (i = 0; i <= order; i++) 
    {
	sum = 0.0;
	for(j = 0; j < length - i; j++) 
	    sum += sig[j] * sig[j + i];
	acf[i]= sum;
    }
    
    /* find lpc coefficients */
    e = acf[0];
    lpc[0] = 1.0;

    for (i = 1; i <= order; i++) 
    {
	ci = 0.0;
	for(j = 1; j < i; j++) 
	    ci += lpc[j] * acf[i-j];
	if (e == 0)
	    ref[i] = ci = 0.0;
	else
	    ref[i] = ci = (acf[i] - ci) / e;
	/* Check stability of the recursion */
	if (-1.000000 < ci && ci < 1.000000) 
	{
	    lpc[i] = ci;
	    for (j = 1; j < i; j++) 
		tmp[j] = lpc[j] - (ci * lpc[i-j]);
	    for( j = 1; j < i; j++) 
		lpc[j] = tmp[j];

	    e = (1 - ci * ci) * e;
	    stableorder = i;
	}
	else break;
    }
    if (stableorder != order) 
    {
	warn("levinson instability, order restricted to %d\n",stableorder);
	for (; i <= order; i++)
	    lpc[i] = 0.0;
    }

    // normalisation for frame length
    lpc[0] = e / length;
#ifndef __GCC__
    free(tmp);
#endif
    return stableorder;
}


#if 0
void
hamming(float *d,unsigned n,float *r,float k)
{float *window = alloc_vec(n);
 unsigned i;
 double half_n = (double)n / 2.0;
 for (i=0; i < n; i++)
  {double x = ((double) i - half_n)/half_n;
   double w = ((1.0-k)+k*cos(x*M_PI));
   window[i] = w;
   r[i] = d[i]*w;
  }
 free(window);
}
#endif



