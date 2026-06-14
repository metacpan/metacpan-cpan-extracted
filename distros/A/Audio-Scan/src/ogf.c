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

#include "ogf.h"
#include "ogg.h"
#include "flac.h"

#pragma pack(push, 1)
typedef struct {
        char tag[4];
        uint8_t version, flag;
        uint64_t granule_pos;
        uint32_t serialno, page_num;
        uint32_t checksum;
        uint8_t segments;
} ogg_header_t;

typedef struct {
    uint8_t type;
    char signature[4];
    uint8_t maj;
    uint8_t min;
    uint16_t num_headers;
    struct {
        char tag[4];
        uint8_t type;
        uint8_t size[3];
    } header;
    struct {
        uint16_t min_block_size;
        uint16_t max_block_size;
        uint8_t min_frame_size[3];
        uint8_t max_frame_size[3];
        uint8_t combo[4];
        uint8_t sample_count[4];
        uint8_t md5[16];
    } streaminfo;
} flac_page_t;
#pragma pack(pop)

uint32_t compute_crc32(uint8_t *data, size_t n);

static int32_t
__le32toh__(int32_t n)
{
#if (__BYTE_ORDER__ == __ORDER_LITTLE_ENDIAN__)
	return n;
#else
	return __builtin_bswap32(n);
#endif
}

/* https://xiph.org/ogg/doc/framing.html
 * https://xiph.org/flac/ogg_mapping.html
 * https://xiph.org/vorbis/doc/Vorbis_I_spec.html#x1-610004.2 */

int
get_ogf_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  return _ogf_parse(infile, file, info, tags, 0);
}

