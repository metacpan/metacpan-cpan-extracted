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

#include "flac.h"

int
get_flac_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  flacinfo *flac = _flac_parse(infile, file, info, tags, 0);
  
  Safefree(flac);
  
  return 0;
}

flacinfo *
_flac_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking)
{
  int err = 0;
  int done = 0;
  unsigned char *bptr;
  unsigned int id3_size = 0;
  uint32_t song_length_ms;
  
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
  
  buffer_init(flac->buf, FLAC_BLOCK_SIZE);
  
  flac->file_size = _file_size(infile);
  
  if ( !_check_buf(infile, flac->buf, 10, FLAC_BLOCK_SIZE) ) {
    err = -1;
    goto out;
  }
  
  // Check for ID3 tags
  bptr = buffer_ptr(flac->buf);
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
    
    DEBUG_TRACE("Found ID3v2 tag of size %d\n", id3_size);
    
    flac->audio_offset += id3_size;
            
    // seek past ID3, we will parse it later
    if ( id3_size < buffer_len(flac->buf) ) {
      buffer_consume(flac->buf, id3_size);
    }
    else {
       buffer_clear(flac->buf);
       
      if (PerlIO_seek(infile, id3_size, SEEK_SET) < 0) {
        err = -1;
        goto out;
      }
    }
    
    if ( !_check_buf(infile, flac->buf, 4, FLAC_BLOCK_SIZE) ) {
      err = -1;
      goto out;
    }
  }
  
  // Verify fLaC magic
  bptr = buffer_ptr(flac->buf);
  if ( memcmp(bptr, "fLaC", 4) != 0 ) {
    PerlIO_printf(PerlIO_stderr(), "Not a valid FLAC file: %s\n", file);
    err = -1;
    goto out;
  }
  
  buffer_consume(flac->buf, 4);
  
  flac->audio_offset += 4;
  
  // Parse all metadata blocks
  while ( !done ) {
    uint8_t type;
    off_t len;
    
    if ( !_check_buf(infile, flac->buf, 4, FLAC_BLOCK_SIZE) ) {
      err = -1;
      goto out;
    }
    
    bptr = buffer_ptr(flac->buf);
    
    if ( bptr[0] & 0x80 ) {
      // last metadata block flag
      done = 1;
    }
    
    type = bptr[0] & 0x7f;
    len  = (bptr[1] << 16) | (bptr[2] << 8) | bptr[3];
    
    buffer_consume(flac->buf, 4);
    
    DEBUG_TRACE("Parsing metadata block, type %d, len %d, done %d\n", type, (int)len, done);
    
    if ( len > flac->file_size - flac->audio_offset ) {
      err = -1;
      goto out;
    }
    
    // Don't read in the full picture in case we aren't reading artwork
    // Do the same for padding, as it can be quite large in some files
    if ( type != FLAC_TYPE_PICTURE && type != FLAC_TYPE_PADDING ) {
      if ( !_check_buf(infile, flac->buf, len, len) ) {
        err = -1;
        goto out;
      }
    }
    
    flac->audio_offset += 4 + len;
    
    switch (type) {
      case FLAC_TYPE_STREAMINFO:
        _flac_parse_streaminfo(flac);
        break;
      
      case FLAC_TYPE_VORBIS_COMMENT:
        if ( !flac->seeking ) {
          // Vorbis comment parsing code from ogg.c
          _parse_vorbis_comments(flac->infile, flac->buf, tags, 0);
        }
        else {
          DEBUG_TRACE("  seeking, not parsing comments\n");
          buffer_consume(flac->buf, len);
        }
        break;
      
      case FLAC_TYPE_APPLICATION:
        if ( !flac->seeking ) {
          _flac_parse_application(flac, len);
        }
        else {
          DEBUG_TRACE("  seeking, skipping application\n");
          buffer_consume(flac->buf, len);
        }
        break;
        
      case FLAC_TYPE_SEEKTABLE:
        if (flac->seeking) {
          _flac_parse_seektable(flac, len);
        }
        else {
          DEBUG_TRACE("  not seeking, skipping seektable\n");
          buffer_consume(flac->buf, len);
        }
        break;
        
      case FLAC_TYPE_CUESHEET:
        if ( !flac->seeking ) {
          _flac_parse_cuesheet(flac);
        }
        else {
          DEBUG_TRACE("  seeking, skipping cuesheet\n");
          buffer_consume(flac->buf, len);
        }
        break;
      
      case FLAC_TYPE_PICTURE:
        if ( !flac->seeking ) {
          if ( !_flac_parse_picture(flac) ) {
            goto out;
          }
        }
        else {
          DEBUG_TRACE("  seeking, skipping picture\n");
          _flac_skip(flac, len);
        }
        break;
      
      case FLAC_TYPE_PADDING:
      default:
        DEBUG_TRACE("  unhandled or padding, skipping\n");
        _flac_skip(flac, len);
    } 
  }
  
  song_length_ms = SvIV( *( my_hv_fetch(info, "song_length_ms") ) );
  
  if (song_length_ms > 0) {
    my_hv_store( info, "bitrate", newSVuv( _bitrate(flac->file_size - flac->audio_offset, song_length_ms) ) );
  }
  else {
    if (!seeking) {
      // Find the first/last frames and manually calculate duration and bitrate
      off_t frame_offset;
      uint64_t first_sample;
      uint64_t last_sample;
      uint64_t tmp;
    
      DEBUG_TRACE("Manually determining duration/bitrate\n");
      
      Newz(0, flac->scratch, sizeof(Buffer), Buffer);
    
      if ( _flac_first_last_sample(flac, flac->audio_offset, &frame_offset, &first_sample, &tmp, 0) ) {
        DEBUG_TRACE("  First sample: %llu (offset %llu)\n", first_sample, frame_offset);
        
        // XXX This last sample isn't really correct, seeking back max_framesize will most likely be several frames
        // from the end, resulting in a slightly shortened duration. Reading backwards through the file
        // would provide a more accurate result
        if ( _flac_first_last_sample(flac, flac->file_size - flac->max_framesize, &frame_offset, &tmp, &last_sample, 0) ) {
          if (flac->samplerate) {
            song_length_ms = (uint32_t)(( ((last_sample - first_sample) * 1.0) / flac->samplerate) * 1000);
            my_hv_store( info, "song_length_ms", newSVuv(song_length_ms) );
            my_hv_store( info, "bitrate", newSVuv( _bitrate(flac->file_size - flac->audio_offset, song_length_ms) ) );
            my_hv_store( info, "total_samples", newSVuv( last_sample - first_sample ) );
          }
          
          DEBUG_TRACE("  Last sample: %llu (offset %llu)\n", last_sample, frame_offset);
        }
      }
      
      buffer_free(flac->scratch);
      Safefree(flac->scratch);
    }
  }
  
  my_hv_store( info, "file_size", newSVuv(flac->file_size) );
  my_hv_store( info, "audio_offset", newSVuv(flac->audio_offset) );
  my_hv_store( info, "audio_size", newSVuv(flac->file_size - flac->audio_offset) );
  
  // Parse ID3 last, due to an issue with libid3tag screwing
  // up the filehandle
  if (id3_size && !seeking) {
    parse_id3(infile, file, info, tags, 0, flac->file_size);
  }

