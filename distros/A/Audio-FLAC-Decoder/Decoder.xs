/* $Id: Decoder.xs,v 1.2 2004/07/18 03:40:10 daniel Exp $ */

/* This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA  02111-1307, USA.
 *
 * Chunks of this code have been borrowed and influenced 
 * by flac/decode.c and the flac XMMS plugin.
 *
 */

#ifdef __cplusplus
"C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <stdio.h>
#include <string.h>
#include <sys/types.h>
#include <errno.h>
#include <stdlib.h>

#include <FLAC/all.h>
#include "include/common.h"
#include "include/dither.h"
#include "include/replaygain_synthesis.h"

#ifdef _MSC_VER
# define alloca            _alloca
#endif

/* strlen the length automatically */
#define my_hv_store(a,b,c)   hv_store(a,b,strlen(b),c,0)
#define my_hv_fetch(a,b)     hv_fetch(a,b,strlen(b),0)

/* Create some generic (and shorter) names for these types. */
typedef FLAC__StreamDecoder decoder_t;
typedef FLAC__StreamDecoderReadStatus read_status_t;

#define FLACdecoder_new()                       FLAC__stream_decoder_new()
#define FLACdecoder_init(a,b,c,d,e,f,g,h,i,j)   FLAC__stream_decoder_init_stream(a,b,c,d,e,f,g,h,i,j)
#define FLACdecoder_process_metadata(x)         FLAC__stream_decoder_process_until_end_of_metadata(x)
#define FLACdecoder_process_single(x)           FLAC__stream_decoder_process_single(x)
#define FLACdecoder_finish(x)                   FLAC__stream_decoder_finish(x)
#define FLACdecoder_delete(x)                   FLAC__stream_decoder_delete(x)
#define FLACdecoder_set_read_callback(x, y)     FLAC__stream_decoder_set_read_callback(x, y)
#define FLACdecoder_set_write_callback(x, y)    FLAC__stream_decoder_set_write_callback(x, y)
#define FLACdecoder_set_metadata_callback(x, y) FLAC__stream_decoder_set_metadata_callback(x, y)
#define FLACdecoder_set_error_callback(x, y)    FLAC__stream_decoder_set_error_callback(x, y)
#define FLACdecoder_set_client_data(x, y)       FLAC__stream_decoder_set_client_data(x, y)
#define FLACdecoder_set_seek_callback(x, y)     FLAC__stream_decoder_set_seek_callback(x, y)
#define FLACdecoder_set_tell_callback(x, y)     FLAC__stream_decoder_set_tell_callback(x, y)
#define FLACdecoder_set_length_callback(x, y)   FLAC__stream_decoder_set_length_callback(x, y)
#define FLACdecoder_set_eof_callback(x, y)      FLAC__stream_decoder_set_eof_callback(x, y)
#define FLACdecoder_seek_absolute(x, y)         FLAC__stream_decoder_seek_absolute(x, y)

#define FLACdecoder_get_state(x)                FLAC__stream_decoder_get_state(x)
#define FLACdecoder_get_channels(x)             FLAC__stream_decoder_get_channels(x)
#define FLACdecoder_get_blocksize(x)		FLAC__stream_decoder_get_blocksize(x)
#define FLACdecoder_get_sample_rate(x)		FLAC__stream_decoder_get_sample_rate(x)
#define FLACdecoder_get_bits_per_sample(x)	FLAC__stream_decoder_get_bits_per_sample(x)
#define FLACdecoder_get_decode_position(x, y)   FLAC__stream_decoder_get_decode_position(x, y)

#define SAMPLES_PER_WRITE 512

typedef struct {
	/* i.e. specification string started with + or - */
	FLAC__bool is_relative;
	FLAC__bool value_is_samples;
	union {
		double seconds;
		FLAC__int64 samples;
	} value;
} SkipUntilSpecification;

