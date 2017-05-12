/*
 * $Id: audio.c,v 1.1.1.1 2001/06/17 01:37:51 ptimof Exp $
 *
 * Copyright (c) 2001 Peter Timofejew. All rights reserved.
 * Portions copyright (c) 2000-2001 Robert Leslie
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA  02111-1307  USA
 *
 */

# ifdef HAVE_CONFIG_H
#  include "config.h"
# endif

// # include "global.h"

# include <string.h>
#include <errno.h>

# include "audio.h"
# include <mad.h>

/*
 * NAME:	audio_linear_round()
 * DESCRIPTION:	generic linear sample quantize routine
 */
inline
signed long audio_linear_round(unsigned int bits, mad_fixed_t sample,
			       struct audio_stats *stats)
{
  /* round */
  sample += (1L << (MAD_F_FRACBITS - bits));

# if 1
  /* clip */
  if (sample >= stats->peak_sample) {
    if (sample >= MAD_F_ONE) {
      ++stats->clipped_samples;
      if (sample - (MAD_F_ONE - 1) > stats->peak_clipping)
	stats->peak_clipping = sample - (MAD_F_ONE - 1);
      sample = MAD_F_ONE - 1;
    }
    stats->peak_sample = sample;
  }
  else if (sample < -stats->peak_sample) {
    if (sample < -MAD_F_ONE) {
      ++stats->clipped_samples;
      if (-MAD_F_ONE - sample > stats->peak_clipping)
	stats->peak_clipping = -MAD_F_ONE - sample;
      sample = -MAD_F_ONE;
    }
    stats->peak_sample = -sample;
  }
# else
  /* clip */
  if (sample >= MAD_F_ONE)
    sample = MAD_F_ONE - 1;
  else if (sample < -MAD_F_ONE)
    sample = -MAD_F_ONE;
# endif

  /* quantize and scale */
  return sample >> (MAD_F_FRACBITS + 1 - bits);
}

/*
 * NAME:	audio_linear_dither()
 * DESCRIPTION:	generic linear sample quantize and dither routine
 */
inline
signed long audio_linear_dither(unsigned int bits, mad_fixed_t sample,
				mad_fixed_t *error, struct audio_stats *stats)
{
  mad_fixed_t quantized;

  /* dither */
  sample += *error;

# if 1
  /* clip */
  quantized = sample;
  if (sample >= stats->peak_sample) {
    if (sample >= MAD_F_ONE) {
      quantized = MAD_F_ONE - 1;
      ++stats->clipped_samples;
      if (sample - quantized > stats->peak_clipping &&
	  mad_f_abs(*error) < (MAD_F_ONE >> (MAD_F_FRACBITS + 1 - bits)))
	stats->peak_clipping = sample - quantized;
    }
    stats->peak_sample = quantized;
  }
  else if (sample < -stats->peak_sample) {
    if (sample < -MAD_F_ONE) {
      quantized = -MAD_F_ONE;
      ++stats->clipped_samples;
      if (quantized - sample > stats->peak_clipping &&
	  mad_f_abs(*error) < (MAD_F_ONE >> (MAD_F_FRACBITS + 1 - bits)))
	stats->peak_clipping = quantized - sample;
    }
    stats->peak_sample = -quantized;
  }
# else
  /* clip */
  quantized = sample;
  if (sample >= MAD_F_ONE)
    quantized = MAD_F_ONE - 1;
  else if (sample < -MAD_F_ONE)
    quantized = -MAD_F_ONE;
# endif

  /* quantize */
  quantized &= ~((1L << (MAD_F_FRACBITS + 1 - bits)) - 1);

  /* error */
  *error = sample - quantized;

  /* scale */
  return quantized >> (MAD_F_FRACBITS + 1 - bits);
}

/*
 * NAME:	audio_pcm_u8()
 * DESCRIPTION:	write a block of unsigned 8-bit PCM samples
 */
unsigned int audio_pcm_u8(unsigned char *data, unsigned int nsamples,
			  mad_fixed_t const *left, mad_fixed_t const *right,
			  enum audio_mode mode, struct audio_stats *stats,
			  struct audio_dither_err *dither_err)
{
  unsigned int len;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	data[0] = audio_linear_round(8, *left++,  stats) + 0x80;
	data[1] = audio_linear_round(8, *right++, stats) + 0x80;

