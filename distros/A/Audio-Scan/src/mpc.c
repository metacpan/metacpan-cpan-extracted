/*
 * Original Copyright:
 *
  Copyright (c) 2005, The Musepack Development Team
  All rights reserved.

  Redistribution and use in source and binary forms, with or without
  modification, are permitted provided that the following conditions are
  met:

  * Redistributions of source code must retain the above copyright
  notice, this list of conditions and the following disclaimer.

  * Redistributions in binary form must reproduce the above
  copyright notice, this list of conditions and the following
  disclaimer in the documentation and/or other materials provided
  with the distribution.

  * Neither the name of the The Musepack Development Team nor the
  names of its contributors may be used to endorse or promote
  products derived from this software without specific prior
  written permission.

  THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS
  "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT
  LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR
  A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT
  OWNER OR CONTRIBUTORS BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL,
  SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT
  LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE,
  DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY
  THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT
  (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE
  OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.
*/

#include "mpc.h"

#define MPC_BLOCK_SIZE 1024
#define MPC_OLD_GAIN_REF 64.82

const int32_t samplefreqs[4] = { 44100, 48000, 37800, 32000 };

// profile is 0...15, where 7...13 is used
static const char *
_mpc_profile_string(uint32_t profile)
{
  static const char na[] = "n.a.";
  static const char *names[] = {
    na,
    "Unstable/Experimental",
    na,
    na,
    na,
    "below Telephone (q=0)",
    "below Telephone (q=1)",
    "Telephone (q=2)",
    "Thumb (q=3)",
    "Radio (q=4)",
    "Standard (q=5)",
    "Extreme (q=6)",
    "Insane (q=7)",
    "BrainDead (q=8)",
    "above BrainDead (q=9)",
    "above BrainDead (q=10)"
  };

  return profile >= sizeof(names) / sizeof(*names) ? na : names[profile];
}

unsigned int
_mpc_bits_get_size(Buffer *buf, uint64_t *p_size)
{
	unsigned char tmp;
	uint64_t size = 0;
	unsigned int ret = 0;

	do {
		tmp = buffer_get_char(buf);
		size = (size << 7) | (tmp & 0x7F);
		ret++;
	} while((tmp & 0x80));

	*p_size = size;
	return ret;
}

static void
_mpc_get_encoder_string(mpc_streaminfo* si)
{
	int ver = si->encoder_version;
	if (si->stream_version >= 8)
		ver = (si->encoder_version >> 24) * 100 + ((si->encoder_version >> 16) & 0xFF);
	if (ver <= 116) {
		if (ver == 0) {
			sprintf(si->encoder, "Buschmann 1.7.0...9, Klemm 0.90...1.05");
		} else {
			switch (ver % 10) {
				case 0:
					sprintf(si->encoder, "Release %u.%u", ver / 100,
							ver / 10 % 10);
					break;
				case 2: case 4: case 6: case 8:
					sprintf(si->encoder, "Beta %u.%02u", ver / 100,
							ver % 100);
					break;
				default:
					sprintf(si->encoder, "--Alpha-- %u.%02u",
							ver / 100, ver % 100);
					break;
			}
		}
	} else {
		int major = si->encoder_version >> 24;
		int minor = (si->encoder_version >> 16) & 0xFF;
		int build = (si->encoder_version >> 8) & 0xFF;
		char * tmp = "--Stable--";

		if (minor & 1)
			tmp = "--Unstable--";

		sprintf(si->encoder, "%s %u.%u.%u", tmp, major, minor, build);
	}
}