/* Allow multiple instances of the decoder object. Stuff each filehandle into (void*)stream */
typedef struct {
	int abort_flag;
	int bytes_streamed;
	int is_streaming;
	FLAC__uint64 stream_length;
	void *buffer;
	PerlIO *stream;
	decoder_t *decoder;
	FLAC__bool has_replaygain;

	/* (24/8) for max bytes per sample */
	FLAC__byte sample_buffer[SAMPLES_PER_WRITE * FLAC__MAX_SUPPORTED_CHANNELS * (24/8)];
	FLAC__int32 reservoir[FLAC__MAX_BLOCK_SIZE * 2 * FLAC__MAX_SUPPORTED_CHANNELS];
	FLAC__uint64 decode_position_last;
	FLAC__uint64 decode_position_frame_last;
	FLAC__uint64 decode_position_frame;
	unsigned buffer_size;
	FLAC__int64 total_samples;
        unsigned bps;
        unsigned channels;
        FLAC__int64 sample_rate;
        FLAC__int64 length_in_msec;
	unsigned wide_samples_in_reservoir;
	SkipUntilSpecification skip_specification;
	SkipUntilSpecification until_specification;

} flac_datasource;

/* start all the callbacks here. */
static void meta_callback(
	const decoder_t *decoder,
	const FLAC__StreamMetadata *metadata, void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;

	if (metadata->type == FLAC__METADATA_TYPE_STREAMINFO) {

		FLAC__uint64 skip, until;

		/* flac__utils_canonicalize_skip_until_specification(decoder_session->skip_specification, decoder_session->sample_rate);
		FLAC__ASSERT(datasource->skip_specification->value.samples >= 0); */
		skip = (FLAC__uint64)datasource->skip_specification.value.samples;

                /* remember, metadata->data.stream_info.total_samples can be 0, meaning 'unknown' */
                if (metadata->data.stream_info.total_samples > 0 && skip >= metadata->data.stream_info.total_samples) {
                        warn("ERROR trying to skip more samples than in stream\n");
                        datasource->abort_flag = true;
                        return;

                } else if (metadata->data.stream_info.total_samples == 0 && skip > 0) {
                        warn("ERROR, can't skip when FLAC metadata has total sample count of 0\n");
                        datasource->abort_flag = true;
                        return;
                }

		datasource->bps		    = metadata->data.stream_info.bits_per_sample;
		datasource->channels        = metadata->data.stream_info.channels;
		datasource->sample_rate     = metadata->data.stream_info.sample_rate;
		datasource->total_samples   = metadata->data.stream_info.total_samples - skip;

		datasource->length_in_msec  = datasource->total_samples * 10 / (datasource->sample_rate / 100);

		/* if (!canonicalize_until_specification(
			datasource->until_specification, datasource->inbasefilename,
			datasource>n->sample_rate, skip, metadata->data.stream_info.total_samples)) {
                        datasource->abort_flag = true;
                        return;
                } */

                FLAC__ASSERT(datasource->until_specification.value.samples >= 0);
                until = (FLAC__uint64)datasource->until_specification.value.samples;

                if (until > 0) {
                        datasource->total_samples -= (metadata->data.stream_info.total_samples - until);
		}

                if (datasource->bps != 8 && datasource->bps != 16 && datasource->bps != 24) {
                        warn("ERROR: bits per sample is not 8/16/24\n");
                        datasource->abort_flag = true;
                        return;
                }
	}
}

static void error_callback(
	const decoder_t *decoder,
	FLAC__StreamDecoderErrorStatus status, void *client_data) {

	/* flac_datasource *datasource = (flac_datasource *)client_data; */

	warn("FLAC decoder error_callback: %s\n", status);
}

static FLAC__StreamDecoderSeekStatus seek_callback(
	const decoder_t *decoder,
	FLAC__uint64 absolute_byte_offset, void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;

	/* can't seek on a socket */
	if (datasource->is_streaming) {
		return FLAC__STREAM_DECODER_SEEK_STATUS_ERROR;
	}

	if (PerlIO_seek(datasource->stream, absolute_byte_offset, SEEK_SET) >= 0) {
		return FLAC__STREAM_DECODER_SEEK_STATUS_OK;
	}

	return FLAC__STREAM_DECODER_SEEK_STATUS_ERROR;
}