	data += 2;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	data[0] = audio_linear_dither(8, *left++,  &dither_err->left,  stats) + 0x80;
	data[1] = audio_linear_dither(8, *right++, &dither_err->right, stats) + 0x80;

	data += 2;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--)
	*data++ = audio_linear_round(8, *left++, stats) + 0x80;
      break;

    case AUDIO_MODE_DITHER:
      while (len--)
	*data++ = audio_linear_dither(8, *left++, &dither_err->left, stats) + 0x80;
      break;

    default:
      return 0;
    }

    return nsamples;
  }
}

/*
 * NAME:	audio_pcm_s16le()
 * DESCRIPTION:	write a block of signed 16-bit little-endian PCM samples
 */
unsigned int audio_pcm_s16le(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				 struct audio_dither_err *dither_err)
{
  unsigned int len;
  register signed int sample0, sample1;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(16, *left++,  stats);
	sample1 = audio_linear_round(16, *right++, stats);

	data[0] = sample0 >> 0;
	data[1] = sample0 >> 8;
	data[2] = sample1 >> 0;
	data[3] = sample1 >> 8;

	data += 4;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(16, *left++,  &dither_err->left,  stats);
	sample1 = audio_linear_dither(16, *right++, &dither_err->right, stats);

	data[0] = sample0 >> 0;
	data[1] = sample0 >> 8;
	data[2] = sample1 >> 0;
	data[3] = sample1 >> 8;

	data += 4;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 2 * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(16, *left++, stats);

	data[0] = sample0 >> 0;
	data[1] = sample0 >> 8;

	data += 2;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(16, *left++, &dither_err->left, stats);

	data[0] = sample0 >> 0;
	data[1] = sample0 >> 8;

	data += 2;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 2;
  }
}

/*
 * NAME:	audio_pcm_s16be()
 * DESCRIPTION:	write a block of signed 16-bit big-endian PCM samples
 */
unsigned int audio_pcm_s16be(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				 struct audio_dither_err *dither_err)
{
  unsigned int len;
  register signed int sample0, sample1;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(16, *left++,  stats);
	sample1 = audio_linear_round(16, *right++, stats);

	data[0] = sample0 >> 8;
	data[1] = sample0 >> 0;
	data[2] = sample1 >> 8;
	data[3] = sample1 >> 0;

	data += 4;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(16, *left++,  &dither_err->left,  stats);
	sample1 = audio_linear_dither(16, *right++, &dither_err->right, stats);

	data[0] = sample0 >> 8;
	data[1] = sample0 >> 0;
	data[2] = sample1 >> 8;
	data[3] = sample1 >> 0;

	data += 4;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 2 * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(16, *left++, stats);

	data[0] = sample0 >> 8;
	data[1] = sample0 >> 0;

	data += 2;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(16, *left++, &dither_err->left, stats);

	data[0] = sample0 >> 8;
	data[1] = sample0 >> 0;

	data += 2;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 2;
  }
}

/*
 * NAME:	audio_pcm_s24le()
 * DESCRIPTION:	write a block of signed 24-bit little-endian PCM samples
 */
unsigned int audio_pcm_s24le(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				  struct audio_dither_err *dither_err)
{
  unsigned int len;
  register signed long sample0, sample1;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++,  stats);
	sample1 = audio_linear_round(24, *right++, stats);

	data[0] = sample0 >>  0;
	data[1] = sample0 >>  8;
	data[2] = sample0 >> 16;

	data[3] = sample1 >>  0;
	data[4] = sample1 >>  8;
	data[5] = sample1 >> 16;

	data += 6;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++,  &dither_err->left,  stats);
	sample1 = audio_linear_dither(24, *right++, &dither_err->right, stats);

	data[0] = sample0 >>  0;
	data[1] = sample0 >>  8;
	data[2] = sample0 >> 16;

	data[3] = sample1 >>  0;
	data[4] = sample1 >>  8;
	data[5] = sample1 >> 16;

	data += 6;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 3 * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++, stats);

	data[0] = sample0 >>  0;
	data[1] = sample0 >>  8;
	data[2] = sample0 >> 16;

	data += 3;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++, &dither_err->left, stats);

	data[0] = sample0 >>  0;
	data[1] = sample0 >>  8;
	data[2] = sample0 >> 16;

	data += 3;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 3;
  }
}

