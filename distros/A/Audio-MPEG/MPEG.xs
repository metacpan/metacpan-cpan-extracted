/*
 *
 * $Id: MPEG.xs,v 1.3 2001/06/18 04:19:40 ptimof Exp $
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

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "decode.h"
#include "audio.h"
#include "encode.h"

#define         Min(A, B)       ((A) < (B) ? (A) : (B))
#define         Max(A, B)       ((A) > (B) ? (A) : (B))

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

MODULE = Audio::MPEG		PACKAGE = Audio::MPEG		

#
# Move along. Nothin' to see here folks.
#

PROTOTYPES: ENABLE

#
# Interface to MAD library
#

MODULE = Audio::MPEG		PACKAGE = Audio::MPEG::Decode

Audio_MPEG_Decode
new(CLASS)
		char *CLASS = NO_INIT
	CODE:
		Newz(0, (void *)RETVAL, sizeof(*RETVAL), char);
		decode_new(RETVAL);		// in decode.c
	OUTPUT:
		RETVAL

void
DESTROY(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		decode_DESTROY(THIS);	// in decode.c
		Safefree(THIS);

#
# MAD version strings
#

SV *
version(THIS)
		Audio_MPEG_Decode THIS
	PREINIT:
		HV *h;
		char *key;
	CODE:
		h = (HV *)sv_2mortal((SV *)newHV());

		key = "version";
		hv_store(h, key, strlen(key), newSVpv((char *)mad_version, 0), 0);
		key = "copyright";
		hv_store(h, key, strlen(key), newSVpv((char *)mad_copyright, 0), 0);
		key = "author";
		hv_store(h, key, strlen(key), newSVpv((char *)mad_author, 0), 0);
		key = "build";
		hv_store(h, key, strlen(key), newSVpv((char *)mad_build, 0), 0);

		RETVAL = newRV((SV *)h);
	OUTPUT:
		RETVAL

#
# Add chunk of MP3 data to decoding buffer.
#

int
buffer(THIS, data)
		Audio_MPEG_Decode THIS
		SV *data
	PREINIT:
		unsigned char *buf;
		size_t len;
	CODE:
		buf = SvPV(data, len);
		RETVAL = decode_buffer(THIS, buf, len);		// in decode.c
	OUTPUT:
		RETVAL

#
# Decode MP3 frame(s) that have been added to the buffer. Can also
# be used to simply verify the frame headers by passing TRUE as a flag
# (this is useful for quickly verifying the integrity of the stream)
#

void
decode_frame(THIS, header_only = 0)
		Audio_MPEG_Decode THIS
		int header_only
	PREINIT:
		struct mad_stream *stream;
		struct mad_frame *frame;
		struct mad_header *header;
		int err = 0;
		unsigned long tagsize;
	PPCODE:
		stream = THIS->stream;
		frame = THIS->frame;
		header = &frame->header;
decode_loop:
		if (mad_header_decode(header, stream) == -1) {
			switch (stream->error) {
			case MAD_ERROR_BUFLEN:
				XSRETURN_NO;
			break;
			case MAD_ERROR_LOSTSYNC:
				if (strncmp(stream->this_frame, "TAG", 3) == 0) {
					mad_stream_skip(stream, 128);
					goto decode_loop;
				} else if (strncmp(stream->this_frame, "ID3", 3) == 0) {
					stream->error = 0x0666;
					tagsize = (((stream->this_frame[6] & 0x7f) << 21)
						| ((stream->this_frame[7] & 0x7f) << 14)
						| ((stream->this_frame[8] & 0x7f) << 7)
						| ((stream->this_frame[9] & 0x7f))) ; //+ 10;
					if (tagsize > stream->bufend - stream->this_frame) {
						mad_stream_skip(stream, stream->bufend -
							stream->this_frame);
					} else {
						mad_stream_skip(stream, tagsize);
					}
					goto decode_loop;
				}
				/* fall through case */
			default:
				err++;
			break;
			}
		}
		if (! header_only) {
			if (mad_frame_decode(frame, stream) == -1) {
				switch (stream->error) {
				case MAD_ERROR_BUFLEN:
					XSRETURN_NO;
				break;
				case MAD_ERROR_LOSTSYNC:
					if (strncmp(stream->this_frame, "TAG", 3) == 0) {
						mad_stream_skip(stream, 128);
						goto decode_loop;
					} else if (strncmp(stream->this_frame, "ID3", 3) == 0) {
						stream->error = 0x0666;
						tagsize = (((stream->this_frame[6] & 0x7f) << 21)
							| ((stream->this_frame[7] & 0x7f) << 14)
							| ((stream->this_frame[8] & 0x7f) << 7)
							| ((stream->this_frame[9] & 0x7f))) ; //+ 10;
						if (tagsize > stream->bufend - stream->this_frame) {
							mad_stream_skip(stream, stream->bufend -
								stream->this_frame);
						} else {
							mad_stream_skip(stream, tagsize);
						}
						goto decode_loop;
					}
					/* fall through case */
				default:
					err++;
				break;
				}
			}
		}
		if (MAD_RECOVERABLE(stream->error))
			err = 0;
		if (!err) {
			THIS->current_frame++;
			THIS->accum_bitrate += header->bitrate / 1000;
			mad_timer_add(&THIS->total_duration, header->duration);
		}
		XSRETURN_YES;

