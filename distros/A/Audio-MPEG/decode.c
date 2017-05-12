/*
 * $Id: decode.c,v 1.2 2001/06/18 03:49:33 ptimof Exp $
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

#include <stdlib.h>
#include <stdio.h>
#include <string.h>
#include <errno.h>
#include "decode.h"

char const *
decode_error_str(enum mad_error error)
{
	static char		str[100];
	switch (error) {
	case MAD_ERROR_BUFLEN:		return "no data in buffer";
	case MAD_ERROR_BUFPTR:      return "input buffer not initialized";
	case MAD_ERROR_NOMEM:      return "not enough memory";
	case MAD_ERROR_LOSTSYNC:   return "lost synchronization";
	case MAD_ERROR_BADLAYER:   return "reserved header layer value";
	case MAD_ERROR_BADBITRATE:     return "forbidden bitrate value";
	case MAD_ERROR_BADSAMPLERATE:  return "reserved sample frequency value";
	case MAD_ERROR_BADEMPHASIS:    return "reserved emphasis value";
	case MAD_ERROR_BADCRC:     return "CRC check failed";
	case MAD_ERROR_BADBITALLOC:    return "forbidden bit allocation value";
	case MAD_ERROR_BADSCALEFACTOR: return "bad scalefactor index";
	case MAD_ERROR_BADFRAMELEN:    return "bad frame length";
	case MAD_ERROR_BADBIGVALUES:   return "bad big_values count";
	case MAD_ERROR_BADBLOCKTYPE:   return "reserved block_type";
	case MAD_ERROR_BADSCFSI:   return "bad scalefactor selection info";
	case MAD_ERROR_BADDATAPTR:     return "bad main_data_begin pointer";
	case MAD_ERROR_BADPART3LEN:    return "bad audio data length";
	case MAD_ERROR_BADHUFFTABLE:   return "bad Huffman table select";
	case MAD_ERROR_BADHUFFDATA:    return "Huffman data overrun";
	case MAD_ERROR_BADSTEREO:  return "incompatible block_type for JS";
	case 0x0666: return "unsupported id3v2 frame";
	}

	sprintf(str, "error 0x%04x", error);
	return str;
}

void
decode_new(Audio_MPEG_Decode self)
{
	if ((self->stream = calloc(1, sizeof(struct mad_stream))) == NULL) {
		perror("in libmpeg decode_init()");
		exit(errno);
	}
	mad_stream_init(self->stream);
	if ((self->frame = calloc(1, sizeof(struct mad_frame))) == NULL) {
		perror("in libmpeg decode_init()");
		exit(errno);
	}
	mad_frame_init(self->frame);
	if ((self->synth = calloc(1, sizeof(struct mad_synth))) == NULL) {
		perror("in libmpeg decode_init()");
		exit(errno);
	}
	mad_synth_init(self->synth);
}

void
decode_DESTROY(Audio_MPEG_Decode self)
{
	if (self->data_in != NULL) free(self->data_in);
	mad_synth_finish(self->synth);
	free(self->synth);
	mad_frame_finish(self->frame);
	free(self->frame);
	mad_stream_finish(self->stream);
	free(self->stream);
}

/*
 * decode_buffer()	- add data to decode buffer
 * Input:
 *	self	decode structure
 *	buf		input buffer to add
 *	len		buffer length
 * Output:
 *	+ve		total data buffered
 */

int
decode_buffer(Audio_MPEG_Decode self, unsigned char *buf, size_t len)
{
	struct mad_stream *stream = self->stream;

	/* if no data to buffer, return */
	if (len == 0) {
		return 0;
	}

	/* if there is leftover from last frame decode, shift it down */
	if (stream->next_frame && stream->next_frame != self->data_in) {
		memmove(self->data_in, stream->next_frame,
			self->data_in_len = &self->data_in[self->data_in_len] -
			stream->next_frame);
		stream->next_frame = self->data_in;
	}

	/* reallocate buffer to allow room for new data (note: realloc also
	   does the initial malloc call as well if data_in is NULL) */
	if ((self->data_in = realloc(self->data_in, self->data_in_len + len)) ==
		NULL) {
		perror("realloc() in libmpeg decode_buffer()");
		exit errno;
	}

	/* add new data */
	memcpy(self->data_in + self->data_in_len, buf, len);
	self->data_in_len += len;
	mad_stream_buffer(self->stream, self->data_in, self->data_in_len);

	return self->data_in_len;
}