static int
_ogf_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking)
{
  Buffer ogg_buf;
  //Buffer vorbis_buf;
  unsigned char *bptr;
  unsigned char *last_bptr;
  unsigned int buf_size;
  unsigned int id3_size = 0; // size of leading ID3 data
  uint32_t song_length_ms = 0;

  off_t file_size;           // total file size
  off_t audio_size;          // total size of audio without tags
  off_t audio_offset = 0;    // offset to audio
  off_t seek_position;

  unsigned char ogghdr[OGG_HEADER_SIZE];
  char header_type;
  int serialno;
  uint64_t our_serialno = ULLONG_MAX;
  int final_serialno;
  int pagenum;
  uint8_t num_segments;
  int pagelen;
  int page = 0;
  int packets = 0;
  int streams = 0;
  int i;
  int err = 0;

  short num_headers = 0;

  unsigned char opushdr[11];
  unsigned char channels;
  unsigned int input_samplerate = 0;
  uint64_t granule_pos = 0;

  unsigned char TOC_byte = 0;

  flacinfo *flac;
  Newz(0, flac, sizeof(flacinfo), flacinfo);
  Newz(0, flac->buf, sizeof(Buffer), Buffer);

  flac->infile         = infile;
  flac->file           = file;
  flac->info           = info;
  flac->tags           = tags;
  flac->audio_offset   = 0;
  flac->seeking        = seeking ? 1 : 0;
  flac->num_seekpoints = 0;

  buffer_init(flac->buf, 0);

  flac->file_size = _file_size(infile);

  buffer_init(&ogg_buf, OGG_BLOCK_SIZE);

  file_size = _file_size(infile);
  if (file_size < 0) {
    PerlIO_printf(PerlIO_stderr(), "no file found: %s\n", file);
    err = -1;
    goto out;
  }

  my_hv_store( info, "file_size", newSVuv(file_size) );

  if ( !_check_buf(infile, &ogg_buf, 10, OGG_BLOCK_SIZE) ) {
    err = -1;
    goto out;
  }

  // Skip ID3 tags if any
  bptr = (unsigned char *)buffer_ptr(&ogg_buf);
  if (
    (bptr[0] == 'I' && bptr[1] == 'D' && bptr[2] == '3') &&
    bptr[3] < 0xff && bptr[4] < 0xff &&
    bptr[6] < 0x80 && bptr[7] < 0x80 && bptr[8] < 0x80 && bptr[9] < 0x80
  ) {
    /* found an ID3 header... */
    id3_size = 10 + (bptr[6]<<21) + (bptr[7]<<14) + (bptr[8]<<7) + bptr[9];

    if (bptr[5] & 0x10) {
      // footer present
      id3_size += 10;
    }

    buffer_clear(&ogg_buf);

    audio_offset += id3_size;

    DEBUG_TRACE("Skipping ID3v2 tag of size %d\n", id3_size);

    PerlIO_seek(infile, id3_size, SEEK_SET);
  }

  while (1) {
    bool full_packet = true;

    // Grab 28-byte Ogg header
    if ( !_check_buf(infile, &ogg_buf, OGG_HEADER_SIZE, OGG_BLOCK_SIZE) ) {
      err = -1;
      goto out;
    }

    buffer_get(&ogg_buf, ogghdr, OGG_HEADER_SIZE);

    audio_offset += OGG_HEADER_SIZE;

    // check that the first four bytes are 'OggS'
    if ( ogghdr[0] != 'O' || ogghdr[1] != 'g' || ogghdr[2] != 'g' || ogghdr[3] != 'S' ) {
      PerlIO_printf(PerlIO_stderr(), "Not an Ogg file (bad OggS header): %s\n", file);
      err = -1;
      goto out;
    }

    // Header type flag
    header_type = ogghdr[5];

    // Absolute granule position, used to find the first audio page
    bptr = ogghdr + 6;
    granule_pos = (uint64_t)CONVERT_INT32LE(bptr);
    bptr += 4;
    granule_pos |= (uint64_t)CONVERT_INT32LE(bptr) << 32;

    // Stream serial number
    serialno = CONVERT_INT32LE((ogghdr+14));

    // Count start-of-stream pages
    if ( header_type & 0x02 ) {
      // we only care about first stream (and no multiplex)
      if (our_serialno == ULLONG_MAX) our_serialno = serialno;
      streams++;
    }

    // stop processing if we reach the 3rd packet and have no data
    if (!num_headers && packets > 2 * streams && !buffer_len(flac->buf) ) {
      break;
    }

    // Page seq number
    pagenum = CONVERT_INT32LE((ogghdr+18));

    if (page >= 0 && page == pagenum) {
      page++;
    }
    else {
      page = -1;
      DEBUG_TRACE("Missing page(s) in Ogg file: %s\n", file);
    }

    // Number of page segments
    num_segments = ogghdr[26];

    // Calculate total page size
    pagelen = ogghdr[27];
    if (num_segments > 1) {
      int i;
      full_packet = false;

      if ( !_check_buf(infile, &ogg_buf, num_segments, OGG_BLOCK_SIZE) ) {
        err = -1;
        goto out;
      }

      for( i = 0; i < num_segments - 1; i++ ) {
        u_char x;
        x = buffer_get_char(&ogg_buf);
        // detect packet termination(s) - there is only one packet per page in OggFlac
        if (x < 255) full_packet = true;
        pagelen += x;
      }

      audio_offset += num_segments - 1;
    }

    if ( !_check_buf(infile, &ogg_buf, pagelen, OGG_BLOCK_SIZE) ) {
      err = -1;
      goto out;
    }

    // Still don't have enough data, must have reached the end of the file
    if ( buffer_len(&ogg_buf) < pagelen ) {
      PerlIO_printf(PerlIO_stderr(), "Premature end of file: %s\n", file);
      err = -1;
      goto out;
    }

    DEBUG_TRACE("OggS page %d (len:%d+28, sn:%u) at %d\n", pagenum, pagelen, serialno, (int)(audio_offset - OGG_HEADER_SIZE));
    if (granule_pos != ULLONG_MAX) DEBUG_TRACE("  granule_pos: %llu\n", granule_pos);
    else DEBUG_TRACE("  granule_pos: -1\n");

    audio_offset += pagelen;

    // if this is not for us, just consume data
    if (serialno != our_serialno) {
      buffer_consume( &ogg_buf, pagelen );
      continue;
    } else if (granule_pos && granule_pos != -1) {
      PerlIO_printf(PerlIO_stderr(), "Audio granule before end of headers\n");
      err = -1;
      goto out;
    }

    DEBUG_TRACE("  Append %d into buffer\n", pagelen);
    buffer_append( flac->buf, buffer_ptr(&ogg_buf), pagelen );

    if (!full_packet) {
      buffer_consume( &ogg_buf, pagelen );
      continue;
    } else {
      packets++;
    }

    // we have a full packet in buffer, let's process it
    TOC_byte = buffer_get_char(flac->buf);
    DEBUG_TRACE("Packet number %d\n", packets);

    // Process \x7fFLAC packet
    if ( TOC_byte == 0x7f ) {
      DEBUG_TRACE("First packet");
      if ( strncmp( buffer_ptr(flac->buf), "FLAC", 4 ) == 0) {
        buffer_consume(flac->buf, 4+2);
        num_headers = buffer_get_short(flac->buf);
        DEBUG_TRACE("  Found OggFlac tags TOC packet type with %hu headers\n", num_headers);
        if ( strncmp( buffer_ptr(flac->buf), "fLaC", 4 ) != 0) {
          PerlIO_printf(PerlIO_stderr(), "Not an OggFlac (fLaC) file: %s\n", file);
          err = -1;
          goto out;
        }
        buffer_consume(flac->buf, 8);
        _flac_parse_streaminfo(flac);
      }
      else {
        PerlIO_printf(PerlIO_stderr(), "Not and OggFlac (FLAC) file: %s\n", file);
        err = -1;
        goto out;
      }
    } else {
      DEBUG_TRACE("Parsing header type %d\n", TOC_byte & 0x7f);
      if (!seeking) {
        uint8_t type = TOC_byte & 0x7f;
        buffer_consume(flac->buf, 3);

        if (type == FLAC_TYPE_VORBIS_COMMENT) {
          DEBUG_TRACE("Parsing vorbis_comment\n");
          _parse_vorbis_comments(infile, flac->buf, tags, 0);
        } else if (type == FLAC_TYPE_PICTURE) {
          DEBUG_TRACE("Parsing picture\n");
          if (!_flac_parse_picture(flac)) {
            err = -1;
            goto out;
          }
        }
      }
      if (TOC_byte & 0x80 || (num_headers && packets == num_headers + 1)) {
          DEBUG_TRACE("Last header\n");
          break;
      }
    }

    // this page belongs to a new packet
    buffer_clear(flac->buf);
    buffer_consume( &ogg_buf, pagelen );
  }

  DEBUG_TRACE("All headers parsed, now doing audio\n");

  // from the first packet past the comments
  my_hv_store( info, "audio_offset", newSViv(audio_offset) );

  audio_size = file_size - audio_offset;
  my_hv_store( info, "audio_size", newSVuv(audio_size) );

  my_hv_store( info, "serial_number", newSVuv(our_serialno) );

  song_length_ms = SvIV( *( my_hv_fetch(info, "song_length_ms") ) );

  if (song_length_ms > 0) {
     my_hv_store( info, "bitrate", newSVuv( _bitrate(audio_size, song_length_ms) ) );
  }

  // find the last Ogg page

#define BUF_SIZE 8500 // from vlc

  if (file_size < audio_offset + OGG_HEADER_SIZE) goto out;
  
  seek_position = file_size - BUF_SIZE;
  while (1) {
    if ( seek_position < audio_offset ) {
      seek_position = audio_offset;
    }

    // calculate average bitrate and duration
    DEBUG_TRACE("Seeking to %d to calculate bitrate/duration\n", (int)seek_position);
    PerlIO_seek(infile, seek_position, SEEK_SET);

    buffer_clear(&ogg_buf);

    if ( !_check_buf(infile, &ogg_buf, OGG_HEADER_SIZE, BUF_SIZE) ) {
      err = -1;
      goto out;
    }

    // Find sync
    bptr = (unsigned char *)buffer_ptr(&ogg_buf);
    buf_size = buffer_len(&ogg_buf);
    last_bptr = bptr;
    // make sure we have room for at least the one ogg page header
    while (buf_size >= OGG_HEADER_SIZE) {
      if (bptr[0] == 'O' && bptr[1] == 'g' && bptr[2] == 'g' && bptr[3] == 'S') {
        bptr += 6;

        // Get absolute granule value
        granule_pos = (uint64_t)CONVERT_INT32LE(bptr);
        bptr += 4;
        granule_pos |= (uint64_t)CONVERT_INT32LE(bptr) << 32;
        bptr += 4;
        DEBUG_TRACE("found granule_pos %llu / samplerate %d to calculate bitrate/duration\n", granule_pos, flac->samplerate);
        //XXX: jump the header size
        last_bptr = bptr;
      }
      else {
        bptr++;
        buf_size--;
      }
    }
    bptr = last_bptr;

    // Get serial number of this page, if the serial doesn't match the beginning of the file
    // we have changed logical bitstreams and can't use the granule_pos for bitrate
    final_serialno = CONVERT_INT32LE((bptr));

    if ( granule_pos && flac->samplerate && our_serialno == final_serialno ) {
      // XXX: needs to adjust for initial granule value if file does not start at 0 samples
      int length = (int)(((granule_pos) * 1.0 / flac->samplerate) * 1000);
      if (!song_length_ms) my_hv_store( info, "song_length_ms", newSVuv(length) );
      my_hv_store( info, "bitrate_ogg", newSVuv( _bitrate(audio_size, length) ) );

      DEBUG_TRACE("Using granule_pos %llu / samplerate %d to calculate bitrate/duration\n", granule_pos, flac->samplerate);
      break;
    }
    if ( !song_length_ms && seek_position == audio_offset ) {
      DEBUG_TRACE("Packet not found we won't be able to determine the length\n");
      break;
    }
    // seek backwards by BUF_SIZE - OGG_HEADER_SIZE so that if our previous sync happened to include the end
    // of page header we will include it in the next read
    seek_position -= (BUF_SIZE - OGG_HEADER_SIZE);
  }

out:
  buffer_free(&ogg_buf);

  buffer_free(flac->buf);
  Safefree(flac->buf);

  DEBUG_TRACE("Err %d\n", err);
  return err;
}