static FLAC__StreamDecoderTellStatus tell_callback(
	const decoder_t *decoder,
	FLAC__uint64 *absolute_byte_offset, void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;
	FLAC__uint64 pos = -1;
	
	/* can't tell on a socket */
	if (datasource->is_streaming) {
		return FLAC__STREAM_DECODER_TELL_STATUS_ERROR;
	}

	pos = PerlIO_tell(datasource->stream);

	if (pos < 0) {
		return FLAC__STREAM_DECODER_TELL_STATUS_ERROR;
	}

	*absolute_byte_offset = pos;
	return FLAC__STREAM_DECODER_TELL_STATUS_OK;
}

static FLAC__StreamDecoderLengthStatus length_callback(
	const decoder_t *decoder,
	FLAC__uint64 *stream_length, void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;

	/* can't find the total length of a socket */
	if (datasource->is_streaming) {
		return FLAC__STREAM_DECODER_LENGTH_STATUS_ERROR;
	}

	*stream_length = datasource->stream_length;
	return FLAC__STREAM_DECODER_LENGTH_STATUS_OK;
}

static FLAC__bool eof_callback(
	const decoder_t *decoder, void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;
	FLAC__uint64 pos = 0;

	if (datasource->is_streaming) {
		return false;
	}

	pos = PerlIO_tell(datasource->stream);

	if (pos >= 0 && pos >= datasource->stream_length) {
		/* printf("stream length: %d pos: %d\n", datasource->stream_length, pos); */
		return true;
	}

	return false;
}

static read_status_t read_callback(
	const decoder_t *decoder,
	FLAC__byte buffer[], size_t *bytes, void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;

	*bytes = PerlIO_read(datasource->stream, buffer, *bytes);

	datasource->buffer_size = *bytes;

	if (*bytes == 0)
		return FLAC__STREAM_DECODER_READ_STATUS_END_OF_STREAM;
	if (*bytes < 0)
		return FLAC__STREAM_DECODER_READ_STATUS_ABORT;

	return FLAC__STREAM_DECODER_READ_STATUS_CONTINUE;
}

static FLAC__StreamDecoderWriteStatus write_callback(
	const decoder_t *decoder,
	const FLAC__Frame *frame, const FLAC__int32 * const buffer[],
	void *client_data) {

	flac_datasource *datasource = (flac_datasource *)client_data;

	const unsigned channels     = frame->header.channels;
	const unsigned wide_samples = frame->header.blocksize;
	unsigned wide_sample, sample, channel;

	if (datasource->abort_flag) {
                return FLAC__STREAM_DECODER_WRITE_STATUS_ABORT;
	}

	for (sample = datasource->wide_samples_in_reservoir * channels, 
		wide_sample = 0; wide_sample < wide_samples; wide_sample++) {

		for (channel = 0; channel < channels; channel++, sample++) {
			datasource->reservoir[sample] = buffer[channel][wide_sample];
		}
	}

	datasource->wide_samples_in_reservoir += wide_samples;

	return FLAC__STREAM_DECODER_WRITE_STATUS_CONTINUE;
}

MODULE = Audio::FLAC::Decoder PACKAGE = Audio::FLAC::Decoder

PROTOTYPES: DISABLE

