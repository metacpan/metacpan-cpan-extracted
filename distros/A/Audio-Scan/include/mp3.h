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

// Use Safefree for libid3tag free calls on Windows
#ifdef _MSC_VER
#define free(ptr) Safefree(ptr)
#endif

#define MP3_BLOCK_SIZE 4096

#define XING_FRAMES  0x01
#define XING_BYTES   0x02
#define XING_TOC     0x04
#define XING_QUALITY 0x08

#define CBR 1
#define ABR 2
#define VBR 3

#define ILLEGAL_MPEG_ID  1
#define MPEG1_ID         3
#define MPEG2_ID         2
#define MPEG25_ID        0
#define ILLEGAL_LAYER_ID 0
#define LAYER1_ID        3
#define LAYER2_ID        2
#define LAYER3_ID        1
#define ILLEGAL_SR       3
#define MODE_MONO        3

// Based on pcutmp3 FrameHeader
typedef struct mp3frame {
  int header32;
  int mpegID;
  int layerID;
  bool crc16_used;
  int bitrate_index;
  int samplingrate_index;
  bool padding;
  bool private_bit_set;
  int mode;
  int mode_extension;
  bool copyrighted;
  bool original;
  int emphasis;
  
  bool valid;
  
  int samplerate;
  int channels;
  int bitrate_kbps;
  int samples_per_frame;
  int bytes_per_slot;
  int frame_size;
} mp3frame;

// based on pcutmp3 XingInfoLameTagFrame
typedef struct xingframe {
  int frame_size;
  
  bool xing_tag;
  bool info_tag;
  int flags;
  int xing_frames;
  int xing_bytes;
  bool has_toc;
  uint8_t xing_toc[100];
  int xing_quality;
  
  bool lame_tag;
  char lame_encoder_version[9];
  uint8_t lame_tag_revision;
  uint8_t lame_vbr_method;
  int lame_lowpass;
  float lame_replay_gain[2];
  uint16_t lame_abr_rate;
  int lame_encoder_delay;
  int lame_encoder_padding;
  uint8_t lame_noise_shaping;
  uint8_t lame_stereo_mode;
  uint8_t lame_unwise;
  uint8_t lame_source_freq;
  int lame_mp3gain;
  float lame_mp3gain_db;
  uint8_t lame_surround;
  uint16_t lame_preset;
  int lame_music_length;
  
  bool vbri_tag;
  uint16_t vbri_delay;
  uint16_t vbri_quality;
  uint32_t vbri_bytes;
  uint32_t vbri_frames;
  
  int lame_tag_ofs;
} xingframe;

typedef struct mp3info {
  PerlIO *infile;
  char *file;
  Buffer *buf;
  HV *info;
  
  off_t file_size;
  uint32_t id3_size;
  off_t audio_offset;
  off_t audio_size;
  uint16_t bitrate;
  uint32_t song_length_ms;
  
  uint8_t vbr;
  int music_frame_count;
  int samples_per_frame;
  
  mp3frame *first_frame;
  xingframe *xing_frame;
} mp3info;

// LAME lookup tables
const char *stereo_modes[] = {
  "Mono",
  "Stereo",
  "Dual",
  "Joint",
  "Force",
  "Auto",
  "Intensity",
  "Undefined"
};

const char *source_freqs[] = {
  "<= 32 kHz",
  "44.1 kHz",
  "48 kHz",
  "> 48 kHz"
};

const char *surround[] = {
  "None",
  "DPL encoding",
  "DPL2 encoding",
  "Ambisonic encoding",
  "Reserved"
};

const char *vbr_methods[] = {
  "Unknown",
  "Constant Bitrate",
  "Average Bitrate",
  "Variable Bitrate method1 (old/rh)",
  "Variable Bitrate method2 (mtrh)",
  "Variable Bitrate method3 (mt)",
  "Variable Bitrate method4",
  NULL,
  "Constant Bitrate (2 pass)",
  "Average Bitrate (2 pass)",
  NULL,
  NULL,
  NULL,
  NULL,
  NULL,
  "Reserved"
};

const char *presets_v[] = {
  "V9",
  "V8",
  "V7",
  "V6",
  "V5",
  "V4",
  "V3",
  "V2",
  "V1",
  "V0"
};

const char *presets_old[] = {
  "r3mix",
  "standard",
  "extreme",
  "insane",
  "standard/fast",
  "extreme/fast",
  "medium",
  "medium/fast"
};

static int bitrate_map[4][4][16] = {
  { { 0 }, //MPEG2.5
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 }
  },
  { { 0 } },
  { { 0 }, // MPEG2
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 8, 16, 24, 32, 40, 48, 56, 64, 80, 96, 112, 128, 144, 160, 0 },
    { 0, 32, 48, 56, 64, 80, 96, 112, 128, 144, 160, 176, 192, 224, 256, 0 }
  }, 
  { { 0 }, // MPEG1
    { 0, 32, 40, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 0 },
    { 0, 32, 48, 56, 64, 80, 96, 112, 128, 160, 192, 224, 256, 320, 384, 0 },
    { 0, 32, 64, 96, 128, 160, 192, 224, 256, 288, 320, 352, 384, 416, 448, 0 }
  }
};

// sample_rate[samplingrate_index]
static int sample_rate_tbl[ ] = {
  44100, 48000, 32000, 0,
};

int get_mp3tags(PerlIO *infile, char *file, HV *info, HV *tags);
int get_mp3fileinfo(PerlIO *infile, char *file, HV *info);
int mp3_find_frame(PerlIO *infile, char *file, int offset);

mp3info * _mp3_parse(PerlIO *infile, char *file, HV *info);
int _decode_mp3_frame(unsigned char *bptr, struct mp3frame *frame);
int _is_ape_header(char *bptr);
int _has_ape(PerlIO *infile, off_t file_size, HV *info);
void _mp3_skip(mp3info *mp3, uint32_t size);
