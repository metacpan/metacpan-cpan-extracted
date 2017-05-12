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

#include "id3.h"
#include "id3_genre.dat"
#include "id3_compat.c"
#include "id3_frametype.c"

#define NGENRES (sizeof(genre_table) / sizeof(genre_table[0]))

// Read an int from a variable number of bytes
static int
_varint(unsigned char *buf, int length)
{
  int i, b, number = 0;

  if (buf) {
    for ( i = 0; i < length; i++ ) {
      b = length - 1 - i;
      number = number | (unsigned int)( buf[i] & 0xff ) << ( 8*b );
    }
    return number;
  }
  else {
    return 0;
  }
}

int
parse_id3(PerlIO *infile, char *file, HV *info, HV *tags, uint32_t seek, off_t file_size)
{
  int err = 0;
  unsigned char *bptr;

  id3info *id3;
  Newz(0, id3, sizeof(id3info), id3info);
  Newz(0, id3->buf, sizeof(Buffer), Buffer);
  Newz(0, id3->utf8, sizeof(Buffer), Buffer);

  id3->infile = infile;
  id3->file   = file;
  id3->info   = info;
  id3->tags   = tags;
  id3->offset = seek;

  buffer_init(id3->buf, ID3_BLOCK_SIZE);

  if ( !seek ) {
    // Check for ID3v1 tag first
    PerlIO_seek(infile, file_size - 128, SEEK_SET);
    if ( !_check_buf(infile, id3->buf, 128, 128) ) {
      err = -1;
      goto out;
    }

    bptr = buffer_ptr(id3->buf);
    if (bptr[0] == 'T' && bptr[1] == 'A' && bptr[2] == 'G') {
      _id3_parse_v1(id3);
    }
  }

  // Check for ID3v2 tag
  PerlIO_seek(infile, seek, SEEK_SET);
  buffer_clear(id3->buf);

  // Read enough for header (10) + extended header size (4)
  if ( !_check_buf(infile, id3->buf, 14, ID3_BLOCK_SIZE) ) {
    err = -1;
    goto out;
  }

  bptr = buffer_ptr(id3->buf);
  if (bptr[0] == 'I' && bptr[1] == 'D' && bptr[2] == '3') {
    _id3_parse_v2(id3);
  }

out:
  buffer_free(id3->buf);
  Safefree(id3->buf);

  if (id3->utf8->alloc)
    buffer_free(id3->utf8);
  Safefree(id3->utf8);

  Safefree(id3);

  return err;
}

int
_id3_parse_v1(id3info *id3)
{
  SV *tmp = NULL;
  uint8_t read = 0;
  unsigned char *bptr;
  uint8_t comment_len;
  uint8_t genre;

  buffer_consume(id3->buf, 3); // TAG

  read = _id3_get_v1_utf8_string(id3, &tmp, 30);
  if (tmp && SvPOK(tmp) && sv_len(tmp)) {
    DEBUG_TRACE("ID3v1 title: %s\n", SvPVX(tmp));
    my_hv_store( id3->tags, ID3_FRAME_TITLE, tmp );
  }
  else {
    if (tmp) SvREFCNT_dec(tmp);
  }
  if (read < 30) {
    buffer_consume(id3->buf, 30 - read);
  }

  tmp = NULL;
  read = _id3_get_v1_utf8_string(id3, &tmp, 30);
  if (tmp && SvPOK(tmp) && sv_len(tmp)) {
    DEBUG_TRACE("ID3v1 artist: %s\n", SvPVX(tmp));
    my_hv_store( id3->tags, ID3_FRAME_ARTIST, tmp );
    tmp = NULL;
  }
  else {
    if (tmp) SvREFCNT_dec(tmp);
  }
  if (read < 30) {
    buffer_consume(id3->buf, 30 - read);
  }

  tmp = NULL;
  read = _id3_get_v1_utf8_string(id3, &tmp, 30);
  if (tmp && SvPOK(tmp) && sv_len(tmp)) {
    DEBUG_TRACE("ID3v1 album: %s\n", SvPVX(tmp));
    my_hv_store( id3->tags, ID3_FRAME_ALBUM, tmp );
    tmp = NULL;
  }
  else {
    if (tmp) SvREFCNT_dec(tmp);
  }
  if (read < 30) {
    buffer_consume(id3->buf, 30 - read);
  }

  tmp = NULL;
  read = _id3_get_v1_utf8_string(id3, &tmp, 4);
  if (tmp && SvPOK(tmp) && sv_len(tmp)) {
    DEBUG_TRACE("ID3v1 year: %s\n", SvPVX(tmp));
    my_hv_store( id3->tags, ID3_FRAME_YEAR, tmp );
    tmp = NULL;
  }
  else {
    if (tmp) SvREFCNT_dec(tmp);
  }
  if (read < 4) {
    buffer_consume(id3->buf, 4 - read);
  }

  bptr = buffer_ptr(id3->buf);
  if (bptr[28] == 0 && bptr[29] != 0) {
    // ID3v1.1 track number is present
    comment_len = 28;
    my_hv_store( id3->tags, ID3_FRAME_TRACK, newSVuv(bptr[29]) );
    my_hv_store( id3->info, "id3_version", newSVpv( "ID3v1.1", 0 ) );
  }
  else {
    comment_len = 30;
    my_hv_store( id3->info, "id3_version", newSVpv( "ID3v1", 0 ) );
  }

  tmp = NULL;
  read = _id3_get_v1_utf8_string(id3, &tmp, comment_len);
  if (tmp && SvPOK(tmp) && sv_len(tmp)) {
    AV *comment_array = newAV();
    av_push( comment_array, newSVpvn("XXX", 3) );
    av_push( comment_array, newSVpvn("", 0) );
    av_push( comment_array, tmp );
    DEBUG_TRACE("ID3v1 comment: %s\n", SvPVX(tmp));
    my_hv_store( id3->tags, ID3_FRAME_COMMENT, newRV_noinc( (SV *)comment_array ) );
    tmp = NULL;
  }
  else {
    if (tmp) SvREFCNT_dec(tmp);
  }
  if (read < 30) {
    buffer_consume(id3->buf, 30 - read);
  }

  genre = buffer_get_char(id3->buf);
  if (genre < NGENRES) {
    char const *genre_string = _id3_genre_index(genre);
    my_hv_store( id3->tags, ID3_FRAME_GENRE, newSVpv(genre_string, 0) );
  }
  else if (genre < 255) {
    my_hv_store( id3->tags, ID3_FRAME_GENRE, newSVpvf("Unknown/%d", genre) );
  }

  return 1;
}

