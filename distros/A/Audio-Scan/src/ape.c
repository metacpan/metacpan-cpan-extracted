/* Original Copyright:
 *
Copyright (c) 2007 Jeremy Evans

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in
all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.

Refactored heavily by Dan Sully

*/

#include "ape.h"

static int _ape_error(ApeTag *tag, char *error, int ret) {
  LOG_WARN("APE: [%s] %s\n", error, tag->filename);
  return ret;
}

int _ape_parse(ApeTag* tag) {
  int ret = 0;
  
  if (!(tag->flags & APE_CHECKED_APE)) {
    if ((ret = _ape_get_tag_info(tag)) < 0) {
      return ret;
    }
  }

  if ((tag->flags & APE_HAS_APE) && !(tag->flags & APE_CHECKED_FIELDS)) {
    if ((ret = _ape_parse_fields(tag)) < 0) {
      return ret;
    }
  }
  
  return 0;
}

// Parses the header and footer of the tag to get information about it.
// Returns 0 on success, <0 on error;
int _ape_get_tag_info(ApeTag* tag) {
  int id3_length = 0;
  uint32_t lyrics_size = 0;
  long data_size = 0;
  off_t file_size = 0;
  unsigned char compare[12];
  unsigned char *tmp_ptr;
  
  file_size = _file_size(tag->fd);
  
  /* No ape or id3 tag possible in this size */
  if (file_size < APE_MINIMUM_TAG_SIZE) {
    tag->flags |= APE_CHECKED_APE;
    tag->flags &= ~(APE_HAS_APE | APE_HAS_ID3);
    return 0;
  } 
  
  if (!(tag->flags & APE_NO_ID3)) {

    if (file_size < APE_ID3_MIN_TAG_SIZE) {

      /* No id3 tag possible in this size */
      tag->flags &= ~APE_HAS_ID3;

    } else {

      char id3[APE_ID3_MIN_TAG_SIZE];

      /* Check for id3 tag. We need to seek past it if it exists. */
      if ((PerlIO_seek(tag->fd, file_size - APE_ID3_MIN_TAG_SIZE, SEEK_SET)) == -1) {
        return _ape_error(tag, "Couldn't seek (id3 offset)", -1);
      }

      if (PerlIO_read(tag->fd, &id3, APE_ID3_MIN_TAG_SIZE) < APE_ID3_MIN_TAG_SIZE) {
        return _ape_error(tag, "Couldn't read (id3 offset)", -2);
      }

      if (id3[0] == 'T' && id3[1] == 'A' && id3[2] == 'G') {
        id3_length = APE_ID3_MIN_TAG_SIZE;
        tag->flags |= APE_HAS_ID3;
      } else {
        tag->flags &= ~APE_HAS_ID3;
      }
    }

    /* Recheck possibility for ape tag now that id3 presence is known */
    if (file_size < APE_MINIMUM_TAG_SIZE + id3_length) {
      tag->flags &= ~APE_HAS_APE;
      tag->flags |= APE_CHECKED_APE;
      return 0;
    }
  }
  
  /* Check for existance of ape tag footer */
  if (PerlIO_seek(tag->fd, file_size - APE_TAG_FOOTER_LEN - id3_length, SEEK_SET) == -1) {
    return _ape_error(tag, "Couldn't seek (tag footer)", -1);
  }

  buffer_init(&tag->tag_footer, APE_TAG_FOOTER_LEN);

  if (!_check_buf(tag->fd, &tag->tag_footer, APE_TAG_FOOTER_LEN, APE_TAG_FOOTER_LEN)) {
    return _ape_error(tag, "Couldn't read tag footer", -2);
  }

  buffer_get(&tag->tag_footer, &compare, 8);

  // XXX this is pretty messy, but will work until I can refactor this whole file
  if (memcmp(APE_PREAMBLE, &compare, 8)) {
    // Check for Lyricsv2 tag between APE and ID3
    char *bptr;
    
    buffer_consume(&tag->tag_footer, 15);
    bptr = buffer_ptr(&tag->tag_footer);
    if ( bptr[0] == 'L' && bptr[1] == 'Y' && bptr[2] == 'R'
      && bptr[3] == 'I' && bptr[4] == 'C' && bptr[5] == 'S'
      && bptr[6] == '2' && bptr[7] == '0' && bptr[8] == '0'
    ) {
      // read Lyrics tag size, stored as a 6-digit number (!?)
      // http://www.id3.org/Lyrics3v2      
      bptr -= 6;
      lyrics_size = atoi(bptr);
      
      if ( (PerlIO_seek(tag->fd, file_size - (160 + lyrics_size + 15), SEEK_SET)) == -1 ) {
        return _ape_error(tag, "Couldn't seek (tag footer)", -1);
      }
      
      buffer_clear(&tag->tag_footer);
      if ( !_check_buf(tag->fd, &tag->tag_footer, APE_TAG_FOOTER_LEN, APE_TAG_FOOTER_LEN) ) {
        return _ape_error(tag, "Couldn't read tag footer", -2);
      }
      
      buffer_get(&tag->tag_footer, &compare, 8);
      
      if (memcmp(APE_PREAMBLE, &compare, 8)) {    
        tag->flags &= ~APE_HAS_APE;
        tag->flags |= APE_CHECKED_APE;
        return 0;
      }
    }
    else {
      tag->flags &= ~APE_HAS_APE;
      tag->flags |= APE_CHECKED_APE;
      return 0;
    }
  }
  
  tag->version      = buffer_get_int_le(&tag->tag_footer) / 1000;
  tag->size         = buffer_get_int_le(&tag->tag_footer);
  tag->item_count   = buffer_get_int_le(&tag->tag_footer);
  tag->footer_flags = buffer_get_int_le(&tag->tag_footer);
  tag->size += APE_TAG_FOOTER_LEN;
  data_size = tag->size - APE_TAG_HEADER_LEN - APE_TAG_FOOTER_LEN;
  
  DEBUG_TRACE("Found APEv%d tag, size %d with %d items\n", tag->version, tag->size, tag->item_count);
  
  my_hv_store( tag->info, "ape_version", newSVpvf( "APEv%d", tag->version ) );

  /* Check tag footer for validity */
  if (tag->size < APE_MINIMUM_TAG_SIZE) {
    return _ape_error(tag, "Tag smaller than minimum possible size", -3);
  }

  if (tag->size > APE_MAXIMUM_TAG_SIZE) {
    return _ape_error(tag, "Tag larger than maximum possible size", -3);
  }

  if (tag->size + (uint32_t)id3_length > (unsigned long)file_size) {
    return _ape_error(tag, "Tag larger than possible size", -3);
  }

  if (tag->item_count > APE_MAXIMUM_ITEM_COUNT) {
    return _ape_error(tag, "Tag item count larger than allowed", -3);
  }

  if (tag->item_count > (tag->size - APE_MINIMUM_TAG_SIZE)/APE_ITEM_MINIMUM_SIZE) {
    return _ape_error(tag, "Tag item count larger than possible", -3);
  }

  if (PerlIO_seek(tag->fd, (file_size -(long)tag->size - id3_length - (lyrics_size ? (lyrics_size + 15) : 0)), SEEK_SET) == -1) {
    return _ape_error(tag, "Couldn't seek to tag offset", -1);
  }
  
  tag->offset = file_size -(long)tag->size - id3_length - (lyrics_size ? (lyrics_size + 15) : 0);
  DEBUG_TRACE("APE tag offset %d\n", tag->offset);

  /* ---------- Read tag header and data --------------- */
  buffer_init(&tag->tag_header, APE_TAG_HEADER_LEN);
  buffer_init(&tag->tag_data, data_size);
  
  if (tag->footer_flags & APE_TAG_CONTAINS_HEADER) {
    // Bug 15324, Header may or may not be present, only read if footer flag says it is
    if (!_check_buf(tag->fd, &tag->tag_header, APE_TAG_HEADER_LEN, APE_TAG_HEADER_LEN)) {
      return _ape_error(tag, "Couldn't read tag header", -2);
    }
    
    buffer_get(&tag->tag_header, &compare, 12);
    tmp_ptr = buffer_ptr(&tag->tag_header);

    /* Check tag header for validity */
    if (memcmp(APE_PREAMBLE, &compare, 8) || 
       (tmp_ptr[8] != '\0' && tmp_ptr[8] != '\1')) {
      return _ape_error(tag, "Bad tag header flags", -3);
    }

    if (tag->size != (buffer_get_int_le(&tag->tag_header) + APE_TAG_HEADER_LEN)) {
      return _ape_error(tag, "Header and footer size do not match", -3);
    }

    if (tag->item_count != buffer_get_int_le(&tag->tag_header)) {
      return _ape_error(tag, "Header and footer item count do not match", -3);
    }
  }
  else {
    // Skip junk where header should be, APE format is really stupid...
    if (PerlIO_seek(tag->fd, APE_TAG_HEADER_LEN, SEEK_CUR) == -1) {
      return _ape_error(tag, "Couldn't seek to tag offset", -1);
    }
  }
  
  tag->offset += APE_TAG_HEADER_LEN;

  if (!_check_buf(tag->fd, &tag->tag_data, data_size, data_size)) {
    return _ape_error(tag, "Couldn't read tag data", -2);
  }
  
  tag->flags |= APE_CHECKED_APE | APE_HAS_APE;
  
  // Reduce the size of the audio_size value
  if (my_hv_exists(tag->info, "audio_size")) {
    int audio_size = SvIV(*(my_hv_fetch(tag->info, "audio_size")));
    if (lyrics_size > 0)
      lyrics_size += 15;
    
    my_hv_store(tag->info, "audio_size", newSVuv(audio_size - tag->size - lyrics_size));
    DEBUG_TRACE("Reduced audio_size value by APE/Lyrics2 tag size %d\n", tag->size + lyrics_size);
  }

  return 1;
}