out:
  buffer_free(flac->buf);
  Safefree(flac->buf);
  
  return flac;
}

// offset is in ms, does sample-accurate seeking, using seektable if available
// based on libFLAC seek_to_absolute_sample_
static int
flac_find_frame(PerlIO *infile, char *file, int offset)
{
  off_t frame_offset = -1;
  uint64_t target_sample;
  uint32_t approx_bytes_per_frame;
  uint64_t lower_bound, upper_bound, lower_bound_sample, upper_bound_sample;
  int64_t pos = -1;
  int8_t max_tries = 100;
  
  // We need to read all metadata first to get some data we need to calculate
  HV *info = newHV();
  HV *tags = newHV();
  flacinfo *flac = _flac_parse(infile, file, info, tags, 1);
  
  // Allocate scratch buffer
  Newz(0, flac->scratch, sizeof(Buffer), Buffer);
  
  if ( !flac->samplerate || !flac->total_samples ) {
    // Can't seek in file without samplerate
    goto out;
  }
  
  // Determine target sample we're looking for
  target_sample = ((offset - 1) / 10) * (flac->samplerate / 100);
  DEBUG_TRACE("Looking for target sample %llu\n", target_sample);
  
  if (flac->min_blocksize == flac->max_blocksize && flac->min_blocksize > 0)
    approx_bytes_per_frame = flac->min_blocksize * flac->channels * flac->bits_per_sample/8 + 64;
  else if (flac->max_framesize > 0)
    approx_bytes_per_frame = (flac->max_framesize + flac->min_framesize) / 2 + 1;
  else
    approx_bytes_per_frame = 4096 * flac->channels * flac->bits_per_sample/8 + 64;
  
  DEBUG_TRACE("approx_bytes_per_frame: %d\n", approx_bytes_per_frame);
  
  lower_bound        = flac->audio_offset;
  lower_bound_sample = 0;
  upper_bound        = flac->file_size;
  upper_bound_sample = flac->total_samples;
  
  if (flac->num_seekpoints) {
    // Use seektable to find seek point
    // Start looking at seekpoint 1
    int i;
    uint64_t new_lower_bound        = lower_bound;
    uint64_t new_upper_bound        = upper_bound;
    uint64_t new_lower_bound_sample = lower_bound_sample;
    uint64_t new_upper_bound_sample = upper_bound_sample;
    
    DEBUG_TRACE("Checking seektable...\n");
    
    for (i = flac->num_seekpoints - 1; i >= 0; i--) {
      if (
           flac->seekpoints[i].sample_number != 0xFFFFFFFFFFFFFFFFLL
        && flac->seekpoints[i].frame_samples > 0
        && (flac->total_samples <= 0 || flac->seekpoints[i].sample_number < flac->total_samples)
        && flac->seekpoints[i].sample_number <= target_sample
      )
        break;
    }
    
    if (i >= 0) {
      // we found a seek point
      new_lower_bound        = flac->audio_offset + flac->seekpoints[i].stream_offset;
      new_lower_bound_sample = flac->seekpoints[i].sample_number;
      
      DEBUG_TRACE("  seektable new_lower_bound %llu, new_lower_bound_sample %llu\n",
        new_lower_bound, new_lower_bound_sample);
    }
    
    // Find the closest seek point > target_sample
    for (i = 0; i < flac->num_seekpoints; i++) {
      if (
           flac->seekpoints[i].sample_number != 0xFFFFFFFFFFFFFFFFLL
        && flac->seekpoints[i].frame_samples > 0
        && (flac->total_samples <= 0 || flac->seekpoints[i].sample_number < flac->total_samples)
        && flac->seekpoints[i].sample_number > target_sample
      )
        break;
    }
    
    if (i < flac->num_seekpoints) {
      // we found a seek point
      new_upper_bound        = flac->audio_offset + flac->seekpoints[i].stream_offset;
      new_upper_bound_sample = flac->seekpoints[i].sample_number;
      
      DEBUG_TRACE("  seektable new_upper_bound %llu, new_upper_bound_sample %llu\n",
        new_upper_bound, new_upper_bound_sample);
    }
    
    if (new_upper_bound >= new_lower_bound) {
      lower_bound = new_lower_bound;
      upper_bound = new_upper_bound;
      lower_bound_sample = new_lower_bound_sample;
      upper_bound_sample = new_upper_bound_sample;
    }
  }
  
  if (upper_bound_sample == lower_bound_sample)
    upper_bound_sample++;
  
  while (max_tries--) {
    int ret = -1;
    uint64_t this_frame_sample;
    uint64_t last_sample;
    
    // check if bounds are still ok
    if (lower_bound_sample >= upper_bound_sample || lower_bound > upper_bound) {
      DEBUG_TRACE("Error: out of bounds\n");
      frame_offset = -1;
      goto out;
    }
    
    // estimate position
    pos = (int64_t)lower_bound + (int64_t)(
      (double)((target_sample - lower_bound_sample) * (upper_bound - lower_bound))
      /
      (double)(upper_bound_sample - lower_bound_sample)
    ) - approx_bytes_per_frame;
    
    DEBUG_TRACE("Initial pos: %lld\n", pos);
  
    if (pos < (int64_t)lower_bound)
      pos = lower_bound;
    
    if (pos >= (int64_t)upper_bound)
      pos = upper_bound - FLAC_FRAME_MAX_HEADER;
    
    DEBUG_TRACE("Searching at pos %lld (lb/lbs %llu/%llu, ub/ubs %llu/%llu)\n",
      pos, lower_bound, lower_bound_sample, upper_bound, upper_bound_sample);
    
    ret = _flac_first_last_sample(flac, pos, &frame_offset, &this_frame_sample, &last_sample, target_sample); 
       
    if (ret < 0) {
      // Error
      goto out;
    }
    else if (ret == 0) {
      // No valid frame found in range pos - flac->max_framesize, adjust bounds and retry  
      upper_bound = pos;
      upper_bound_sample -= flac->min_blocksize;
      
      DEBUG_TRACE("  No valid frame found, retrying (ub/ubs %llu/%llu)\n", upper_bound, upper_bound_sample);
      
      continue;
    }
    
    // make sure we are not seeking in corrupted stream
    if (this_frame_sample < lower_bound_sample) {
      DEBUG_TRACE("  Frame at %d, this_frame_sample %llu, < lower_bound_sample %llu, aborting\n",
        (int)frame_offset, this_frame_sample, lower_bound_sample);
      
      goto out;
    }
    
    DEBUG_TRACE("    Frame at %d, this_frame_sample %llu, last_sample %llu (target %llu)\n",
      (int)frame_offset, this_frame_sample, last_sample, target_sample);
    
    if (target_sample >= this_frame_sample && target_sample < last_sample) {
      DEBUG_TRACE("    Found target frame\n");
      break;
    }
    
    // narrow the search
    if (target_sample < this_frame_sample) {
      upper_bound_sample = this_frame_sample;
      upper_bound = frame_offset;
      approx_bytes_per_frame = 2 * (upper_bound - pos) / 3 + 16;
      
      DEBUG_TRACE("    Moving upper_bound to %llu, upper_bound_sample to %llu, approx_bytes_per_frame %d\n",
        upper_bound, upper_bound_sample, approx_bytes_per_frame);
    }
    else {
      lower_bound_sample = last_sample;
      lower_bound = frame_offset + 1;
      approx_bytes_per_frame = 2 * (lower_bound - pos) / 3 + 16;
      
      DEBUG_TRACE("    Moving lower_bound to %llu, lower_bound_sample to %llu, approx_bytes_per_frame %d\n",
        lower_bound, lower_bound_sample, approx_bytes_per_frame);
    }
  }
  
  DEBUG_TRACE("max_tries: %d\n", max_tries);
  
out:
  // Don't leak
  SvREFCNT_dec(info);
  SvREFCNT_dec(tags);
  
  // free seek struct
  Safefree(flac->seekpoints);
  
  // free scratch buffer
  if (flac->scratch->alloc)
    buffer_free(flac->scratch);
  Safefree(flac->scratch);
  
  Safefree(flac);
  
  return frame_offset;
}