static int32_t
_mpc_read_header_sv8(mpc_streaminfo *si)
{
  unsigned char blocktype[2];
  unsigned char *bptr = buffer_ptr(si->buf);
  uint64_t size;

  while ( memcmp(bptr, "AP", 2) != 0 ) { // scan all blocks until audio
    memcpy(blocktype, bptr, 2);
    buffer_consume(si->buf, 2);

    _mpc_bits_get_size(si->buf, &size);
    size -= 3;

    DEBUG_TRACE("%c%c block, size %llu\n", blocktype[0], blocktype[1], size);

    if ( !_check_buf(si->infile, si->buf, size, MPC_BLOCK_SIZE) ) {
      return -1;
    }

    if (memcmp(blocktype, "SH", 2) == 0) {
      // Skip CRC
      buffer_consume(si->buf, 4);

      si->stream_version = buffer_get_char(si->buf);
      _mpc_bits_get_size(si->buf, &si->pcm_samples);
      _mpc_bits_get_size(si->buf, &si->beg_silence);

      si->is_true_gapless = 1;

      bptr = buffer_ptr(si->buf);
      si->sample_freq = samplefreqs[ (bptr[0] & 0xE0) >> 5 ];
      si->max_band = (bptr[0] & 0x1F) + 1;
      si->channels = ( (bptr[1] & 0xF0) >> 4 ) + 1;
      si->ms = (bptr[1] & 0x8) >> 3;
      si->block_pwr = (bptr[1] & 0x7) * 2;
      buffer_consume(si->buf, 2);
    }
    else if (memcmp(blocktype, "RG", 2) == 0) {
      // Check version
      if ( buffer_get_char(si->buf) != 1 ) {
        // Skip
        buffer_consume(si->buf, size - 1);
      }
      else {
        si->gain_title = buffer_get_short(si->buf);
        si->peak_title = buffer_get_short(si->buf);
        si->gain_album = buffer_get_short(si->buf);
        si->peak_album = buffer_get_short(si->buf);
      }
    }
    else if (memcmp(blocktype, "EI", 2) == 0) {
      bptr = buffer_ptr(si->buf);

      si->fprofile = ((bptr[0] & 0xFE) >> 1) / 8.;
      si->profile_name = _mpc_profile_string((uint32_t)si->fprofile);
      buffer_consume(si->buf, 1);

      si->encoder_version = buffer_get_char(si->buf) << 24; // major
      si->encoder_version |= buffer_get_char(si->buf) << 16; // minor
      si->encoder_version |= buffer_get_char(si->buf) << 8; // build
      DEBUG_TRACE("ver: %d\n", si->encoder_version);

      _mpc_get_encoder_string(si);
    }
    else {
      break;
    }

    bptr = buffer_ptr(si->buf);
  }

  return 0;
}

static int32_t
_mpc_read_header_sv7(mpc_streaminfo *si)
{
  unsigned char *bptr;

  // Update (si->stream_version);
  if (si->stream_version > 0x71) {
    return 0;
  }

  si->bitrate            = 0;
  si->frames             = buffer_get_int_le(si->buf);

  bptr = buffer_ptr(si->buf);
  si->is                 = (bptr[3] >> 7) & 0x1;
  si->ms                 = (bptr[3] >> 6) & 0x1;
  si->max_band           = bptr[3] & 0x3F;

  si->block_size         = 1;
  si->profile            = (bptr[2] >> 4) & 0xF;
  si->profile_name       = _mpc_profile_string(si->profile);
  // skip Link
  si->sample_freq        = samplefreqs[bptr[2] & 0x3];
  // skip MaxLevel
  buffer_consume(si->buf, 4);

  si->peak_title         = buffer_get_short_le(si->buf);
  si->gain_title         = buffer_get_short_le(si->buf);

  si->peak_album         = buffer_get_short_le(si->buf);
  si->gain_album         = buffer_get_short_le(si->buf);

  // convert gain info
  if (si->gain_title != 0) {
    int tmp = (int)((MPC_OLD_GAIN_REF - (int16_t)si->gain_title / 100.) * 256. + .5);
    if (tmp >= (1 << 16) || tmp < 0) tmp = 0;
    si->gain_title = (int16_t)tmp;
  }

  if (si->gain_album != 0) {
    int tmp = (int)((MPC_OLD_GAIN_REF - (int16_t)si->gain_album / 100.) * 256. + .5);
    if (tmp >= (1 << 16) || tmp < 0) tmp = 0;
    si->gain_album = (int16_t)tmp;
  }

  if (si->peak_title != 0)
    si->peak_title = (uint16_t) (log10(si->peak_title) * 20 * 256 + .5);

  if (si->peak_album != 0)
    si->peak_album = (uint16_t) (log10(si->peak_album) * 20 * 256 + .5);

  bptr = buffer_ptr(si->buf);
  si->is_true_gapless    = (bptr[3] >> 7) & 0x1;
  si->last_frame_samples = ((bptr[3] >> 1) & 0x7F) | ((bptr[2] >> 4) & 0xF);  // true gapless: valid samples for last frame
  buffer_consume(si->buf, 4);

  bptr = buffer_ptr(si->buf);
  si->encoder_version    = bptr[3];
  si->channels           = 2;

  _mpc_get_encoder_string(si);

  return 0;
}

