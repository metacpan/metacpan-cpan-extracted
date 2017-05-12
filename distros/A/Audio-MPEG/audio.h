/*
 * $Id: audio.h,v 1.1.1.1 2001/06/17 01:37:51 ptimof Exp $
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

# ifndef AUDIO_H
# define AUDIO_H

#include <mad.h>
#include "resample.h"

/* __BIG_ENDIAN__ is defined by gcc */
#if defined(__BIG_ENDIAN__)
#define audio_pcm_s16  audio_pcm_s16be
#define audio_pcm_s24  audio_pcm_s24be
#define audio_pcm_s32  audio_pcm_s32be
#else
#define audio_pcm_s16  audio_pcm_s16le
#define audio_pcm_s24  audio_pcm_s24le
#define audio_pcm_s32  audio_pcm_s32le
#endif

# define MAX_NSAMPLES	(1152 * 3)	/* allow for resampled frame */

enum audio_mode {
  AUDIO_MODE_ROUND  = 0x0001,
  AUDIO_MODE_DITHER = 0x0002
};

enum audio_mpeg_output_type {
  AUDIO_MPEG_OUTPUT_TYPE_PCM8 =		0x0001,
  AUDIO_MPEG_OUTPUT_TYPE_PCM16 =	0x0002,
  AUDIO_MPEG_OUTPUT_TYPE_PCM24 =	0x0003,
  AUDIO_MPEG_OUTPUT_TYPE_PCM32 =	0x0004,
  AUDIO_MPEG_OUTPUT_TYPE_FLOAT =	0x0005,
  AUDIO_MPEG_OUTPUT_TYPE_SND =		0x0006,
  AUDIO_MPEG_OUTPUT_TYPE_WAVE =		0x0007
};

struct audio_stats {
  unsigned long clipped_samples;
  mad_fixed_t peak_clipping;
  mad_fixed_t peak_sample;
};

struct audio_dither_err {
  mad_fixed_t left;
  mad_fixed_t right;
};

struct audio_params {
	unsigned int samplerate;
	unsigned int channels;
	enum audio_mode mode;
	enum audio_mpeg_output_type type;
};

struct audio_mpeg_output {
	struct audio_params *params;
	struct audio_stats *stats;
	struct audio_dither_err *dither_err;
	struct resample_state resample[2];
	mad_fixed_t (*resampled)[2][MAX_NSAMPLES];
	unsigned int resample_init;
	unsigned int do_resample;
	unsigned int decode_delay_applied;
};

typedef struct audio_mpeg_output * Audio_MPEG_Output;

void output_new(Audio_MPEG_Output);
void output_DESTROY(Audio_MPEG_Output);

signed long audio_linear_round(unsigned int, mad_fixed_t,
			       struct audio_stats *);
signed long audio_linear_dither(unsigned int, mad_fixed_t, mad_fixed_t *,
				struct audio_stats *);

unsigned int audio_pcm_u8(unsigned char *, unsigned int,
			  mad_fixed_t const *, mad_fixed_t const *,
			  enum audio_mode, struct audio_stats *,
			 struct audio_dither_err *);
unsigned int audio_pcm_s16le(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);
unsigned int audio_pcm_s16be(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);
unsigned int audio_pcm_s24le(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);
unsigned int audio_pcm_s24be(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);
unsigned int audio_pcm_s32le(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);
unsigned int audio_pcm_s32be(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);

unsigned char audio_mulaw_round(mad_fixed_t);
unsigned char audio_mulaw_dither(mad_fixed_t, mad_fixed_t *);

unsigned int audio_pcm_mulaw(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);

unsigned int audio_pcm_float(unsigned char *, unsigned int,
			     mad_fixed_t const *, mad_fixed_t const *,
			     enum audio_mode, struct audio_stats *,
				 struct audio_dither_err *);

void audio_pcm_mono(mad_fixed_t *, unsigned int, mad_fixed_t const *,
	mad_fixed_t const *);

void audio_snd_header(struct audio_params *, unsigned int, unsigned char *,
	unsigned int);
void audio_wave_header(struct audio_params *, unsigned int, unsigned char *,
	unsigned int);

# endif
