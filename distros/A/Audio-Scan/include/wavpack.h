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

#define WAVPACK_BLOCK_SIZE 4096

typedef struct {
//  char ckID [4];              // "wvpk"
  uint32_t ckSize;            // size of entire block (minus 8, of course)
  uint16_t version;           // 0x402 to 0x410 are currently valid for decode
  u_char track_no;            // track number (0 if not used, like now)
  u_char index_no;            // track sub-index (0 if not used, like now)
  uint32_t total_samples;     // total samples for entire file, but this is
                              // only valid if block_index == 0 and a value of
                              // -1 indicates unknown length
  uint32_t block_index;       // index of first sample in block relative to
                              // beginning of file (normally this would start
                              // at 0 for the first block)
  uint32_t block_samples;     // number of samples in this block (0 = no audio)
  uint32_t flags;             // various flags for id and decoding
  uint32_t crc;               // crc for actual decoded data
} WavpackHeader;

typedef struct {
  unsigned short FormatTag, NumChannels;
  uint32_t SampleRate, BytesPerSecond;
  unsigned short BlockAlign, BitsPerSample;
} WaveHeader3;

typedef struct {
//  char ckID [4];
  int32_t ckSize;
  short version;
  short bits;                 // added for version 2.00
  short flags, shift;         // added for version 3.00
  int32_t total_samples; //, crc, crc2;
//  char extension [4], extra_bc, extras [3];
} WavpackHeader3;

typedef struct wvpinfo {
  PerlIO *infile;
  char *file;
  Buffer *buf;
  HV *info;
  off_t file_size;
  off_t file_offset;
  off_t audio_offset;
  
  WavpackHeader *header; // current block header data
  
  uint8_t seeking; // flag if we're seeking
} wvpinfo;

const int wavpack_sample_rates[] = {
  6000, 8000, 9600, 11025, 12000, 16000, 22050, 24000, 32000, 44100, 48000, 64000, 88200, 96000, 192000
};

#define ID_UNIQUE               0x3f
#define ID_OPTIONAL_DATA        0x20
#define ID_ODD_SIZE             0x40
#define ID_LARGE                0x80

#define ID_DUMMY                0x0
#define ID_ENCODER_INFO         0x1
#define ID_DECORR_TERMS         0x2
#define ID_DECORR_WEIGHTS       0x3
#define ID_DECORR_SAMPLES       0x4
#define ID_ENTROPY_VARS         0x5
#define ID_HYBRID_PROFILE       0x6
#define ID_SHAPING_WEIGHTS      0x7
#define ID_FLOAT_INFO           0x8
#define ID_INT32_INFO           0x9
#define ID_WV_BITSTREAM         0xa
#define ID_WVC_BITSTREAM        0xb
#define ID_WVX_BITSTREAM        0xc
#define ID_CHANNEL_INFO         0xd

#define ID_RIFF_HEADER          (ID_OPTIONAL_DATA | 0x1)
#define ID_RIFF_TRAILER         (ID_OPTIONAL_DATA | 0x2)
#define ID_REPLAY_GAIN          (ID_OPTIONAL_DATA | 0x3)    // never used (APEv2)
#define ID_CUESHEET             (ID_OPTIONAL_DATA | 0x4)    // never used (APEv2)
#define ID_CONFIG_BLOCK         (ID_OPTIONAL_DATA | 0x5)
#define ID_MD5_CHECKSUM         (ID_OPTIONAL_DATA | 0x6)
#define ID_SAMPLE_RATE          (ID_OPTIONAL_DATA | 0x7)

static int get_wavpack_info(PerlIO *infile, char *file, HV *info);
wvpinfo * _wavpack_parse(PerlIO *infile, char *file, HV *info, uint8_t seeking);
int _wavpack_parse_block(wvpinfo *wvp);
int _wavpack_parse_sample_rate(wvpinfo *wvp, uint32_t size);
int _wavpack_parse_channel_info(wvpinfo *wvp, uint32_t size);
void _wavpack_skip(wvpinfo *wvp, uint32_t size);
int _wavpack_parse_old(wvpinfo *wvp);