static int
get_mpcfileinfo(PerlIO *infile, char *file, HV *info)
{
  Buffer buf;
  int32_t ret = 0;
  unsigned char *bptr;

  mpc_streaminfo *si;

  Newz(0, si, sizeof(mpc_streaminfo), mpc_streaminfo);
  buffer_init(&buf, MPC_BLOCK_SIZE);

  si->buf    = &buf;
  si->infile = infile;

  // get header position
  if ((si->header_position = skip_id3v2(infile)) < 0) {
    PerlIO_printf(PerlIO_stderr(), "Musepack: [Couldn't skip ID3v2]: %s\n", file);
    goto out;
  }

  // seek to first byte of mpc data
  if (PerlIO_seek(infile, si->header_position, SEEK_SET) < 0) {
    PerlIO_printf(PerlIO_stderr(), "Musepack: [Couldn't seek to offset %d]: %s\n", si->header_position, file);
    goto out;
  }

  if ( !_check_buf(infile, &buf, 128, MPC_BLOCK_SIZE) ) {
    goto out;
  }

  if (PerlIO_seek(infile, si->header_position + 6 * 4, SEEK_SET) < 0) {
    PerlIO_printf(PerlIO_stderr(), "Musepack: [Couldn't seek to offset %d + (6*4)]: %s\n", si->header_position, file);
    goto out;
  }

  si->tag_offset = PerlIO_tell(infile);

  si->total_file_length = _file_size(infile);

  bptr = buffer_ptr(&buf);

  if (memcmp(bptr, "MP+", 3) == 0) {
    buffer_consume(&buf, 3);
    si->stream_version = buffer_get_char(&buf);

    if ((si->stream_version & 15) == 7) {
      DEBUG_TRACE("parsing MPC SV7 header\n");
      ret = _mpc_read_header_sv7(si);
    }

  }
  else if (memcmp(bptr, "MPCK", 4) == 0) {
    buffer_consume(&buf, 4);

    DEBUG_TRACE("parsing MPC SV8 header\n");
    ret = _mpc_read_header_sv8(si);
  }
  else {
    PerlIO_printf(PerlIO_stderr(), "Not a Musepack SV7 or SV8 file: %s\n", file);
    goto out;
  }

  // estimation, exact value needs too much time
  if ( !si->pcm_samples )
    si->pcm_samples = 1152 * si->frames - 576;

  if (ret == 0) {
    double total_seconds = (double)( (si->pcm_samples * 1.0) / si->sample_freq);

    my_hv_store(info, "stream_version", newSVuv(si->stream_version));
    my_hv_store(info, "samplerate", newSViv(si->sample_freq));
    my_hv_store(info, "channels", newSViv(si->channels));
    my_hv_store(info, "song_length_ms", newSVuv(total_seconds * 1000));
    my_hv_store(info, "bitrate", newSVuv(8 * (double)(si->total_file_length - si->tag_offset) / total_seconds));

    my_hv_store(info, "audio_offset", newSVuv(si->tag_offset));
    my_hv_store(info, "audio_size", newSVuv(si->total_file_length - si->tag_offset));
    my_hv_store(info, "file_size", newSVuv(si->total_file_length));
    my_hv_store(info, "encoder", newSVpv(si->encoder, 0));

    if (si->profile_name)
      my_hv_store(info, "profile", newSVpv(si->profile_name, 0));

    my_hv_store(info, "gapless", newSViv(si->is_true_gapless));
    my_hv_store(info, "track_gain", newSVpvf("%2.2f dB", si->gain_title == 0 ? 0 : MPC_OLD_GAIN_REF - si->gain_title / 256.0));
    my_hv_store(info, "album_gain", newSVpvf("%2.2f dB", si->gain_album == 0 ? 0 : MPC_OLD_GAIN_REF - si->gain_album / 256.0));
  }

out:
  Safefree(si);
  buffer_free(&buf);

  return ret;
}