int _ape_parse_fields(ApeTag* tag) {
  int ret = 0;
  uint32_t i;

  /* Don't exceed the maximum number of items allowed */
  if (tag->num_fields >= APE_MAXIMUM_ITEM_COUNT) {
    return _ape_error(tag, "Maximum item count exceeded", -3);
  }
  
  for (i = 0; i < tag->item_count; i++) {
    if ((ret = _ape_parse_field(tag)) != 0) {
      return ret;
    }
  }

  if (buffer_len(&tag->tag_data) != 0) {
    return _ape_error(tag, "Data remaining after specified number of items parsed", -3);
  }

  tag->flags |= APE_CHECKED_FIELDS;
  
  return 0;
}

int _ape_parse_field(ApeTag* tag) {

  /* Ape tag item format:
   *
   * <value_size:4 bytes>
   * <flags:4 bytes>
   * <key:N bytes, 2 to 255 chars, ASCII range. 0x00 terminated>
   * <value:value_size bytes>
   */
  uint32_t data_size = tag->size - APE_MINIMUM_TAG_SIZE;
  uint32_t size, flags, key_length = 0, val_length = 0;
  unsigned char *tmp_ptr;
  SV *key = NULL;
  SV *value = NULL;
  
  if (buffer_len(&tag->tag_data) < 8)
    return _ape_error(tag, "Ran out of tag data before number of items was reached", -3);
  
  size  = buffer_get_int_le(&tag->tag_data);
  flags = buffer_get_int_le(&tag->tag_data);

  tmp_ptr = buffer_ptr(&tag->tag_data);
  while (tmp_ptr[0] != '\0') {
    key_length += 1;
    tmp_ptr    += 1;
  }

  key = newSVpvn( buffer_ptr(&tag->tag_data), key_length );
  buffer_consume(&tag->tag_data, key_length + 1);
  
  // Bug 9942, APE tags can contain multiple items with a null separator
  tmp_ptr = buffer_ptr(&tag->tag_data);
  while (tmp_ptr[0] != '\0' && val_length <= size) {
    val_length += 1;
    tmp_ptr    += 1;
  }
  
  tag->offset += 8 + key_length + 1;
  
  DEBUG_TRACE("key_length: %d / val_length: %d / size: %d / flags %x @ %d\n", key_length, val_length, size, flags, tag->offset);
  
  if (flags & APE_TAG_TYPE_BINARY) {
    // Binary data, just copy it as-is
    
    // Special handling if the tag is cover art, strip the filename from the front of
    // the cover art data
    if ( sv_len(key) == 17 && !memcmp( upcase(SvPVX(key)), "COVER ART (FRONT)", 17 ) ) {
      if ( _env_true("AUDIO_SCAN_NO_ARTWORK") ) {
        // Don't read artwork, just return the size
        value = newSVuv(size - (val_length + 1) );
        
        my_hv_store( tag->tags, "COVER ART (FRONT)_offset", newSVuv(tag->offset + val_length + 1) );
        
        buffer_consume(&tag->tag_data, size);
      }
      else {
        buffer_consume(&tag->tag_data, val_length + 1); // consume filename + null
        size -= val_length + 1;
      }
    }
    
    if ( value == NULL ) {
      value = newSVpvn( buffer_ptr(&tag->tag_data), size );
      buffer_consume(&tag->tag_data, size);
    }
    
    tag->offset += val_length + 1;
  }
  else if (val_length >= size - 1) {
    // Single item
    value = newSVpvn( buffer_ptr(&tag->tag_data), val_length < size ? val_length : size );
    
    buffer_consume(&tag->tag_data, size);
    
    // Don't add invalid items
    if (_ape_check_validity(tag, flags, SvPVX(key), SvPVX(value)) != 0) {
      // skip this item
      return 0;
    }
    else {
      sv_utf8_decode(value);
      DEBUG_TRACE("  %s = %s\n", SvPVX(key), SvPVX(value));
    }
    
    tag->offset += val_length < size ? val_length : size;
  }
  else {
    // Multiple items
    AV *av = newAV();
    SV *tmp_val;
    uint32_t done = 0;
    
    while ( done < size ) {
      val_length = 0;
      tmp_ptr = buffer_ptr(&tag->tag_data);
      while (tmp_ptr[0] != '\0' && done < size) {
        val_length++;
        tmp_ptr++;
        done++;
      }
      
      tmp_val = newSVpvn( buffer_ptr(&tag->tag_data), val_length );
      buffer_consume(&tag->tag_data, val_length);
      
      tag->offset += val_length;
    
      // Don't add invalid items
      if (_ape_check_validity(tag, flags, SvPVX(key), SvPVX(tmp_val)) != 0) {
        // skip this item
        buffer_consume(&tag->tag_data, size - done);
        return 0;
      }
      else {
        sv_utf8_decode(tmp_val);
      }
      
      DEBUG_TRACE("  %s = %s\n", SvPVX(key), SvPVX(tmp_val));
    
      av_push(av, tmp_val);
      
      if ( done < size ) {
        // Still more to read, consume the null separator
        buffer_consume(&tag->tag_data, 1);
        tag->offset++;
        done++;
      }
    }
    
    value = newRV_noinc( (SV *)av );
  }

  /* Find and check start of value */
  if (size + buffer_len(&tag->tag_data) + APE_ITEM_MINIMUM_SIZE > data_size) {
    return _ape_error(tag, "Impossible item length (greater than remaining space)", -3);
  }
  
  my_hv_store(tag->tags, upcase(SvPVX(key)), value);
  
  SvREFCNT_dec(key);

  tag->num_fields++;

  return 0;
}

