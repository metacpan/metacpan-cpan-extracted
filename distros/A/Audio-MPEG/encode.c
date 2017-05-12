/*
 * $Id: encode.c,v 1.1.1.1 2001/06/17 01:37:51 ptimof Exp $
 *
 * Copyright (c) 2001 Peter Timofejew. All rights reserved.
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

#include "encode.h"

/*
 * lame_encode_buffer_interleaved_float() - encode interleaved buffer
 */

unsigned int
lame_encode_buffer_interleaved_float(lame_t *flags, float *pcm,
	unsigned int len, unsigned char *out, unsigned int outlen)

{
	unsigned int i;
	float left[MAX_NSAMPLES];
	float right[MAX_NSAMPLES];

	for (i = 0; i < len; i++) {
		left[i] = *pcm++ * 32768.0;		/* LAME assumes +/- 2e15 */
		if (flags->num_channels == 1)
			right[i] = left[i];
		else
			right[i] = *pcm++ * 32768.0;
	}

	return lame_encode_buffer_sample_t(flags, left, right, len, out, outlen);
}