SV*
open(class, path)
	char *class;
	SV   *path;

	CODE:

	/* for setting the stream length */
	FLAC__uint64 pos;

	/* Create our new self and a ref to it - all of these are cleaned up in DESTROY */
	HV *self = newHV();
	SV *obj_ref = newRV_noinc((SV*) self);

	/* our stash for streams */
	flac_datasource *datasource = safemalloc(sizeof(flac_datasource));

	/* holder for the decoder itself */
	datasource->decoder = FLACdecoder_new();

	/* check and see if a pathname was passed in, otherwise it might be a
	 * IO::Socket subclass, or even a *FH Glob */
	if (SvOK(path) && (SvTYPE(SvRV(path)) != SVt_PVGV)) {

		if ((datasource->stream = PerlIO_open((char*)SvPV_nolen(path), "r")) == NULL) {

			FLACdecoder_finish(datasource->decoder);
			FLACdecoder_delete(datasource->decoder);

			safefree(datasource);

			warn("failed on open: [%d] - [%s]\n", errno, strerror(errno));
			XSRETURN_UNDEF;
		}

		datasource->is_streaming = 0;

	} else if (SvOK(path)) {

		/* Did we get a Glob, or a IO::Socket subclass?
		 *
		 * XXX This should really be a class method so the caller
		 * can tell us if it's streaming or not. But how to do this on
		 * a per object basis without changing open()s arugments. That
		 * may be the easiest/only way. XXX
		 *
		 */

		if (sv_isobject(path) && sv_derived_from(path, "IO::Socket")) {
			datasource->is_streaming = 1;
		} else {
			datasource->is_streaming = 0;
		}

		/* dereference and get the SV* that contains the Magic & FH,
		 * then pull the fd from the PerlIO object */
		datasource->stream = IoIFP(GvIOp(SvRV(path)));

	} else {

		XSRETURN_UNDEF;
	}

	if (!datasource->is_streaming) {

		pos = PerlIO_tell(datasource->stream);

		if (PerlIO_seek(datasource->stream, 0, SEEK_END) != -1) {
		
			datasource->stream_length = PerlIO_tell(datasource->stream);

			if (PerlIO_seek(datasource->stream, pos, SEEK_SET) == -1) {

				FLACdecoder_finish(datasource->decoder);
				FLACdecoder_delete(datasource->decoder);

				safefree(datasource);

				warn("failed on seek to beginning: [%d] - [%s]\n", errno, strerror(errno));
				XSRETURN_UNDEF;
			}
		}
	}

	if (FLACdecoder_init(datasource->decoder,
	                     read_callback,
	                     seek_callback,
	                     tell_callback,
	                     length_callback,
	                     eof_callback,
	                     write_callback,
	                     meta_callback,
	                     error_callback,
	                     datasource) != FLAC__STREAM_DECODER_INIT_STATUS_OK) {

		warn("Failed on initializing the decoder: [%d]\n", FLACdecoder_get_state(datasource->decoder));

		FLACdecoder_finish(datasource->decoder);
		FLACdecoder_delete(datasource->decoder);

		safefree(datasource);

		XSRETURN_UNDEF;
        }
	
	/* skip ahead to the pcm data */
	FLACdecoder_process_metadata(datasource->decoder);

	datasource->bytes_streamed = 0;
	datasource->decode_position_last = 0;
	datasource->decode_position_frame = 0;
	datasource->decode_position_frame_last = 0;

	/* initalize bitrate, channels, etc */
	/*__read_info(self, vf); */

	/* Values stored at base level */
	my_hv_store(self, "PATH", newSVsv(path));
	my_hv_store(self, "DATASOURCE", newSViv((IV) datasource));
	/*my_hv_store(self, "READCOMMENTS", newSViv(1)); */

	/* Bless the hashref to create a class object */
	sv_bless(obj_ref, gv_stashpv(class, FALSE));

	RETVAL = obj_ref;

	OUTPUT:
	RETVAL

long
sysread(obj, buffer, nbytes = 1024)
	SV* obj;
	SV* buffer;
	int nbytes;

	CODE:
	{

	int total_bytes_read = 0;
	unsigned blocksize   = 1;
	char *readBuffer     = alloca(nbytes);

	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	if (!datasource) XSRETURN_UNDEF;
	if (!datasource->decoder) XSRETURN_UNDEF;

	while (datasource->wide_samples_in_reservoir < SAMPLES_PER_WRITE) {

		unsigned s = datasource->wide_samples_in_reservoir;

		if (FLACdecoder_get_state(datasource->decoder) == FLAC__STREAM_DECODER_END_OF_STREAM ) {
			break;

		} else if (!FLACdecoder_process_single(datasource->decoder)) {

			warn("Audio::FLAC::Decoder - read error while processing frame.\n");
			break;
		}

		blocksize = datasource->wide_samples_in_reservoir - s;
		datasource->decode_position_frame_last = datasource->decode_position_frame;

		if (!FLACdecoder_get_decode_position(datasource->decoder, &datasource->decode_position_frame)) {
			datasource->decode_position_frame = 0;
		}
	}

	while (nbytes > 0) {

		if (datasource->wide_samples_in_reservoir <= 0) {

			break;

		} else {

			const unsigned channels = FLACdecoder_get_channels(datasource->decoder);
			const unsigned bps = FLACdecoder_get_bits_per_sample(datasource->decoder);
			const unsigned n = min(datasource->wide_samples_in_reservoir, SAMPLES_PER_WRITE);
			const unsigned delta = n * channels;
			unsigned i;

			int bytes = (int)pack_pcm_signed_little_endian(
				datasource->sample_buffer, datasource->reservoir, n, channels, bps, bps
			);

			for (i = delta; i < datasource->wide_samples_in_reservoir * channels; i++) {
				datasource->reservoir[i-delta] = datasource->reservoir[i];
			}

			datasource->wide_samples_in_reservoir -= n;

			readBuffer        = datasource->sample_buffer;

			total_bytes_read += bytes;
			readBuffer       += bytes;
			nbytes           -= bytes;

			datasource->decode_position_last = 
				datasource->decode_position_frame - 
				datasource->wide_samples_in_reservoir *
				(datasource->decode_position_frame - datasource->decode_position_frame_last) /
				blocksize;
		}
	}

	/* copy the buffer into our passed SV* */
	sv_setpvn(buffer, readBuffer-total_bytes_read, total_bytes_read);

	if (total_bytes_read < 0) XSRETURN_UNDEF;

	RETVAL = total_bytes_read;

	}

	OUTPUT:
	RETVAL

