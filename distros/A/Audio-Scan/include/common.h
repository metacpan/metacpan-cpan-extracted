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
 
// Enable for debug output
//#define AUDIO_SCAN_DEBUG

#ifdef AUDIO_SCAN_DEBUG
# define DEBUG_TRACE(...) PerlIO_printf(PerlIO_stderr(), __VA_ARGS__)
#else
# define DEBUG_TRACE(...)
#endif

#define LOG_WARN(...) warn(__VA_ARGS__)

#if __GNUC__ > 2 || (__GNUC__ == 2 && __GNUC_MINOR__ > 4)
# define _PACKED __attribute((packed))
#else
# define _PACKED
#endif

#define DEFAULT_BLOCK_SIZE 4096

#ifndef _MSC_VER
// We use the built-in GUID type on Windows
typedef struct _GUID {
  uint32_t Data1;
  uint16_t Data2;
  uint16_t Data3;
  uint8_t  Data4[8];
} _PACKED GUID;
#endif

/* for PRIu64 */
#ifdef _MSC_VER
#include "pinttypes.h"
#else
#include <inttypes.h>
#endif

#define HAS_GUID
#include "buffer.h"

/* strlen the length automatically */
#define my_hv_store(a,b,c)     hv_store(a,b,strlen(b),c,0)
#define my_hv_store_ent(a,b,c) hv_store_ent(a,b,c,0)
#define my_hv_fetch(a,b)       hv_fetch(a,b,strlen(b),0)
#define my_hv_exists(a,b)      hv_exists(a,b,strlen(b))
#define my_hv_exists_ent(a,b)  hv_exists_ent(a,b,0)
#define my_hv_delete(a,b)      hv_delete(a,b,strlen(b),0)

#define GET_INT32BE(b) \
(i = (b[0] << 24) | (b[1] << 16) | b[2] << 8 | b[3], b += 4, i)

#define GET_INT16BE(b) \
(i = (b[0] << 8) | b[1], b += 2, i)

#define CONVERT_INT32LE(b) \
(i = (b[3] << 24) | (b[2] << 16) | b[1] << 8 | b[0], i)

int _check_buf(PerlIO *infile, Buffer *buf, int size, int min_size);
void _split_vorbis_comment(char* comment, HV* tags);
int32_t skip_id3v2(PerlIO *infile);
uint32_t _bitrate(uint32_t audio_size, uint32_t song_length_ms);
off_t _file_size(PerlIO *infile);
int _env_true(const char *name);
int _decode_base64(char *s);
HV * _decode_flac_picture(PerlIO *infile, Buffer *buf, uint32_t *pic_length);