/*
 * NAME:	audio_pcm_s24be()
 * DESCRIPTION:	write a block of signed 24-bit big-endian PCM samples
 */
unsigned int audio_pcm_s24be(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				  struct audio_dither_err *dither_err)
{
  unsigned int len;
  register signed long sample0, sample1;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++,  stats);
	sample1 = audio_linear_round(24, *right++, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;

	data[3] = sample1 >> 16;
	data[4] = sample1 >>  8;
	data[5] = sample1 >>  0;

	data += 6;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++,  &dither_err->left,  stats);
	sample1 = audio_linear_dither(24, *right++, &dither_err->right, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;

	data[3] = sample1 >> 16;
	data[4] = sample1 >>  8;
	data[5] = sample1 >>  0;

	data += 6;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 3 * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;

	data += 3;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample1 = audio_linear_dither(24, *left++, &dither_err->left, stats);

	data[0] = sample1 >> 16;
	data[1] = sample1 >>  8;
	data[2] = sample1 >>  0;

	data += 3;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 3;
  }
}

/*
 * NAME:	audio_pcm_s32le()
 * DESCRIPTION:	write a block of signed 32-bit little-endian PCM samples
 */
unsigned int audio_pcm_s32le(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				  struct audio_dither_err *dither_err)
{
  unsigned int len;
  register signed long sample0, sample1;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++,  stats);
	sample1 = audio_linear_round(24, *right++, stats);

	data[0] = 0;
	data[1] = sample0 >>  0;
	data[2] = sample0 >>  8;
	data[3] = sample0 >> 16;

	data[4] = 0;
	data[5] = sample1 >>  0;
	data[6] = sample1 >>  8;
	data[7] = sample1 >> 16;

	data += 8;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++,  &dither_err->left,  stats);
	sample1 = audio_linear_dither(24, *right++, &dither_err->right, stats);

	data[0] = 0;
	data[1] = sample0 >>  0;
	data[2] = sample0 >>  8;
	data[3] = sample0 >> 16;

	data[4] = 0;
	data[5] = sample1 >>  0;
	data[6] = sample1 >>  8;
	data[7] = sample1 >> 16;

	data += 8;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 4 * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++, stats);

	data[0] = 0;
	data[1] = sample0 >>  0;
	data[2] = sample0 >>  8;
	data[3] = sample0 >> 16;

	data += 4;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++, &dither_err->left, stats);

	data[0] = 0;
	data[1] = sample0 >>  0;
	data[2] = sample0 >>  8;
	data[3] = sample0 >> 16;

	data += 4;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 4;
  }
}

/*
 * NAME:	audio_pcm_s32be()
 * DESCRIPTION:	write a block of signed 32-bit big-endian PCM samples
 */
unsigned int audio_pcm_s32be(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				  struct audio_dither_err *dither_err)
{
  unsigned int len;
  register signed long sample0, sample1;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++,  stats);
	sample1 = audio_linear_round(24, *right++, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;
	data[3] = 0;

	data[4] = sample1 >> 16;
	data[5] = sample1 >>  8;
	data[6] = sample1 >>  0;
	data[7] = 0;

	data += 8;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++,  &dither_err->left,  stats);
	sample1 = audio_linear_dither(24, *right++, &dither_err->right, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;
	data[3] = 0;

	data[4] = sample1 >> 16;
	data[5] = sample1 >>  8;
	data[6] = sample1 >>  0;
	data[7] = 0;

	data += 8;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 4 * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	sample0 = audio_linear_round(24, *left++, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;
	data[3] = 0;

	data += 4;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	sample0 = audio_linear_dither(24, *left++, &dither_err->left, stats);

	data[0] = sample0 >> 16;
	data[1] = sample0 >>  8;
	data[2] = sample0 >>  0;
	data[3] = 0;

	data += 4;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 4;
  }
}

/*
 * NAME:	audio_mulaw_round()
 * DESCRIPTION:	convert a linear PCM value to 8-bit ISDN mu-law
 */