#
# Create PCM stream (in mad_fixed_t type) from decoded frame
#

void
synth_frame(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		mad_synth_frame(THIS->synth, THIS->frame);

#
# Return last error code
#

unsigned int
err(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->stream->error;
	OUTPUT:
		RETVAL

int
err_ok(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		switch (THIS->stream->error) {
		case 0:
		case MAD_ERROR_BUFLEN:
		case MAD_ERROR_LOSTSYNC:
		case MAD_ERROR_BADCRC:
		case MAD_ERROR_BADDATAPTR:
			RETVAL = 1;
		break;
		default:
			RETVAL = 0;
		break;
		}
	OUTPUT:
		RETVAL

#
# Return English error string of last error
#

char *
errstr(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = (char *)decode_error_str(THIS->stream->error);
	OUTPUT:
		RETVAL

unsigned int
current_frame(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->current_frame;
	OUTPUT:
		RETVAL

unsigned int
total_frames(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->current_frame;
	OUTPUT:
		RETVAL

double
frame_duration(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = (double)mad_timer_count(THIS->frame->header.duration, 
			MAD_UNITS_MILLISECONDS) / 1000.0;
	OUTPUT:
		RETVAL

double
total_duration(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = (double)mad_timer_count(THIS->total_duration, 
			MAD_UNITS_MILLISECONDS) / 1000.0;
	OUTPUT:
		RETVAL

unsigned int
bit_rate(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->frame->header.bitrate / 1000;
	OUTPUT:
		RETVAL

double
average_bit_rate(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = (double)THIS->accum_bitrate / (double)THIS->current_frame;
	OUTPUT:
		RETVAL

unsigned int
sample_rate(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->frame->header.samplerate;
	OUTPUT:
		RETVAL

unsigned int
layer(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->frame->header.layer;
	OUTPUT:
		RETVAL

unsigned short
channels(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = THIS->synth->pcm.channels;
	OUTPUT:
		RETVAL

struct mad_pcm *
pcm(THIS)
		Audio_MPEG_Decode THIS
	CODE:
		RETVAL = &THIS->synth->pcm;
	OUTPUT:
		RETVAL

#
# mad_fixed_t PCM->denormalized output
#

MODULE = Audio::MPEG		PACKAGE = Audio::MPEG::Output

Audio_MPEG_Output
new(CLASS, params_data_ref = &PL_sv_undef)
		char *CLASS = NO_INIT
		SV *params_data_ref
	PREINIT:
		HV *params_data;
		SV **hval;
		char *key;
	CODE:
		Newz(0, (void *)RETVAL, sizeof(*RETVAL), char);
		output_new(RETVAL);

		/* set up defaults */
		RETVAL->params->samplerate = 44100;
		RETVAL->params->channels = 2;
		RETVAL->params->mode = AUDIO_MODE_DITHER;
		RETVAL->params->type = AUDIO_MPEG_OUTPUT_TYPE_FLOAT;

		/* process input arguments */
		if (items > 1) {
			params_data = (HV *)SvRV(params_data_ref);
			key = "out_sample_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				RETVAL->params->samplerate = SvUV(*hval);
			key = "out_channels";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				RETVAL->params->channels = SvUV(*hval);
			key = "mode";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				RETVAL->params->mode = SvUV(*hval);
			key = "type";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				RETVAL->params->type = SvUV(*hval);
			key = "apply_delay";
			RETVAL->decode_delay_applied = 1;
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				RETVAL->decode_delay_applied = SvUV(*hval) ? 0 : 1;
		}
	OUTPUT:
		RETVAL

void
DESTROY(THIS)
		Audio_MPEG_Output THIS
	CODE:
		output_DESTROY(THIS);
		Safefree(THIS);

#
# Some audio formats require a header. This will generate one.
#

void
header(THIS, datasize = 0)
		Audio_MPEG_Output THIS
		unsigned int datasize
	PREINIT:
		struct audio_params *params;
	PPCODE:
		params = THIS->params;
		switch (params->type) {
		case AUDIO_MPEG_OUTPUT_TYPE_SND:
			{
				unsigned char header[24];
				if (!datasize)
					datasize = ~0;	/* (unsigned) -1 */
				audio_snd_header(params, datasize, header, sizeof(header));
				XPUSHs(sv_2mortal(newSVpvn(header, sizeof(header))));
			}
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_WAVE:
			{
				unsigned char header[44];
				audio_wave_header(params, datasize, header, sizeof(header));
				XPUSHs(sv_2mortal(newSVpvn(header, sizeof(header))));
			}
		break;
		default:
				XPUSHs(sv_2mortal(newSVpv("", 0)));
		break;
		}

#
# Transform mad_fixed_t PCM stream to a more usable stream.
#

void
encode(THIS, pcm)
		Audio_MPEG_Output THIS
		struct mad_pcm *pcm
	PREINIT:
		mad_fixed_t const *left = NULL;
		mad_fixed_t const *right = NULL;
		unsigned int pcm_len;
		unsigned int delay = 0;
		struct audio_params *params;
		struct audio_stats *stats;
		struct audio_dither_err *dither_err;
		unsigned int len;
		unsigned char data[MAX_NSAMPLES * sizeof(double) * 2];
		mad_fixed_t mono[MAX_NSAMPLES];
	PPCODE:
		params = THIS->params;
		stats = THIS->stats;
		dither_err = THIS->dither_err;
		if (!pcm->length) {
			warn("pcm sample length cannot be 0");
			XSRETURN_UNDEF;
		}

		if (! THIS->decode_delay_applied) {
			THIS->decode_delay_applied = 1;
			delay = pcm->length / 2;
		}

		if (!pcm->channels || pcm->channels > 2) {
			warn("number of pcm channels must be either 1 or 2");
			XSRETURN_UNDEF;
		}

		if (!pcm->samplerate) {
			warn("pcm sample rate cannot be 0");
			XSRETURN_UNDEF;
		}

		if (!THIS->resample_init) {
			/* if difference of 6% or more, resample */
			if (abs(params->samplerate - pcm->samplerate) >
				6L * params->samplerate / 100) {
				if (resample_init(&THIS->resample[0],
					pcm->samplerate, params->samplerate) == -1 ||
					resample_init(&THIS->resample[1],
					pcm->samplerate, params->samplerate) == -1) {
					warn("cannot resample");
				} else {
					THIS->do_resample = 1;
				}
			}
			THIS->resample_init = 1;
		}

		left = pcm->samples[0] + delay;
		if (pcm->channels == 2)
			right = pcm->samples[1] + delay;
		
		if ((pcm_len = pcm->length - delay) < 1) {
			warn("pcm sample length cannot be less than 1");
			XSRETURN_UNDEF;
		}

		if (THIS->do_resample) {
			unsigned int old_pcm_len = pcm_len;

			pcm_len = resample_block(&THIS->resample[0], old_pcm_len, left, 
				(*THIS->resampled)[0]);
			left = (*THIS->resampled)[0];

			if (pcm->channels == 2) {
				resample_block(&THIS->resample[1], old_pcm_len, right, 
					(*THIS->resampled)[1]);
				right = (*THIS->resampled)[1];
			}
		}

		/* if mono in, force stereo if config param channels == 2 */
		if (pcm->channels == 1) {
			if (params->channels == 2) {
				right = left;
			}
		}

		/* if stereo in, and mono out is selected, make left = (left+right)/2 */
		if (pcm->channels == 2 && params->channels == 1) {
			audio_pcm_mono(mono, pcm_len, left, right);
			left = mono;
			right = NULL;
		}

		switch (params->type) {
		case AUDIO_MPEG_OUTPUT_TYPE_WAVE:
			len = audio_pcm_s16le(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_SND:
			len = audio_pcm_mulaw(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_FLOAT:
			len = audio_pcm_float(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_PCM32:
			len = audio_pcm_s32(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_PCM24:
			len = audio_pcm_s24(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_PCM16:
			len = audio_pcm_s16(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		case AUDIO_MPEG_OUTPUT_TYPE_PCM8:
			len = audio_pcm_u8(data, pcm_len, left, right, params->mode,
				stats, dither_err);
		break;
		}
		XPUSHs(sv_2mortal(newSVpvn(data, len)));

unsigned int
clipped_samples(THIS)
		Audio_MPEG_Output THIS
	CODE:
		RETVAL = THIS->stats->clipped_samples;
	OUTPUT:
		RETVAL

double
peak_amplitude(THIS)
		Audio_MPEG_Output THIS
	PREINIT:
		mad_fixed_t peak;
	CODE:
		peak = MAD_F_ONE + THIS->stats->peak_clipping;
		if (peak == MAD_F_ONE)
			peak = THIS->stats->peak_sample;
		RETVAL = 20.0 * log10(mad_f_todouble(peak));
	OUTPUT:
		RETVAL

#
# Interface to the LAME library
#

MODULE = Audio::MPEG		PACKAGE = Audio::MPEG::Encode

Audio_MPEG_Encode
new(CLASS, params_data_ref = &PL_sv_undef)
		char *CLASS = NO_INIT
		SV *params_data_ref
	PREINIT:
		lame_t *flags;
		HV *params_data;
		SV **hval;
		char *key;
		double argdbl;
		int argint;
		char *argstr;
		STRLEN arglen;
	CODE:
		/* initialize the library */
		if ((flags = lame_init()) == (lame_t *)-1) {
			warn("error initializing LAME library");
			XSRETURN_UNDEF;
		}

		Newz(0, (void *)RETVAL, sizeof(*RETVAL), char);
		RETVAL->flags = flags;

		/* process input arguments */
		if (items > 1) {
			params_data = (HV *)SvRV(params_data_ref);

			/* number of input channels */
			key = "in_channels";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->num_channels =  SvIV(*hval);
			else {
				flags->num_channels = 2;
			}

			/* input sample rate (in Hz).
			   Allowed values are:
			   MPEG1	32, 44.1,   48kHz
			   MPEG2	16, 22.05,  24
			   MPEG2.5	 8, 11.025, 12
			*/
			key = "in_sample_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE))
				!= NULL) {
				switch (argint = SvIV(*hval)) {
				case 8000:
				case 11025:
				case 12000:
				case 16000:
				case 22050:
				case 24000:
				case 32000:
				case 44100:
				case 48000:
					flags->in_samplerate = argint;
				break;
				default:
					warn("input sample frequency invalid");
					XSRETURN_UNDEF;
				break;
				}
			} else {
				flags->in_samplerate = 44100;
			}
			
			/* output sample rate (in Hz). default is 0 (LAME picks best)
			   Allowed values are:
			   MPEG1	32, 44.1,   48kHz
			   MPEG2	16, 22.05,  24
			   MPEG2.5	 8, 11.025, 12
			*/
			key = "out_sample_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE))
				!= NULL) {
				switch (argint = SvIV(*hval)) {
				case 8000:
				case 11025:
				case 12000:
				case 16000:
				case 22050:
				case 24000:
				case 32000:
				case 44100:
				case 48000:
					lame_set_out_samplerate(flags, argint);
				break;
				default:
					warn("output resample frequency invalid");
					XSRETURN_UNDEF;
				break;
				}
			}
			
			/* scale output by this amount before encoding.
			   default is 0 (disabled) */
			key = "scale";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				lame_set_scale(flags, SvNV(*hval));

			/* quality setting 0 .. 9  0=best (slow), 9=worst. Default is 5 */
			key = "quality";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				lame_set_quality(flags, SvIV(*hval));
			
			/* mode = 0,1,2,3 = stereo, jstereo, dual (not supported), mono
			   default: LAME picks based on comp ratio and input channels */
			key = "mode";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE))
				!= NULL) {
				argstr = SvPV(*hval, arglen);
				if (strEQ(argstr, "stereo"))
					lame_set_mode(flags, STEREO);
				else if (strEQ(argstr, "joint-stereo"))
					lame_set_mode(flags, JOINT_STEREO);
				else if (strEQ(argstr, "mono"))
					lame_set_mode(flags, MONO);
				else {
					warn("output audio mode invalid");
					XSRETURN_UNDEF;
				}
			}

			/* use M/S mode with switching threshold based on comp ratio
			   default = 0 (disabled) */
			key = "mode_automs";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				lame_set_mode_automs(flags, SvIV(*hval));
			
			/* use free format. default = 0 (disabled) */
			key = "free_format";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->free_format =  SvIV(*hval);

			/* desired constant bitrate */
			key = "bit_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->brate =  SvIV(*hval);

			/* desired comp ratio. default is 11. interacts with bitrate */
			key = "compression_ratio";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->compression_ratio = SvNV(*hval);

			if (flags->brate && flags->compression_ratio) {
				warn("both bitrate and compression ratio set");
				XSRETURN_UNDEF;
			}

			/* mark as copyright. default is 0 */
			key = "copyright";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->copyright = SvIV(*hval);

			/* mark as original. default is 1 */
			key = "original";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->original = SvIV(*hval);

			/* generate CRCs. default is 0 */
			key = "CRC";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->error_protection = SvIV(*hval);

			/* padding type. 0=pad no frames, 1=pad all frames, 2=adjust
			   padding (default)
			key = "padding_type";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->padding_type = SvIV(*hval);

			/* enforce strict ISO compliance. default=0 */
			key = "strict";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->strict_ISO = SvIV(*hval);

			/* VBR type: 0=off,1=mt,2=rh,3=abr,4=mtrh default 0 */
			key = "vbr";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE))
				!= NULL) {
				if (flags->brate || flags->compression_ratio) {
					warn("both fixed and variable bitrate set");
					XSRETURN_UNDEF;
				}
				argstr = SvPV(*hval, arglen);
				if (strEQ(argstr, "vbr"))
					flags->VBR = vbr_default;
				else if (strEQ(argstr, "1"))
					flags->VBR = vbr_default;
				else if (strEQ(argstr, "old"))
					flags->VBR = vbr_rh;
				else if (strEQ(argstr, "new"))
					flags->VBR = vbr_mt;
				else if (strEQ(argstr, "mtrh"))
					flags->VBR = vbr_mtrh;
				else {
					warn("invalid VBR setting");
					XSRETURN_UNDEF;
				}
			}

			/* VBR quality: 0 = highest, 9 = lowest */
			key = "vbr_quality";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->VBR_q = SvIV(*hval);

			/* Average VBR */
			key = "average_bitrate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE))
				!= NULL) {
				if (flags->brate || flags->compression_ratio) {
					warn("both fixed and average bitrate set");
					XSRETURN_UNDEF;
				}
				flags->VBR = vbr_abr;
				flags->VBR_mean_bitrate_kbps = SvIV(*hval);
				if (flags->VBR_mean_bitrate_kbps >= 8000) {
					flags->VBR_mean_bitrate_kbps =
						(flags->VBR_mean_bitrate_kbps + 500) / 1000;
					flags->VBR_mean_bitrate_kbps =
						Min(flags->VBR_mean_bitrate_kbps, 320);
					flags->VBR_mean_bitrate_kbps =
						Max(flags->VBR_mean_bitrate_kbps, 8);
				}
			}

			/* min/max bitrates for VBR */
			key = "min_bit_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->VBR_min_bitrate_kbps = SvIV(*hval) / 1000;
			key = "min_hard_bit_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->VBR_hard_min = SvIV(*hval) / 1000;
			key = "max_bit_rate";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->VBR_max_bitrate_kbps = SvIV(*hval) / 1000;

			/* filtering. 0 = LAME chooses (default), -1 = disabled,
			   otherwise Hz of filter. valid are 1 .. 50,000 Hz  */
			key = "lowpass_filter_frequency";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->lowpassfreq = SvIV(*hval);
			key = "lowpass_filter_width";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->lowpasswidth = SvIV(*hval);
			key = "no_lowpass_filter";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->lowpassfreq = -1;
			
			key = "highpass_filter_frequency";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->highpassfreq = SvIV(*hval);
			key = "highpass_filter_width";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->highpasswidth = SvIV(*hval);
			key = "no_highpass_filter";
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				flags->highpassfreq = -1;

			key = "apply_delay";
			RETVAL->encode_delay_applied = 1;
			if ((hval = hv_fetch(params_data, key, strlen(key), FALSE)) != NULL)
				RETVAL->encode_delay_applied = SvUV(*hval) ? 0 : 1;
		}

		/* finish initialization of parameters */
		if (lame_init_params(flags) == -1) {
			warn("unable to initialize LAME library parameters");
			XSRETURN_UNDEF;
		}

	OUTPUT:
		RETVAL

void
DESTROY(THIS)
		Audio_MPEG_Encode THIS
	CODE:
		lame_close(THIS->flags);
		Safefree(THIS);

#
# This is the delay, in PCM samples, that is introduced by encoding.
#

int
encoder_delay(THIS)
		Audio_MPEG_Encode THIS
	CODE:
		RETVAL = THIS->flags->encoder_delay;
	OUTPUT:
		RETVAL

#
# encode_float() - encodes interleaved float pcm samples (maximum precision)
#

void
encode_float(THIS, pcm_sv)
		Audio_MPEG_Encode THIS
		SV *pcm_sv
	PREINIT:
		unsigned char *pcm;
		STRLEN pcm_len;
		unsigned int encode_len;
		unsigned char out[LAME_MAXMP3BUFFER / sizeof(short) * sizeof(float)];
	PPCODE:
		pcm = SvPV(pcm_sv, pcm_len);
		if (!pcm_len) {
			warn("pcm sample length cannot be 0");
			XSRETURN_UNDEF;
		}
		if (! THIS->encode_delay_applied) {
			/* skip n input samples to compensate for encoding delay */
			THIS->encode_delay_applied = 1;
			pcm += THIS->flags->encoder_delay * sizeof(float) *
				THIS->flags->num_channels;
			pcm_len -= THIS->flags->encoder_delay;
			if ((pcm_len -= THIS->flags->encoder_delay) < 1) {
				warn("pcm sample length is less than 0 after encoder delay compensation");
				XSRETURN_UNDEF;
			}
		}
		encode_len = lame_encode_buffer_interleaved_float(THIS->flags,
			(float *)pcm, pcm_len / sizeof(float) / THIS->flags->num_channels,
			out, LAME_MAXMP3BUFFER);
		XPUSHs(sv_2mortal(newSVpvn(out, encode_len)));

#
# encode16() - encodes interleaved signed 16bit pcm samples
#

void
encode16(THIS, pcm_sv)
		Audio_MPEG_Encode THIS
		SV *pcm_sv
	PREINIT:
		unsigned char *pcm;
		STRLEN pcm_len;
		unsigned int encode_len;
		unsigned char out[LAME_MAXMP3BUFFER];
	PPCODE:
		pcm = SvPV(pcm_sv, pcm_len);
		if (!pcm_len) {
			warn("pcm sample length cannot be 0");
			XSRETURN_UNDEF;
		}
		if (! THIS->encode_delay_applied) {
			/* skip n input samples to compensate for encoding delay */
			THIS->encode_delay_applied = 1;
			pcm += THIS->flags->encoder_delay * sizeof(short) *
				THIS->flags->num_channels;
			if ((pcm_len -= THIS->flags->encoder_delay) < 1) {
				warn("pcm sample length is less than 0 after encoder delay compensation");
				XSRETURN_UNDEF;
			}
		}
		if (THIS->flags->num_channels == 2) {
			encode_len = lame_encode_buffer_interleaved(THIS->flags,
				(short *)pcm, pcm_len / sizeof(short) /
				THIS->flags->num_channels, out, LAME_MAXMP3BUFFER);
		} else {
			encode_len = lame_encode_buffer(THIS->flags,
				(short *)pcm, (short *)pcm, pcm_len / sizeof(short) /
				THIS->flags->num_channels, out, LAME_MAXMP3BUFFER);
		}
		XPUSHs(sv_2mortal(newSVpvn(out, encode_len)));

#
# This must always be called after one thinks the encoding is finished
#

void
encode_flush(THIS)
		Audio_MPEG_Encode THIS
	PREINIT:
		unsigned int encode_len;
		unsigned char out[LAME_MAXMP3BUFFER];
	PPCODE:
		encode_len = lame_encode_flush(THIS->flags, out, LAME_MAXMP3BUFFER);
		XPUSHs(sv_2mortal(newSVpvn(out, encode_len)));

#
# Write the Xing VBR header to an MP3 file. NOTE: file *must* be opened
# read/write!
#

void
encode_vbr_flush(THIS, fp)
		Audio_MPEG_Encode THIS
		FILE *fp
	CODE:
		lame_mp3_tags_fid(THIS->flags, fp);