int _ape_check_validity(ApeTag* tag, uint32_t flags, char* key, char* value) {
  unsigned long key_length;
  char* key_end;
  char* c;
  
  /* Check valid flags */
  if (flags > 7) {
    return _ape_error(tag, "Invalid item flags", -3);
  }
  
  /* Check valid key */
  key_length = strlen(key);
  key_end    = key + (long)key_length;

  if (key_length < 2) {
    return _ape_error(tag, "Invalid item key, too short (<2)", -3);
  }

  if (key_length > 255) {
    return _ape_error(tag, "Invalid item key, too long (>255)", -3);
  }

  if (key_length == 3) {
#ifdef _MSC_VER
    if (strnicmp(key, "id3", 3) == 0 || 
        strnicmp(key, "tag", 3) == 0 || 
        strnicmp(key, "mp+", 3) == 0) {
#else
    if (strncasecmp(key, "id3", 3) == 0 || 
        strncasecmp(key, "tag", 3) == 0 || 
        strncasecmp(key, "mp+", 3) == 0) {
#endif
      return _ape_error(tag, "Invalid item key 'id3, tag or mp+'", -3);
    }
  }

#ifdef _MSC_VER
  if (key_length == 4 && strnicmp(key, "oggs", 4) == 0) {
#else
  if (key_length == 4 && strncasecmp(key, "oggs", 4) == 0) {
#endif
    return _ape_error(tag, "Invalid item key 'oggs'", -3);
  }

  for (c = key; c < key_end; c++) {
    if ((unsigned char)(*c) < 0x20 || (unsigned char)(*c) > 0x7f) {
      return _ape_error(tag, "Invalid or non-ASCII key character", -3);
    }
  }
  
  if (tag->version > 1) {
    /* Check value is utf-8 if flags specify utf8 or external format*/
    if (((flags & APE_ITEM_TYPE_FLAGS) & 2) == 0 && !is_utf8_string((unsigned char*)(value), strlen(value))) {
      return _ape_error(tag, "Invalid UTF-8 value", -3);
    }
  }
  
  return 0;
}

static int
get_ape_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  int status = -1;
  ApeTag* tag;
  
  Newz(0, tag, sizeof(ApeTag), ApeTag);

  if (tag == NULL) {
    PerlIO_printf(PerlIO_stderr(), "APE: [Couldn't allocate memory (ApeTag)] %s\n", file);
    return status;
  }

  tag->fd         = infile;
  tag->info       = info;
  tag->tags       = tags;
  tag->filename   = file;
  tag->flags      = 0;
  tag->size       = 0;
  tag->offset     = 0;
  tag->item_count = 0;
  tag->num_fields = 0;

  status = _ape_parse(tag);

  buffer_free(&tag->tag_header);
  buffer_free(&tag->tag_footer);
  buffer_free(&tag->tag_data);
  Safefree(tag);

  return status;
}