int
_id3_parse_v2(id3info *id3)
{
  int ret = 1;
  unsigned char *bptr;

  // Verify we have a valid tag
  bptr = buffer_ptr(id3->buf);
  if ( !(
    bptr[3] < 0xff && bptr[4] < 0xff &&
    bptr[6] < 0x80 && bptr[7] < 0x80 && bptr[8] < 0x80 && bptr[9] < 0x80
  ) ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid ID3v2 tag in %s\n", id3->file);
    return 0;
  }

  buffer_consume(id3->buf, 3); // ID3

  id3->version_major = buffer_get_char(id3->buf);
  id3->version_minor = buffer_get_char(id3->buf);
  id3->flags         = buffer_get_char(id3->buf);
  id3->size          = 10 + buffer_get_syncsafe(id3->buf, 4);

  id3->size_remain = id3->size - 10;

  if (id3->flags & ID3_TAG_FLAG_FOOTERPRESENT) {
    id3->size += 10;
  }

  DEBUG_TRACE("Parsing ID3v2.%d.%d tag, flags %x, size %d\n", id3->version_major, id3->version_minor, id3->flags, id3->size);

  if (id3->flags & ID3_TAG_FLAG_UNSYNCHRONISATION) {
    if (id3->version_major < 4) {
      // It's unclear but the v2.4.0-changes document seems to say that v2.4 should
      // ignore the tag-level unsync flag and only worry about frame-level unsync

      // For v2.2/v2.3, unsync the entire tag.  This is unfortunate due to
      // increased memory usage but the only way to do it, as frame size values only
      // indicate the post-unsync size, so it's not possible to unsync each frame individually
      // tested with v2.3-unsync.mp3
      if ( !_check_buf(id3->infile, id3->buf, id3->size, id3->size) ) {
        ret = 0;
        goto out;
      }

      id3->size_remain = _id3_deunsync( buffer_ptr(id3->buf), id3->size );

      DEBUG_TRACE("    Un-synchronized tag, new_size %d\n", id3->size_remain);
    }
    else {
      DEBUG_TRACE("  Ignoring v2.4 tag un-synchronize flag\n");
    }
  }

  if (id3->flags & ID3_TAG_FLAG_EXTENDEDHEADER) {
    uint32_t ehsize;

    // If the tag is v2.2, this bit is actually the compression bit and the tag should be ignored
    if (id3->version_major == 2) {
      ret = 0;
      goto out;
    }

    // tested with v2.3-ext-header.mp3

    // We don't care about the value of the extended flags or CRC, so just read the size and skip it
    ehsize = buffer_get_int(id3->buf);

    // ehsize may be invalid, tested with v2.3-ext-header-invalid.mp3
    if (ehsize > id3->size_remain - 4) {
      warn("Error: Invalid ID3 extended header size (%s)\n", id3->file);
      ret = 0;
      goto out;
    }

    DEBUG_TRACE("  Skipping extended header, size %d\n", ehsize);

    if ( !_check_buf(id3->infile, id3->buf, ehsize, ID3_BLOCK_SIZE) ) {
      ret = 0;
      goto out;
    }
    buffer_consume(id3->buf, ehsize);

    id3->size_remain -= ehsize + 4;
  }

  // Parse frames
  while (id3->size_remain > 0) {
    //DEBUG_TRACE("    remain: %d\n", id3->size_remain);
    if ( !_id3_parse_v2_frame(id3) ) {
      break;
    }
  }

  if (id3->version_major < 4) {
    // map old year/date/time (TYER/TDAT/TIME) frames to TDRC
    // tested in v2.3-xsop.mp3
    _id3_convert_tdrc(id3);
  }

  // Set id3_version info element, which contains all tag versions found
  {
    SV *version = newSVpvf( "ID3v2.%d.%d", id3->version_major, id3->version_minor );

    if ( my_hv_exists(id3->info, "id3_version") ) {
      SV **entry = my_hv_fetch(id3->info, "id3_version");
      if (entry != NULL) {
        sv_catpv( version, ", " );
        sv_catsv( version, *entry );
      }
    }

    my_hv_store( id3->info, "id3_version", version );
  }

out:
  return ret;
}