// Returns:
//  1: Found a valid frame
//  0: Did not find a valid frame
// -1: Error
int
_flac_first_last_sample(flacinfo *flac, off_t seek_offset, off_t *frame_offset, uint64_t *first_sample, uint64_t *last_sample, uint64_t target_sample)
{
  unsigned char *bptr;
  unsigned int buf_size;
  int ret = 0;
  uint32_t i;
  
  buffer_init_or_clear(flac->scratch, flac->max_framesize);
  
  if (seek_offset > flac->file_size - FLAC_FRAME_MAX_HEADER) {
    DEBUG_TRACE("  Error: seek_offset > file_size - header size\n");
    ret = -1;
    goto out;
  }
  
  if ( (PerlIO_seek(flac->infile, seek_offset, SEEK_SET)) == -1 ) {
    DEBUG_TRACE("  Error: seek failed\n");
    ret = -1;
    goto out;
  }
    
  if ( !_check_buf(flac->infile, flac->scratch, FLAC_FRAME_MAX_HEADER, flac->max_framesize) ) {
    DEBUG_TRACE("  Error: read failed\n");
    ret = -1;
    goto out;
  }

  bptr = buffer_ptr(flac->scratch);
  buf_size = buffer_len(flac->scratch);

  for (i = 0; i != buf_size - FLAC_HEADER_LEN; i++) {
    // Verify sync and various reserved bits
    if ( bptr[i] != 0xFF
      || (bptr[i+1] >> 2) != 0x3E
      || bptr[i+1] & 0x02
      || bptr[i+3] & 0x01
    ) {
      continue;
    }
    
    DEBUG_TRACE("Checking frame header @ %d: %0x %0x %0x %0x\n", (int)seek_offset + i, bptr[i], bptr[i+1], bptr[i+2], bptr[i+3]);
    
    // Verify we have a valid FLAC frame header
    // and get the first/last sample numbers in the frame if it's valid
    if ( !_flac_read_frame_header(flac, &bptr[i], first_sample, last_sample) ) {
      DEBUG_TRACE("  Unable to read frame header\n");
      continue;
    }
    
    DEBUG_TRACE("  first_sample %llu\n", *first_sample);
    
    *frame_offset = seek_offset + i;
    ret = 1;
    
    // If looking for a target sample, return the nearest frame found in this buffer
    if (target_sample) {
      if (target_sample >= *first_sample && target_sample < *last_sample) {
        // This frame is the one
        break;
      }
      else if (target_sample < *first_sample) {
        // Too far, return what we have
        break;
      }
    }
    else {
      // Not looking for a target sample, return first one found
      break;
    }
  }
  
out:
  if (ret <= 0)
    *frame_offset = -1;
  
  return ret;
}