off_t
ogf_find_frame(PerlIO *infile, char *file, int offset)
{
  HV *info = newHV();
  HV *tags = newHV();
  int frame_offset = -1;

  if (offset < 0) {
    goto out;
  }

  frame_offset = _ogf_find_frame(infile, file, offset, info, tags);

out:
  // Don't leak
  SvREFCNT_dec(info);
  SvREFCNT_dec(tags);

  return frame_offset;
}

static off_t
_ogf_find_frame(PerlIO *infile, char *file, int offset, HV *info, HV *tags)
{
  int frame_offset = -1;
  uint32_t samplerate;
  uint32_t song_length_ms;
  uint64_t target_sample;

  DEBUG_TRACE("Find_frame %d in %s\n", offset, file);

  // We need to read all metadata first to get some data we need to calculate
  if ( _ogf_parse(infile, file, info, tags, 1) != 0 ) {
    goto out;
  }

  song_length_ms = SvUV( *(my_hv_fetch( info, "song_length_ms" )) );
  if (offset >= song_length_ms) {
    goto out;
  }

  // Determine target sample we're looking for
  samplerate = SvIV( *(my_hv_fetch( info, "samplerate" )) );
  target_sample = (uint64_t)offset * samplerate / 1000;

  DEBUG_TRACE("Looking for target sample %llu\n", target_sample);
  frame_offset = _ogg_binary_search_sample(infile, file, info, target_sample);

out:
  return frame_offset;
}