int
_id3_parse_v2_frame(id3info *id3)
{
  int ret = 1;
  char id[5];
  uint16_t flags = 0;
  uint32_t size  = 0;
  uint32_t decoded_size = 0;
  uint32_t unsync_extra = 0;
  id3_frametype const *frametype;
  Buffer *tmp_buf = 0;

  // If the frame is compressed, it will be decompressed here
  Buffer *decompressed = 0;

  // tag_data_safe flag is used if skipping artwork and artwork is not raw image data (needs unsync)
  id3->tag_data_safe = 1;

  if ( !_check_buf(id3->infile, id3->buf, 10, ID3_BLOCK_SIZE) ) {
    ret = 0;
    goto out;
  }

  if (id3->version_major == 2) {
    // v2.2
    id3_compat const *compat;

    // Read 3-letter id
    buffer_get(id3->buf, &id, 3);
    id[3] = 0;

    if (id[0] == 0) {
      // padding
      DEBUG_TRACE("  Found start of padding, aborting\n");
      ret = 0;
      goto out;
    }

    size = buffer_get_int24(id3->buf);

    DEBUG_TRACE("  %s, size %d\n", id, size);

    // map 3-char id to 4-char id
    compat = _id3_compat_lookup((char *)&id, 3);
    if (compat && compat->equiv) {
      strncpy(id, compat->equiv, 4);
      id[4] = 0;

      DEBUG_TRACE("    compat -> %s\n", id);
    }
    else {
      // no compat mapping (obsolete), prepend 'Y' to id
      id[4] = 0;
      id[3] = id[2];
      id[2] = id[1];
      id[1] = id[0];
      id[0] = 'Y';

      DEBUG_TRACE("    obsolete/unknown -> %s\n", id);
    }

    id3->size_remain -= 6;

    if (size > id3->size_remain) {
      DEBUG_TRACE("    frame size too big, aborting\n");
      ret = 0;
      goto out;
    }
  }
  else {
    // Read 4-letter id
    buffer_get(id3->buf, &id, 4);
    id[4] = 0;

    if (id[0] == 0) {
      // padding
      DEBUG_TRACE("  Found start of padding, aborting\n");
      ret = 0;
      goto out;
    }

    id3->size_remain -= 4;

    if (id3->version_major == 3) {
      // v2.3
      id3_compat const *compat;

      size  = buffer_get_int(id3->buf);
      flags = buffer_get_short(id3->buf);

      DEBUG_TRACE("  %s, frame flags %x, size %d\n", id, flags, size);

      // map to v2.4 id
      if (id[3] == ' ') {
        // iTunes writes bad frame IDs such as 'TSA ', these should be run through compat
        // as 3-char frames
        compat = _id3_compat_lookup((char *)&id, 3);
      }
      else {
        compat = _id3_compat_lookup((char *)&id, 4);
      }
      if (compat && compat->equiv) {
        strncpy(id, compat->equiv, 4);
        id[4] = 0;

        DEBUG_TRACE("    compat -> %s\n", id);
      }

      id3->size_remain -= 6;

      if (size > id3->size_remain) {
        DEBUG_TRACE("    frame size too big, aborting\n");
        ret = 0;
        goto out;
      }

      if (flags & ID3_FRAME_FLAG_V23_COMPRESSION) {
        // tested with v2.3-compressed-frame.mp3
        decoded_size = buffer_get_int(id3->buf);
        id3->size_remain -= 4;
        size -= 4;
      }

      if (flags & ID3_FRAME_FLAG_V23_ENCRYPTION) {
        // tested with v2.3-encrypted-frame.mp3
#ifdef AUDIO_SCAN_DEBUG
        DEBUG_TRACE("    encrypted, method %d\n", buffer_get_char(id3->buf));
#else
        buffer_consume(id3->buf, 1);
#endif

        id3->size_remain--;
        size--;

        DEBUG_TRACE("    skipping encrypted frame\n");
        _id3_skip(id3, size);
        id3->size_remain -= size;
        goto out;
      }

      if (flags & ID3_FRAME_FLAG_V23_GROUPINGIDENTITY) {
        // tested with v2.3-group-id.mp3
#ifdef AUDIO_SCAN_DEBUG
        DEBUG_TRACE("    group_id %d\n", buffer_get_char(id3->buf));
#else
        buffer_consume(id3->buf, 1);
#endif

        id3->size_remain--;
        size--;
      }

      // Perform decompression if necessary after all optional extra bytes have been read
      // XXX need test for compressed + unsync
      if (flags & ID3_FRAME_FLAG_V23_COMPRESSION && decoded_size) {
        unsigned long tmp_size;

        if ( !_check_buf(id3->infile, id3->buf, size, ID3_BLOCK_SIZE) ) {
          ret = 0;
          goto out;
        }

        DEBUG_TRACE("    decompressing, decoded_size %d\n", decoded_size);

        Newz(0, decompressed, sizeof(Buffer), Buffer);
        buffer_init(decompressed, decoded_size);

        tmp_size = decoded_size;
        if (
          uncompress(buffer_ptr(decompressed), &tmp_size, buffer_ptr(id3->buf), size) != Z_OK
          ||
    	    tmp_size != decoded_size
    	  ) {
          DEBUG_TRACE("    unable to decompress frame\n");
          buffer_free(decompressed);
          Safefree(decompressed);
          decompressed = 0;
        }
        else {
          // Hack buffer so it knows we've added data directly
          decompressed->end = decoded_size;
        }
      }
    }
    else {
      // v2.4

      // iTunes writes non-syncsafe length integers, check for this here
      if ( _varint(buffer_ptr(id3->buf), 4) & 0x80 ) {
        size = buffer_get_int(id3->buf);
        DEBUG_TRACE("    found non-syncsafe iTunes size for %s, size adjusted to %d\n", id, size);
      }
      else {
        size = buffer_get_syncsafe(id3->buf, 4);
      }

      flags = buffer_get_short(id3->buf);

      id3->size_remain -= 6;

      DEBUG_TRACE("  %s, frame flags %x, size %d\n", id, flags, size);

      if (size > id3->size_remain) {
        DEBUG_TRACE("    frame size too big, aborting\n");
        ret = 0;
        goto out;
      }

      // iTunes writes bad frame IDs such as 'TSA ', these should be run through compat
      // as 3-char frames
      if (id[3] == ' ') {
        id3_compat const *compat;
        compat = _id3_compat_lookup((char *)&id, 3);
        if (compat && compat->equiv) {
          strncpy(id, compat->equiv, 4);
          id[4] = 0;

          DEBUG_TRACE("    bad iTunes v2.4 tag, compat -> %s\n", id);
        }
      }

      if (flags & ID3_FRAME_FLAG_V24_GROUPINGIDENTITY) {
        // tested with v2.4-group-id.mp3
#ifdef AUDIO_SCAN_DEBUG
        DEBUG_TRACE("    group_id %d\n", buffer_get_char(id3->buf));
#else
        buffer_consume(id3->buf, 1);
#endif
        id3->size_remain--;
        size--;
      }

      if (flags & ID3_FRAME_FLAG_V24_ENCRYPTION) {
        // tested with v2.4-encrypted-frame.mp3
#ifdef AUDIO_SCAN_DEBUG
        DEBUG_TRACE("    encrypted, method %d\n", buffer_get_char(id3->buf));
#else
        buffer_consume(id3->buf, 1);
#endif

        id3->size_remain--;
        size--;

        DEBUG_TRACE("    skipping encrypted frame\n");
        _id3_skip(id3, size);
        id3->size_remain -= size;
        goto out;
      }

      if (flags & ID3_FRAME_FLAG_V24_DATALENGTHINDICATOR) {
        decoded_size = buffer_get_syncsafe(id3->buf, 4);
        id3->size_remain -= 4;
        size -= 4;

        DEBUG_TRACE("    data length indicator, size %d\n", decoded_size);
      }

      if (flags & ID3_FRAME_FLAG_V24_UNSYNCHRONISATION) {
        // Special case, do not unsync an APIC frame if not reading artwork,
        // FF's are not likely to appear in the part we care about anyway
        if ( !strcmp(id, "APIC") && _env_true("AUDIO_SCAN_NO_ARTWORK") ) {
          DEBUG_TRACE("    Would un-synchronize APIC frame, but ignoring because of AUDIO_SCAN_NO_ARTWORK\n");

          // Reset decoded_size to 0 since we aren't actually decoding.
          // XXX this would break if we have a compressed + unsync APIC frame but not very likely in the real world
          decoded_size = 0;

          id3->tag_data_safe = 0;
        }
        else {
          // tested with v2.4-unsync.mp3
          if ( !_check_buf(id3->infile, id3->buf, size, ID3_BLOCK_SIZE) ) {
            ret = 0;
            goto out;
          }

          decoded_size = _id3_deunsync( buffer_ptr(id3->buf), size );

          unsync_extra = size - decoded_size;

          DEBUG_TRACE("    Un-synchronized frame, new_size %d\n", decoded_size);
        }
      }

      if (flags & ID3_FRAME_FLAG_V24_COMPRESSION) {
        // tested with v2.4-compressed-frame.mp3
        // XXX need test for compressed + unsync
        unsigned long tmp_size;

        if ( !_check_buf(id3->infile, id3->buf, size, ID3_BLOCK_SIZE) ) {
          ret = 0;
          goto out;
        }

        DEBUG_TRACE("    decompressing\n");

        Newz(0, decompressed, sizeof(Buffer), Buffer);
        buffer_init(decompressed, decoded_size);

        tmp_size = decoded_size;
        if (
          uncompress(buffer_ptr(decompressed), &tmp_size, buffer_ptr(id3->buf), size) != Z_OK
          ||
    	    tmp_size != decoded_size
    	  ) {
          DEBUG_TRACE("    unable to decompress frame\n");
          buffer_free(decompressed);
          Safefree(decompressed);
          decompressed = 0;
        }
        else {
          // Hack buffer so it knows we've added data directly
          decompressed->end = decoded_size;
        }
      }
    }
  }

  // Special case, completely skip XHD3 frame (mp3HD) as it will be large
  // Also skip NCON, a large tag written by MusicMatch
  if ( !strcmp(id, "XHD3") || !strcmp(id, "NCON") ) {
    DEBUG_TRACE("    skipping large binary %s frame\n", id);
    _id3_skip(id3, size);
    id3->size_remain -= size;
    goto out;
  }

  frametype = _id3_frametype_lookup(id, 4);
  if (frametype == 0) {
    switch ( id[0] ) {
    case 'T':
      frametype = &id3_frametype_text;
      break;

    case 'W':
      frametype = &id3_frametype_url;
      break;

    case 'X':
    case 'Y':
    case 'Z':
      frametype = &id3_frametype_experimental;
      break;

    default:
      frametype = &id3_frametype_unknown;
      break;
    }
  }

#ifdef AUDIO_SCAN_DEBUG
  {
    int i;
    DEBUG_TRACE("    nfields %d:", frametype->nfields);
    for (i = 0; i < frametype->nfields; ++i) {
      DEBUG_TRACE(" %d", frametype->fields[i]);
    }
    DEBUG_TRACE("\n");
  }
#endif

  // If frame was compressed, temporarily set the id3 buffer to use the decompressed buffer
  if (decompressed) {
    tmp_buf  = id3->buf;
    id3->buf = decompressed;
  }

  if ( !_id3_parse_v2_frame_data(id3, (char *)&id, decoded_size ? decoded_size : size, frametype) ) {
    DEBUG_TRACE("    error parsing frame, aborting\n");
    ret = 0;
    goto out;
  }

  if (id3->size_remain > size) {
    id3->size_remain -= size;
  }
  else {
    id3->size_remain = 0;
  }

  // Consume extra bytes if we had to unsync this frame
  if (unsync_extra) {
    DEBUG_TRACE("    consuming extra bytes after unsync: %d\n", unsync_extra);
    buffer_consume(id3->buf, unsync_extra);
  }

out:
  if (decompressed) {
    // Reset id3 buffer and consume rest of compressed frame
    id3->buf = tmp_buf;
    buffer_consume(id3->buf, size);

    buffer_free(decompressed);
    Safefree(decompressed);
  }

  return ret;
}