unsigned char audio_mulaw_round(mad_fixed_t sample)
{
  unsigned int sign, mulaw;

  enum {
    bias = (mad_fixed_t) ((0x10 << 1) + 1) << (MAD_F_FRACBITS - 13)
  };

  if (sample < 0) {
    sample = bias - sample;
    sign   = 0x7f;
  }
  else {
    sample = bias + sample;
    sign   = 0xff;
  }

  if (sample >= MAD_F_ONE)
    mulaw = 0x7f;
  else {
    unsigned int segment;
    unsigned long mask;

    segment = 7;
    for (mask = 1L << (MAD_F_FRACBITS - 1); !(sample & mask); mask >>= 1)
      --segment;

    mulaw = ((segment << 4) |
	     ((sample >> (MAD_F_FRACBITS - 1 - (7 - segment) - 4)) & 0x0f));
  }

  mulaw ^= sign;

# if 0
  if (mulaw == 0x00)
    mulaw = 0x02;
# endif

  return mulaw;
}

static
mad_fixed_t mulaw2linear(unsigned char mulaw)
{
  int sign, segment, mantissa, value;

  enum {
    bias = (0x10 << 1) + 1
  };

  mulaw = ~mulaw;

  sign = (mulaw >> 7) & 0x01;
  segment = (mulaw >> 4) & 0x07;
  mantissa = (mulaw >> 0) & 0x0f;

  value = ((0x21 | (mantissa << 1)) << segment) - bias;
  if (sign)
    value = -value;

  return (mad_fixed_t) value << (MAD_F_FRACBITS - 13);
}

/*
 * NAME:	audio_mulaw_dither()
 * DESCRIPTION:	convert a linear PCM value to dithered 8-bit ISDN mu-law
 */
unsigned char audio_mulaw_dither(mad_fixed_t sample, mad_fixed_t *error)
{
  int sign, mulaw;
  mad_fixed_t biased;

  enum {
    bias = (mad_fixed_t) ((0x10 << 1) + 1) << (MAD_F_FRACBITS - 13)
  };

  /* dither */
  sample += *error;

  if (sample < 0) {
    biased = bias - sample;
    sign   = 0x7f;
  }
  else {
    biased = bias + sample;
    sign   = 0xff;
  }

  if (biased >= MAD_F_ONE)
    mulaw = 0x7f;
  else {
    unsigned int segment;
    unsigned long mask;

    segment = 7;
    for (mask = 1L << (MAD_F_FRACBITS - 1); !(biased & mask); mask >>= 1)
      --segment;

    mulaw = ((segment << 4) |
	     ((biased >> (MAD_F_FRACBITS - 1 - (7 - segment) - 4)) & 0x0f));
  }

  mulaw ^= sign;

# if 0
  if (mulaw == 0x00)
    mulaw = 0x02;
# endif

  /* error */
  *error = sample - mulaw2linear(mulaw);

  return mulaw;
}

/*
 * NAME:	audio_pcm_mulaw()
 * DESCRIPTION:	write a block of 8-bit mu-law encoded samples
 */
unsigned int audio_pcm_mulaw(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				 struct audio_dither_err *dither_err)
{
  unsigned int len;

  len = nsamples;

  if (right) {  /* stereo */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--) {
	data[0] = audio_mulaw_round(*left++);
	data[1] = audio_mulaw_round(*right++);

	data += 2;
      }
      break;

    case AUDIO_MODE_DITHER:
      while (len--) {
	data[0] = audio_mulaw_dither(*left++,  &dither_err->left);
	data[1] = audio_mulaw_dither(*right++, &dither_err->right);

	data += 2;
      }
      break;

    default:
      return 0;
    }

    return nsamples * 2;
  }
  else {  /* mono */
    switch (mode) {
    case AUDIO_MODE_ROUND:
      while (len--)
	*data++ = audio_mulaw_round(*left++);
      break;

    case AUDIO_MODE_DITHER:
      while (len--)
	*data++ = audio_mulaw_dither(*left++, &dither_err->left);
      break;

    default:
      return 0;
    }

    return nsamples;
  }
}

void
output_new(Audio_MPEG_Output self)
{
	if ((self->params = (void *)calloc(1, sizeof(struct audio_params))) == NULL) {
		perror("in libmpeg output_init()");
		exit(errno);
	}
	if ((self->stats = (void *)calloc(1, sizeof(struct audio_stats))) == NULL) {
		perror("in libmpeg output_init()");
		exit(errno);
	}
	if ((self->dither_err = (void *)calloc(1, sizeof(struct audio_dither_err))) == NULL) {
		perror("in libmpeg output_init()");
		exit(errno);
	}
	if ((self->resampled = (void *)calloc(1, sizeof(*self->resampled))) == NULL) {
		perror("in libmpeg output_init()");
		exit(errno);
	}
}

