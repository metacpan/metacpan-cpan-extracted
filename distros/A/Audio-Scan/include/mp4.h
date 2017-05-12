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

#define MP4_BLOCK_SIZE 4096

#define FOURCC_EQ(a, b) ((a)[0] == (b)[0] && (a)[1] == (b)[1] && (a)[2] && (b)[2] && (a)[3] == (b)[3])

typedef enum {
  AAC_INVALID   =  0, 
  AAC_MAIN      =  1, /* AAC Main */
  AAC_LC        =  2, /* AAC Low complexity */
  AAC_SSR       =  3, /* AAC SSR */
  AAC_LTP       =  4, /* AAC Long term prediction */
  AAC_HE        =  5, /* AAC High efficiency (SBR) */
  AAC_SCALE     =  6, /* Scalable */
  AAC_TWINVQ    =  7, /* TwinVQ */
  AAC_CELP      =  8, /* CELP */
  AAC_HVXC      =  9, /* HVXC */
  AAC_TTSI      = 12, /* TTSI */
  AAC_MS        = 13, /* Main synthetic */
  AAC_WAVE      = 14, /* Wavetable synthesis */
  AAC_MIDI      = 15, /* General MIDI */
  AAC_FX        = 16, /* Algorithmic Synthesis and Audio FX */
  AAC_LC_ER     = 17, /* AAC Low complexity with error recovery */
  AAC_LTP_ER    = 19, /* AAC Long term prediction with error recovery */
  AAC_SCALE_ER  = 20, /* AAC scalable with error recovery */
  AAC_TWINVQ_ER = 21, /* TwinVQ with error recovery */
  AAC_BSAC_ER   = 22, /* BSAC with error recovery */
  AAC_LD_ER     = 23, /* AAC LD with error recovery */
  AAC_CELP_ER   = 24, /* CELP with error recovery */
  AAC_HXVC_ER   = 25, /* HXVC with error recovery */
  AAC_HILN_ER   = 26, /* HILN with error recovery */
  AAC_PARAM_ER  = 27, /* Parametric with error recovery */
  AAC_SSC       = 28, /* AAC SSC */
  AAC_PS        = 29, /* Parametric Stereo */ 
  AAC_ESCAPE    = 31, /* Escape */
  AAC_SLS       = 37, /* Scalable Lossless */
} aac_object_type;

const uint32_t samplerate_table[16] = {
  96000, 88200, 64000, 48000, 44100, 32000, 24000,
  22050, 16000, 12000, 11025, 8000, 7350, -1, -1, 0
};

const uint8_t bps_table[4] = {
  8, 16, 20, 24
};

typedef struct tts {
  uint32_t sample_count;
  uint32_t sample_duration;
} tts;

typedef struct stc {
  uint32_t first_chunk;
  uint32_t samples_per_chunk;
} stc;

typedef struct mp4info {
  PerlIO *infile;
  char *file;
  Buffer *buf;
  uint64_t file_size; // total file size
  uint64_t size;      // total size
  uint8_t  hsize;     // header size
  uint64_t rsize;     // remaining size
  uint64_t audio_offset;
  uint64_t audio_size;
  HV *info;
  HV *tags;
  uint32_t current_track;
  uint32_t track_count;
  uint8_t seen_moov;
  uint8_t dlna_invalid;
  
  // Things needed for DLNA detection
  uint8_t audio_object_type;
  uint16_t channels;
  uint32_t samplerate;
  uint32_t bitrate;
  
  // Data structures used to support seeking
  // Based on code from Rockbox
  
  uint8_t seeking;      // flag if we're seeking
  uint32_t old_st_size; // size of original st* boxes
  uint32_t new_st_size; // size of rewritten st* boxes
  uint32_t meta_size;   // size of variable meta box
  SV *seekhdr;          // rewritten header during second seek pass
  
  // stsc
  uint32_t num_sample_to_chunks;
  struct stc *sample_to_chunk;
  SV *new_stsc;
  
  // stco
  uint32_t *chunk_offset;
  uint32_t num_chunk_offsets;
  SV *new_stco;
  
  // stts
  struct tts *time_to_sample;
  uint32_t num_time_to_samples;
  SV *new_stts;
  
  // stsz
  uint16_t *sample_byte_size;
  uint32_t num_sample_byte_sizes;
  SV *new_stsz;
} mp4info;

static int get_mp4tags(PerlIO *infile, char *file, HV *info, HV *tags);
int mp4_find_frame(PerlIO *infile, char *file, int offset);
int mp4_find_frame_return_info(PerlIO *infile, char *file, int offset, HV *info);

mp4info * _mp4_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking);
int _mp4_read_box(mp4info *mp4);
uint8_t _mp4_parse_ftyp(mp4info *mp4);
uint8_t _mp4_parse_mvhd(mp4info *mp4);
uint8_t _mp4_parse_tkhd(mp4info *mp4);
uint8_t _mp4_parse_mdhd(mp4info *mp4);
uint8_t _mp4_parse_hdlr(mp4info *mp4);
uint8_t _mp4_parse_stsd(mp4info *mp4);
uint8_t _mp4_parse_mp4a(mp4info *mp4);
uint8_t _mp4_parse_esds(mp4info *mp4);
uint8_t _mp4_parse_alac(mp4info *mp4);
uint8_t _mp4_parse_stts(mp4info *mp4);
uint8_t _mp4_parse_stsc(mp4info *mp4);
uint8_t _mp4_parse_stsz(mp4info *mp4);
uint8_t _mp4_parse_stco(mp4info *mp4);
uint8_t _mp4_parse_meta(mp4info *mp4);
uint8_t _mp4_parse_ilst(mp4info *mp4);
uint8_t _mp4_parse_ilst_data(mp4info *mp4, uint32_t size, SV *key);
uint8_t _mp4_parse_ilst_custom(mp4info *mp4, uint32_t size);
HV * _mp4_get_current_trackinfo(mp4info *mp4);
uint32_t _mp4_descr_length(Buffer *buf);
void _mp4_skip(mp4info *mp4, uint32_t size);
uint32_t _mp4_samples_in_chunk(mp4info *mp4, uint32_t chunk);
uint32_t _mp4_total_samples(mp4info *mp4);
uint32_t _mp4_get_sample_duration(mp4info *mp4, uint32_t sample);