int
_flac_read_frame_header(flacinfo *flac, unsigned char *buf, uint64_t *first_sample, uint64_t *last_sample)
{
  // A lot of this code is based on libFLAC stream_decoder.c read_frame_header_
  uint32_t x;
  uint64_t xx;
  uint32_t blocksize = 0;
  uint32_t blocksize_hint = 0;
  uint32_t samplerate_hint = 0;
  uint32_t frame_number = 0;
  uint8_t  raw_header_len = 4;
  uint8_t  crc8;
  
  // Block size
  switch(x = buf[2] >> 4) {
    case 0:
      return 0;
    case 1:
      blocksize = 192;
      break;
    case 2: case 3: case 4: case 5:
      blocksize = 576 << (x-2);
      break;
    case 6: case 7:
      blocksize_hint = x;
      break;
    case 8: case 9: case 10: case 11: case 12: case 13: case 14: case 15:
      blocksize = 256 << (x-8);
      break;
    default:
      break;
  }
  
  // Sample rate, all we need here is the hint
  switch(x = buf[2] & 0x0f) {
    case 12: case 13: case 14:
      samplerate_hint = x;
      break;
    case 15:
      return 0;
    default:
      break;
  }
  
  if ( buf[1] & 0x01 || flac->min_blocksize != flac->max_blocksize ) {
    // Variable blocksize
    // XXX need test
    if ( !_flac_read_utf8_uint64(buf, &xx, &raw_header_len) )
      return 0;
    
    if ( xx == 0xFFFFFFFFFFFFFFFFLL )
      return 0;
      
    DEBUG_TRACE("  variable blocksize, first sample %llu\n", xx);
    
    *first_sample = xx;
  }
  else {
    // Fixed blocksize, x = frame number
    if ( !_flac_read_utf8_uint32(buf, &x, &raw_header_len) )
      return 0;
    
    if ( x == 0xFFFFFFFF )
      return 0;
    
    DEBUG_TRACE("  fixed blocksize, frame number %d\n", x);
    
    frame_number = x;
  }
  
  if (blocksize_hint) {
    DEBUG_TRACE("  blocksize_hint %d\n", blocksize_hint);
    x = buf[raw_header_len++];
    if (blocksize_hint == 7) {
      uint32_t _x = buf[raw_header_len++];
      x = (x << 8) | _x;
    }
    blocksize = x + 1;
  }
  
  DEBUG_TRACE("  blocksize %d\n", blocksize);
  
  // XXX need test
  if (samplerate_hint) {
    DEBUG_TRACE("  samplerate_hint %d\n", samplerate_hint);
    raw_header_len++;
    if (samplerate_hint != 12) {
      raw_header_len++;
    }
  }
  
  // Verify CRC-8
  crc8 = buf[raw_header_len];
  if ( _flac_crc8(buf, raw_header_len) != crc8 ) {
    DEBUG_TRACE("  CRC failed\n");
    return 0;
  }
  
  // Calculate sample number from frame number if needed
  if (frame_number) {
    // Fixed blocksize, use min_blocksize value as blocksize above may be different if last frame
    *first_sample = frame_number * flac->min_blocksize;
  }
  else {
    *first_sample = 0;
  }
  
  *last_sample = *first_sample + blocksize;
  
  return 1;
}

