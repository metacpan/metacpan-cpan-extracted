#include <mad.h>
#include <string.h>
#include <stdio.h>
#include "dither.h"

static struct mad_dither_func_table {
	enum mad_dither_type type;
	mad_dither_pcmfunc_t *pcmfunc;
	unsigned int pcmlength;
} mad_dither_func[] = {
	{ MAD_DITHER_S8,     mad_dither_s8,     1 },
	{ MAD_DITHER_U8,     mad_dither_u8,     1 },
	{ MAD_DITHER_S16_LE, mad_dither_s16_le, 2 },
	{ MAD_DITHER_S16_BE, mad_dither_s16_be, 2 },
	{ MAD_DITHER_S24_LE, mad_dither_s24_le, 3 },
	{ MAD_DITHER_S24_BE, mad_dither_s24_be, 3 },
	{ MAD_DITHER_S32_LE, mad_dither_s32_le, 4 },
	{ MAD_DITHER_S32_BE, mad_dither_s32_be, 4 },
};

void mad_dither_init(struct mad_dither *dither, int type) {
	struct mad_dither_func_table *ptr;
	
	for (ptr = mad_dither_func; ptr != NULL; ptr++) {
		if (ptr->type == type) {
			dither->pcmfunc   = ptr->pcmfunc;
			dither->pcmlength = ptr->pcmlength;
			return;
		}
	}
	
	dither->pcmfunc = NULL;
	return;
}

enum {
	FMIN = -MAD_F_ONE,
	FMAX =  MAD_F_ONE - 1
};

static inline unsigned long prng(unsigned long state) {
	return (state * 0x0019660dL + 0x3c6ef35fL) & 0xffffffffL;
}

inline signed long mad_dither_linear(struct mad_dither_info *ds, struct mad_dither_error *de, unsigned int bits, mad_fixed_t sample) {
	unsigned int scalebits;
	mad_fixed_t output, mask, random;
	
	/* noise shape */
	sample += de->error[0] - de->error[1] + de->error[2];
	
	de->error[2] = de->error[1];
	de->error[1] = de->error[0] / 2;
	
	/* bias */
	output = sample + (1L << (MAD_F_FRACBITS + 1 - bits - 1));
	
	scalebits = MAD_F_FRACBITS + 1 - bits;
	mask = (1L << scalebits) - 1;
	
	/* dither */
	random  = prng(de->random);
	output += (random & mask) - (de->random & mask);
	
	de->random = random;
	
	/* clip */
	if (output >= ds->peak_sample) {
		if (output > FMAX) {
			++ds->clipped;
			if (output - FMAX > ds->peak_clip)
				ds->peak_clip = output - FMAX;
				
			output = FMAX;
			
			if (sample > FMAX)
				sample = FMAX;
		}
		ds->peak_sample = output;
	} else if (output < -ds->peak_sample) {
		if (output < FMIN) {
			++ds->clipped;
			
			if (FMIN - output > ds->peak_clip)
				ds->peak_clip = FMIN - output;
				
			output = FMIN;
			
			if (sample < FMIN)
				sample = FMIN;
		}
		
		ds->peak_sample = -output;
	}
	
	/* quantize */
	output &= ~mask;
	
	/* error feedback */
	de->error[0] = sample - output;
	
	/* scale */
	return output >> scalebits;
}

/* mad_dither_pcmfunc_t functions are here */

void mad_dither_u8(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	
	if (right) {
		while (length--) {
			data[0] = mad_dither_linear(de, &de->state[0], 8, *left++)  ^ 0x80;
			data[1] = mad_dither_linear(de, &de->state[1], 8, *right++) ^ 0x80;
			
			data += 2;
		}
	} else {
		while (length--) {
			*data++ = mad_dither_linear(de, &de->state[0], 8, *left++)  ^ 0x80;
		}
	}
}

void mad_dither_s8(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	
	if (right) {
		while (length--) {
			data[0] = mad_dither_linear(de, &de->state[0], 8, *left++);
			data[1] = mad_dither_linear(de, &de->state[1], 8, *right++);
			
			data += 2;
		}
	} else {
		while (length--) {
			*data++ = mad_dither_linear(de, &de->state[0], 8, *left++);
		}
	}
}

