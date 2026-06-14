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

#ifdef _MSC_VER
  #include "win32/zlib.h"
#else
  #include <zlib.h>
#endif

#define ID3_BLOCK_SIZE 4096

// ID3v1 field frames

#define ID3_FRAME_TITLE    "TIT2"
#define ID3_FRAME_ARTIST   "TPE1"
#define ID3_FRAME_ALBUM    "TALB"
#define ID3_FRAME_TRACK    "TRCK"
#define ID3_FRAME_YEAR     "TDRC"
#define ID3_FRAME_GENRE    "TCON"
#define ID3_FRAME_COMMENT  "COMM"

// Tag flags
enum {
  ID3_TAG_FLAG_UNSYNCHRONISATION     = 0x80,
  ID3_TAG_FLAG_EXTENDEDHEADER        = 0x40,
  ID3_TAG_FLAG_EXPERIMENTALINDICATOR = 0x20,
  ID3_TAG_FLAG_FOOTERPRESENT         = 0x10
};

// Frame flags
enum {
  // v2.3 flags
  ID3_FRAME_FLAG_V23_COMPRESSION         = 0x0080,
  ID3_FRAME_FLAG_V23_ENCRYPTION          = 0x0040,
  ID3_FRAME_FLAG_V23_GROUPINGIDENTITY    = 0x0020,

  // v2.4 flags
  ID3_FRAME_FLAG_V24_GROUPINGIDENTITY    = 0x0040,
  ID3_FRAME_FLAG_V24_COMPRESSION         = 0x0008,
  ID3_FRAME_FLAG_V24_ENCRYPTION          = 0x0004,
  ID3_FRAME_FLAG_V24_UNSYNCHRONISATION   = 0x0002,
  ID3_FRAME_FLAG_V24_DATALENGTHINDICATOR = 0x0001
};

enum id3_field_type {
  ID3_FIELD_TYPE_TEXTENCODING,
  ID3_FIELD_TYPE_LATIN1,
  ID3_FIELD_TYPE_LATIN1LIST,
  ID3_FIELD_TYPE_STRING,
  ID3_FIELD_TYPE_STRINGFULL,
  ID3_FIELD_TYPE_STRINGLIST,
  ID3_FIELD_TYPE_LANGUAGE,
  ID3_FIELD_TYPE_FRAMEID,
  ID3_FIELD_TYPE_DATE,
  ID3_FIELD_TYPE_INT8,
  ID3_FIELD_TYPE_INT16,
  ID3_FIELD_TYPE_INT24,
  ID3_FIELD_TYPE_INT32,
  ID3_FIELD_TYPE_INT32PLUS,
  ID3_FIELD_TYPE_BINARYDATA
};

enum id3_field_textencoding {
  ISO_8859_1 = 0x00,
  UTF_16     = 0x01,
  UTF_16BE   = 0x02,
  UTF_8      = 0x03
};

typedef struct id3info {
  PerlIO *infile;
  char *file;
  Buffer *buf;
  HV *info;
  HV *tags;

  // scratch buffer used for UTF-8 decoding each frame
  Buffer *utf8;

  uint8_t version_major;
  uint8_t version_minor;
  uint8_t flags;
  uint8_t tag_data_safe;
  uint32_t size;
  uint32_t size_remain;
  off_t offset; // For non-MP3, offset into file where tag begins
} id3info;

typedef struct id3_compat {
  char const *id;
  char const *equiv;
} id3_compat;

typedef struct id3_frametype {
  char const *id;
  unsigned int nfields;
  enum id3_field_type const *fields;
  char const *description;
} id3_frametype;

extern struct id3_frametype const id3_frametype_text;
extern struct id3_frametype const id3_frametype_url;
extern struct id3_frametype const id3_frametype_experimental;
extern struct id3_frametype const id3_frametype_unknown;
extern struct id3_frametype const id3_frametype_obsolete;

int parse_id3(PerlIO *infile, char *file, HV *info, HV *tags, off_t seek, off_t file_size);
int _id3_parse_v1(id3info *id3);
int _id3_parse_v2(id3info *id3);
int _id3_parse_v2_frame(id3info *id3);
int _id3_parse_v2_frame_data(id3info *id3, char const *id, uint32_t size, id3_frametype const *frametype);
void _id3_set_array_tag(id3info *id3, char const *id, AV *framedata);
uint32_t _id3_get_v1_utf8_string(id3info *id3, SV **string, uint32_t len);
uint32_t _id3_get_utf8_string(id3info *id3, SV **string, uint32_t len, uint8_t encoding);
uint32_t _id3_parse_rvad(id3info *id3, char const *id, uint32_t size);
uint32_t _id3_parse_rgad(id3info *id3);
uint32_t _id3_parse_rva2(id3info *id3, uint32_t len, AV *framedata);
uint32_t _id3_parse_sylt(id3info *id3, uint8_t encoding, uint32_t len, AV *framedata);
uint32_t _id3_parse_etco(id3info *id3, uint32_t len, AV *framedata);
void _id3_convert_tdrc(id3info *id3);
uint32_t _id3_deunsync(unsigned char *data, uint32_t length);
void _id3_skip(id3info *id3, uint32_t size);
char const * _id3_genre_index(unsigned int index);
char const * _id3_genre_name(char const *string);
static id3_compat const * _id3_compat_lookup(register char const *, register unsigned int);
const struct id3_frametype * _id3_frametype_lookup(register const char *, register size_t);