void
_flac_parse_streaminfo(flacinfo *flac)
{
  uint64_t tmp;
  SV *md5;
  unsigned char *bptr;
  int i;
  uint32_t song_length_ms;
  
  flac->min_blocksize = buffer_get_short(flac->buf);
  my_hv_store( flac->info, "minimum_blocksize", newSVuv(flac->min_blocksize) );
  
  flac->max_blocksize = buffer_get_short(flac->buf);
  my_hv_store( flac->info, "maximum_blocksize", newSVuv(flac->max_blocksize) );
  
  flac->min_framesize = buffer_get_int24(flac->buf);
  my_hv_store( flac->info, "minimum_framesize", newSVuv(flac->min_framesize) );
  
  flac->max_framesize = buffer_get_int24(flac->buf);
  my_hv_store( flac->info, "maximum_framesize", newSVuv(flac->max_framesize) );
  
  if ( !flac->max_framesize ) {
    flac->max_framesize = FLAC_MAX_FRAMESIZE;
  }
  
  tmp = buffer_get_int64(flac->buf);
  
  flac->samplerate      = (uint32_t)((tmp >> 44) & 0xFFFFF);
  flac->total_samples   = tmp & 0xFFFFFFFFFLL;
  flac->channels        = (uint32_t)(((tmp >> 41) & 0x7) + 1);
  flac->bits_per_sample = (uint32_t)(((tmp >> 36) & 0x1F) + 1);
  
  my_hv_store( flac->info, "samplerate", newSVuv(flac->samplerate) );
  my_hv_store( flac->info, "channels", newSVuv(flac->channels) );
  my_hv_store( flac->info, "bits_per_sample", newSVuv(flac->bits_per_sample) );
  my_hv_store( flac->info, "total_samples", newSVnv(flac->total_samples) );
  
  bptr = buffer_ptr(flac->buf);
  md5 = newSVpvf("%02x", bptr[0]);

  for (i = 1; i < 16; i++) {
    sv_catpvf(md5, "%02x", bptr[i]);
  }

  my_hv_store(flac->info, "audio_md5", md5);
  buffer_consume(flac->buf, 16);
  
  song_length_ms = (uint32_t)(( (flac->total_samples * 1.0) / flac->samplerate) * 1000);
  my_hv_store( flac->info, "song_length_ms", newSVuv(song_length_ms) );
}