int
_id3_parse_v2_frame_data(id3info *id3, char const *id, uint32_t size, id3_frametype const *frametype)
{
  int ret = 1;
  uint32_t read = 0;
  int8_t encoding = -1;

  uint8_t buffer_art = ( !strcmp(id, "APIC") ) ? 1 : 0;
  uint8_t skip_art   = ( buffer_art && _env_true("AUDIO_SCAN_NO_ARTWORK") ) ? 1 : 0;

  // Bug 16703, a completely empty frame is against the rules, skip it
  if (!size)
    return 1;

  if (skip_art) {
    // Only buffer enough for the APIC header fields, this is only a rough guess
    // because the description could technically be very long
    if ( !_check_buf(id3->infile, id3->buf, 128, ID3_BLOCK_SIZE) ) {
      return 0;
    }
    DEBUG_TRACE("    partial read due to AUDIO_SCAN_NO_ARTWORK\n");
  }
  else {
    // Use a special buffering mode for binary artwork, to avoid
    // using 2x the memory of the APIC frame (once for buffer, once for SV)
    if (buffer_art) {
      // Buffer enough for encoding/MIME/picture type/description
      if ( !_check_buf(id3->infile, id3->buf, 128, ID3_BLOCK_SIZE) ) {
        return 0;
      }
    }
    else {
      // Buffer the entire frame
      if ( !_check_buf(id3->infile, id3->buf, size, ID3_BLOCK_SIZE) ) {
        return 0;
      }
    }
  }

  if ( frametype->fields[0] == ID3_FIELD_TYPE_TEXTENCODING ) {
    // many frames have an encoding byte, read it here
    encoding = buffer_get_char(id3->buf);
    read++;
    DEBUG_TRACE("    encoding: %d\n", encoding);

    if (encoding < 0 || encoding > 3) {
      DEBUG_TRACE("    invalid encoding, skipping frame\n");
      goto out;
    }
  }

  // Special handling for TXXX/WXXX frames
  if ( !strcmp(id, "TXXX") || !strcmp(id, "WXXX") ) {
    // Read key and uppercase it
    SV *key   = NULL;
    SV *value = NULL;

    read += _id3_get_utf8_string(id3, &key, size - read, encoding);

    if (key != NULL && SvPOK(key) && sv_len(key)) {
      upcase(SvPVX(key));

      // Read value
      if (frametype->fields[2] == ID3_FIELD_TYPE_LATIN1) {
        // WXXX frames have a latin1 value field regardless of encoding byte
        encoding = ISO_8859_1;
      }

      read += _id3_get_utf8_string(id3, &value, size - read, encoding);

      // (T|W)XXX frames don't support multiple strings separated by nulls, even in v2.4

      // Only one tag per unique key value is allowed, that's why there is no array support here
      if (value != NULL && SvPOK(value) && sv_len(value)) {
        my_hv_store_ent( id3->tags, key, value );
      }
      else {
        my_hv_store_ent( id3->tags, key, &PL_sv_undef );
        if (value) SvREFCNT_dec(value);
      }
    }
    else {
      DEBUG_TRACE("    invalid/empty (T|W)XXX key, skipping frame\n");
    }

    if (key) SvREFCNT_dec(key);
  }

  // Special handling for TCON genre frame
  else if ( !strcmp(id, "TCON") ) {
    AV *genres = newAV();
    char *sptr, *end, *tmp;

    while (read < size) {
      SV *value  = NULL;

      // v2.4 handles multiple genres using null char separators (or $00 $00 in UTF-16),
      // this is handled by _id3_get_utf8_string
      read += _id3_get_utf8_string(id3, &value, size - read, encoding);
      if (value != NULL && SvPOK(value)) {
        sptr = SvPVX(value);

        // Test if the string contains only a number,
        // strtol will set tmp to end in this case
        end = sptr + sv_len(value);
        strtol(sptr, &tmp, 0);

        if ( tmp == end ) {
          // Convert raw number to genre string
          av_push( genres, newSVpv( _id3_genre_name((char *)sptr), 0 ) );

          // value as an SV won't be used, must drop refcnt
          SvREFCNT_dec(value);
        }
        else if ( *sptr == '(' ) {
          // Handle (26), (26)Ambient, etc, only the number portion will be read

          if (id3->version_major < 4) {
            // v2.2/v2.3 handle multiple genres using parens for some reason, i.e. (51)(39) or (55)(Text)
            char *ptr = sptr;
            char *end = sptr + sv_len(value);

            while (end - ptr > 0) {
              if ( *ptr++ == '(' ) {
                char *paren = strchr(ptr, ')');
                if (paren == NULL)
                  paren = end;

                if ( isdigit(*ptr) || !strncmp((char *)ptr, "RX", 2) || !strncmp((char *)ptr, "CR", 2) ) {
                  av_push( genres, newSVpv( _id3_genre_name((char *)ptr), 0 ) );
                }
                else {
                  // Handle text within parens
                  av_push( genres, newSVpvn(ptr,  paren - ptr) );
                }
                ptr = paren;
              }
            }
          }
          else {
            // v2.4, the (51) method is no longer valid but we will support it anyway
            sptr++;
            if ( isdigit(*sptr) || !strncmp(sptr, "RX", 2) || !strncmp(sptr, "CR", 2) ) {
              av_push( genres, newSVpv( _id3_genre_name((char *)sptr), 0 ) );
            }
            else {
              av_push( genres, newSVpv( (char *)sptr, 0 ) );
            }
          }

          // value as an SV won't be used, must drop refcnt
          SvREFCNT_dec(value);
        }
        else {
          // Support raw RX/CR value
          if ( !strncmp(sptr, "RX", 2) || !strncmp(sptr, "CR", 2) ) {
            av_push( genres, newSVpv( _id3_genre_name((char *)sptr), 0 ) );

            // value as an SV won't be used, must drop refcnt
            SvREFCNT_dec(value);
          }
          else {
            // Store plain text genre
            av_push( genres, value );
          }
        }
      }
    }

    if (av_len(genres) > 0) {
      my_hv_store( id3->tags, id, newRV_noinc( (SV *)genres ) );
    }
    else if (av_len(genres) == 0) {
      my_hv_store( id3->tags, id, av_shift(genres) );
      SvREFCNT_dec(genres);
    }
    else {
      SvREFCNT_dec(genres);
    }
  }

  // 1-field frames: MCDI, PCNT, SEEK (unsupported), T* (text), W* (url), unknown
  // and 2-field frames where the first field is encoding
  // are mapped to plain hash entries
  else if (
    frametype->nfields == 1 ||
    (frametype->nfields == 2 && frametype->fields[0] == ID3_FIELD_TYPE_TEXTENCODING)
  ) {
    int i = frametype->nfields - 1;
    AV *array = NULL;
    SV *value = NULL;
    int count = 0;

    switch ( frametype->fields[i] ) {
      case ID3_FIELD_TYPE_LATIN1: // W* frames
        read += _id3_get_utf8_string(id3, &value, size - read, ISO_8859_1);
        if (value != NULL && SvPOK(value))
          my_hv_store( id3->tags, id, value );
        break;

      case ID3_FIELD_TYPE_STRINGLIST: // T* frames
        // XXX technically in v2.2/v2.3 we should ignore multiple strings separated by nulls, but
        // allowing it is fine I think
        while (read < size) {
          if (count++ == 1 && value != NULL) {
            // we're reading the second string in the list, move first value to new array
            array = newAV();
            av_push(array, value);
          }
          value = NULL;

          read += _id3_get_utf8_string(id3, &value, size - read, encoding);

          if (array != NULL && value != NULL && SvPOK(value)) {
            // second+ string, add to array
            // Bug 16452, do not add a null string
            if (sv_len(value) > 0)
              av_push(array, value);
          }
        }

        if (array != NULL) {
          if (av_len(array) == 0) {
            // Handle the case where we have multiple empty strings leaving an array of 1
            my_hv_store( id3->tags, id, av_shift(array) );
            SvREFCNT_dec(array);
          }
          else {
            my_hv_store( id3->tags, id, newRV_noinc( (SV *)array ) );
          }
        }
        else if (value != NULL && SvPOK(value)) {
          my_hv_store( id3->tags, id, value );
        }
        break;

      case ID3_FIELD_TYPE_INT32: // SEEK (unsupported, XXX need test)
        my_hv_store( id3->tags, id, newSViv( buffer_get_int(id3->buf) ) );
        read += 4;
        break;

      case ID3_FIELD_TYPE_INT32PLUS: // PCNT
        my_hv_store( id3->tags, id, newSViv( _varint( buffer_ptr(id3->buf), size - read ) ) );
        buffer_consume(id3->buf, size - read);
        read = size;
        break;

      case ID3_FIELD_TYPE_BINARYDATA: // unknown/obsolete frames
        // Special handling for RVA(D), tested in v2.2-itunes81.mp3, v2.3-itunes81.mp3
        if ( !strcmp(id, "RVAD") ) {
          read += _id3_parse_rvad(id3, id, size - read);
        }

        // Special handling for RGAD (non-standard replaygain frame), tested in v2.3-rgad.mp3
        // Based on some code found at http://getid3.sourceforge.net/source/module.tag.id3v2.phps
        else if ( !strcmp(id, "RGAD") ) {
          read += _id3_parse_rgad(id3);
        }

        // Other unknown binary data
        else {
          // Y* obsolete frames
          my_hv_store( id3->tags, id, newSVpvn( buffer_ptr(id3->buf), size - read ) );
          buffer_consume(id3->buf, size - read);
          read = size;
        }
        break;

      default:
        // XXX
        warn("   !!! unhandled field type %d\n", frametype->fields[i]);
        buffer_consume(id3->buf, size - read);
        read += size - read;
        break;
    }
  }

  // 2+ field frames are mapped to arrayrefs:
  // The following frames have tests:
  // ETCO, UFID, USLT, SYLT, COMM, RVA2, APIC, GEOB, POPM, LINK, PRIV
  //
  // XXX The following frames need tests:
  // MLLT, SYTC, EQU2, RVRB, AENC, POSS, USER, OWNE,
  // COMR, ENCR, GRID, SIGN, ASPI, LINK (v2.4)
  else {
    int i = 0;
    AV *framedata = newAV();

    // If we read an initial encoding byte, start at field 2
    if (encoding >= 0)
      i = 1;

    for (; i < frametype->nfields; i++) {
      SV *value = NULL;

      switch ( frametype->fields[i] ) {
        case ID3_FIELD_TYPE_LATIN1:
          // Special case, fix v2.2 PIC frame fields as they don't match APIC
          // This is a rather hackish place to put this, but there's not really any other place
          if ( id3->version_major == 2 && !strcmp(id, "APIC") ) {
            av_push( framedata, newSVpvn( buffer_ptr(id3->buf), 3 ) );
            buffer_consume(id3->buf, 3);
            read += 3;
            DEBUG_TRACE("    PIC image format, read %d\n", read);
          }
          else {
            read += _id3_get_utf8_string(id3, &value, size - read, ISO_8859_1);
            if (value != NULL && SvPOK(value))
              av_push( framedata, value );
          }
          break;

        // ID3_FIELD_TYPE_LATIN1FULL - not used

        case ID3_FIELD_TYPE_LATIN1LIST: // LINK
          while (read < size) {
            read += _id3_get_utf8_string(id3, &value, size - read, ISO_8859_1);
            if (value != NULL && SvPOK(value))
              av_push( framedata, value );
            value = NULL;
            DEBUG_TRACE("    latin1list, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_STRING:
          read += _id3_get_utf8_string(id3, &value, size - read, encoding);
          if (value != NULL && SvPOK(value)) {
            av_push( framedata, value );
            DEBUG_TRACE("    string, read %d: %s\n", read, SvPVX(value));
          }
          else {
            av_push( framedata, &PL_sv_undef );
            if (value) SvREFCNT_dec(value);
          }
          break;

        case ID3_FIELD_TYPE_STRINGFULL: // USLT, COMM, read entire string until end of frame
        {
          SV *tmp = newSVpvn( "", 0 );
          while (read < size) {
            read += _id3_get_utf8_string(id3, &value, size - read, encoding);
            if (value != NULL && SvPOK(value)) {
              sv_catsv( tmp, value );
              SvREFCNT_dec(value);
            }
            value = NULL;
          }
          av_push( framedata, tmp );
          DEBUG_TRACE("    stringfull, read %d: %s\n", read, SvPVX(tmp));
          break;
        }

        // ID3_FIELD_TYPE_STRINGLIST - only used for text frames, handled above

        case ID3_FIELD_TYPE_LANGUAGE: // USLT, SYLT, COMM, USER, 3-byte language code
          if (size - read >= 3) {
            av_push( framedata, newSVpvn( buffer_ptr(id3->buf), 3 ) );
            buffer_consume(id3->buf, 3);
            read += 3;
            DEBUG_TRACE("    language, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_FRAMEID: // LINK, 3-byte frame id (v2.3, must be a bug in the spec?),
                                     // 4-byte frame id (v2.4) XXX need test
        {
          uint8_t len = (id3->version_major == 3) ? 3 : 4;
          if (size - read >= len) {
            av_push( framedata, newSVpvn( buffer_ptr(id3->buf), len ) );
            buffer_consume(id3->buf, len);
            read += len;
            DEBUG_TRACE("    frameid, read %d\n", read);
          }
          break;
        }

        case ID3_FIELD_TYPE_DATE: // OWNE, COMR, XXX need test, YYYYMMDD
          if (size - read >= 8) {
            av_push( framedata, newSVpvn( buffer_ptr(id3->buf), 8 ) );
            buffer_consume(id3->buf, 8);
            read += 8;
            DEBUG_TRACE("    date, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_INT8: // ETCO, MLLT, SYTC, SYLT, EQU2, RVRB, APIC,
                                  // POPM, RBUF, POSS, COMR, ENCR, GRID, SIGN, ASPI
          if (size - read >= 1) {
            av_push( framedata, newSViv( buffer_get_char(id3->buf) ) );
            read += 1;
            DEBUG_TRACE("    int8, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_INT16: // MLLT, RVRB, AENC, ASPI
          if (size - read >= 2) {
            av_push( framedata, newSViv( buffer_get_short(id3->buf) ) );
            read += 2;
            DEBUG_TRACE("    int16, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_INT24: // MLLT, RBUF
          if (size - read >= 3) {
            av_push( framedata, newSViv( buffer_get_int24(id3->buf) ) );
            read += 3;
            DEBUG_TRACE("    int24, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_INT32: // RBUF, SEEK, ASPI
          if (size - read >= 4) {
            av_push( framedata, newSViv( buffer_get_int(id3->buf) ) );
            read += 4;
            DEBUG_TRACE("    int32, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_INT32PLUS: // POPM
          if (size - read >= 4) {
            av_push( framedata, newSViv( _varint( buffer_ptr(id3->buf), size - read ) ) );
            buffer_consume(id3->buf, size - read);
            read = size;
            DEBUG_TRACE("    int32plus, read %d\n", read);
          }
          break;

        case ID3_FIELD_TYPE_BINARYDATA: // ETCO, MLLT, SYTC, SYLT, RVA2, EQU2, APIC,
                                        // GEOB, AENC, POSS, COMR, ENCR, GRID, PRIV, SIGN, ASPI
          // Special handling for APIC tags when in skip_art mode
          if (skip_art) {
            av_push( framedata, newSVuv(size - read) );

            // Record offset of APIC image data too, unless the data needs to be unsynchronized or is empty
            if (id3->tag_data_safe && (size - read) > 0)
              av_push( framedata, newSVuv(id3->offset + (id3->size - id3->size_remain) + read) );

            _id3_skip(id3, size - read);
            read = size;
          }

          // Special buffering mode for APIC data, avoids a large buffer allocation
          else if (buffer_art) {
            uint32_t remain = size - read;
            uint32_t chunk_size;
            SV *artwork = newSVpv("", 0);

            while (read < size) {
              if ( !_check_buf(id3->infile, id3->buf, 1, ID3_BLOCK_SIZE) ) {
                return 0;
              }

              chunk_size = remain < buffer_len(id3->buf) ? remain : buffer_len(id3->buf);

              read += chunk_size;
              remain -= chunk_size;

              sv_catpvn( artwork, buffer_ptr(id3->buf), chunk_size );
              buffer_consume(id3->buf, chunk_size);

              DEBUG_TRACE("    buffered %d bytes of APIC data (remaining %d)\n", chunk_size, remain);
            }

            av_push( framedata, artwork );
          }

          // Special handling for RVA2 tags
          else if ( !strcmp(id, "RVA2") ) {
            read += _id3_parse_rva2(id3, size, framedata);
          }

          // Special handling for SYLT tags
          else if ( !strcmp(id, "SYLT") ) {
            read += _id3_parse_sylt(id3, encoding, size - read, framedata);
          }

          // Special handling for ETCO tags
          else if ( !strcmp(id, "ETCO") ) {
            read += _id3_parse_etco(id3, size - read, framedata);
          }

          // All other binary frames, copy as-is
          else {
            if (size - read > 1) {
              av_push( framedata, newSVpvn( buffer_ptr(id3->buf), size - read ) );
              buffer_consume(id3->buf, size - read);
              read = size;
              DEBUG_TRACE("    binarydata, read %d\n", read);
            }
          }
          break;

        default:
          break;
      }
    }

    _id3_set_array_tag(id3, id, framedata);
  }

out:
  if (read < size) {
    buffer_consume(id3->buf, size - read);
    DEBUG_TRACE("    !!! consuming extra bytes in frame: %d\n", size - read);
  }

  return ret;
}

void
_id3_set_array_tag(id3info *id3, char const *id, AV *framedata)
{
  if ( av_len(framedata) != -1 ) {
    if ( my_hv_exists( id3->tags, id ) ) {
      // If tag already exists, move it to an arrayref
      SV **entry = my_hv_fetch( id3->tags, id );
      if (entry != NULL) {
        if ( SvTYPE( SvRV(*entry) ) == SVt_PV ) {
          // A normal string entry, convert to array
	  AV *ref = newAV();

          // XXX need test, this may be illegal because you can't have multiple duplicate frames?
          DEBUG_TRACE("   !!! converting normal string tag to array\n");

          av_push( ref, *entry );
          av_push( ref, newRV_noinc( (SV *)framedata ) );
          my_hv_store( id3->tags, id, newRV_noinc( (SV *)ref ) );
        }
        else if ( SvTYPE( SvRV(*entry) ) == SVt_PVAV ) {
          // If type of first item is array, add new item to entry
          SV **first = av_fetch( (AV *)SvRV(*entry), 0, 0 );
          if ( first == NULL || ( SvROK(*first) && SvTYPE( SvRV(*first) ) == SVt_PVAV ) ) {
            av_push( (AV *)SvRV(*entry), newRV_noinc( (SV *)framedata ) );
          }
          else {
            AV *ref = newAV();
            av_push( ref, SvREFCNT_inc(*entry) );
            av_push( ref, newRV_noinc( (SV *)framedata) );
            my_hv_store( id3->tags, id, newRV_noinc( (SV *)ref ) );
          }
        }
      }
    }
    else {
      my_hv_store( id3->tags, id, newRV_noinc( (SV *)framedata ) );
    }
  }
  else {
    SvREFCNT_dec(framedata);
  }
}

// Read a latin1 or UTF-8 string from an ID3v1 tag
// This function handles trimming spaces off the end
uint32_t
_id3_get_v1_utf8_string(id3info *id3, SV **string, uint32_t len)
{
  uint32_t read = 0;
  char *ptr;
  char *str;

  read = _id3_get_utf8_string(id3, string, len, ISO_8859_1);

  if (read) {
    // Trim spaces from end
    if (*string != NULL) {
      str = SvPVX(*string);
      ptr = str + sv_len(*string);

      while (ptr > str && ptr[-1] == ' ')
        --ptr;

      *ptr = 0;
      SvCUR_set(*string, ptr - str);
    }
  }

  return read;
}

uint32_t
_id3_get_utf8_string(id3info *id3, SV **string, uint32_t len, uint8_t encoding)
{
  uint8_t byteorder = UTF16_BYTEORDER_ANY;
  uint32_t read = 0;
  unsigned char *bptr;

  // Init scratch buffer if necessary
  if ( !id3->utf8->alloc ) {
    // Use a larger initial buffer if reading ISO-8859-1 to avoid
    // always having to allocate a second time
    buffer_init( id3->utf8, encoding == ISO_8859_1 ? len * 2 : len );
  }
  else {
    // Reset scratch buffer
    buffer_clear(id3->utf8);
  }

  if ( *string != NULL ) {
    warn("    !!! string SV is not null: %s\n", SvPVX(*string));
  }

  switch (encoding) {
    case ISO_8859_1:
      read += buffer_get_latin1_as_utf8(id3->buf, id3->utf8, len);
      break;

    case UTF_16BE:
      byteorder = UTF16_BYTEORDER_BE;

    case UTF_16:
      bptr = buffer_ptr(id3->buf);

      switch ( (bptr[0] << 8) | bptr[1] ) {
      case 0xfeff:
        DEBUG_TRACE("    UTF-16 BOM is big-endian\n");
        byteorder = UTF16_BYTEORDER_BE;
        buffer_consume(id3->buf, 2);
        read += 2;
        break;

      case 0xfffe:
        DEBUG_TRACE("    UTF-16 BOM is little-endian\n");
        byteorder = UTF16_BYTEORDER_LE;
        buffer_consume(id3->buf, 2);
        read += 2;
        break;
      }

      /* Bug 14728
        If there is no BOM, assume LE, this is what appears in the wild -andy
      */
      if (byteorder == UTF16_BYTEORDER_ANY) {
        DEBUG_TRACE("    UTF-16 byte order defaulting to little-endian, no BOM\n");
        byteorder = UTF16_BYTEORDER_LE;
      }

      read += buffer_get_utf16_as_utf8(id3->buf, id3->utf8, len - read, byteorder);
      break;

    case UTF_8:
      read += buffer_get_utf8(id3->buf, id3->utf8, len);
      break;

    default:
      break;
  }

  if (read) {
    if ( buffer_len(id3->utf8) ) {
      *string = newSVpv( buffer_ptr(id3->utf8), 0 );
      sv_utf8_decode(*string);
      DEBUG_TRACE("    read utf8 string of %d bytes: %s\n", buffer_len(id3->utf8), SvPVX(*string));
    }
    else {
      DEBUG_TRACE("    empty string\n");
    }
  }

  return read;
}

uint32_t
_id3_parse_rvad(id3info *id3, char const *id, uint32_t size)
{
  unsigned char *rva = buffer_ptr(id3->buf);
  int sign_r = rva[0] & 0x01 ? 1 : -1;
  int sign_l = rva[0] & 0x02 ? 1 : -1;
  int bytes = rva[1] / 8;
  float vol[2];
  float peak[2];
  int i;
  AV *framedata = newAV();

  // Sanity check, first byte must be either 0 or 1, second byte > 0
  if (rva[0] & 0xFE || rva[1] == 0) {
    return 0;
  }

  // Calculated size must match the actual size
  if (size != 2 + (bytes * 4)) {
    return 0;
  }

  rva += 2;

  vol[0] = _varint( rva, bytes ) * sign_r / 256.;
  vol[1] = _varint( rva + bytes, bytes ) * sign_l / 256.;

  peak[0] = _varint( rva + (bytes * 2), bytes );
  peak[1] = _varint( rva + (bytes * 3), bytes );

  // iTunes uses a range of -255 to 255
	// to be -100% (silent) to 100% (+6dB)
  for (i = 0; i < 2; i++) {
    if ( vol[i] == -255 ) {
      vol[i] = -96.0;
    }
    else {
      vol[i] = 20.0 * log( ( vol[i] + 255 ) / 255 ) / log(10);
    }

    av_push( framedata, newSVpvf( "%f dB", vol[i] ) );
    av_push( framedata, newSVpvf( "%f", peak[i] ) );
  }

  my_hv_store( id3->tags, id, newRV_noinc( (SV *)framedata ) );

  buffer_consume(id3->buf, 2 + (bytes * 4));

  return 2 + (bytes * 4);
}

uint32_t
_id3_parse_rgad(id3info *id3)
{
  float radio = 0.0;
  float audiophile = 0.0;
  uint8_t sign = 0;
  HV *framedata = newHV();
  uint32_t read = 0;

  // Peak (32-bit float)
  my_hv_store( framedata, "peak", newSVpvf( "%f", (float)buffer_get_float32(id3->buf) ) );
  read += 4;

  // Radio (16 bits)

  // Radio Name code (3 bits, should always be 1)
  buffer_get_bits(id3->buf, 3);

  my_hv_store( framedata, "track_originator", newSVuv( buffer_get_bits(id3->buf, 3) ) );

  // Sign bit (1 bit)
  sign = buffer_get_bits(id3->buf, 1);

  // Gain value (9 bits)
  radio = (float)buffer_get_bits(id3->buf, 9);
  radio /= 10.0;
  if (sign == 1) radio *= -1.0;
  my_hv_store( framedata, "track_gain", newSVpvf( "%f dB", radio ) );

  read += 2;

  // Audiophile (16 bits)

  // Audiophile Name code (3 bits, should always be 2)
  buffer_get_bits(id3->buf, 3);

  // Audiophile Originator code (3 bits)
  my_hv_store( framedata, "album_originator", newSVuv( buffer_get_bits(id3->buf, 3) ) );

  // Sign bit (1 bit)
  sign = buffer_get_bits(id3->buf, 1);

  // Gain value (9 bits)
  audiophile = (float)buffer_get_bits(id3->buf, 9);
  audiophile /= 10.0;
  if (sign == 1) audiophile *= -1.0;
  my_hv_store( framedata, "album_gain", newSVpvf( "%f dB", audiophile ) );

  read += 2;

  my_hv_store( id3->tags, "RGAD", newRV_noinc( (SV *)framedata ) );

  return read;
}

uint32_t
_id3_parse_rva2(id3info *id3, uint32_t len, AV *framedata)
{
  float adj = 0.0;
  int adj_fp;
  uint8_t peakbits;
  float peak = 0.0;
  uint32_t read = 0;
  unsigned char *bptr;

  // Channel
  av_push( framedata, newSViv( buffer_get_char(id3->buf) ) );

  // Adjustment
  bptr = buffer_ptr(id3->buf);
  adj_fp = *(signed char *)(bptr) << 8;
  adj_fp |= *(unsigned char *)(bptr+1);
  adj = adj_fp / 512.0;
  av_push( framedata, newSVpvf( "%f dB", adj ) );
  buffer_consume(id3->buf, 2);

  // Peak
  // Based on code from mp3gain
  peakbits = buffer_get_char(id3->buf);

  read += 4;

  if (4 + (peakbits + 7) / 8 <= len) {
    DEBUG_TRACE("    peakbits: %d\n", peakbits);
    if (peakbits > 0) {
      peak += (float)buffer_get_char(id3->buf);
      read++;
    }
    if (peakbits > 8) {
      peak += (float)buffer_get_char(id3->buf) / 256.0;
      read++;
    }
    if (peakbits > 16) {
      peak += (float)buffer_get_char(id3->buf) / 65536.0;
      read++;
    }

    if (peakbits > 0)
      peak /= (float)(1 << ((peakbits - 1) & 7));
  }

  av_push( framedata, newSVpvf( "%f dB", peak ) );

  return read;
}

uint32_t
_id3_parse_sylt(id3info *id3, uint8_t encoding, uint32_t len, AV *framedata)
{
  uint32_t read = 0;
  AV *content = newAV();
  unsigned char *bptr;

  while (read < len) {
    SV *value = NULL;
    HV *lyric = newHV();

    read += _id3_get_utf8_string(id3, &value, len - read, encoding);
    if (value != NULL && SvPOK(value) && sv_len(value)) {
      my_hv_store( lyric, "text", value );
    }
    else {
      my_hv_store( lyric, "text", &PL_sv_undef );
      if (value) SvREFCNT(value);
    }

    my_hv_store( lyric, "timestamp", newSVuv( buffer_get_int(id3->buf) ) );
    read += 4;

    // A $0A newline byte may follow, for some odd reason
    bptr = buffer_ptr(id3->buf);
    if ( len - read > 0 && bptr[0] == 0x0a ) {
      buffer_consume(id3->buf, 1);
      read++;
    }

    av_push( content, newRV_noinc( (SV *)lyric ) );
  }

  av_push( framedata, newRV_noinc( (SV *)content ) );

  return read;
}

uint32_t
_id3_parse_etco(id3info *id3, uint32_t len, AV *framedata)
{
  uint32_t read = 0;
  AV *content = newAV();

  while (read < len) {
    HV *event = newHV();

    my_hv_store( event, "type", newSVuv( buffer_get_char(id3->buf) ) );
    my_hv_store( event, "timestamp", newSVuv( buffer_get_int(id3->buf) ) );
    read += 5;

    av_push( content, newRV_noinc( (SV *)event ) );
  }

  av_push( framedata, newRV_noinc( (SV *)content ) );

  return read;
}

void
_id3_convert_tdrc(id3info *id3)
{
  char timestamp[17] = { 0 };

  if ( my_hv_exists(id3->tags, "TYER") ) {
    SV *tyer = my_hv_delete(id3->tags, "TYER");
    if (SvPOK(tyer) && sv_len(tyer) == 4) {
      char *ptr = SvPVX(tyer);
      timestamp[0] = ptr[0];
      timestamp[1] = ptr[1];
      timestamp[2] = ptr[2];
      timestamp[3] = ptr[3];
      DEBUG_TRACE("  Converted TYER (%s) to TDRC (%s)\n", SvPVX(tyer), timestamp);
    }
  }

  if ( my_hv_exists(id3->tags, "TDAT") ) {
    SV *tdat = my_hv_delete(id3->tags, "TDAT");
    if (SvPOK(tdat) && sv_len(tdat) == 4) {
      char *ptr = SvPVX(tdat);
      timestamp[4] = '-';
      timestamp[5] = ptr[2];
      timestamp[6] = ptr[3];
      timestamp[7] = '-';
      timestamp[8] = ptr[0];
      timestamp[9] = ptr[1];
      DEBUG_TRACE("  Converted TDAT (%s) to TDRC (%s)\n", SvPVX(tdat), timestamp);
    }
  }

  if ( my_hv_exists(id3->tags, "TIME") ) {
    SV *time = my_hv_delete(id3->tags, "TIME");
    if (SvPOK(time) && sv_len(time) == 4) {
      char *ptr = SvPVX(time);
      timestamp[10] = 'T';
      timestamp[11] = ptr[0];
      timestamp[12] = ptr[1];
      timestamp[13] = ':';
      timestamp[14] = ptr[2];
      timestamp[15] = ptr[3];
      DEBUG_TRACE("  Converted TIME (%s) to TDRC (%s)\n", SvPVX(time), timestamp);
    }
  }

  if (timestamp[0]) {
    my_hv_store( id3->tags, "TDRC", newSVpv(timestamp, 0) );
  }
}

// deunsync in-place, from libid3tag
uint32_t
_id3_deunsync(unsigned char *data, uint32_t length)
{
  unsigned char *old;
  unsigned char *end = data + length;
  unsigned char *new;

  if (length == 0)
    return 0;

  for (old = new = data; old < end - 1; ++old) {
    *new++ = *old;
    if (old[0] == 0xff && old[1] == 0x00)
      ++old;
  }

  *new++ = *old;

  return new - data;
}

void
_id3_skip(id3info *id3, uint32_t size)
{
  if ( buffer_len(id3->buf) >= size ) {
    buffer_consume(id3->buf, size);

    DEBUG_TRACE("  skipped buffer data size %d\n", size);
  }
  else {
    PerlIO_seek(id3->infile, size - buffer_len(id3->buf), SEEK_CUR);
    buffer_clear(id3->buf);

    DEBUG_TRACE("  seeked past %d bytes to %d\n", size, (int)PerlIO_tell(id3->infile));
  }
}

// return an ID3v1 genre string indexed by number
char const *
_id3_genre_index(unsigned int index)
{
  return (index < NGENRES) ? genre_table[index] : 0;
}

// translate an ID3v2 genre number/keyword to its full name
char const *
_id3_genre_name(char const *string)
{
  static char const genre_remix[] = { 'R', 'e', 'm', 'i', 'x', 0 };
  static char const genre_cover[] = { 'C', 'o', 'v', 'e', 'r', 0 };
  unsigned long number;

  if (string == 0 || *string == 0)
    return 0;

  if (string[0] == 'R' && string[1] == 'X')
    return genre_remix;
  if (string[0] == 'C' && string[1] == 'R')
    return genre_cover;

  number = strtol(string, NULL, 0);

  return (number < NGENRES) ? genre_table[number] : string;
}
