#ifndef _AUDIO
#define _AUDIO
typedef struct
 {
  UV rate;
  IV flags;
  SV *comment;
  SV *data;
 } Audio;

#define AUDIO_F_COMPLEX 1
#define AUDIO_F_FREQ    2
#define AUDIO_COMPLEX(au) ((au)->flags & AUDIO_F_COMPLEX)
#define AUDIO_WORDS(au) (AUDIO_COMPLEX(au) ? 2 : 1)

typedef void fft_f(int n,float *data);

#ifndef dTHX
#define dTHX extern int Audio__notUsed
#define aTHX_
#define pTHX_
#endif

#define InputStream PerlIO *
#define OutputStream PerlIO *

#ifndef AUDIO_PI
#define	AUDIO_PI 3.14159265358979323846
#endif

#define Audio_samples(au) (SvCUR((au)->data)/(sizeof(float)*AUDIO_WORDS(au)))
#define Audio_duration(au) ((float) Audio_samples(au)/(au)->rate)
#define Audio_silence(au,t) Audio_more(aTHX_ au,(int) (t*(au)->rate))
#define AUDIO_DATA(au) ((float *) SvPVX((au)->data))

extern float *Audio_more _((pTHX_ Audio *au, int n));
extern short		*_u2l;		/* 8-bit u-law to 16-bit PCM */
extern unsigned char	*_l2u;		/* 13-bit PCM to 8-bit u-law */
#define	ulaw2short(X)	(_u2l[(unsigned char) (X)])
#define	short2ulaw(X)	(_l2u[((short)(X)) >> 3])
extern long float2ulaw _((float f));
extern float ulaw2float _((long u));
extern long float2linear _((float f,int bits));
extern float linear2float _((long l,int bits));
extern SV * Audio_shorts _((Audio *au));
extern float *Audio_w _((int n));
extern void Audio_r2_fft  _((int n,float *data));
extern void Audio_r2_ifft _((int n,float *data));
extern void Audio_r4_fft  _((int n,float *data));
extern void Audio_r4_ifft _((int n,float *data));
extern void Audio_conjugate _((int n,float *data,float scale));
extern void Audio_complex_debug _((int N,float *x,PerlIO *f));
extern void Audio_difference _((int n, float *a, float *b));
extern void Audio_autocorrelation _((int N, float *x,unsigned p,float *r));
extern void Audio_durbin _((int NUM_POLES, float *R,float *aa));
extern int  Audio_lpc _((int length, const float *sig, int order, float *acf,
   	              float *ref, float *lpc));

extern void Audio_Load _((Audio *au, InputStream f));
extern void Audio_Save _((Audio *au, OutputStream f, char *comment));
extern IV   Audio_rate _((Audio * au, IV rate));




#endif /* _AUDIO */