void
_flac_parse_application(flacinfo *flac, int len)
{
  HV *app;
  SV *id = newSVuv( buffer_get_int(flac->buf) );
  SV *data = newSVpvn( buffer_ptr(flac->buf), len - 4 );
  buffer_consume(flac->buf, len - 4);
  
  if ( my_hv_exists(flac->tags, "APPLICATION") ) {
    // XXX needs test
    SV **entry = my_hv_fetch(flac->tags, "APPLICATION");
    if (entry != NULL) {
      app = (HV *)SvRV(*entry);
      my_hv_store_ent(app, id, data);
    }
  }
  else {
    app = newHV();
    
    my_hv_store_ent(app, id, data);

    my_hv_store( flac->tags, "APPLICATION", newRV_noinc( (SV *)app ) );
  }
  
  SvREFCNT_dec(id);
}

void
_flac_parse_seektable(flacinfo *flac, int len)
{
  uint32_t i;
  uint32_t count = len / 18;
  
  flac->num_seekpoints = count;
  
  New(0, 
    flac->seekpoints,
    count * sizeof(*flac->seekpoints),
    struct seekpoint
  );
  
  for (i = 0; i < count; i++) {
    flac->seekpoints[i].sample_number = buffer_get_int64(flac->buf);
    flac->seekpoints[i].stream_offset = buffer_get_int64(flac->buf);
    flac->seekpoints[i].frame_samples = buffer_get_short(flac->buf);
    
    DEBUG_TRACE(
      "  sample_number %llu stream_offset %llu frame_samples %d\n",
      flac->seekpoints[i].sample_number,
      flac->seekpoints[i].stream_offset,
      flac->seekpoints[i].frame_samples
    );
  }
}

void
_flac_parse_cuesheet(flacinfo *flac)
{
  AV *cue = newAV();
  unsigned char *bptr;
  uint64_t leadin;
  uint8_t is_cd;
  char decimal[21];
  uint8_t num_tracks;
  
  // Catalog number, may be empty
  bptr = buffer_ptr(flac->buf);
  if (bptr[0]) {
    av_push( cue, newSVpvf("CATALOG %s\n", bptr) );
  }
  buffer_consume(flac->buf, 128);
  
  leadin = buffer_get_int64(flac->buf);
  is_cd = (uint8_t)buffer_get_char(flac->buf);
  
  buffer_consume(flac->buf, 258);
  
  num_tracks = (uint8_t)buffer_get_char(flac->buf);
  DEBUG_TRACE("  number of cue tracks: %d\n", num_tracks);
  
  av_push( cue, newSVpvf("FILE \"%s\" FLAC\n", flac->file) );
  
  while (num_tracks--) {
    char isrc[13];
    uint8_t tmp;
    uint8_t type;
    uint8_t pre;
    uint8_t num_index;
    
    uint64_t track_offset = buffer_get_int64(flac->buf);
    uint8_t  tracknum = (uint8_t)buffer_get_char(flac->buf);
    
    buffer_get(flac->buf, isrc, 12);
    isrc[12] = '\0';
    
    tmp = (uint8_t)buffer_get_char(flac->buf);
    type = (tmp >> 7) & 0x1;
    pre  = (tmp >> 6) & 0x1;
    buffer_consume(flac->buf, 13);
    
    num_index = (uint8_t)buffer_get_char(flac->buf);
    
    DEBUG_TRACE("    track %d: offset %llu, type %d, pre %d, num_index %d\n", tracknum, track_offset, type, pre, num_index);
    
    if (tracknum > 0 && tracknum < 100) {
      av_push( cue, newSVpvf("  TRACK %02u %s\n",
        tracknum, type == 0 ? "AUDIO" : "DATA"
      ) );
      
      if (pre) {
        av_push( cue, newSVpv("    FLAGS PRE\n", 0) );
      }
      
      if (isrc[0]) {
        av_push( cue, newSVpvf("    ISRC %s\n", isrc) );
      }
    }
    
    while (num_index--) {
      SV *index;
      
      uint64_t index_offset = buffer_get_int64(flac->buf);
      uint8_t index_num = (uint8_t)buffer_get_char(flac->buf);
      buffer_consume(flac->buf, 3);
      
      DEBUG_TRACE("      index %d, offset %llu\n", index_num, index_offset);
      
      index = newSVpvf("    INDEX %02u ", index_num);
      
      if (is_cd) {
        uint64_t frame = ((track_offset + index_offset) / (flac->samplerate / 75));
        uint8_t m, s, f;
        
        f = (uint8_t)(frame % 75);
        frame /= 75;
        s = (uint8_t)(frame % 60);
        frame /= 60;
        m = (uint8_t)frame;

        sv_catpvf(index, "%02u:%02u:%02u\n", m, s, f);
      }
      else {
        // XXX need test
        sprintf(decimal, "%"PRIu64, track_offset + index_offset);
        sv_catpvf(index, "%s\n", decimal);
      }
      
      av_push( cue, index );
    }
    
    if (tracknum == 170) {
      // Add lead-in and lead-out
      sprintf(decimal, "%"PRIu64, leadin);
      av_push( cue, newSVpvf("REM FLAC__lead-in %s\n", decimal) );
      
      // XXX is tracknum right here?
      sprintf(decimal, "%"PRIu64, track_offset);
      av_push( cue, newSVpvf("REM FLAC__lead-out %u %s\n", tracknum, decimal) );
    }
  }
  
  my_hv_store( flac->tags, "CUESHEET_BLOCK", newRV_noinc( (SV *)cue ) );
}

