/* dither.h:  dithering engine.  dithers naitive mad_fixed_t samples into
   pcm samples using a linear sample quantize and dither routine - again - 
   lifted from the mad-0.14.2b source distribution */

enum mad_dither_type {
	MAD_DITHER_S8     = 1, 
	MAD_DITHER_U8     = 2,
	MAD_DITHER_S16_LE = 3, 
	MAD_DITHER_S16_BE = 4,
	MAD_DITHER_S24_LE = 5, 
	MAD_DITHER_S24_BE = 6,
	MAD_DITHER_S32_LE = 7, 
	MAD_DITHER_S32_BE = 8,
};

struct mad_dither_info {
	struct mad_dither_error {
		mad_fixed_t	error[3];
		mad_fixed_t	random;
	} state[2];
	
	unsigned long	clipped;
	mad_fixed_t	peak_clip;
	mad_fixed_t	peak_sample;
};

signed long mad_dither_linear(struct mad_dither_info *, struct mad_dither_error *, unsigned int, mad_fixed_t);

typedef void mad_dither_pcmfunc_t(struct mad_dither_info *, unsigned char *, unsigned int, mad_fixed_t const *, mad_fixed_t const *);

mad_dither_pcmfunc_t mad_dither_s8;
mad_dither_pcmfunc_t mad_dither_u8;
mad_dither_pcmfunc_t mad_dither_s16_le;
mad_dither_pcmfunc_t mad_dither_s16_be;
mad_dither_pcmfunc_t mad_dither_s24_le;
mad_dither_pcmfunc_t mad_dither_s24_be;
mad_dither_pcmfunc_t mad_dither_s32_le;
mad_dither_pcmfunc_t mad_dither_s32_be;
mad_dither_pcmfunc_t mad_dither_float;

struct mad_dither {
	mad_dither_pcmfunc_t	*pcmfunc;
	unsigned int		pcmlength;

	struct mad_dither_info	info;
};

void mad_dither_init(struct mad_dither *, int);
