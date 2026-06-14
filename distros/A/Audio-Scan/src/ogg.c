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

#include "ogg.h"

int
get_ogg_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  return _ogg_parse(infile, file, info, tags, 0);
}

int
_ogg_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking)
{
  Buffer ogg_buf, vorbis_buf;
  unsigned char *bptr;
  unsigned int buf_size;

  unsigned int id3_size = 0; // size of leading ID3 data

  off_t file_size;           // total file size
  off_t audio_size;          // total size of audio without tags
  off_t audio_offset = 0;    // offset to audio

  unsigned char ogghdr[OGG_HEADER_SIZE];
  char header_type;
  int serialno;
  int final_serialno;
  int pagenum;
  uint8_t num_segments;
  int pagelen;
  int page = 0;
  int packets = 0;
  int streams = 0;

  unsigned char vorbishdr[23];
  unsigned char channels;
  unsigned int blocksize_0 = 0;
  unsigned int avg_buf_size;
  unsigned int samplerate = 0;
  unsigned int bitrate_nominal = 0;
  uint64_t granule_pos = 0;

  unsigned char vorbis_type = 0;

  int i;
  int err = 0;

  buffer_init(&ogg_buf, OGG_BLOCK_SIZE);
  buffer_init(&vorbis_buf, 0);

  file_size = _file_size(infile);
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
      streams++;
    }

    // Keep track of packet count
    if ( !(header_type & 0x01) ) {
      packets++;
    }

    // stop processing if we reach the 3rd packet and have no data
    if (packets > 2 * streams && !buffer_len(&vorbis_buf) ) {
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

    DEBUG_TRACE("OggS page %d / packet %d at %d\n", pagenum, packets, (int)(audio_offset - OGG_HEADER_SIZE));
    DEBUG_TRACE("  granule_pos: %llu\n", granule_pos);

    // If the granule_pos > 0, we have reached the end of headers and
    // this is the first audio page
    if (granule_pos > 0 && granule_pos != -1) {
      // If seeking, don't waste time on comments
      if (seeking) {
        break;
      }

      // Parse comments, but only if we have any extra data in the buffer
      if ( buffer_len(&vorbis_buf) > 0 ) {
        _parse_vorbis_comments(infile, &vorbis_buf, tags, 1);
        DEBUG_TRACE("  parsed vorbis comments\n");
      }

      buffer_clear(&vorbis_buf);

      break;
    }

    // Number of page segments
    num_segments = ogghdr[26];

    // Calculate total page size
    pagelen = ogghdr[27];
    if (num_segments > 1) {
      int i;

      if ( !_check_buf(infile, &ogg_buf, num_segments, OGG_BLOCK_SIZE) ) {
        err = -1;
        goto out;
      }

      for( i = 0; i < num_segments - 1; i++ ) {
        u_char x;
        x = buffer_get_char(&ogg_buf);
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

    audio_offset += pagelen;

    // Copy page into vorbis buffer
    buffer_append( &vorbis_buf, buffer_ptr(&ogg_buf), pagelen );
    DEBUG_TRACE("  Read %d into vorbis buffer\n", pagelen);

    // Process vorbis packet
    if ( !vorbis_type ) {
      vorbis_type = buffer_get_char(&vorbis_buf);
      // Verify 'vorbis' string
      if ( strncmp( buffer_ptr(&vorbis_buf), "vorbis", 6 ) ) {
        PerlIO_printf(PerlIO_stderr(), "Not a Vorbis file (bad vorbis header): %s\n", file);
        goto out;
      }
      buffer_consume( &vorbis_buf, 6 );

      DEBUG_TRACE("  Found vorbis packet type %d\n", vorbis_type);
    }

    if (vorbis_type == 1) {
      // Parse info
      // Grab 23-byte Vorbis header
      if ( buffer_len(&vorbis_buf) < 23 ) {
        PerlIO_printf(PerlIO_stderr(), "Not a Vorbis file (bad vorbis header): %s\n", file);
        goto out;
      }

      buffer_get(&vorbis_buf, vorbishdr, 23);

      my_hv_store( info, "version", newSViv( CONVERT_INT32LE(vorbishdr) ) );

      channels = vorbishdr[4];
      my_hv_store( info, "channels", newSViv(channels) );
      my_hv_store( info, "stereo", newSViv( channels == 2 ? 1 : 0 ) );

      samplerate = CONVERT_INT32LE((vorbishdr+5));
      my_hv_store( info, "samplerate", newSViv(samplerate) );
      my_hv_store( info, "bitrate_upper", newSViv( CONVERT_INT32LE((vorbishdr+9)) ) );

      bitrate_nominal = CONVERT_INT32LE((vorbishdr+13));
      my_hv_store( info, "bitrate_nominal", newSViv(bitrate_nominal) );
      my_hv_store( info, "bitrate_lower", newSViv( CONVERT_INT32LE((vorbishdr+17)) ) );

      blocksize_0 = 2 << ((vorbishdr[21] & 0xF0) >> 4);
      my_hv_store( info, "blocksize_0", newSViv( blocksize_0 ) );
      my_hv_store( info, "blocksize_1", newSViv( 2 << (vorbishdr[21] & 0x0F) ) );

      DEBUG_TRACE("  parsed vorbis info header\n");

      buffer_clear(&vorbis_buf);
      vorbis_type = 0;
    }

    // Skip rest of this page
    buffer_consume( &ogg_buf, pagelen );
  }

  buffer_clear(&ogg_buf);

  // audio_offset is 28 less because we read the Ogg header
  audio_offset -= OGG_HEADER_SIZE;

  // from the first packet past the comments
  my_hv_store( info, "audio_offset", newSViv(audio_offset) );

  audio_size = file_size - audio_offset;
  my_hv_store( info, "audio_size", newSVuv(audio_size) );

  my_hv_store( info, "serial_number", newSVuv(serialno) );

  // calculate average bitrate and duration
  avg_buf_size = blocksize_0 * 2;
  if ( file_size > avg_buf_size ) {
    DEBUG_TRACE("Seeking to %d to calculate bitrate/duration\n", (int)(file_size - avg_buf_size));
    PerlIO_seek(infile, file_size - avg_buf_size, SEEK_SET);
  }
  else {
    DEBUG_TRACE("Seeking to %d to calculate bitrate/duration\n", (int)audio_offset);
    PerlIO_seek(infile, audio_offset, SEEK_SET);
  }

  if ( PerlIO_read(infile, buffer_append_space(&ogg_buf, avg_buf_size), avg_buf_size) == 0 ) {
    if ( PerlIO_error(infile) ) {
      PerlIO_printf(PerlIO_stderr(), "Error reading: %s\n", strerror(errno));
    }
    else {
      PerlIO_printf(PerlIO_stderr(), "File too small. Probably corrupted.\n");
    }

    err = -1;
    goto out;
  }

  // Find sync
  bptr = (unsigned char *)buffer_ptr(&ogg_buf);
  buf_size = buffer_len(&ogg_buf);
  while (
    buf_size >= 14
    && (bptr[0] != 'O' || bptr[1] != 'g' || bptr[2] != 'g' || bptr[3] != 'S')
  ) {
    bptr++;
    buf_size--;

    if ( buf_size < 14 ) {
      // Give up, use less accurate bitrate for length
      DEBUG_TRACE("buf_size %d, using less accurate bitrate for length\n", buf_size);

      my_hv_store( info, "song_length_ms", newSVpvf( "%d", (int)((audio_size * 8) / bitrate_nominal) * 1000) );
      my_hv_store( info, "bitrate_average", newSViv(bitrate_nominal) );

      goto out;
    }
  }
  bptr += 6;

  // Get absolute granule value
  granule_pos = (uint64_t)CONVERT_INT32LE(bptr);
  bptr += 4;
  granule_pos |= (uint64_t)CONVERT_INT32LE(bptr) << 32;
  bptr += 4;

  // Get serial number of this page, if the serial doesn't match the beginning of the file
  // we have changed logical bitstreams and can't use the granule_pos for bitrate
  final_serialno = CONVERT_INT32LE((bptr));

  if ( granule_pos && samplerate && serialno == final_serialno ) {
    // XXX: needs to adjust for initial granule value if file does not start at 0 samples
    int length = (int)((granule_pos * 1.0 / samplerate) * 1000);
    my_hv_store( info, "song_length_ms", newSVuv(length) );
    my_hv_store( info, "bitrate_average", newSVuv( _bitrate(audio_size, length) ) );

    DEBUG_TRACE("Using granule_pos %llu / samplerate %d to calculate bitrate/duration\n", granule_pos, samplerate);
  }
  else {
    // Use nominal bitrate
    my_hv_store( info, "song_length_ms", newSVpvf( "%d", (int)((audio_size * 8) / bitrate_nominal) * 1000) );
    my_hv_store( info, "bitrate_average", newSVuv(bitrate_nominal) );

    DEBUG_TRACE("Using nominal bitrate for average\n");
  }

out:
  buffer_free(&ogg_buf);
  buffer_free(&vorbis_buf);

  if (err) return err;

  return 0;
}

void
_parse_vorbis_comments(PerlIO *infile, Buffer *vorbis_buf, HV *tags, int has_framing)
{
  unsigned int len;
  unsigned int num_comments;
  char *tmp;
  char *bptr;
  SV *vendor;

  // Vendor string
  len = buffer_get_int_le(vorbis_buf);
  vendor = newSVpvn( buffer_ptr(vorbis_buf), len );
  sv_utf8_decode(vendor);
  my_hv_store( tags, "VENDOR", vendor );
  buffer_consume(vorbis_buf, len);

  // Number of comments
  num_comments = buffer_get_int_le(vorbis_buf);

  while (num_comments--) {
    len = buffer_get_int_le(vorbis_buf);

    // Sanity check length
    if ( len > buffer_len(vorbis_buf) ) {
      DEBUG_TRACE("invalid Vorbis comment length: %u\n", len);
      return;
    }

    bptr = buffer_ptr(vorbis_buf);

    if (
#ifdef _MSC_VER
      !strnicmp(bptr, "METADATA_BLOCK_PICTURE=", 23)
#else
      !strncasecmp(bptr, "METADATA_BLOCK_PICTURE=", 23)
#endif
    ) {
      // parse METADATA_BLOCK_PICTURE according to http://wiki.xiph.org/VorbisComment#METADATA_BLOCK_PICTURE
      AV *pictures;
      HV *picture;
      Buffer pic_buf;
      uint32_t pic_length;

      buffer_consume(vorbis_buf, 23);

      // Copy picture into new buffer and base64 decode it
      buffer_init(&pic_buf, len - 23);
      buffer_append( &pic_buf, buffer_ptr(vorbis_buf), len - 23 );
      buffer_consume(vorbis_buf, len - 23);

      _decode_base64( buffer_ptr(&pic_buf) );

      picture = _decode_flac_picture(infile, &pic_buf, &pic_length);
      if ( !picture ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid Vorbis METADATA_BLOCK_PICTURE comment\n");
      }
      else {
        DEBUG_TRACE("  found picture of length %d\n", pic_length);

        if ( my_hv_exists(tags, "ALLPICTURES") ) {
          SV **entry = my_hv_fetch(tags, "ALLPICTURES");
          if (entry != NULL) {
            pictures = (AV *)SvRV(*entry);
            av_push( pictures, newRV_noinc( (SV *)picture ) );
          }
        }
        else {
          pictures = newAV();

          av_push( pictures, newRV_noinc( (SV *)picture ) );

          my_hv_store( tags, "ALLPICTURES", newRV_noinc( (SV *)pictures ) );
        }
      }

      buffer_free(&pic_buf);
    }
    else if (
#ifdef _MSC_VER
      !strnicmp(bptr, "COVERART=", 9)
#else
      !strncasecmp(bptr, "COVERART=", 9)
#endif
    ) {
      // decode COVERART into ALLPICTURES
      AV *pictures;
      HV *picture = newHV();

      // Fill in recommended default values for most of the picture hash
      my_hv_store( picture, "color_index", newSVuv(0) );
      my_hv_store( picture, "depth", newSVuv(0) );
      my_hv_store( picture, "description", newSVpvn("", 0) );
      my_hv_store( picture, "height", newSVuv(0) );
      my_hv_store( picture, "width", newSVuv(0) );
      my_hv_store( picture, "mime_type", newSVpvn("image/", 6) ); // As recommended, real mime should be in COVERARTMIME
      my_hv_store( picture, "picture_type", newSVuv(0) ); // Other

      if ( _env_true("AUDIO_SCAN_NO_ARTWORK") ) {
        my_hv_store( picture, "image_data", newSVuv(len - 9) );
        buffer_consume(vorbis_buf, len);
      }
      else {
        int pic_length;

        buffer_consume(vorbis_buf, 9);
        pic_length = _decode_base64( buffer_ptr(vorbis_buf) );
        DEBUG_TRACE("  found picture of length %d\n", pic_length);

        my_hv_store( picture, "image_data", newSVpvn( buffer_ptr(vorbis_buf), pic_length ) );
        buffer_consume(vorbis_buf, len - 9);
      }

      if ( my_hv_exists(tags, "ALLPICTURES") ) {
        SV **entry = my_hv_fetch(tags, "ALLPICTURES");
        if (entry != NULL) {
          pictures = (AV *)SvRV(*entry);
          av_push( pictures, newRV_noinc( (SV *)picture ) );
        }
      }
      else {
        pictures = newAV();

        av_push( pictures, newRV_noinc( (SV *)picture ) );

        my_hv_store( tags, "ALLPICTURES", newRV_noinc( (SV *)pictures ) );
      }
    }
    else {
      New(0, tmp, (int)len + 1, char);
      buffer_get(vorbis_buf, tmp, len);
      tmp[len] = '\0';

      _split_vorbis_comment( tmp, tags );

      Safefree(tmp);
    }
  }

  if (has_framing) {
    // Skip framing byte (Ogg only)
    buffer_consume(vorbis_buf, 1);
  }
}

static off_t
ogg_find_frame(PerlIO *infile, char *file, int offset)
{
  int frame_offset = -1;
  uint32_t samplerate;
  uint32_t song_length_ms;
  uint64_t target_sample;

  // We need to read all metadata first to get some data we need to calculate
  HV *info = newHV();
  HV *tags = newHV();
  if ( _ogg_parse(infile, file, info, tags, 1) != 0 ) {
    goto out;
  }

  song_length_ms = SvIV( *(my_hv_fetch( info, "song_length_ms" )) );
  if (offset >= song_length_ms) {
    goto out;
  }

  samplerate = SvIV( *(my_hv_fetch( info, "samplerate" )) );

  // Determine target sample we're looking for
  target_sample = (uint64_t)offset * samplerate / 1000;
  DEBUG_TRACE("Looking for target sample %llu\n", target_sample);

  frame_offset = _ogg_binary_search_sample(infile, file, info, target_sample);

out:
  // Don't leak
  SvREFCNT_dec(info);
  SvREFCNT_dec(tags);

  return frame_offset;
}

int
_ogg_binary_search_sample(PerlIO *infile, char *file, HV *info, uint64_t target_sample)
{
  Buffer buf;
  unsigned char *bptr;
  unsigned int buf_size;
  int frame_offset = -1;
  int best_frame_offset = -1;
  uint64_t granule_pos = 0;
  off_t low;
  off_t high;

  off_t audio_offset = SvIV( *(my_hv_fetch( info, "audio_offset" )) );
  off_t file_size    = SvIV( *(my_hv_fetch( info, "file_size" )) );
  uint32_t serialno  = SvIV( *(my_hv_fetch( info, "serial_number" )) );

  // Define the binary search range
  low  = audio_offset;
  high = file_size - OGG_HEADER_SIZE;

  buffer_init(&buf, OGG_MAX_PAGE_SIZE + OGG_HEADER_SIZE);

  while (high > low) {
    off_t mid;
    off_t page_start_offset = -1;
    uint32_t cur_serialno;
    int i; // Used by macro CONVERT_INT32LE

    // no point dividing the buffer in half if we don't potentially have a full header in each half
    if (high - low > 2 * OGG_HEADER_SIZE) {
      mid = low + ((high - low) / 2);
    } else {
      mid = low; // Fast-forward search
    }

    DEBUG_TRACE("Searching for sample %llu between %d and %d (mid %d)\n", target_sample, low, high, mid);

    if (mid > file_size - OGG_HEADER_SIZE) {
      DEBUG_TRACE("  Reached end of file, aborting\n");
      frame_offset = -1;
      goto out;
    }

    if (PerlIO_seek(infile, mid, SEEK_SET) == -1) {
      frame_offset = -1;
      goto out;
    }

    buffer_clear(&buf);

    // Worst case is:
    // ....OggS...<OGG_MAX_PAGE_SIZE>...OggS
    //      ^-mid                        ^-high
    //
    // To handle this, read OGG_HEADER_SIZE bytes extra after 'high'
    // so that we find the header that starts just before 'high'.
    // Still, the actual granule might be in the lower side of
    // the previous interval, so we'll need to get it later
    if (!_check_buf(infile, &buf, OGG_HEADER_SIZE,
      MIN(OGG_MAX_PAGE_SIZE, high - mid) + OGG_HEADER_SIZE)) {
      frame_offset = -1;
      goto out;
    }

    for (bptr = buffer_ptr(&buf), buf_size = buffer_len(&buf); ; ++bptr, --buf_size) {
      if (buf_size < 4) {
        // no page start found, force exit of outer loop
        DEBUG_TRACE("  no OggS in current buffer\n");
        break;
      }

      if (bptr[0] != 'O' || bptr[1] != 'g' || bptr[2] != 'g' || bptr[3] != 'S') {
        continue;
      }

      page_start_offset = buffer_len(&buf) - buf_size;
      frame_offset = mid + page_start_offset;

      break;
    }

    if (page_start_offset < 0) {
      DEBUG_TRACE("  nothing found in upper half, searching lower (best:%d)\n", best_frame_offset);
      DEBUG_TRACE("  searching between %d and %d (mid %d)\n", low, high, mid);
      high = mid;
      continue;
    }

    buffer_consume(&buf, page_start_offset);
    bptr = buffer_ptr(&buf);
    granule_pos = (uint64_t)CONVERT_INT32LE((bptr + 6));
    granule_pos |= (uint64_t)CONVERT_INT32LE((bptr + 10)) << 32;

    // Also read serial number, if this ever changes within a file it is a chained
    // file and we can't seek
    cur_serialno = CONVERT_INT32LE((bptr + 14));
    if (serialno != cur_serialno) {
      DEBUG_TRACE("  serial number changed to %x, aborting seek\n", cur_serialno);
      frame_offset = -1;
      goto out;
    }

    // if we are not on a usable granule, we need to frab it and it might be far ahead
    while (granule_pos == ULLONG_MAX) {
        uint16_t segments = *(bptr + 26);
        int page_len = OGG_HEADER_SIZE + segments - 1 + segments * 255;
        DEBUG_TRACE("  landed on unusable granule, next page in %hu (avail:%d)\n", page_len, buffer_len(&buf));

        // replenish enough to get next ogg header and then consume the current page
        if (buffer_len(&buf) < page_len + OGG_HEADER_SIZE) _check_buf(infile, &buf, page_len + OGG_HEADER_SIZE, OGG_MAX_PAGE_SIZE);
        buffer_consume(&buf, page_len);
        bptr = buffer_ptr(&buf);

        // safety measure
        if (memcmp(bptr, "OggS", 4)) {
            PerlIO_printf(PerlIO_stderr(), "error searching for usable granule: %s\n", file);
            frame_offset = -1;
            goto out;
        }

        // now evaluate if we finally reached a usable granule (we must be aligned)
        granule_pos = (uint64_t)CONVERT_INT32LE((bptr + 6));
        granule_pos |= (uint64_t)CONVERT_INT32LE((bptr + 10)) << 32;
    }

    DEBUG_TRACE("  checking frame at %d\n", frame_offset);

    if (granule_pos > target_sample) {
      best_frame_offset = frame_offset;
      DEBUG_TRACE("  searching lower (best:%d)\n", best_frame_offset);
      high = mid;
    }
    else if (granule_pos < target_sample) {
      DEBUG_TRACE("  searching higher (best:%d)\n", best_frame_offset);
      low = frame_offset + OGG_HEADER_SIZE;
    }
    else {
      DEBUG_TRACE("  found frame at %d\n", frame_offset);
      best_frame_offset = frame_offset;
      break;
    }
  }

  frame_offset = best_frame_offset;

out:
  buffer_free(&buf);
  return frame_offset;
}
