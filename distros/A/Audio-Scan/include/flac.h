/*
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
 */

#pragma once 

#define FLAC_BLOCK_SIZE 4096
#define FLAC_FRAME_MAX_HEADER 22

/* frame header size (16 bytes) + 4608 stereo 16-bit samples (higher than 4608 is possible, but not done) */
#define FLAC_MAX_FRAMESIZE 18448
#define FLAC_HEADER_LEN 16

enum flac_types {
  FLAC_TYPE_STREAMINFO,
  FLAC_TYPE_PADDING,
  FLAC_TYPE_APPLICATION,
  FLAC_TYPE_SEEKTABLE,
  FLAC_TYPE_VORBIS_COMMENT,
  FLAC_TYPE_CUESHEET,
  FLAC_TYPE_PICTURE
};

typedef struct seekpoint {
  uint64_t sample_number;
  uint64_t stream_offset;
  uint16_t frame_samples;
} seekpoint;

typedef struct flacinfo {
  PerlIO *infile;
  char *file;
  Buffer *buf;
  Buffer *scratch;
  HV *info;
  HV *tags;
  off_t file_size;
  off_t audio_offset;

  uint32_t min_blocksize;
  uint32_t max_blocksize;
  uint32_t min_framesize;
  uint32_t max_framesize;
  uint8_t  channels;
  uint32_t samplerate;
  uint32_t bits_per_sample;
  uint64_t total_samples;

  uint8_t seeking; // flag if we're seeking

  uint32_t num_seekpoints;
  struct seekpoint *seekpoints;
} flacinfo;

int get_flac_metadata(PerlIO *infile, char *file, HV *info, HV *tags);
flacinfo * _flac_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking);
void _flac_parse_streaminfo(flacinfo *flac);
void _flac_parse_application(flacinfo *flac, int len);
void _flac_parse_seektable(flacinfo *flac, int len);
void _flac_parse_cuesheet(flacinfo *flac);
int _flac_parse_picture(flacinfo *flac);
int _flac_binary_search_sample(flacinfo *flac, uint64_t target_sample, off_t low, off_t high);
int _flac_read_frame_header(flacinfo *flac, unsigned char *buf, uint64_t *first_sample, uint64_t *last_sample);
int _flac_first_last_sample(flacinfo *flac, off_t seek_offset, off_t *frame_offset, uint64_t *first_sample, uint64_t *last_sample, uint64_t target_sample);
uint8_t _flac_crc8(const unsigned char *buf, unsigned len);
int _flac_read_utf8_uint64(unsigned char *raw, uint64_t *val, uint8_t *rawlen);
int _flac_read_utf8_uint32(unsigned char *raw, uint32_t *val, uint8_t *rawlen);
void _flac_skip(flacinfo *flac, uint32_t size);
