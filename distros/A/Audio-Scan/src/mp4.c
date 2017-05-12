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

#include "mp4.h"

static int
get_mp4tags(PerlIO *infile, char *file, HV *info, HV *tags)
{
  mp4info *mp4 = _mp4_parse(infile, file, info, tags, 0);
  
  Safefree(mp4);

  return 0;
}

// wrapper to return just the file offset
int
mp4_find_frame(PerlIO *infile, char *file, int offset)
{
  HV *info = newHV();
  int frame_offset = -1;
  
  mp4_find_frame_return_info(infile, file, offset, info);
  
  if ( my_hv_exists(info, "seek_offset") ) {
    frame_offset = SvIV( *(my_hv_fetch(info, "seek_offset") ) );
  }
  
  SvREFCNT_dec(info);
  
  return frame_offset;
}

// offset is in ms
// This is based on code from Rockbox
int
mp4_find_frame_return_info(PerlIO *infile, char *file, int offset, HV *info)
{
  int ret = 1;
  uint16_t samplerate = 0;
  uint32_t sound_sample_loc;
  uint32_t i = 0;
  uint32_t j = 0;
  uint32_t new_sample = 0;
  uint32_t new_sound_sample = 0;
  
  uint32_t chunk = 1;
  uint32_t range_samples = 0;
  uint32_t total_samples = 0;
  uint32_t skipped_samples = 0;
  uint32_t chunk_sample;
  uint32_t prev_chunk;
  uint32_t prev_chunk_samples;
  uint32_t file_offset;
  uint32_t chunk_offset;
  
  uint32_t box_size = 0;
  Buffer tmp_buf;
  char tmp_size[4];
  
  // We need to read all info first to get some data we need to calculate
  HV *tags = newHV();
  mp4info *mp4 = _mp4_parse(infile, file, info, tags, 1);
  
  // Init seek buffer
  //  Newz(0, &tmp_buf, sizeof(Buffer), Buffer);
  buffer_init(&tmp_buf, MP4_BLOCK_SIZE);
  
  // Seeking not yet supported for files with multiple tracks
  if (mp4->track_count > 1) {
    ret = -1;
    goto out;
  }
  
  if ( !my_hv_exists(info, "samplerate") ) {
    PerlIO_printf(PerlIO_stderr(), "find_frame: unknown sample rate\n");
    ret = -1;
    goto out;
  }
  
  // Pull out the samplerate
  samplerate = SvIV( *( my_hv_fetch( info, "samplerate" ) ) );
  
  // convert offset to sound_sample_loc
  sound_sample_loc = (offset / 10) * (samplerate / 100);
  DEBUG_TRACE("Looking for target sample %u\n", sound_sample_loc);
  
  // Make sure we have the necessary metadata
  if ( 
       !mp4->num_time_to_samples 
    || !mp4->num_sample_byte_sizes
    || !mp4->num_sample_to_chunks
    || !mp4->num_chunk_offsets
  ) {
    PerlIO_printf(PerlIO_stderr(), "find_frame: File does not contain seek metadata: %s\n", file);
    ret = -1;
    goto out;
  }
  
  // Find the destination block from time_to_sample array
  while ( (i < mp4->num_time_to_samples) &&
      (new_sound_sample < sound_sample_loc)
  ) {
      j = (sound_sample_loc - new_sound_sample) / mp4->time_to_sample[i].sample_duration;
      
      DEBUG_TRACE(
        "i = %d / j = %d, sample_count[i]: %d, sample_duration[i]: %d\n",
        i, j,
        mp4->time_to_sample[i].sample_count,
        mp4->time_to_sample[i].sample_duration
      );
  
      if (j <= mp4->time_to_sample[i].sample_count) {
        new_sample += j;
        new_sound_sample += j * mp4->time_to_sample[i].sample_duration;
        break;
      } 
      else {
        // XXX need test for this bit of code (variable stts)
        new_sound_sample += (mp4->time_to_sample[i].sample_duration
            * mp4->time_to_sample[i].sample_count);
        new_sample += mp4->time_to_sample[i].sample_count;
        i++;
      }
  }
  
  if ( new_sample >= mp4->num_sample_byte_sizes ) {
    PerlIO_printf(PerlIO_stderr(), "find_frame: Offset out of range (%d >= %d)\n", new_sample, mp4->num_sample_byte_sizes);
    ret = -1;
    goto out;
  }
  
  DEBUG_TRACE("new_sample: %d, new_sound_sample: %d\n", new_sample, new_sound_sample);
  
  // Write new stts box
  {
    int i;
    uint32_t total_sample_count = _mp4_total_samples(mp4);
    uint32_t stts_entries = total_sample_count - new_sample;
    uint32_t cur_duration = 0;
    struct tts *stts;
    int32_t stts_index = -1;
    
    Newz(0, stts, stts_entries * sizeof(*stts), struct tts);
    
    for (i = new_sample; i < total_sample_count; i++) {
      uint32_t duration = _mp4_get_sample_duration(mp4, i);
      
      if (cur_duration && cur_duration == duration) {
        // same as previous entry, combine together
        stts_entries--;
        stts[stts_index].sample_count++;
      }
      else {
        stts_index++;
        stts[stts_index].sample_count = 1;
        stts[stts_index].sample_duration = duration;
        cur_duration = duration;
      }
    }
    
    DEBUG_TRACE("Writing new stts (entries: %d)\n", stts_entries);
    buffer_put_int(&tmp_buf, stts_entries);
    
    for (i = 0; i < stts_entries; i++) {
      DEBUG_TRACE("  sample_count %d, sample_duration %d\n", stts[i].sample_count, stts[i].sample_duration);
      buffer_put_int(&tmp_buf, stts[i].sample_count);
      buffer_put_int(&tmp_buf, stts[i].sample_duration);
    }
    
    mp4->new_stts = newSVpv("", 0);
    put_u32( tmp_size, buffer_len(&tmp_buf) + 12 );
    sv_catpvn( mp4->new_stts, tmp_size, 4 );
    sv_catpvn( mp4->new_stts, "stts", 4 );
    sv_catpvn( mp4->new_stts, "\0\0\0\0", 4 );
    sv_catpvn( mp4->new_stts, (char *)buffer_ptr(&tmp_buf), buffer_len(&tmp_buf) );
    //buffer_dump(&tmp_buf, 0);
    buffer_clear(&tmp_buf);
    
    Safefree(stts);
  }
  
  // We know the new block, now calculate the file position
  
  /* Locate the chunk containing the sample */
  prev_chunk         = mp4->sample_to_chunk[0].first_chunk;
  prev_chunk_samples = mp4->sample_to_chunk[0].samples_per_chunk;
  
  for (i = 1; i < mp4->num_sample_to_chunks; i++) {
    chunk = mp4->sample_to_chunk[i].first_chunk;
    range_samples = (chunk - prev_chunk) * prev_chunk_samples;
    
    DEBUG_TRACE("prev_chunk: %d, prev_chunk_samples: %d, chunk: %d, range_samples: %d\n",
      prev_chunk, prev_chunk_samples, chunk, range_samples);

    if (new_sample < total_samples + range_samples)
      break;

    total_samples += range_samples;
    prev_chunk = mp4->sample_to_chunk[i].first_chunk;
    prev_chunk_samples = mp4->sample_to_chunk[i].samples_per_chunk;
  }
  
  DEBUG_TRACE("prev_chunk: %d, prev_chunk_samples: %d, total_samples: %d\n", prev_chunk, prev_chunk_samples, total_samples);
  
  if (new_sample >= mp4->sample_to_chunk[0].samples_per_chunk) {
    chunk = prev_chunk + (new_sample - total_samples) / prev_chunk_samples;
  }
  else {
    chunk = 1;
  }
  
  DEBUG_TRACE("chunk: %d\n", chunk);
  
  /* Get sample of the first sample in the chunk */
  chunk_sample = total_samples + (chunk - prev_chunk) * prev_chunk_samples;
  
  DEBUG_TRACE("chunk_sample: %d\n", chunk_sample);
  
  /* Get offset in file */

  if (chunk > mp4->num_chunk_offsets) {
    file_offset = mp4->chunk_offset[mp4->num_chunk_offsets - 1];
  }
  else {
    file_offset = mp4->chunk_offset[chunk - 1];
  }
  
  DEBUG_TRACE("file_offset: %d\n", file_offset);

  if (chunk_sample > new_sample) {
    PerlIO_printf(PerlIO_stderr(), "find_frame: sample out of range (%d > %d)\n", chunk_sample, new_sample);
    ret = -1;
    goto out;
  }
  
  // Move offset within the chunk to the correct sample range
  for (i = chunk_sample; i < new_sample; i++) { 
    file_offset += mp4->sample_byte_size[i];
    skipped_samples++;
    DEBUG_TRACE("  file_offset + %d: %d\n", mp4->sample_byte_size[i], file_offset);
  }

  if (file_offset > mp4->audio_offset + mp4->audio_size) {
    PerlIO_printf(PerlIO_stderr(), "find_frame: file offset out of range (%d > %lld)\n", file_offset, mp4->audio_offset + mp4->audio_size);
    ret = -1;
    goto out;
  }
  
  // Write new stsc box
  {
    int i;
    uint32_t stsc_entries = mp4->num_chunk_offsets - chunk + 1;
    uint32_t cur_samples_per_chunk = 0;
    struct stc *stsc;
    int32_t stsc_index = -1;
    uint32_t chunk_delta = 1;
    j = 1;
    
    Newz(0, stsc, stsc_entries * sizeof(*stsc), struct stc);
    
    for (i = chunk; i <= mp4->num_chunk_offsets; i++) {
      // Find the number of samples in chunk i
      uint32_t samples_in_chunk = _mp4_samples_in_chunk(mp4, i);
      
      if (cur_samples_per_chunk && cur_samples_per_chunk == samples_in_chunk) {
        // same as previous entry, combine together
        stsc_entries--;
      }
      else {
        stsc_index++;
        
        stsc[stsc_index].first_chunk = chunk_delta;
        
        if (j == 1) {
          // The first chunk may have less samples in it due to seeking within a chunk
          stsc[stsc_index].samples_per_chunk = samples_in_chunk - skipped_samples;
          cur_samples_per_chunk = samples_in_chunk - skipped_samples;
          j++;
        }
        else {
          stsc[stsc_index].samples_per_chunk = samples_in_chunk;
          cur_samples_per_chunk = samples_in_chunk;
        }
      }
      
      chunk_delta++;
    }
    
    DEBUG_TRACE("Writing new stsc (entries: %d)\n", stsc_entries);
    buffer_put_int(&tmp_buf, stsc_entries);
    
    for (i = 0; i < stsc_entries; i++) {
      DEBUG_TRACE("  first_chunk %d, samples_per_chunk %d\n", stsc[i].first_chunk, stsc[i].samples_per_chunk);
      buffer_put_int(&tmp_buf, stsc[i].first_chunk);
      buffer_put_int(&tmp_buf, stsc[i].samples_per_chunk);
      buffer_put_int(&tmp_buf, 1); // XXX sample description index, is this OK?
    }
    
    mp4->new_stsc = newSVpv("", 0);
    put_u32( tmp_size, buffer_len(&tmp_buf) + 12 );
    sv_catpvn( mp4->new_stsc, tmp_size, 4 );
    sv_catpvn( mp4->new_stsc, "stsc", 4 );
    sv_catpvn( mp4->new_stsc, "\0\0\0\0", 4 );
    sv_catpvn( mp4->new_stsc, (char *)buffer_ptr(&tmp_buf), buffer_len(&tmp_buf) );
    DEBUG_TRACE("Created new stsc\n");
    //buffer_dump(&tmp_buf, 0);
    buffer_clear(&tmp_buf);
    
    Safefree(stsc);
  }
  
  // Write new stsz box, num_sample_byte_sizes -= $new_sample, skip $new_sample items
  buffer_put_int(&tmp_buf, 0);
  buffer_put_int(&tmp_buf, mp4->num_sample_byte_sizes - new_sample);
  DEBUG_TRACE("Writing new stsz: %d items\n", mp4->num_sample_byte_sizes - new_sample);
  j = 1;
  for (i = new_sample; i < mp4->num_sample_byte_sizes; i++) {
    DEBUG_TRACE("  sample %d sample_byte_size %d\n", j++, mp4->sample_byte_size[i]);
    buffer_put_int(&tmp_buf, mp4->sample_byte_size[i]);
  }
  
  mp4->new_stsz = newSVpv("", 0);
  put_u32( tmp_size, buffer_len(&tmp_buf) + 12 );
  sv_catpvn( mp4->new_stsz, tmp_size, 4 );
  sv_catpvn( mp4->new_stsz, "stsz", 4 );
  sv_catpvn( mp4->new_stsz, "\0\0\0\0", 4 );
  sv_catpvn( mp4->new_stsz, (char *)buffer_ptr(&tmp_buf), buffer_len(&tmp_buf) );
  DEBUG_TRACE("Created new stsz\n");
  //buffer_dump(&tmp_buf, 0);
  buffer_clear(&tmp_buf);
  
  // Total up size of 4 new st* boxes
  // stco is calculated directly since we can't write it without offsets
  mp4->new_st_size
    = sv_len(mp4->new_stts)
    + sv_len(mp4->new_stsc)
    + sv_len(mp4->new_stsz)
    + 12 + ( 4 * (mp4->num_chunk_offsets - chunk + 2) ); // stco size
  
  DEBUG_TRACE("new_st_size: %d, old_st_size: %d\n", mp4->new_st_size, mp4->old_st_size);
  
  // Calculate offset for each chunk
  chunk_offset = SvIV( *( my_hv_fetch(info, "audio_offset") ) );
  chunk_offset -= ( mp4->old_st_size - mp4->new_st_size );
  chunk_offset += 8; // mdat size + fourcc
  
  DEBUG_TRACE("chunk_offset: %d\n", chunk_offset);
  
  // Write new stco box, num_chunk_offsets -= $chunk, skip $chunk items
  buffer_put_int(&tmp_buf, mp4->num_chunk_offsets - chunk + 1);
  DEBUG_TRACE("Writing new stco: %d items\n", mp4->num_chunk_offsets - chunk + 1);
  for (i = chunk - 1; i < mp4->num_chunk_offsets; i++) {
    if (i == chunk - 1) {
      // The first chunk offset is the start of mdat (chunk_offset)
      buffer_put_int( &tmp_buf, chunk_offset );
      DEBUG_TRACE( "  offset %d (orig %d)\n", chunk_offset, mp4->chunk_offset[i] );
    }
    else {
      buffer_put_int( &tmp_buf, mp4->chunk_offset[i] - file_offset + chunk_offset );
      DEBUG_TRACE( "  offset %d (orig %d)\n", mp4->chunk_offset[i] - file_offset + chunk_offset, mp4->chunk_offset[i] );
    }
  }
  
  mp4->new_stco = newSVpv("", 0);
  put_u32( tmp_size, buffer_len(&tmp_buf) + 12 );
  sv_catpvn( mp4->new_stco, tmp_size, 4 );
  sv_catpvn( mp4->new_stco, "stco", 4 );
  sv_catpvn( mp4->new_stco, "\0\0\0\0", 4 );
  sv_catpvn( mp4->new_stco, (char *)buffer_ptr(&tmp_buf), buffer_len(&tmp_buf) );
  DEBUG_TRACE("Created new stco\n");
  //buffer_dump(&tmp_buf, 0);
  buffer_clear(&tmp_buf);
  
  DEBUG_TRACE("real st size: %ld\n",
      sv_len(mp4->new_stts)
    + sv_len(mp4->new_stsc)
    + sv_len(mp4->new_stsz) 
    + sv_len(mp4->new_stco)
  );
    
  // Make second pass through header, reducing size of all parent boxes by st* size difference
  // Copy all boxes, replacing st* boxes with new ones
  mp4->seekhdr = newSVpv("", 0);
  
  PerlIO_seek(mp4->infile, 0, SEEK_SET);
  
  // XXX this is ugly, because we are reading a second time we have to reset
  // various things in the mp4 struct
  Newz(0, mp4->buf, sizeof(Buffer), Buffer);
  buffer_init(mp4->buf, MP4_BLOCK_SIZE);
  
  mp4->audio_offset  = 0;
  mp4->current_track = 0;
  mp4->track_count   = 0;
  
  // free seek structs because we will be reading them a second time
  if (mp4->time_to_sample) Safefree(mp4->time_to_sample);
  if (mp4->sample_to_chunk) Safefree(mp4->sample_to_chunk);
  if (mp4->sample_byte_size) Safefree(mp4->sample_byte_size);
  if (mp4->chunk_offset) Safefree(mp4->chunk_offset);
  
  mp4->time_to_sample   = NULL;
  mp4->sample_to_chunk  = NULL;
  mp4->sample_byte_size = NULL;
  mp4->chunk_offset     = NULL;
  
  while ( (box_size = _mp4_read_box(mp4)) > 0 ) {
    mp4->audio_offset += box_size;
    DEBUG_TRACE("seek pass 2: read box of size %d\n", box_size);
    
    if (mp4->audio_offset >= mp4->file_size)
      break;
  }
  
  my_hv_store( info, "seek_offset", newSVuv(file_offset) );
  my_hv_store( info, "seek_header", mp4->seekhdr );
  
  if (mp4->buf) {
    buffer_free(mp4->buf);
    Safefree(mp4->buf);
  }

out:
  // Don't leak
  SvREFCNT_dec(tags);
  
  if (mp4->new_stts) SvREFCNT_dec(mp4->new_stts);
  if (mp4->new_stsc) SvREFCNT_dec(mp4->new_stsc);
  if (mp4->new_stsz) SvREFCNT_dec(mp4->new_stsz);
  if (mp4->new_stco) SvREFCNT_dec(mp4->new_stco);
  
  // free seek structs
  if (mp4->time_to_sample) Safefree(mp4->time_to_sample);
  if (mp4->sample_to_chunk) Safefree(mp4->sample_to_chunk);
  if (mp4->sample_byte_size) Safefree(mp4->sample_byte_size);
  if (mp4->chunk_offset) Safefree(mp4->chunk_offset);
  
  // free seek buffer
  buffer_free(&tmp_buf);
  
  Safefree(mp4);
  
  if (ret == -1) {
    my_hv_store( info, "seek_offset", newSViv(-1) );
  }
  
  return ret;
}