void
output_DESTROY(Audio_MPEG_Output self)
{
	free(self->params);
	free(self->stats);
	free(self->dither_err);
	resample_finish(&self->resample[0]);
	resample_finish(&self->resample[1]);
	free(self->resampled);
}


/*
 * int32be() - store a 32-bit big-endian integer
 */

static
void int32be(unsigned char *ptr, unsigned long num)
{
	ptr[0] = num >> 24;
	ptr[1] = num >> 16;
	ptr[2] = num >> 8;
	ptr[3] = num >> 0;
}

/*
 * int32le() - store a 32-bit little-endian integer
 */

static
void int32le(unsigned char *ptr, unsigned long num)
{
	ptr[0] = num >> 0;
	ptr[1] = num >> 8;
	ptr[2] = num >> 16;
	ptr[3] = num >> 24;;
}

/*
 * int16le() - store a 16-bit little-endian integer
 */

static
void int16le(unsigned char *ptr, unsigned long num)
{
	ptr[0] = num >> 0;
	ptr[1] = num >> 8;
}

/*
 * NAME:	audio_pcm_float()
 * DESCRIPTION:	write a block of native float PCM samples
 */
unsigned int audio_pcm_float(unsigned char *data, unsigned int nsamples,
			     mad_fixed_t const *left, mad_fixed_t const *right,
			     enum audio_mode mode, struct audio_stats *stats,
				 struct audio_dither_err *dither_err)
{
  float *data_f = (float *)data;
  mad_fixed_t long sample0, sample1;
  unsigned int len;

  len = nsamples;

  if (right) {  /* stereo */
      while (len--) {
	sample0 = *left++;
	if (mad_f_abs(sample0) > stats->peak_sample)
		stats->peak_sample = mad_f_abs(sample0);
	sample1 = *right++;
	if (mad_f_abs(sample1) > stats->peak_sample)
		stats->peak_sample = mad_f_abs(sample1);
	*data_f++ = mad_f_todouble(sample0);
	*data_f++ = mad_f_todouble(sample1);
      }
    return nsamples * 2 * sizeof(float);
  }
  else {  /* mono */
      while (len--) {
	sample0 = *left++;
	if (mad_f_abs(sample0) > stats->peak_sample)
		stats->peak_sample = mad_f_abs(sample0);
	*data_f++ = mad_f_todouble(sample0);
    }

    return nsamples * sizeof(float);
  }
}

void audio_pcm_mono(mad_fixed_t *mono, unsigned int len,
	mad_fixed_t const *left, mad_fixed_t const *right)
{
	while (len--) {
		*mono++ = (*left++ + *right++) / 2;
	}
}

void
audio_snd_header(struct audio_params *params, unsigned int datasize,
	unsigned char *header, unsigned int header_len)
{
	int32be(header + 0, 0x2e736e64L);			/* magic for ".snd" */
	int32be(header + 4, header_len);			/* hdr_size */
	int32be(header + 8, datasize);				/* data_size (default is -1) */
	int32be(header + 12, 1);					/* encoding 8-bit ISDN mu-law */
	int32be(header + 16, params->samplerate);	/* sample_rate */
	int32be(header + 20, params->channels);		/* channels */
}

void
audio_wave_header(struct audio_params *params, unsigned int datasize,
	unsigned char *header, unsigned int header_len)
{
	unsigned int block_al = params->channels * (16 / 8);
	unsigned int bytes_ps = params->samplerate * block_al;

	/* RIFF header */
	memcpy(header, "RIFF", 4);					/* RIFF id */
	int32le(header + 4, datasize + 36);			/* RIFF len */
	memcpy(header + 8, "WAVE", 4);				/* M$ WAVE format */
	memcpy(header + 12, "fmt ", 4);				/* who knows */
	int32le(header + 16, 16);					/* ibid */
	int16le(header + 20, 0x0001);				/* WAVE PCM */
	int16le(header + 22, params->channels);		/* channels */
	int32le(header + 24, params->samplerate);	/* samplerate */
	int32le(header + 28, bytes_ps);				/* avg bytes/sec */
	int16le(header + 32, block_al);				/* block alignment */
	int16le(header + 34, 16);					/* bits/sample */

	/* data chunk header */
	memcpy(header + 36, "data", 4);				/* data chunk header */
	int32le(header + 40, datasize);
}