void mad_dither_s16_le(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	register signed int sample0, sample1;

	if (right) {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 16, *left++);
			sample1 = mad_dither_linear(de, &de->state[1], 16, *right++);
			
			data[0] = sample0 >> 0;
			data[1] = sample0 >> 8;
			data[2] = sample1 >> 0;
			data[3] = sample1 >> 8;
			
			data += 4;
		}
	} else {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 16, *left++);
			
			data[0] = sample0 >> 0;
			data[1] = sample0 >> 8;
			
			data += 2;
		}
	}
}

void mad_dither_s16_be(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	register signed int sample0, sample1;
	
	if (right) {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 16, *left++);
			sample1 = mad_dither_linear(de, &de->state[1], 16, *right++);
			
			data[0] = sample0 >> 8;
			data[1] = sample0 >> 0;
			data[2] = sample1 >> 8;
			data[3] = sample1 >> 0;
			
			data += 4;
		}
	} else {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 16, *left++);
			
			data[0] = sample0 >> 8;
			data[1] = sample0 >> 0;
			
			data += 2;
		}
	}
}

void mad_dither_s24_le(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	register signed long sample0, sample1;
	
	if (right) {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			sample1 = mad_dither_linear(de, &de->state[1], 24, *right++);
			
			data[0] = sample0 >> 0;
			data[1] = sample0 >> 8;
			data[2] = sample0 >> 16;

			data[3] = sample1 >> 0;
			data[4] = sample1 >> 8;
			data[5] = sample1 >> 16;
			
			data += 6;
		}
	} else {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			
			data[0] = sample0 >> 0;
			data[1] = sample0 >> 8;
			data[2] = sample0 >> 16;
			
			data += 3;
		}
	}
}

void mad_dither_s24_be(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	register signed long sample0, sample1;
	
	if (right) {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			sample1 = mad_dither_linear(de, &de->state[1], 24, *right++);
			
			data[0] = sample0 >> 16;
			data[1] = sample0 >> 8;
			data[2] = sample0 >> 0;

			data[3] = sample1 >> 16;
			data[4] = sample1 >> 8;
			data[5] = sample1 >> 0;
			
			data += 6;
		}
	} else {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			
			data[0] = sample0 >> 16;
			data[1] = sample0 >> 8;
			data[2] = sample0 >> 0;
			
			data += 3;
		}
	}
}

void mad_dither_s32_le(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	register signed int sample0, sample1;
	
	if (right) {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			sample1 = mad_dither_linear(de, &de->state[1], 24, *right++);
			
			data[0] = 0;
			data[1] = sample0 >> 0;
			data[2] = sample0 >> 8;
			data[3] = sample0 >> 16;

			data[4] = 0;
			data[5] = sample1 >> 0;
			data[6] = sample1 >> 8;
			data[7] = sample1 >> 16;			
			
			data += 8;
		}
	} else {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			
			data[0] = 0;
			data[1] = sample0 >> 0;
			data[2] = sample0 >> 8;
			data[3] = sample0 >> 16;			
			
			data += 4;
		}
	}
}

void mad_dither_s32_be(struct mad_dither_info *de, unsigned char *data, unsigned int samples, mad_fixed_t const *left, mad_fixed_t const *right) {
	unsigned int length = samples;
	register signed int sample0, sample1;
	
	if (right) {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			sample1 = mad_dither_linear(de, &de->state[1], 24, *right++);

			data[0] = sample0 >> 16;
			data[1] = sample0 >> 8;
			data[2] = sample0 >> 0;
			data[3] = 0;
			
			data[4] = sample1 >> 16;
			data[5] = sample1 >> 8;
			data[6] = sample1 >> 0;			
			data[7] = 0;
			
			data += 8;
		}
	} else {
		while (length--) {
			sample0 = mad_dither_linear(de, &de->state[0], 24, *left++);
			
			data[0] = sample0 >> 16;
			data[1] = sample0 >> 8;
			data[2] = sample0 >> 0;			
			data[3] = 0;
			
			data += 4;
		}
	}
}