int
_flac_parse_picture(flacinfo *flac)
{
  AV *pictures;
  HV *picture;
  int ret = 1;
  uint32_t pic_length;
  
  picture = _decode_flac_picture(flac->infile, flac->buf, &pic_length);
  if ( !picture ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid FLAC file: %s, bad picture block\n", flac->file);
    ret = 0;
    goto out;
  }
  
  // Skip past pic data if necessary
  if ( _env_true("AUDIO_SCAN_NO_ARTWORK") ) {
    my_hv_store( picture, "offset", newSVuv(flac->audio_offset - pic_length) );
    _flac_skip(flac, pic_length);
  }
  else {
    buffer_consume(flac->buf, pic_length);
  }
  
  DEBUG_TRACE("  found picture of length %d\n", pic_length);
  
  if ( my_hv_exists(flac->tags, "ALLPICTURES") ) {
    SV **entry = my_hv_fetch(flac->tags, "ALLPICTURES");
    if (entry != NULL) {
      pictures = (AV *)SvRV(*entry);
      av_push( pictures, newRV_noinc( (SV *)picture ) );
    }
  }
  else {
    pictures = newAV();
    
    av_push( pictures, newRV_noinc( (SV *)picture ) );

    my_hv_store( flac->tags, "ALLPICTURES", newRV_noinc( (SV *)pictures ) );
  }

out:
  return ret;
}

/* CRC-8, poly = x^8 + x^2 + x^1 + x^0, init = 0 */
uint8_t const _flac_crc8_table[256] = {
  0x00, 0x07, 0x0E, 0x09, 0x1C, 0x1B, 0x12, 0x15,
  0x38, 0x3F, 0x36, 0x31, 0x24, 0x23, 0x2A, 0x2D,
  0x70, 0x77, 0x7E, 0x79, 0x6C, 0x6B, 0x62, 0x65,
  0x48, 0x4F, 0x46, 0x41, 0x54, 0x53, 0x5A, 0x5D,
  0xE0, 0xE7, 0xEE, 0xE9, 0xFC, 0xFB, 0xF2, 0xF5,
  0xD8, 0xDF, 0xD6, 0xD1, 0xC4, 0xC3, 0xCA, 0xCD,
  0x90, 0x97, 0x9E, 0x99, 0x8C, 0x8B, 0x82, 0x85,
  0xA8, 0xAF, 0xA6, 0xA1, 0xB4, 0xB3, 0xBA, 0xBD,
  0xC7, 0xC0, 0xC9, 0xCE, 0xDB, 0xDC, 0xD5, 0xD2,
  0xFF, 0xF8, 0xF1, 0xF6, 0xE3, 0xE4, 0xED, 0xEA,
  0xB7, 0xB0, 0xB9, 0xBE, 0xAB, 0xAC, 0xA5, 0xA2,
  0x8F, 0x88, 0x81, 0x86, 0x93, 0x94, 0x9D, 0x9A,
  0x27, 0x20, 0x29, 0x2E, 0x3B, 0x3C, 0x35, 0x32,
  0x1F, 0x18, 0x11, 0x16, 0x03, 0x04, 0x0D, 0x0A,
  0x57, 0x50, 0x59, 0x5E, 0x4B, 0x4C, 0x45, 0x42,
  0x6F, 0x68, 0x61, 0x66, 0x73, 0x74, 0x7D, 0x7A,
  0x89, 0x8E, 0x87, 0x80, 0x95, 0x92, 0x9B, 0x9C,
  0xB1, 0xB6, 0xBF, 0xB8, 0xAD, 0xAA, 0xA3, 0xA4,
  0xF9, 0xFE, 0xF7, 0xF0, 0xE5, 0xE2, 0xEB, 0xEC,
  0xC1, 0xC6, 0xCF, 0xC8, 0xDD, 0xDA, 0xD3, 0xD4,
  0x69, 0x6E, 0x67, 0x60, 0x75, 0x72, 0x7B, 0x7C,
  0x51, 0x56, 0x5F, 0x58, 0x4D, 0x4A, 0x43, 0x44,
  0x19, 0x1E, 0x17, 0x10, 0x05, 0x02, 0x0B, 0x0C,
  0x21, 0x26, 0x2F, 0x28, 0x3D, 0x3A, 0x33, 0x34,
  0x4E, 0x49, 0x40, 0x47, 0x52, 0x55, 0x5C, 0x5B,
  0x76, 0x71, 0x78, 0x7F, 0x6A, 0x6D, 0x64, 0x63,
  0x3E, 0x39, 0x30, 0x37, 0x22, 0x25, 0x2C, 0x2B,
  0x06, 0x01, 0x08, 0x0F, 0x1A, 0x1D, 0x14, 0x13,
  0xAE, 0xA9, 0xA0, 0xA7, 0xB2, 0xB5, 0xBC, 0xBB,
  0x96, 0x91, 0x98, 0x9F, 0x8A, 0x8D, 0x84, 0x83,
  0xDE, 0xD9, 0xD0, 0xD7, 0xC2, 0xC5, 0xCC, 0xCB,
  0xE6, 0xE1, 0xE8, 0xEF, 0xFA, 0xFD, 0xF4, 0xF3
};