// offset is in ms
int
ogf_find_frame_return_info(PerlIO *infile, char *file, int offset, HV *info)
{
  int err = -1;
  HV *tags = newHV();
  int frame_offset = _ogf_find_frame(infile, file, offset, info, tags);

  // finally adjust STREAMINFO header
  if (frame_offset >= 0) {
    Buffer buf;
    flac_page_t *page;
    ogg_header_t *header;
    uint32_t audio_offset = SvIV( *(my_hv_fetch( info, "audio_offset" )) );

    // don't understand my mp4.c does not seek here...
    PerlIO_seek(infile, 0, SEEK_SET);
    buffer_init(&buf, OGG_MAX_PAGE_SIZE + OGG_HEADER_SIZE);

    // there is only one segment in header
    _check_buf(infile, &buf, OGG_MAX_PAGE_SIZE, OGG_MAX_PAGE_SIZE + OGG_HEADER_SIZE);
    header = buffer_ptr(&buf);
    page = buffer_ptr(&buf) + sizeof(*header) + 1;

    DEBUG_TRACE("now reading vorbis comment\n");

    // 1st page is 1st packet and with single lacing value
    if (!strncmp(header->tag, "OggS", 4) && page->type == 0x7f &&
        !strncmp(page->signature, "FLAC", 4) && !strncmp(page->header.tag, "fLaC", 4)) {
        SV* seek_header = newSVpv("", 0);
        int page_count = 0;
        bool done = false;
        off_t page_len = sizeof(*header) + 1 + sizeof(*page);

        page->streaminfo.combo[3] &= 0xf0;
        memset(page->streaminfo.sample_count, 0, sizeof(page->streaminfo.sample_count));
        memset(page->streaminfo.md5, 0, sizeof(page->streaminfo.md5));
        page->num_headers = 1;
#if (__BYTE_ORDER__ != __ORDER_LITTLE_ENDIAN__)
        page->num_headers <<= 8;
#endif        
        header->checksum = 0;
        header->checksum = __le32toh__(compute_crc32(buffer_ptr(&buf), page_len));

        // store the updated OggFlac first packet/page (same in this case)
        sv_catpvn( seek_header, (char*) buffer_ptr(&buf), page_len);   

        // now we need to keep the 1st page (vorbis comment) and the rest is useless
        do {
            int i;
            uint8_t *ptr;

            // replenish what we consumed to that we have a full buffer
            buffer_consume(&buf, page_len);
            _check_buf(infile, &buf, page_len, page_len);
            page_len = 0;

            header = buffer_ptr(&buf);
            ptr = buffer_ptr(&buf) + sizeof(*header) + 1;
            
            // make sure this is a page
            if (memcmp(header->tag, "OggS", 4)) {
                PerlIO_printf(PerlIO_stderr(), "error reading vorbis comment (%s)\n", file);
                buffer_free(&buf);
                SvREFCNT_dec(seek_header);
                goto out;
            }

            if (header->granule_pos == ULLONG_MAX) {
                page_len = header->segments * 255;
            } else for (ptr = buffer_ptr(&buf) + sizeof(*header), i = 0; i < header->segments && !done; i++, ptr++) {
                page_len += *ptr;
                if (*ptr != 255) done = true;
            }         

            page_len += sizeof(*header) + header->segments;
            
            // this is the last flac header, need to to set VORBIS_COMMENT as last header and update crc
            if (page_count++ == 0) {
                ptr = buffer_ptr(&buf) + sizeof(*header) + header->segments;
                *ptr = 0x80 | FLAC_TYPE_VORBIS_COMMENT;
                header->checksum = 0;
                header->checksum = __le32toh__(compute_crc32(buffer_ptr(&buf), page_len));
                DEBUG_TRACE("found vorbis comment header\n", page_len, header->segments);
            }
            
            sv_catpvn( seek_header, (char*) buffer_ptr(&buf), page_len );
            DEBUG_TRACE("adding page %d of len:%d with %d segments\n", page_count, page_len, header->segments);
        } while (!done);

        my_hv_store( info, "seek_header", seek_header );
    }

    err = 1;
    buffer_free(&buf);
  }

out:
  // Don't leak
  SvREFCNT_dec(tags);
  if (frame_offset != -1) {
    my_hv_store( info, "seek_offset", newSVuv(frame_offset) );
  }
  return err;
}