mp4info *
_mp4_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking)
{
  off_t file_size;
  uint32_t box_size = 0;
  
  mp4info *mp4;
  Newz(0, mp4, sizeof(mp4info), mp4info);
  Newz(0, mp4->buf, sizeof(Buffer), Buffer);
  
  mp4->audio_offset  = 0;
  mp4->infile        = infile;
  mp4->file          = file;
  mp4->info          = info;
  mp4->tags          = tags;
  mp4->current_track = 0;
  mp4->track_count   = 0;
  mp4->seen_moov     = 0;
  mp4->seeking       = seeking ? 1 : 0;
  
  mp4->time_to_sample   = NULL;
  mp4->sample_to_chunk  = NULL;
  mp4->sample_byte_size = NULL;
  mp4->chunk_offset     = NULL;
  
  buffer_init(mp4->buf, MP4_BLOCK_SIZE);
  
  file_size = _file_size(infile);
  mp4->file_size = file_size;
  
  my_hv_store( info, "file_size", newSVuv(file_size) );
  
  // Create empty tracks array
  my_hv_store( info, "tracks", newRV_noinc( (SV *)newAV() ) );
  
  while ( (box_size = _mp4_read_box(mp4)) > 0 ) {
    mp4->audio_offset += box_size;
    DEBUG_TRACE("read box of size %d / audio_offset %llu\n", box_size, mp4->audio_offset);
    
    if (mp4->audio_offset >= file_size)
      break;
  }
  
  // XXX: if no ftyp was found, assume it is brand 'mp41'
  
  // if no bitrate was found (i.e. ALAC), calculate based on file_size/song_length_ms
  if ( !my_hv_exists(info, "avg_bitrate") ) {
    SV **entry = my_hv_fetch(info, "song_length_ms");
    if (entry) {
      SV **audio_offset = my_hv_fetch(info, "audio_offset");
      if (audio_offset) {
        uint32_t song_length_ms = SvIV(*entry);
        uint32_t bitrate = _bitrate(file_size - SvIV(*audio_offset), song_length_ms);
      
        my_hv_store( info, "avg_bitrate", newSVuv(bitrate) );
        mp4->bitrate = bitrate;
      }
    }
  }
  
  // DLNA detection, based on code from libdlna
  if (!mp4->dlna_invalid && mp4->samplerate && mp4->bitrate && mp4->channels) {
    switch (mp4->audio_object_type) {
      case AAC_LC:
      case AAC_LC_ER:
      {
        if (mp4->samplerate < 8000 || mp4->samplerate > 48000)
          break;
        
        if (mp4->channels <= 2) {
          if (mp4->bitrate <= 192000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_ISO_192", 0) );
          else if (mp4->bitrate <= 320000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_ISO_320", 0) );
          else if (mp4->bitrate <= 576000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_ISO", 0) );
        }
        else if (mp4->channels <= 6) {
          if (mp4->bitrate <= 1440000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_MULT5_ISO", 0) );
        }
        
        break;
      }
      
      case AAC_LTP:
      case AAC_LTP_ER:
      {
        if (mp4->samplerate < 8000)
          break;
        
        if (mp4->samplerate <= 48000) {
          if (mp4->channels <= 2 && mp4->bitrate <= 576000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_LTP_ISO", 0) );
        }
        else if (mp4->samplerate <= 96000) {
          if (mp4->channels <= 6 && mp4->bitrate <= 2880000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_LTP_MULT5_ISO", 0) );
          else if (mp4->channels <= 8 && mp4->bitrate <= 4032000)
            my_hv_store( info, "dlna_profile", newSVpv("AAC_LTP_MULT7_ISO", 0) );
        }
        
        break;
      }
      
      case AAC_HE:
      {
        if (mp4->samplerate < 8000)
          break;
        
        if (mp4->samplerate <= 24000) {
          if (mp4->channels > 2)
            break;
          
          if (mp4->bitrate <= 128000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_L2_ISO_128", 0) );
          else if (mp4->bitrate <= 320000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_L2_ISO_320", 0) );
          else if (mp4->bitrate <= 576000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_L2_ISO", 0) );
        }
        else if (mp4->samplerate <= 48000) {
          if (mp4->channels <= 2 && mp4->bitrate <= 576000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_L3_ISO", 0) );
          else if (mp4->channels <= 6 && mp4->bitrate <= 1440000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_MULT5_ISO", 0) );
          else if (mp4->channels <= 8 && mp4->bitrate <= 4032000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_MULT7", 0) );
        }
        else if (mp4->samplerate <= 96000) {
          if (mp4->channels <= 8 && mp4->bitrate <= 4032000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAAC_MULT7", 0) );
        }
        
        break;
      }
      
      case AAC_PARAM_ER:
      case AAC_PS:
      {
        if (mp4->samplerate < 8000)
          break;
        
        if (mp4->samplerate <= 24000) {
          if (mp4->channels > 2)
            break;
          
          if (mp4->bitrate <= 128000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_L2_128", 0) );
          else if (mp4->bitrate <= 320000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_L2_320", 0) );
          else if (mp4->bitrate <= 576000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_L2", 0) );
        }
        else if (mp4->samplerate <= 48000) {
          if (mp4->channels <= 2 && mp4->bitrate <= 576000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_L3", 0) );
          else if (mp4->channels <= 6 && mp4->bitrate <= 1440000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_L4", 0) );
          else if (mp4->channels <= 6 && mp4->bitrate <= 2880000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_MULT5", 0) );
          else if (mp4->channels <= 8 && mp4->bitrate <= 4032000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_MULT7", 0) );
        }
        else if (mp4->samplerate <= 96000) {
          if (mp4->channels <= 8 && mp4->bitrate <= 4032000)
            my_hv_store( info, "dlna_profile", newSVpv("HEAACv2_MULT7", 0) );
        }
        
        break;
      }
      
      case AAC_BSAC_ER:
      {
        if (mp4->samplerate < 16000 || mp4->samplerate > 48000)
          break;

        if (mp4->bitrate > 128000)
          break;

        if (mp4->channels <= 2)
          my_hv_store( info, "dlna_profile", newSVpv("BSAC_ISO", 0) );
        else if (mp4->channels <= 6)
          my_hv_store( info, "dlna_profile", newSVpv("BSAC_MULT5_ISO", 0) );

        break;
      }
      
      default:
        break;
    }
  }
  
  buffer_free(mp4->buf);
  Safefree(mp4->buf);
  
  return mp4;
}

int
_mp4_read_box(mp4info *mp4)
{
  uint64_t size;  // total size of box
  char type[5];
  uint8_t skip = 0;
  
  mp4->rsize = 0; // remaining size in box
  
  if ( !_check_buf(mp4->infile, mp4->buf, 16, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  size = buffer_get_int(mp4->buf);
  strncpy( type, (char *)buffer_ptr(mp4->buf), 4 );
  type[4] = '\0';
  buffer_consume(mp4->buf, 4);
  
  // Check for 64-bit size
  if (size == 1) {
    size = buffer_get_int64(mp4->buf);
    mp4->hsize = 16;
  }
  else if (size == 0) {
    // XXX: size extends to end of file
    mp4->hsize = 8;
  }
  else {
    mp4->hsize = 8;
  }
  
  if (size) {
    mp4->rsize = size - mp4->hsize;
  }
  
  mp4->size = size;
  
  DEBUG_TRACE("%s size %llu\n", type, size);
  
  if (mp4->seekhdr) {
    // Copy and adjust header if seeking
    char tmp_size[4];
    
    if (
         FOURCC_EQ(type, "moov")
      || FOURCC_EQ(type, "trak")
      || FOURCC_EQ(type, "mdia")
      || FOURCC_EQ(type, "minf")
      || FOURCC_EQ(type, "stbl")
    ) {
      // Container box, adjust size
      put_u32(tmp_size, size - (mp4->old_st_size - mp4->new_st_size));
      DEBUG_TRACE("  Box is parent of st*, changed size to %llu\n", size - (mp4->old_st_size - mp4->new_st_size));
      sv_catpvn( mp4->seekhdr, tmp_size, 4 );
      sv_catpvn( mp4->seekhdr, type, 4 );
    }
    // Replace st* boxes with our new versions
    else if ( FOURCC_EQ(type, "stts") ) {
      DEBUG_TRACE("adding new stts of size %ld\n", sv_len(mp4->new_stts));
      sv_catsv( mp4->seekhdr, mp4->new_stts );
    }
    else if ( FOURCC_EQ(type, "stsc") ) {
      DEBUG_TRACE("adding new stsc of size %ld\n", sv_len(mp4->new_stsc));
      sv_catsv( mp4->seekhdr, mp4->new_stsc );
    }
    else if ( FOURCC_EQ(type, "stsz") ) {
      DEBUG_TRACE("adding new stsz of size %ld\n", sv_len(mp4->new_stsz));
      sv_catsv( mp4->seekhdr, mp4->new_stsz );
    }
    else if ( FOURCC_EQ(type, "stco") ) {
      DEBUG_TRACE("adding new stco of size %ld\n", sv_len(mp4->new_stco));
      sv_catsv( mp4->seekhdr, mp4->new_stco );
    }
    else {
      // Normal box, copy it
      put_u32(tmp_size, size);
      sv_catpvn( mp4->seekhdr, tmp_size, 4 );
      sv_catpvn( mp4->seekhdr, type, 4 );
      
      // stsd is special and contains real bytes and is also a container
      if ( FOURCC_EQ(type, "stsd") ) {
        sv_catpvn( mp4->seekhdr, (char *)buffer_ptr(mp4->buf), 8 );
      }
      
      // mp4a is special, ugh
      else if ( FOURCC_EQ(type, "mp4a") ) {
        sv_catpvn( mp4->seekhdr, (char *)buffer_ptr(mp4->buf), 28 );
      }
      
      // and so is meta
      else if ( FOURCC_EQ(type, "meta") ) {
        sv_catpvn( mp4->seekhdr, (char *)buffer_ptr(mp4->buf), mp4->meta_size );
      }
      
      // Copy contents unless it's a container
      else if (
           !FOURCC_EQ(type, "edts")
        && !FOURCC_EQ(type, "dinf")
        && !FOURCC_EQ(type, "udta")
        && !FOURCC_EQ(type, "mdat")
      ) {
        if ( !_check_buf(mp4->infile, mp4->buf, size - 8, MP4_BLOCK_SIZE) ) {
          return 0;
        }
        
        // XXX find a way to skip udta completely when rewriting seek header
        // to avoid useless copying of artwork.  Will require adjusting offsets
        // differently.
        
        sv_catpvn( mp4->seekhdr, (char *)buffer_ptr(mp4->buf), size - 8 );
      }
    }
    
    // XXX should probably return size here and avoid reading info a second time
    // or move the header copying code to somewhere else
  }
  
  if ( FOURCC_EQ(type, "ftyp") ) {
    if ( !_mp4_parse_ftyp(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad ftyp box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( 
       FOURCC_EQ(type, "moov") 
    || FOURCC_EQ(type, "edts")
    || FOURCC_EQ(type, "mdia")
    || FOURCC_EQ(type, "minf")
    || FOURCC_EQ(type, "dinf")
    || FOURCC_EQ(type, "stbl")
    || FOURCC_EQ(type, "udta")
  ) {
    // These boxes are containers for nested boxes, return only the fact that
    // we read the header size of the container
    size = mp4->hsize;
    
    if ( FOURCC_EQ(type, "trak") ) {
      mp4->track_count++;
    }
  }
  else if ( FOURCC_EQ(type, "trak") ) {
    // Also a container, but we need to increment track_count too
    size = mp4->hsize;
    mp4->track_count++;
  }
  else if ( FOURCC_EQ(type, "mvhd") ) {
    mp4->seen_moov = 1;
    
    if ( !_mp4_parse_mvhd(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad mvhd box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( FOURCC_EQ(type, "tkhd") ) {
    if ( !_mp4_parse_tkhd(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad tkhd box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( FOURCC_EQ(type, "mdhd") ) {
    if ( !_mp4_parse_mdhd(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad mdhd box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( FOURCC_EQ(type, "hdlr") ) {
    if ( !_mp4_parse_hdlr(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad hdlr box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( FOURCC_EQ(type, "stsd") ) {
    if ( !_mp4_parse_stsd(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad stsd box): %s\n", mp4->file);
      return 0;
    }
    
    // stsd is a special real box + container, count only the real bytes (8)
    size = 8 + mp4->hsize;
  }
  else if ( FOURCC_EQ(type, "mp4a") ) {
    if ( !_mp4_parse_mp4a(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad mp4a box): %s\n", mp4->file);
      return 0;
    }
    
    // mp4a is a special real box + container, count only the real bytes (28)
    size = 28 + mp4->hsize;
  }
  else if ( FOURCC_EQ(type, "alac") ) {
    if ( !_mp4_parse_alac(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad alac box): %s\n", mp4->file);
      return 0;
    }
        
    // skip rest (alac description)
    mp4->rsize -= 28;
    skip = 1;
  }
  else if ( FOURCC_EQ(type, "drms") ) {
    // Mark encoding
    HV *trackinfo = _mp4_get_current_trackinfo(mp4);
    
    my_hv_store( trackinfo, "encoding", newSVpvn("drms", 4) );
    
    // Skip rest
    skip = 1;
  }
  else if ( FOURCC_EQ(type, "esds") ) {
    if ( !_mp4_parse_esds(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad esds box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( FOURCC_EQ(type, "stts") ) {
    if ( mp4->seeking && mp4->track_count == 1 ) {
      if ( !_mp4_parse_stts(mp4) ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad stts box): %s\n", mp4->file);
        return 0;
      }
      mp4->old_st_size += size;
    }
    else {
      skip = 1;
    }
  }
  else if ( FOURCC_EQ(type, "stsc") ) {
    if ( mp4->seeking && mp4->track_count == 1 ) {
      if ( !_mp4_parse_stsc(mp4) ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad stsc box): %s\n", mp4->file);
        return 0;
      }
      mp4->old_st_size += size;
    }
    else {
      skip = 1;
    }
  }
  else if ( FOURCC_EQ(type, "stsz") ) {
    if ( mp4->seeking && mp4->track_count == 1 ) {
      if ( !_mp4_parse_stsz(mp4) ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad stsz box): %s\n", mp4->file);
        return 0;
      }
      mp4->old_st_size += size;
    }
    else {
      skip = 1;
    }
  }
  else if ( FOURCC_EQ(type, "stco") ) {
    if ( mp4->seeking && mp4->track_count == 1 ) {
      if ( !_mp4_parse_stco(mp4) ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad stco box): %s\n", mp4->file);
        return 0;
      }
      mp4->old_st_size += size;
    }
    else {
      skip = 1;
    }
  }
  else if ( FOURCC_EQ(type, "meta") ) {
    uint8_t meta_size = _mp4_parse_meta(mp4);
    if ( !meta_size ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad meta box): %s\n", mp4->file);
      return 0;
    }
    
    mp4->meta_size = meta_size;
    
    // meta is a special real box + container, count only the real bytes
    size = meta_size + mp4->hsize;
  }
  else if ( FOURCC_EQ(type, "ilst") ) {
    if ( !_mp4_parse_ilst(mp4) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid MP4 file (bad ilst box): %s\n", mp4->file);
      return 0;
    }
  }
  else if ( FOURCC_EQ(type, "mdat") ) {
    // Audio data here, there may be boxes after mdat, so we have to skip it
    skip = 1;
    
    // If we haven't seen moov yet, set a flag so we can print a warning
    // or handle it some other way
    if ( !mp4->seen_moov ) {
      my_hv_store( mp4->info, "leading_mdat", newSVuv(1) );
      mp4->dlna_invalid = 1; // DLNA 8.6.34.8, moov must be before mdat
    }
    
    // Record audio offset and length
    my_hv_store( mp4->info, "audio_offset", newSVuv(mp4->audio_offset) );
    my_hv_store( mp4->info, "audio_size", newSVuv(size) );
    mp4->audio_size = size;
  }
  else {
    DEBUG_TRACE("  Unhandled box, skipping\n");
    skip = 1;
  }
  
  if (skip) {
    _mp4_skip(mp4, mp4->rsize);
  }
  
  return size;
}

uint8_t
_mp4_parse_ftyp(mp4info *mp4)
{
  AV *compatible_brands = newAV();
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  my_hv_store( mp4->info, "major_brand", newSVpvn( buffer_ptr(mp4->buf), 4 ) );
  buffer_consume(mp4->buf, 4);
  
  my_hv_store( mp4->info, "minor_version", newSVuv( buffer_get_int(mp4->buf) ) );
  
  mp4->rsize -= 8;
  
  if (mp4->rsize % 4) {
    // invalid ftyp
    return 0;
  }
  
  while (mp4->rsize > 0) {
    av_push( compatible_brands, newSVpvn( buffer_ptr(mp4->buf), 4 ) );
    buffer_consume(mp4->buf, 4);
    mp4->rsize -= 4;
  }
    
  my_hv_store( mp4->info, "compatible_brands", newRV_noinc( (SV *)compatible_brands ) );
  
  return 1;
}

uint8_t
_mp4_parse_mvhd(mp4info *mp4)
{
  uint32_t timescale;
  uint8_t version;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  version = buffer_get_char(mp4->buf);
  buffer_consume(mp4->buf, 3); // flags
  
  if (version == 0) { // 32-bit values
    // Skip ctime and mtime
    buffer_consume(mp4->buf, 8);
    
    timescale = buffer_get_int(mp4->buf);
    my_hv_store( mp4->info, "mv_timescale", newSVuv(timescale) );
    
    my_hv_store( mp4->info, "song_length_ms", newSVuv( (buffer_get_int(mp4->buf) * 1.0 / timescale ) * 1000 ) );
  }
  else if (version == 1) { // 64-bit values
    // Skip ctime and mtime
    buffer_consume(mp4->buf, 16);
    
    timescale = buffer_get_int(mp4->buf);
    my_hv_store( mp4->info, "mv_timescale", newSVuv(timescale) );
    
    my_hv_store( mp4->info, "song_length_ms", newSVuv( (buffer_get_int64(mp4->buf) * 1.0 / timescale ) * 1000 ) );
  }
  else {
    return 0;
  }
    
  // Skip rest
  buffer_consume(mp4->buf, 80);
    
  return 1;
}

uint8_t
_mp4_parse_tkhd(mp4info *mp4)
{
  AV *tracks = (AV *)SvRV( *(my_hv_fetch(mp4->info, "tracks")) );
  HV *trackinfo = newHV();
  uint32_t id;
  double width;
  double height;
  uint8_t version;
  
  uint32_t timescale = SvIV( *(my_hv_fetch(mp4->info, "mv_timescale")) );
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  version = buffer_get_char(mp4->buf);
  buffer_consume(mp4->buf, 3); // flags
  
  // XXX DLNA Requirement [8.6.34.5]: For the default audio track, "Track_enabled"
  // must be set to the value of 1 in the "flags" field of Track Header Box of the track.
  
  if (version == 0) { // 32-bit values
    // Skip ctime and mtime
    buffer_consume(mp4->buf, 8);
    
    id = buffer_get_int(mp4->buf);
    
    my_hv_store( trackinfo, "id", newSVuv(id) );
    
    // Skip reserved
    buffer_consume(mp4->buf, 4);
    
    my_hv_store( trackinfo, "duration", newSVuv( (buffer_get_int(mp4->buf) * 1.0 / timescale ) * 1000 ) );
  }
  else if (version == 1) { // 64-bit values
    // Skip ctime and mtime
    buffer_consume(mp4->buf, 16);
    
    id = buffer_get_int(mp4->buf);
    
    my_hv_store( trackinfo, "id", newSVuv(id) );
    
    // Skip reserved
    buffer_consume(mp4->buf, 4);
    
    my_hv_store( trackinfo, "duration", newSVuv( (buffer_get_int64(mp4->buf) * 1.0 / timescale ) * 1000 ) );
  }
  else {
    return 0;
  }
  
  // Skip reserved, layer, alternate_group, volume, reserved, matrix
  buffer_consume(mp4->buf, 52);
  
  // width/height are fixed-point 16.16
  width = buffer_get_short(mp4->buf);
  width += buffer_get_short(mp4->buf) / 65536.;
  if (width > 0) {
    my_hv_store( trackinfo, "width", newSVnv(width) );
  }
  
  height = buffer_get_short(mp4->buf);
  height += buffer_get_short(mp4->buf) / 65536.;
  if (height > 0) {
    my_hv_store( trackinfo, "height", newSVnv(height) );
  }
  
  av_push( tracks, newRV_noinc( (SV *)trackinfo ) );
  
  // Remember the current track we're dealing with
  mp4->current_track = id;
  
  return 1;
}

uint8_t
_mp4_parse_mdhd(mp4info *mp4)
{
  uint32_t timescale;
  uint8_t version;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  version = buffer_get_char(mp4->buf);
  buffer_consume(mp4->buf, 3); // flags
  
  if (version == 0) { // 32-bit values
    // Skip ctime and mtime
    buffer_consume(mp4->buf, 8);
    
    timescale = buffer_get_int(mp4->buf);
    my_hv_store( mp4->info, "samplerate", newSVuv(timescale) );
    
    // Skip duration, if have song_length_ms from mvhd
    if ( my_hv_exists( mp4->info, "song_length_ms" ) ) {
      buffer_consume(mp4->buf, 4);
    }
    else {
      my_hv_store( mp4->info, "song_length_ms", newSVuv( (buffer_get_int(mp4->buf) * 1.0 / timescale ) * 1000 ) );
    }
  }
  else if (version == 1) { // 64-bit values
    // Skip ctime and mtime
    buffer_consume(mp4->buf, 16);
    
    timescale = buffer_get_int(mp4->buf);
    my_hv_store( mp4->info, "samplerate", newSVuv(timescale) );
    
    // Skip duration, if have song_length_ms from mvhd
    if ( my_hv_exists( mp4->info, "song_length_ms" ) ) {
      buffer_consume(mp4->buf, 8);
    }
    else {
      my_hv_store( mp4->info, "song_length_ms", newSVuv( (buffer_get_int64(mp4->buf) * 1.0 / timescale ) * 1000 ) );
    }
  }
  else {
    return 0;
  }
  
  mp4->samplerate = timescale;
    
  // Skip rest
  buffer_consume(mp4->buf, 4);
    
  return 1;
}

uint8_t
_mp4_parse_hdlr(mp4info *mp4)
{
  HV *trackinfo = _mp4_get_current_trackinfo(mp4);
  SV *handler_name;
  
  if (!trackinfo) {
    return 0;
  }
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version, flags, pre_defined
  buffer_consume(mp4->buf, 8);
  
  my_hv_store( trackinfo, "handler_type", newSVpvn( buffer_ptr(mp4->buf), 4 ) );
  buffer_consume(mp4->buf, 4);
  
  // Skip reserved
  buffer_consume(mp4->buf, 12);
  
  handler_name = newSVpv( buffer_ptr(mp4->buf), 0 );
  sv_utf8_decode(handler_name);
  my_hv_store( trackinfo, "handler_name", handler_name );
  
  buffer_consume(mp4->buf, mp4->rsize - 24);
  
  return 1;
}

uint8_t
_mp4_parse_stsd(mp4info *mp4)
{
  uint32_t entry_count;
  
  if ( !_check_buf(mp4->infile, mp4->buf, 8, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  entry_count = buffer_get_int(mp4->buf);
  
  return 1;
}

uint8_t
_mp4_parse_mp4a(mp4info *mp4)
{
  HV *trackinfo = _mp4_get_current_trackinfo(mp4);
  
  if ( !_check_buf(mp4->infile, mp4->buf, 28, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  my_hv_store( trackinfo, "encoding", newSVpvn("mp4a", 4) );
  
  // Skip reserved
  buffer_consume(mp4->buf, 16);
  
  mp4->channels = buffer_get_short(mp4->buf);
  my_hv_store( trackinfo, "channels", newSVuv(mp4->channels) );
  my_hv_store( trackinfo, "bits_per_sample", newSVuv( buffer_get_short(mp4->buf) ) );
  
  // Skip reserved
  buffer_consume(mp4->buf, 4);
  
  // Skip bogus samplerate
  buffer_consume(mp4->buf, 2);
  
  // Skip reserved
  buffer_consume(mp4->buf, 2);
  
  return 1;
}

uint8_t
_mp4_parse_esds(mp4info *mp4)
{
  HV *trackinfo = _mp4_get_current_trackinfo(mp4);
  uint32_t len = 0;
  uint32_t avg_bitrate;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  // Public docs on esds are hard to find, this is based on faad
  // and http://www.geocities.com/xhelmboyx/quicktime/formats/mp4-layout.txt
  
  // verify ES_DescrTag
  if (buffer_get_char(mp4->buf) == 0x03) {
    // read length
    if ( _mp4_descr_length(mp4->buf) < 5 + 15 ) {
      return 0;
    }
    
    // skip 3 bytes
    buffer_consume(mp4->buf, 3);
  }
  else {
    // skip 2 bytes
    buffer_consume(mp4->buf, 2);
  }
  
  // verify DecoderConfigDescrTab
  if (buffer_get_char(mp4->buf) != 0x04) {
    return 0;
  }
  
  // read length
  if ( _mp4_descr_length(mp4->buf) < 13 ) {
    return 0;
  }
  
  // XXX: map to string
  my_hv_store( trackinfo, "audio_type", newSVuv( buffer_get_char(mp4->buf) ) );
  
  buffer_consume(mp4->buf, 4);
  
  my_hv_store( trackinfo, "max_bitrate", newSVuv( buffer_get_int(mp4->buf) ) );
  
  avg_bitrate = buffer_get_int(mp4->buf);
  if (avg_bitrate) {
    if ( my_hv_exists(mp4->info, "avg_bitrate") ) {
      // If there are multiple tracks, just add up the bitrates
      avg_bitrate += SvIV(*(my_hv_fetch(mp4->info, "avg_bitrate")));
    }
    my_hv_store( mp4->info, "avg_bitrate", newSVuv(avg_bitrate) );
    mp4->bitrate = avg_bitrate;
  }
  
  // verify DecSpecificInfoTag
  if (buffer_get_char(mp4->buf) != 0x05) {
    return 0;
  }
  
  // Read audio object type
  // 5 bits, if 0x1F, read 6 more bits
  len = _mp4_descr_length(mp4->buf);
  if (len > 0) {
    uint32_t aot;
    
    len *= 8; // count the number of bits left
    
    aot = buffer_get_bits(mp4->buf, 5);
    len -= 5;
    
    if ( aot == 0x1F ) {      
      aot = 32 + buffer_get_bits(mp4->buf, 6);
      len -= 6;
    }
    
    // samplerate: 4 bits
    //   if 0xF, samplerate is next 24 bits
    //   else lookup in samplerate table
    {
      uint32_t samplerate = buffer_get_bits(mp4->buf, 4);
      len -= 4;
      
      if (samplerate == 0xF) { // XXX need test file with 24-bit samplerate field
        samplerate = buffer_get_bits(mp4->buf, 24);
        len -= 24;
      }
      else {
        samplerate = samplerate_table[samplerate];
      }
      
      // Channel configuration (4 bits)
      // XXX This is sometimes wrong (1 when it should be 2)
      mp4->channels = buffer_get_bits(mp4->buf, 4);
      my_hv_store( trackinfo, "channels", newSVuv(mp4->channels) );
      len -= 4;
      
      if (aot == AAC_SLS) {
        // Read some SLS-specific config
        // bits per sample (3 bits) { 8, 16, 20, 24 }
        uint8_t bps = buffer_get_bits(mp4->buf, 3);
        len -= 3;
        
        my_hv_store( trackinfo, "bits_per_sample", newSVuv( bps_table[bps] ) );
      }
      else if (aot == AAC_HE || aot == AAC_PS) {
        // Read extended samplerate info
        samplerate = buffer_get_bits(mp4->buf, 4);
        len -= 4;
        if (samplerate == 0xF) { // XXX need test file with 24-bit samplerate field
          samplerate = buffer_get_bits(mp4->buf, 24);
          len -= 24;
        }
        else {
          samplerate = samplerate_table[samplerate];
        }
      }
      
      my_hv_store( trackinfo, "samplerate", newSVuv(samplerate) );
      mp4->samplerate = samplerate;
    }
    
    my_hv_store( trackinfo, "audio_object_type", newSVuv(aot) );
    mp4->audio_object_type = aot;
    
    // Skip rest of box
    buffer_get_bits(mp4->buf, len);
  }
  
  // verify SL config descriptor type tag
  if (buffer_get_char(mp4->buf) != 0x06) {
    return 0;
  }
  
  _mp4_descr_length(mp4->buf);
  
  // verify SL value
  if (buffer_get_char(mp4->buf) != 0x02) {
    return 0;
  }
  
  return 1;
}

uint8_t
_mp4_parse_alac(mp4info *mp4)
{
  HV *trackinfo = _mp4_get_current_trackinfo(mp4);
  
  if ( !_check_buf(mp4->infile, mp4->buf, 28, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  my_hv_store( trackinfo, "encoding", newSVpvn("alac", 4) );
  
  // Skip reserved
  buffer_consume(mp4->buf, 16);
  
  mp4->channels = buffer_get_short(mp4->buf);
  my_hv_store( trackinfo, "channels", newSVuv(mp4->channels) );
  my_hv_store( trackinfo, "bits_per_sample", newSVuv( buffer_get_short(mp4->buf) ) );
  
  // Skip reserved
  buffer_consume(mp4->buf, 4);
  
  // Skip bogus samplerate
  buffer_consume(mp4->buf, 2);
  
  // Skip reserved
  buffer_consume(mp4->buf, 2);
  
  return 1;
}

uint8_t
_mp4_parse_stts(mp4info *mp4)
{
  int i;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  mp4->num_time_to_samples = buffer_get_int(mp4->buf);
  DEBUG_TRACE("  num_time_to_samples %d\n", mp4->num_time_to_samples);
  
  New(0, 
    mp4->time_to_sample,
    mp4->num_time_to_samples * sizeof(*mp4->time_to_sample),
    struct tts
  );
  
  if ( !mp4->time_to_sample ) {
    PerlIO_printf(PerlIO_stderr(), "Unable to parse stts: too large\n");
    return 0;
  }
  
  for (i = 0; i < mp4->num_time_to_samples; i++) {
    mp4->time_to_sample[i].sample_count    = buffer_get_int(mp4->buf);
    mp4->time_to_sample[i].sample_duration = buffer_get_int(mp4->buf);
    
    DEBUG_TRACE(
      "  sample_count %d sample_duration %d\n",
      mp4->time_to_sample[i].sample_count,
      mp4->time_to_sample[i].sample_duration
    );
  }
  
  return 1;
}

uint8_t
_mp4_parse_stsc(mp4info *mp4)
{
  int i;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  mp4->num_sample_to_chunks = buffer_get_int(mp4->buf);
  DEBUG_TRACE("  num_sample_to_chunks %d\n", mp4->num_sample_to_chunks);
  
  New(0, 
    mp4->sample_to_chunk,
    mp4->num_sample_to_chunks * sizeof(*mp4->sample_to_chunk),
    struct stc
  );
  
  if ( !mp4->sample_to_chunk ) {
    PerlIO_printf(PerlIO_stderr(), "Unable to parse stsc: too large\n");
    return 0;
  }
  
  for (i = 0; i < mp4->num_sample_to_chunks; i++) {
    mp4->sample_to_chunk[i].first_chunk = buffer_get_int(mp4->buf);
    mp4->sample_to_chunk[i].samples_per_chunk = buffer_get_int(mp4->buf);
    
    // Skip sample desc index
    buffer_consume(mp4->buf, 4);
    
    DEBUG_TRACE("  first_chunk %d samples_per_chunk %d\n",
      mp4->sample_to_chunk[i].first_chunk,
      mp4->sample_to_chunk[i].samples_per_chunk
    );
  }
  
  return 1;
}

uint8_t
_mp4_parse_stsz(mp4info *mp4)
{
  int i;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  // Check sample size is 0
  if ( buffer_get_int(mp4->buf) != 0 ) {
    DEBUG_TRACE("  stsz uses fixed sample size\n");
    buffer_consume(mp4->buf, 4);
    return 1;
  }
  
  mp4->num_sample_byte_sizes = buffer_get_int(mp4->buf);
  
  DEBUG_TRACE("  num_sample_byte_sizes %d\n", mp4->num_sample_byte_sizes);
  
  New(0, 
    mp4->sample_byte_size,
    mp4->num_sample_byte_sizes * sizeof(*mp4->sample_byte_size),
    uint16_t
  );
  
  if ( !mp4->sample_byte_size ) {
    PerlIO_printf(PerlIO_stderr(), "Unable to parse stsz: too large\n");
    return 0;
  }
  
  for (i = 0; i < mp4->num_sample_byte_sizes; i++) {
    uint32_t v = buffer_get_int(mp4->buf);
    
    if (v > 0x0000ffff) {
      DEBUG_TRACE("stsz[%d] > 65 kB (%ld)\n", i, (long)v);
      return 0;
    }
    
    mp4->sample_byte_size[i] = v;
    
    //DEBUG_TRACE("  sample_byte_size %d\n", v);
  }
  
  return 1;
}

uint8_t
_mp4_parse_stco(mp4info *mp4)
{
  int i;
  
  if ( !_check_buf(mp4->infile, mp4->buf, mp4->rsize, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  mp4->num_chunk_offsets = buffer_get_int(mp4->buf);
  DEBUG_TRACE("  num_chunk_offsets %d\n", mp4->num_chunk_offsets);
      
  New(0, 
    mp4->chunk_offset,
    mp4->num_chunk_offsets * sizeof(*mp4->chunk_offset),
    uint32_t
  );
  
  if ( !mp4->chunk_offset ) {
    PerlIO_printf(PerlIO_stderr(), "Unable to parse stco: too large\n");
    return 0;
  }
  
  for (i = 0; i < mp4->num_chunk_offsets; i++) {
    mp4->chunk_offset[i] = buffer_get_int(mp4->buf);
    
    //DEBUG_TRACE("  chunk_offset %d\n", mp4->chunk_offset[i]);
  }
  
  return 1;
}

uint8_t
_mp4_parse_meta(mp4info *mp4)
{
  uint32_t hdlr_size;
  char type[5];
  
  if ( !_check_buf(mp4->infile, mp4->buf, 12, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  // Skip version/flags
  buffer_consume(mp4->buf, 4);
  
  // Parse/skip meta version of hdlr
  hdlr_size = buffer_get_int(mp4->buf);
  strncpy( type, (char *)buffer_ptr(mp4->buf), 4 );
  type[4] = '\0';
  buffer_consume(mp4->buf, 4);
  
  if ( !FOURCC_EQ(type, "hdlr") ) {
    return 0;
  }
  
  // Skip rest of hdlr
  if ( !_check_buf(mp4->infile, mp4->buf, hdlr_size - 8, MP4_BLOCK_SIZE) ) {
    return 0;
  }
  
  buffer_consume(mp4->buf, hdlr_size - 8);  
  
  return 12 + hdlr_size - 8;
}

uint8_t
_mp4_parse_ilst(mp4info *mp4)
{
  while (mp4->rsize) {
    uint32_t size;
    char key[5];
    
    if ( !_check_buf(mp4->infile, mp4->buf, 8, MP4_BLOCK_SIZE) ) {
      return 0;
    }
    
    DEBUG_TRACE("  ilst rsize %llu\n", mp4->rsize);
    
    // Read Apple annotation box
    size = buffer_get_int(mp4->buf);
    strncpy( key, (char *)buffer_ptr(mp4->buf), 4 );
    key[4] = '\0';
    buffer_consume(mp4->buf, 4);
    
    DEBUG_TRACE("  %s size %d\n", key, size);
    
    // Note: extra _check_buf calls in this function and other ilst functions
    // are to avoid reading in the full size of ilst in the case of large artwork
    
    upcase(key);
    
    if ( FOURCC_EQ(key, "----") ) {
      // user-specified key/value pair
      if ( !_mp4_parse_ilst_custom(mp4, size - 8) ) {
        return 0;
      }
    }
    else {
      uint32_t bsize;
      
      // Ensure we have 8 bytes
      if ( !_check_buf(mp4->infile, mp4->buf, 8, MP4_BLOCK_SIZE) ) {
        return 0;
      }
      
      // Verify data box
      bsize = buffer_get_int(mp4->buf);
      
      DEBUG_TRACE("    box size %d\n", bsize);
      
      // Sanity check for bad data size
      if ( bsize <= size - 8 ) {
        SV *skey;
        
        char *bptr = buffer_ptr(mp4->buf);
        if ( !FOURCC_EQ(bptr, "data") ) {
          return 0;
        }
      
        buffer_consume(mp4->buf, 4);
        
        skey = newSVpv(key, 0);
      
        if ( !_mp4_parse_ilst_data(mp4, bsize - 8, skey) ) {
          SvREFCNT_dec(skey);
          return 0;
        }
        
        SvREFCNT_dec(skey);
        
        // XXX: bug 14476, files with multiple COVR images aren't handled here, just skipped for now
        if ( bsize < size - 8 ) {
          DEBUG_TRACE("    skipping rest of box, %d\n", size - 8 - bsize );
          _mp4_skip(mp4, size - 8 - bsize);
        }
      }
      else {
        DEBUG_TRACE("    invalid data size %d, skipping value\n", bsize);
        _mp4_skip(mp4, size - 12);
      }
    }
    
    mp4->rsize -= size;
  }
  
  return 1;
}

uint8_t
_mp4_parse_ilst_data(mp4info *mp4, uint32_t size, SV *key)
{
  uint32_t flags;
  unsigned char *ckey;
  SV *value;
  
  ckey = (unsigned char *)SvPVX(key);
  if ( FOURCC_EQ(ckey, "COVR") && _env_true("AUDIO_SCAN_NO_ARTWORK") ) {
    // Skip artwork if requested and avoid the memory cost
    value = newSVuv(size - 8);
    
    my_hv_store( mp4->tags, "COVR_offset", newSVuv(mp4->audio_offset + (mp4->size - mp4->rsize) + 24) );
    
    _mp4_skip(mp4, size);
  }
  else {
    // Read the full ilst value
    if ( !_check_buf(mp4->infile, mp4->buf, size, MP4_BLOCK_SIZE) ) {
      return 0;
    }
    
    // Version(0) + Flags
    flags = buffer_get_int(mp4->buf);

    // Skip reserved
    buffer_consume(mp4->buf, 4);

    DEBUG_TRACE("      flags %d\n", flags);
    
    if ( !flags || flags == 21 ) {
      if ( FOURCC_EQ( SvPVX(key), "TRKN" ) || FOURCC_EQ( SvPVX(key), "DISK" ) ) {
        // Special case trkn, disk (pair of 16-bit ints)
        uint16_t num = 0;
        uint16_t total = 0;
      
        buffer_consume(mp4->buf, 2); // padding
    
        num = buffer_get_short(mp4->buf);
      
        // Total may not always be present
        if (size > 12) {
          total = buffer_get_short(mp4->buf);  
          buffer_consume(mp4->buf, size - 14); // optional padding
        }
      
        DEBUG_TRACE("      %d/%d\n", num, total);
    
        if (total) {
          my_hv_store_ent( mp4->tags, key, newSVpvf( "%d/%d", num, total ) );
        }
        else if (num) {
          my_hv_store_ent( mp4->tags, key, newSVuv(num) );
        }
        
        return 1;
      }
      else if ( FOURCC_EQ( SvPVX(key), "GNRE" ) ) {
        // Special case genre, 16-bit int as id3 genre code
        char const *genre_string;
        uint16_t genre_num = buffer_get_short(mp4->buf);
    
        if (genre_num > 0 && genre_num < NGENRES + 1) {
          genre_string = _id3_genre_index(genre_num - 1);
          my_hv_store_ent( mp4->tags, key, newSVpv( genre_string, 0 ) );
        }
        
        return 1;
      }
      else {
        // Other binary type, try to guess type based on size
        uint32_t dsize = size - 8;
      
        if (dsize == 1) {
          value = newSVuv( buffer_get_char(mp4->buf) );
        }
        else if (dsize == 2) {
          value = newSVuv( buffer_get_short(mp4->buf) );
        }
        else if (dsize == 4) {
          value = newSVuv( buffer_get_int(mp4->buf) );
        }
        else if (dsize == 8) {
          value = newSVuv( buffer_get_int64(mp4->buf) );
        }
        else {
          value = newSVpvn( buffer_ptr(mp4->buf), dsize );
          buffer_consume(mp4->buf, dsize);
        }
      }
    }
    else { // text data
      value = newSVpvn( buffer_ptr(mp4->buf), size - 8 );
      sv_utf8_decode(value);
    
      // strip copyright symbol 0xA9 out of key
      if ( ckey[0] == 0xA9 ) {
        ckey++;
      }

      DEBUG_TRACE("      %s = %s\n", ckey, SvPVX(value));
    
      buffer_consume(mp4->buf, size - 8);
    }
  }
    
  // if key exists, create array
  if ( my_hv_exists( mp4->tags, (char *)ckey ) ) {
    SV **entry = my_hv_fetch( mp4->tags, (char *)ckey );
    if (entry != NULL) {
      if ( SvROK(*entry) && SvTYPE(SvRV(*entry)) == SVt_PVAV ) {
        av_push( (AV *)SvRV(*entry), value );
      }
      else {
        // A non-array entry, convert to array.
        AV *ref = newAV();
        av_push( ref, newSVsv(*entry) );
        av_push( ref, value );
        my_hv_store( mp4->tags, (char *)ckey, newRV_noinc( (SV*)ref ) );
      }
    }
  }
  else {
    my_hv_store( mp4->tags, (char *)ckey, value );
  }
  
  return 1;
} 

uint8_t
_mp4_parse_ilst_custom(mp4info *mp4, uint32_t size)
{
  SV *key = NULL;
  
  while (size) {
    char type[5];
    uint32_t bsize;
    
    // Ensure we have 8 bytes to get the size and type
    if ( !_check_buf(mp4->infile, mp4->buf, 8, MP4_BLOCK_SIZE) ) {
      return 0;
    }
    
    // Read box
    bsize = buffer_get_int(mp4->buf);
    strncpy( type, (char *)buffer_ptr(mp4->buf), 4 );
    type[4] = '\0';
    buffer_consume(mp4->buf, 4);
    
    DEBUG_TRACE("    %s size %d\n", type, bsize);
    
    if ( FOURCC_EQ(type, "name") ) {
      // Ensure we have bsize bytes
      if ( !_check_buf(mp4->infile, mp4->buf, bsize, MP4_BLOCK_SIZE) ) {
        return 0;
      }
      
      buffer_consume(mp4->buf, 4); // padding
      key = newSVpvn( buffer_ptr(mp4->buf), bsize - 12);
      sv_utf8_decode(key);
      upcase(SvPVX(key));
      buffer_consume(mp4->buf, bsize - 12);
      
      DEBUG_TRACE("      %s\n", SvPVX(key));
    }
    else if ( FOURCC_EQ(type, "data") ) {
      if (!key) {
        // No key yet, data is out of order
        return 0;
      }
      
      if ( !_mp4_parse_ilst_data(mp4, bsize - 8, key) ) {
        SvREFCNT_dec(key);
        return 0;
      }
    }
    else {
      // skip (mean, or other boxes)
      if ( !_check_buf(mp4->infile, mp4->buf, bsize - 8, MP4_BLOCK_SIZE) ) {
        return 0;
      }
      
      buffer_consume(mp4->buf, bsize - 8);
    }
    
    size -= bsize;
  }
  
  SvREFCNT_dec(key);
  
  return 1;
}

HV *
_mp4_get_current_trackinfo(mp4info *mp4)
{
  // Return the trackinfo hash for track id == mp4->current_track
  AV *tracks;
  HV *trackinfo;
  int i;
  
  SV **entry = my_hv_fetch(mp4->info, "tracks");
  if (entry != NULL) {
    tracks = (AV *)SvRV(*entry);
  }
  else {
    return NULL;
  }

  // Find entry for this stream number
  for (i = 0; av_len(tracks) >= 0 && i <= av_len(tracks); i++) {
    SV **info = av_fetch(tracks, i, 0);
    if (info != NULL) {
      SV **tid;
      
      trackinfo = (HV *)SvRV(*info);        
      tid = my_hv_fetch( trackinfo, "id" );
      if (tid != NULL) {
        if ( SvIV(*tid) == mp4->current_track ) {
          return trackinfo;
        }
      }
    }
  }
  
  return NULL;
}

uint32_t
_mp4_descr_length(Buffer *buf)
{
  uint8_t b;
  uint8_t num_bytes = 0;
  uint32_t length = 0;
  
  do {
    b = buffer_get_char(buf);
    num_bytes++;
    length = (length << 7) | (b & 0x7f);
  } while ( (b & 0x80) && num_bytes < 4 );
  
  return length;
}

void
_mp4_skip(mp4info *mp4, uint32_t size)
{
  if ( buffer_len(mp4->buf) >= size ) {
    //buffer_dump(mp4->buf, size);
    buffer_consume(mp4->buf, size);
    
    DEBUG_TRACE("  skipped buffer data size %d\n", size);
  }
  else {
    PerlIO_seek(mp4->infile, size - buffer_len(mp4->buf), SEEK_CUR);
    buffer_clear(mp4->buf);
    
    DEBUG_TRACE("  seeked past %d bytes to %d\n", size, (int)PerlIO_tell(mp4->infile));
  }
}

uint32_t
_mp4_samples_in_chunk(mp4info *mp4, uint32_t chunk)
{
  int i;
  
  for (i = mp4->num_sample_to_chunks - 1; i >= 0; i--) {
    if (mp4->sample_to_chunk[i].first_chunk <= chunk) {
      return mp4->sample_to_chunk[i].samples_per_chunk;
    }
  }
  
  return mp4->sample_to_chunk[0].samples_per_chunk;
}

uint32_t
_mp4_total_samples(mp4info *mp4)
{
  int i;
  uint32_t total = 0;
  
  for (i = 0; i < mp4->num_time_to_samples; i++) {
    total += mp4->time_to_sample[i].sample_count;
  }
  
  return total;
}

uint32_t
_mp4_get_sample_duration(mp4info *mp4, uint32_t sample)
{
  int i;
  uint32_t co = 0;
  
  for (i = 0; i < mp4->num_time_to_samples; i++) {
    uint32_t delta = mp4->time_to_sample[i].sample_count;
    if (sample < co + delta) {
      return mp4->time_to_sample[i].sample_duration;
    }
    
    co += delta;
  }
  
  return 0;
}