uint8_t
_flac_crc8(const unsigned char *buf, unsigned len)
{
  uint8_t crc = 0;

  while(len--)
    crc = _flac_crc8_table[crc ^ *buf++];

  return crc;
}

int
_flac_read_utf8_uint64(unsigned char *raw, uint64_t *val, uint8_t *rawlen)
{
  uint64_t v = 0;
  uint32_t x;
  unsigned i;
  
  x = raw[(*rawlen)++];
  
  if(!(x & 0x80)) { /* 0xxxxxxx */
    v = x;
    i = 0;
  }
  else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
    v = x & 0x1F;
    i = 1;
  }
  else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
    v = x & 0x0F;
    i = 2;
  }
  else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
    v = x & 0x07;
    i = 3;
  }
  else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
    v = x & 0x03;
    i = 4;
  }
  else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
    v = x & 0x01;
    i = 5;
  }
  else if(x & 0xFE && !(x & 0x01)) { /* 11111110 */
    v = 0;
    i = 6;
  }
  else {
    *val = 0xffffffffffffffffULL;
    return 1;
  }
  
  for( ; i; i--) {
    x = raw[(*rawlen)++];
    if(!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
      *val = 0xffffffffffffffffULL;
      return 1;
    }
    v <<= 6;
    v |= (x & 0x3F);
  }
  *val = v;
  return 1;
}

int
_flac_read_utf8_uint32(unsigned char *raw, uint32_t *val, uint8_t *rawlen)
{
  uint32_t v = 0;
  uint32_t x;
  unsigned i;
  
  x = raw[(*rawlen)++];
  
  if(!(x & 0x80)) { /* 0xxxxxxx */
    v = x;
    i = 0;
  }
  else if(x & 0xC0 && !(x & 0x20)) { /* 110xxxxx */
    v = x & 0x1F;
    i = 1;
  }
  else if(x & 0xE0 && !(x & 0x10)) { /* 1110xxxx */
    v = x & 0x0F;
    i = 2;
  }
  else if(x & 0xF0 && !(x & 0x08)) { /* 11110xxx */
    v = x & 0x07;
    i = 3;
  }
  else if(x & 0xF8 && !(x & 0x04)) { /* 111110xx */
    v = x & 0x03;
    i = 4;
  }
  else if(x & 0xFC && !(x & 0x02)) { /* 1111110x */
    v = x & 0x01;
    i = 5;
  }
  else {
    *val = 0xffffffff;
    return 1;
  }
  
  for( ; i; i--) {
    x = raw[(*rawlen)++];
    if(!(x & 0x80) || (x & 0x40)) { /* 10xxxxxx */
      *val = 0xffffffff;
      return 1;
    }
    v <<= 6;
    v |= (x & 0x3F);
  }
  *val = v;
  return 1;
}

void
_flac_skip(flacinfo *flac, uint32_t size)
{
  if ( buffer_len(flac->buf) >= size ) {
    buffer_consume(flac->buf, size);
    
    DEBUG_TRACE("  skipped buffer data size %d\n", size);
  }
  else {
    PerlIO_seek(flac->infile, size - buffer_len(flac->buf), SEEK_CUR);
    buffer_clear(flac->buf);
    
    DEBUG_TRACE("  seeked past %d bytes to %d\n", size, (int)PerlIO_tell(flac->infile));
  }
}