uint32_t crc32_table[] = {
0x00000000,0x04C11DB7,0x09823B6E,0x0D4326D9,0x130476DC,0x17C56B6B,0x1A864DB2,0x1E475005,
0x2608EDB8,0x22C9F00F,0x2F8AD6D6,0x2B4BCB61,0x350C9B64,0x31CD86D3,0x3C8EA00A,0x384FBDBD,
0x4C11DB70,0x48D0C6C7,0x4593E01E,0x4152FDA9,0x5F15ADAC,0x5BD4B01B,0x569796C2,0x52568B75,
0x6A1936C8,0x6ED82B7F,0x639B0DA6,0x675A1011,0x791D4014,0x7DDC5DA3,0x709F7B7A,0x745E66CD,
0x9823B6E0,0x9CE2AB57,0x91A18D8E,0x95609039,0x8B27C03C,0x8FE6DD8B,0x82A5FB52,0x8664E6E5,
0xBE2B5B58,0xBAEA46EF,0xB7A96036,0xB3687D81,0xAD2F2D84,0xA9EE3033,0xA4AD16EA,0xA06C0B5D,
0xD4326D90,0xD0F37027,0xDDB056FE,0xD9714B49,0xC7361B4C,0xC3F706FB,0xCEB42022,0xCA753D95,
0xF23A8028,0xF6FB9D9F,0xFBB8BB46,0xFF79A6F1,0xE13EF6F4,0xE5FFEB43,0xE8BCCD9A,0xEC7DD02D,
0x34867077,0x30476DC0,0x3D044B19,0x39C556AE,0x278206AB,0x23431B1C,0x2E003DC5,0x2AC12072,
0x128E9DCF,0x164F8078,0x1B0CA6A1,0x1FCDBB16,0x018AEB13,0x054BF6A4,0x0808D07D,0x0CC9CDCA,
0x7897AB07,0x7C56B6B0,0x71159069,0x75D48DDE,0x6B93DDDB,0x6F52C06C,0x6211E6B5,0x66D0FB02,
0x5E9F46BF,0x5A5E5B08,0x571D7DD1,0x53DC6066,0x4D9B3063,0x495A2DD4,0x44190B0D,0x40D816BA,
0xACA5C697,0xA864DB20,0xA527FDF9,0xA1E6E04E,0xBFA1B04B,0xBB60ADFC,0xB6238B25,0xB2E29692,
0x8AAD2B2F,0x8E6C3698,0x832F1041,0x87EE0DF6,0x99A95DF3,0x9D684044,0x902B669D,0x94EA7B2A,
0xE0B41DE7,0xE4750050,0xE9362689,0xEDF73B3E,0xF3B06B3B,0xF771768C,0xFA325055,0xFEF34DE2,
0xC6BCF05F,0xC27DEDE8,0xCF3ECB31,0xCBFFD686,0xD5B88683,0xD1799B34,0xDC3ABDED,0xD8FBA05A,
0x690CE0EE,0x6DCDFD59,0x608EDB80,0x644FC637,0x7A089632,0x7EC98B85,0x738AAD5C,0x774BB0EB,
0x4F040D56,0x4BC510E1,0x46863638,0x42472B8F,0x5C007B8A,0x58C1663D,0x558240E4,0x51435D53,
0x251D3B9E,0x21DC2629,0x2C9F00F0,0x285E1D47,0x36194D42,0x32D850F5,0x3F9B762C,0x3B5A6B9B,
0x0315D626,0x07D4CB91,0x0A97ED48,0x0E56F0FF,0x1011A0FA,0x14D0BD4D,0x19939B94,0x1D528623,
0xF12F560E,0xF5EE4BB9,0xF8AD6D60,0xFC6C70D7,0xE22B20D2,0xE6EA3D65,0xEBA91BBC,0xEF68060B,
0xD727BBB6,0xD3E6A601,0xDEA580D8,0xDA649D6F,0xC423CD6A,0xC0E2D0DD,0xCDA1F604,0xC960EBB3,
0xBD3E8D7E,0xB9FF90C9,0xB4BCB610,0xB07DABA7,0xAE3AFBA2,0xAAFBE615,0xA7B8C0CC,0xA379DD7B,
0x9B3660C6,0x9FF77D71,0x92B45BA8,0x9675461F,0x8832161A,0x8CF30BAD,0x81B02D74,0x857130C3,
0x5D8A9099,0x594B8D2E,0x5408ABF7,0x50C9B640,0x4E8EE645,0x4A4FFBF2,0x470CDD2B,0x43CDC09C,
0x7B827D21,0x7F436096,0x7200464F,0x76C15BF8,0x68860BFD,0x6C47164A,0x61043093,0x65C52D24,
0x119B4BE9,0x155A565E,0x18197087,0x1CD86D30,0x029F3D35,0x065E2082,0x0B1D065B,0x0FDC1BEC,
0x3793A651,0x3352BBE6,0x3E119D3F,0x3AD08088,0x2497D08D,0x2056CD3A,0x2D15EBE3,0x29D4F654,
0xC5A92679,0xC1683BCE,0xCC2B1D17,0xC8EA00A0,0xD6AD50A5,0xD26C4D12,0xDF2F6BCB,0xDBEE767C,
0xE3A1CBC1,0xE760D676,0xEA23F0AF,0xEEE2ED18,0xF0A5BD1D,0xF464A0AA,0xF9278673,0xFDE69BC4,
0x89B8FD09,0x8D79E0BE,0x803AC667,0x84FBDBD0,0x9ABC8BD5,0x9E7D9662,0x933EB0BB,0x97FFAD0C,
0xAFB010B1,0xAB710D06,0xA6322BDF,0xA2F33668,0xBCB4666D,0xB8757BDA,0xB5365D03,0xB1F740B4
};

uint32_t compute_crc32(uint8_t *data, size_t n) {
  uint32_t crc = 0;

  while (n--) {
    uint8_t pos = (crc ^ (((uint32_t) *data++) << 24)) >> 24;
    crc = (crc << 8) ^ crc32_table[pos];
  }

  return crc;
}