void
DESTROY (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	FLACdecoder_finish(datasource->decoder);
	FLACdecoder_delete(datasource->decoder);

	safefree(datasource);

IV
channels (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	RETVAL = FLACdecoder_get_channels(datasource->decoder);

	OUTPUT:
	RETVAL

IV
bits_per_sample (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	RETVAL = FLACdecoder_get_bits_per_sample(datasource->decoder);

	OUTPUT:
	RETVAL

IV
sample_rate (obj)
	SV* obj;

	CODE:
	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	RETVAL = FLACdecoder_get_sample_rate(datasource->decoder);

	OUTPUT:
	RETVAL

IV
raw_seek (obj, pos, whence)
	SV* obj;
	long pos;
	int whence;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	/* can't seek on a socket. */
	if (datasource->is_streaming) {
		XSRETURN_UNDEF;
	}

	if (!FLAC__stream_decoder_reset(datasource->decoder)) {
		XSRETURN_UNDEF;
	}

	RETVAL = PerlIO_seek(datasource->stream, pos, whence);

	}

	OUTPUT:
	RETVAL

FLAC__uint64
raw_tell (obj)
	SV* obj;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	FLAC__uint64 decode_position = 0;

	/* this is effectively doing a ftell() */
	if (!FLACdecoder_get_decode_position(datasource->decoder, &decode_position)) {
		decode_position = -1;
	}

	RETVAL = decode_position;

	}

	OUTPUT:
	RETVAL

IV
sample_seek (obj, sample)
	SV* obj;
	IV  sample;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	RETVAL = FLACdecoder_seek_absolute(datasource->decoder, sample);

	}

	OUTPUT:
	RETVAL

FLAC__uint64
time_seek (obj, seconds)
	SV* obj;
	IV  seconds;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	const double distance  = (double)seconds * 1000.0 / (double)datasource->length_in_msec;
	unsigned target_sample = (unsigned)(distance * (double)datasource->total_samples);

	if (FLACdecoder_seek_absolute(datasource->decoder, (FLAC__uint64)target_sample)) {

		if (!FLACdecoder_get_decode_position(datasource->decoder, &datasource->decode_position_frame)) {
			datasource->decode_position_frame = 0;
		}

		datasource->wide_samples_in_reservoir = 0;
	}

	RETVAL = datasource->decode_position_frame;

	}

	OUTPUT:
	RETVAL

FLAC__uint64
time_tell (obj)
	SV* obj;

	CODE:
	{

	HV *self = (HV *) SvRV(obj);
	flac_datasource *datasource = (flac_datasource *) SvIV(*(my_hv_fetch(self, "DATASOURCE")));

	FLAC__uint64 decode_position = 0;
	/* float time_position = 0; */

	if (!FLACdecoder_get_decode_position(datasource->decoder, &decode_position)) {

		decode_position = -1;

	} else {

		/* time_position = metadata->data.stream_info.total_samples * 10 / 
			(metadata->data.stream_info.sample_rate / 100);
		*/
	}

	RETVAL = decode_position;

	}

	OUTPUT:
	RETVAL
