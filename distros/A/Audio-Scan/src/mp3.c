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

/*
 * This file is derived from mt-daap project.
 */

#include "mp3.h"

int
get_mp3fileinfo(PerlIO *infile, char *file, HV *info)
{
 mp3info *mp3 = _mp3_parse(infile, file, info);

 buffer_free(mp3->buf);
 Safefree(mp3->buf);
 Safefree(mp3->first_frame);
 Safefree(mp3->xing_frame);
 Safefree(mp3);

 return 0;
}

int
get_mp3tags(PerlIO *infile, char *file, HV *info, HV *tags)
{
  int ret;
  
  off_t file_size = _file_size(infile);
  
  // See if this file has an APE tag as fast as possible
  // This is still a big performance hit :(
  if ( _has_ape(infile, file_size, info) ) {
    get_ape_metadata(infile, file, info, tags);
  }
  
  ret = parse_id3(infile, file, info, tags, 0, file_size);

  return ret;
}

int
_is_ape_header(char *bptr)
{
  if ( bptr[0] == 'A' && bptr[1] == 'P' && bptr[2] == 'E'
    && bptr[3] == 'T' && bptr[4] == 'A' && bptr[5] == 'G'
    && bptr[6] == 'E' && bptr[7] == 'X'
  ) {
    return 1;
  }
  
  return 0;
}

int
_has_ape(PerlIO *infile, off_t file_size, HV *info)
{
  Buffer buf;
  uint8_t ret = 0;
  char *bptr;
  
  if ( (PerlIO_seek(infile, file_size - 160, SEEK_SET)) == -1 ) {
    return 0;
  }
  
  DEBUG_TRACE("Seeked to %d looking for APE tag\n", (int)PerlIO_tell(infile));
  
  // Bug 9942, read 136 bytes so we can check at -32 bytes in case file
  // does not have an ID3v1 tag
  buffer_init(&buf, 136);
  if ( !_check_buf(infile, &buf, 136, 136) ) {
    goto out;
  }
  
  bptr = buffer_ptr(&buf);
  
  if ( _is_ape_header(bptr) ) {
    DEBUG_TRACE("APE tag found at -160 (with ID3v1)\n");
    ret = 1;
  }
  else {
    // Look for Lyrics tag which may possibly be between APE and ID3v1
    bptr += 23;
    if ( bptr[0] == 'L' && bptr[1] == 'Y' && bptr[2] == 'R'
      && bptr[3] == 'I' && bptr[4] == 'C' && bptr[5] == 'S'
      && bptr[6] == '2' && bptr[7] == '0' && bptr[8] == '0'
    ) {
      // read Lyrics tag size, stored as a 6-digit number (!?)
      // http://www.id3.org/Lyrics3v2
      uint32_t lyrics_size = 0;
      off_t file_size = _file_size(infile);
      
      bptr -= 6;
      lyrics_size = atoi(bptr);
      
      DEBUG_TRACE("LYRICS200 tag found (size %d), adjusting APE offset (%d)\n", lyrics_size, -(160 + lyrics_size + 15));
      
      if ( (PerlIO_seek(infile, file_size - (160 + lyrics_size + 15), SEEK_SET)) == -1 ) {
        goto out;
      }
      
      DEBUG_TRACE("Seeked before Lyrics tag to %d\n", (int)PerlIO_tell(infile));
      
      buffer_clear(&buf);
      if ( !_check_buf(infile, &buf, 136, 136) ) {
        goto out;
      }
      
      if ( _is_ape_header( buffer_ptr(&buf) ) ) {
        DEBUG_TRACE("APE tag found at %d (ID3v1 + Lyricsv2)\n", -(160 + lyrics_size + 15));
        ret = 1;
        goto out;
      }
      
      // APE code will remove the lyrics_size from audio_size, but if no APE tag do it here
      if (my_hv_exists(info, "audio_size")) {
        int audio_size = SvIV(*(my_hv_fetch(info, "audio_size")));
        my_hv_store(info, "audio_size", newSVuv(audio_size - lyrics_size - 15));
        DEBUG_TRACE("Reduced audio_size value by Lyrics2 tag size %d\n", lyrics_size + 15);
      }
    }
    
    // APE tag without ID3v1 tag will be -32 bytes from end
    buffer_consume(&buf, 128);
    
    bptr = buffer_ptr(&buf);

    if ( _is_ape_header(bptr) ) {
      DEBUG_TRACE("APE tag found at -32 (no ID3v1)\n");
      ret = 1;
    }
  }
  
out:
  buffer_free(&buf);
  
  return ret;
}

// _decode_mp3_frame, based on pcutmp3 FrameHeader.decode()
int
_decode_mp3_frame(unsigned char *bptr, struct mp3frame *frame)
{
  int i;
  
  frame->header32 = GET_INT32BE(bptr);
  
  frame->mpegID             = (frame->header32 >> 19) & 3;
  frame->layerID            = (frame->header32 >> 17) & 3;
  frame->crc16_used         = (frame->header32 & 0x00010000) == 0;
  frame->bitrate_index      = (frame->header32 >> 12) & 0xF;
  frame->samplingrate_index = (frame->header32 >> 10) & 3;
  frame->padding            = (frame->header32 & 0x00000200) != 0;
  frame->private_bit_set    = (frame->header32 & 0x00000100) != 0;
  frame->mode               = (frame->header32 >> 6) & 3;
  frame->mode_extension     = (frame->header32 >> 4) & 3;
  frame->copyrighted        = (frame->header32 & 0x00000008) != 0;
  frame->original           = (frame->header32 & 0x00000004) == 0; // bit set -> copy
  frame->emphasis           = frame->header32 & 3;
  
  frame->valid = (frame->mpegID != ILLEGAL_MPEG_ID) 
    && (frame->layerID != ILLEGAL_LAYER_ID)
    && (frame->bitrate_index != 0)
    && (frame->bitrate_index != 15)
    && (frame->samplingrate_index != ILLEGAL_SR);
  
  if (!frame->valid) {
    return -1;
  }
  
  frame->samplerate = sample_rate_tbl[ frame->samplingrate_index ];
  
  if (frame->mpegID == MPEG2_ID)
    frame->samplerate >>= 1; // 16,22,48 kHz
  
  if (frame->mpegID == MPEG25_ID)
    frame->samplerate >>= 2; // 8,11,24 kHz
  
  frame->channels = (frame->mode == MODE_MONO) ? 1 : 2;
  
  frame->bitrate_kbps = bitrate_map[ frame->mpegID ][ frame->layerID ][ frame->bitrate_index ];
  
  if (frame->layerID == LAYER1_ID) {
    // layer 1: always 384 samples/frame and 4byte-slots
    frame->samples_per_frame = 384;
    frame->bytes_per_slot = 4;
  }
  else {
    // layer 2: always 1152 samples/frame
    // layer 3: MPEG1: 1152 samples/frame, MPEG2/2.5: 576 samples/frame
    frame->samples_per_frame = ((frame->mpegID == MPEG1_ID) || (frame->layerID == LAYER2_ID)) ? 1152 : 576;
    frame->bytes_per_slot = 1;
  }
  
  frame->frame_size = ((frame->bitrate_kbps * 125) * frame->samples_per_frame) / frame->samplerate;
  
  if (frame->bytes_per_slot > 1)
    frame->frame_size -= frame->frame_size % frame->bytes_per_slot;
  
  if (frame->padding)
    frame->frame_size += frame->bytes_per_slot;

  DEBUG_TRACE("Frame @%p: size=%d, %d samples, %dkbps %d/%d\n",
      bptr, frame->frame_size, frame->samples_per_frame,
      frame->bitrate_kbps, frame->samplerate, frame->channels);

  return 0;
}

// _mp3_get_average_bitrate
// average bitrate by averaging all the frames in the file.  This used
// to seek to the middle of the file and take a 32K chunk but this was
// found to have bugs if it seeked near invalid FF sync bytes that could
// be detected as a real frame
static short _mp3_get_average_bitrate(mp3info *mp3, uint32_t offset, uint32_t audio_size)
{
  struct mp3frame frame;
  int frame_count   = 0;
  int bitrate_total = 0;
  int err = 0;
  int done = 0;
  int wrap_skip = 0;
  int prev_bitrate = 0;
  bool vbr = FALSE;

  unsigned char *bptr;
  
  buffer_clear(mp3->buf);

  // Seek to offset
  PerlIO_seek(mp3->infile, offset, SEEK_SET);
  
  while ( done < audio_size - 4 ) {
    // Buffer size is optimized for a possible common case: 20 frames of 192kbps CBR
    if ( !_check_buf(mp3->infile, mp3->buf, 4, MP3_BLOCK_SIZE * 3) ) {
      err = -1;
      goto out;
    }
    
    done += buffer_len(mp3->buf);
    
    if (wrap_skip) {
      // Skip rest of frame from last buffer
      DEBUG_TRACE("Wrapped, consuming %d bytes from previous frame\n", wrap_skip);
      buffer_consume(mp3->buf, wrap_skip);
      wrap_skip = 0;
    }
  
    while ( buffer_len(mp3->buf) >= 4 ) {
      bptr = buffer_ptr(mp3->buf);
      while ( *bptr != 0xFF ) {
        buffer_consume(mp3->buf, 1);
      
        if ( buffer_len(mp3->buf) < 4 ) {
          // ran out of data
          goto out;
        }
      
        bptr = buffer_ptr(mp3->buf);
      }

      if ( !_decode_mp3_frame( buffer_ptr(mp3->buf), &frame ) ) {
        // Found a valid frame
        frame_count++;
        bitrate_total += frame.bitrate_kbps;
        
        if ( !vbr ) {
          // If we see the bitrate changing, we have a VBR file, and read
          // the entire file.  Otherwise, if we see 20 frames with the same
          // bitrate, assume CBR and stop
          if (prev_bitrate > 0 && prev_bitrate != frame.bitrate_kbps) {
            DEBUG_TRACE("Bitrate changed, assuming file is VBR\n");
            vbr = TRUE;
          }
          else {
            if (frame_count > 20) {
              DEBUG_TRACE("Found 20 frames with same bitrate, assuming CBR\n");
              goto out;
            }
            
            prev_bitrate = frame.bitrate_kbps;
          }
        }
        
        //DEBUG_TRACE("  Frame %d: %dkbps, %dkHz\n", frame_count, frame.bitrate_kbps, frame.samplerate);

        if (frame.frame_size > buffer_len(mp3->buf)) {
          // Partial frame in buffer
          wrap_skip = frame.frame_size - buffer_len(mp3->buf);
          buffer_consume(mp3->buf, buffer_len(mp3->buf));
        }
        else {
          buffer_consume(mp3->buf, frame.frame_size);
        }
      }
      else {
        // Not a valid frame, stray 0xFF
        buffer_consume(mp3->buf, 1);
      }
    }
  }

out:
  if (err) return err;
  
  if (!frame_count) return -1;
  
  DEBUG_TRACE("Average of %d frames: %dkbps\n", frame_count, bitrate_total / frame_count);

  return bitrate_total / frame_count;
}

static int
_parse_xing(mp3info *mp3)
{
  int i;
  unsigned char *bptr;
  int xing_offset = 4;
  
  if (mp3->first_frame->mpegID == MPEG1_ID) {
    xing_offset += mp3->first_frame->channels == 2 ? 32 : 17;
  }
  else {
    xing_offset += mp3->first_frame->channels == 2 ? 17 : 9;
  }
  
  if ( !_check_buf(mp3->infile, mp3->buf, 4 + xing_offset, MP3_BLOCK_SIZE) ) {
    return 0;
  }
  
  buffer_consume(mp3->buf, xing_offset);
  
  bptr = buffer_ptr(mp3->buf);

  if ( bptr[0] == 'X' || bptr[0] == 'I' ) {
    if (
      ( bptr[1] == 'i' && bptr[2] == 'n' && bptr[3] == 'g' )
      ||
      ( bptr[1] == 'n' && bptr[2] == 'f' && bptr[3] == 'o' )
    ) {
      DEBUG_TRACE("Found Xing/Info tag\n");
      
      mp3->xing_frame->xing_tag   = bptr[0] == 'X';
      mp3->xing_frame->info_tag   = bptr[0] == 'I';
      mp3->xing_frame->frame_size = mp3->first_frame->frame_size;
      
      if ( !_check_buf(mp3->infile, mp3->buf, 160, MP3_BLOCK_SIZE) ) {
        return 0;
      }
      
      // It's VBR if tag is Xing, and CBR if Info
      mp3->vbr = bptr[1] == 'i' ? VBR : CBR;

      buffer_consume(mp3->buf, 4);

      mp3->xing_frame->flags = buffer_get_int(mp3->buf);

      if (mp3->xing_frame->flags & XING_FRAMES) {
        mp3->xing_frame->xing_frames = buffer_get_int(mp3->buf);
      }

      if ( mp3->xing_frame->flags & XING_BYTES) {
        mp3->xing_frame->xing_bytes = buffer_get_int(mp3->buf);
      }

      if (mp3->xing_frame->flags & XING_TOC) {
        uint8_t i;
        bptr = buffer_ptr(mp3->buf);
        for (i = 0; i < 100; i++) {
          mp3->xing_frame->xing_toc[i] = bptr[i];
        }
        
        mp3->xing_frame->has_toc = 1;
        
        buffer_consume(mp3->buf, 100);
      }

      if (mp3->xing_frame->flags & XING_QUALITY) {
        mp3->xing_frame->xing_quality = buffer_get_int(mp3->buf);
      }

      // LAME tag
      bptr = buffer_ptr(mp3->buf);
      if ( bptr[0] == 'L' && bptr[1] == 'A' && bptr[2] == 'M' && bptr[3] == 'E' ) {
        mp3->xing_frame->lame_tag = TRUE;
        
        strncpy(mp3->xing_frame->lame_encoder_version, (char *)bptr, 9);
        bptr += 9;

        // revision/vbr method byte
        mp3->xing_frame->lame_tag_revision = bptr[0] >> 4;
        mp3->xing_frame->lame_vbr_method   = bptr[0] & 15;
        buffer_consume(mp3->buf, 10);

        // Determine vbr status
        switch (mp3->xing_frame->lame_vbr_method) {
          case 1:
          case 8:
            mp3->vbr = CBR;
            break;
          case 2:
          case 9:
            mp3->vbr = ABR;
            break;
          default:
            mp3->vbr = VBR;
        }

        mp3->xing_frame->lame_lowpass = buffer_get_char(mp3->buf) * 100;

        // Skip peak
        buffer_consume(mp3->buf, 4);

        // Replay Gain, code from mpg123
        mp3->xing_frame->lame_replay_gain[0] = 0;
        mp3->xing_frame->lame_replay_gain[1] = 0;

        for (i=0; i<2; i++) {
          // Originator
          unsigned char origin;
          bptr = buffer_ptr(mp3->buf);
          
          origin = (bptr[0] >> 2) & 0x7;

          if (origin != 0) {
            // Gain type
            unsigned char gt = bptr[0] >> 5;
            if (gt == 1)
              gt = 0; /* radio */
            else if (gt == 2)
              gt = 1; /* audiophile */
            else
              continue;

            mp3->xing_frame->lame_replay_gain[gt]
              = (( (bptr[0] & 0x4) >> 2 ) ? -0.1 : 0.1)
              * ( (bptr[0] & 0x3) | bptr[1] );
          }

          buffer_consume(mp3->buf, 2);
        }

        // Skip encoding flags
        buffer_consume(mp3->buf, 1);

        // ABR rate/VBR minimum
        mp3->xing_frame->lame_abr_rate = buffer_get_char(mp3->buf);

        // Encoder delay/padding
        bptr = buffer_ptr(mp3->buf);
        mp3->xing_frame->lame_encoder_delay = ((((int)bptr[0]) << 4) | (((int)bptr[1]) >> 4));
        mp3->xing_frame->lame_encoder_padding = (((((int)bptr[1]) << 8) | (((int)bptr[2]))) & 0xfff);
        // sanity check
        if (mp3->xing_frame->lame_encoder_delay < 0 || mp3->xing_frame->lame_encoder_delay > 3000) {
          mp3->xing_frame->lame_encoder_delay = -1;
        }
        if (mp3->xing_frame->lame_encoder_padding < 0 || mp3->xing_frame->lame_encoder_padding > 3000) {
          mp3->xing_frame->lame_encoder_padding = -1;
        }
        buffer_consume(mp3->buf, 3);

        // Misc
        bptr = buffer_ptr(mp3->buf);
        mp3->xing_frame->lame_noise_shaping = bptr[0] & 0x3;
        mp3->xing_frame->lame_stereo_mode   = (bptr[0] & 0x1C) >> 2;
        mp3->xing_frame->lame_unwise        = (bptr[0] & 0x20) >> 5;
        mp3->xing_frame->lame_source_freq   = (bptr[0] & 0xC0) >> 6;
        buffer_consume(mp3->buf, 1);

        // XXX MP3 Gain, can't find a test file, current
        // mp3gain doesn't write this data
/*
        bptr = buffer_ptr(mp3->buf);
        unsigned char sign = (bptr[0] & 0x80) >> 7;
        mp3->xing_frame->lame_mp3gain = bptr[0] & 0x7F;
        if (sign) {
          mp3->xing_frame->lame_mp3gain *= -1;
        }
        mp3->xing_frame->lame_mp3gain_db = mp3->xing_frame->lame_mp3gain * 1.5;
*/
        buffer_consume(mp3->buf, 1);

        // Preset/Surround
        bptr = buffer_ptr(mp3->buf);
        mp3->xing_frame->lame_surround = (bptr[0] & 0x38) >> 3;
        mp3->xing_frame->lame_preset   = ((bptr[0] << 8) | bptr[1]) & 0x7ff;
        buffer_consume(mp3->buf, 2);

        // Music Length
        mp3->xing_frame->lame_music_length = buffer_get_int(mp3->buf);

        // Skip CRCs
      }
    }
  }
  // Check for VBRI header from Fhg encoders
  else if ( bptr[0] == 'V' && bptr[1] == 'B' && bptr[2] == 'R' && bptr[3] == 'I' ) {
    DEBUG_TRACE("Found VBRI tag\n");
    
    mp3->xing_frame->vbri_tag = TRUE;
    mp3->vbr = VBR;
    
    if ( !_check_buf(mp3->infile, mp3->buf, 14, MP3_BLOCK_SIZE) ) {
      return 0;
    }
    
    // Skip tag and version ID
    buffer_consume(mp3->buf, 6);

    mp3->xing_frame->vbri_delay   = buffer_get_short(mp3->buf);
    mp3->xing_frame->vbri_quality = buffer_get_short(mp3->buf);
    mp3->xing_frame->vbri_bytes   = buffer_get_int(mp3->buf);
    mp3->xing_frame->vbri_frames  = buffer_get_int(mp3->buf);
  }
  
  return 1;
}

static int
_is_mp3x_profile(mp3info *mp3)
{
  if (mp3->first_frame->layerID != LAYER3_ID)
    return 0;
    
  if (mp3->first_frame->mpegID != MPEG1_ID && mp3->first_frame->mpegID != MPEG2_ID)
    return 0;
  
  if (mp3->first_frame->samplerate != 16000
    && mp3->first_frame->samplerate != 22050
    && mp3->first_frame->samplerate != 24000)
    return 0;
  
  if (mp3->bitrate >= 8 && mp3->bitrate <= 320)
    return 1;
 
  return 0;
}

static int
_is_mp3_profile(mp3info *mp3)
{
  if (mp3->first_frame->layerID != LAYER3_ID)
    return 0;
  
  if (mp3->first_frame->mpegID != MPEG1_ID)
    return 0;
  
  if (mp3->first_frame->samplerate != 32000
    && mp3->first_frame->samplerate != 44100
    && mp3->first_frame->samplerate != 48000)
    return 0;
  
  if (mp3->bitrate >= 32 && mp3->bitrate <= 320)
    return 1;
  
  return 0;
}

mp3info *
_mp3_parse(PerlIO *infile, char *file, HV *info)
{
  unsigned char *bptr;
  char id3v1taghdr[4];

  uint32_t song_length_ms = 0;
  uint64_t total_samples = 0;
  struct mp3frame frame;
  
  bool found_first_frame = FALSE;
  
  mp3info *mp3;
  Newz(0, mp3, sizeof(mp3info), mp3info);
  Newz(0, mp3->buf, sizeof(Buffer), Buffer);
  Newz(0, mp3->first_frame, sizeof(mp3frame), mp3frame);
  Newz(0, mp3->xing_frame, sizeof(xingframe), xingframe);
  
  mp3->infile       = infile;
  mp3->file         = file;
  mp3->info         = info;
  
  mp3->file_size    = _file_size(infile);
  mp3->id3_size     = 0;
  mp3->audio_offset = 0;
  mp3->audio_size   = 0;
  mp3->bitrate      = 0;
  
  buffer_init(mp3->buf, MP3_BLOCK_SIZE);
  
  my_hv_store( info, "file_size", newSVuv(mp3->file_size) );
  
  if ( !_check_buf(mp3->infile, mp3->buf, 10, MP3_BLOCK_SIZE) ) {
    goto out;
  }
  
  bptr = buffer_ptr(mp3->buf);

  if (
    (bptr[0] == 'I' && bptr[1] == 'D' && bptr[2] == '3') &&
    bptr[3] < 0xff && bptr[4] < 0xff &&
    bptr[6] < 0x80 && bptr[7] < 0x80 && bptr[8] < 0x80 && bptr[9] < 0x80
  ) {
    /* found an ID3 header... */
    mp3->id3_size = 10 + (bptr[6]<<21) + (bptr[7]<<14) + (bptr[8]<<7) + bptr[9];

    if (bptr[5] & 0x10) {
      // footer present
      mp3->id3_size += 10;
    }
    
    DEBUG_TRACE("Found ID3v2.%d.%d tag, size %d\n", bptr[3], bptr[4], mp3->id3_size);

    // Always seek past the ID3 tags
    _mp3_skip(mp3, mp3->id3_size);
    
    if ( !_check_buf(mp3->infile, mp3->buf, 4, MP3_BLOCK_SIZE) ) {
      goto out;
    }

    mp3->audio_offset += mp3->id3_size;
  }

  // Find an MP3 frame
  while ( !found_first_frame && buffer_len(mp3->buf) ) {
    bptr = buffer_ptr(mp3->buf);
    
    while ( *bptr != 0xFF ) {
      buffer_consume(mp3->buf, 1);
     
      mp3->audio_offset++;

      if ( !buffer_len(mp3->buf) ) {
        if (mp3->audio_offset >= mp3->file_size - 4) {
          // No audio frames in file
          warn("Unable to find any MP3 frames in file: %s\n", file);
          goto out;
        }
        
        if ( !_check_buf(mp3->infile, mp3->buf, 4, MP3_BLOCK_SIZE) ) {
          warn("Unable to find any MP3 frames in file: %s\n", file);
          goto out;
        }
      }
      
      bptr = buffer_ptr(mp3->buf);
    }
    
    DEBUG_TRACE("Found FF sync at offset %d\n", (int)mp3->audio_offset);
    
    // Make sure we have 4 bytes
    if ( !_check_buf(mp3->infile, mp3->buf, 4, MP3_BLOCK_SIZE) ) {
      goto out;
    }

    if ( !_decode_mp3_frame( (unsigned char *)buffer_ptr(mp3->buf), &frame ) ) {
      struct mp3frame frame2, frame3;
      
      // Need the whole frame to consider it valid
      if ( _check_buf(mp3->infile, mp3->buf, frame.frame_size, MP3_BLOCK_SIZE)

        // If we have enough data for the start of the next frame then
        // it must also look valid and be consistent
        && (
          !_check_buf(mp3->infile, mp3->buf, frame.frame_size + 4, MP3_BLOCK_SIZE)
          || (
               !_decode_mp3_frame( (unsigned char *)buffer_ptr(mp3->buf) + frame.frame_size, &frame2 )
            && frame.samplerate == frame2.samplerate
            && frame.channels == frame2.channels
          )
        )

        // If we have enough data for the start of the over-next frame then
        // it must also look valid and be consistent
        && (
          !_check_buf(mp3->infile, mp3->buf, frame.frame_size + frame2.frame_size + 4, MP3_BLOCK_SIZE)
          || (
               !_decode_mp3_frame( (unsigned char *)buffer_ptr(mp3->buf) + frame.frame_size + frame2.frame_size, &frame3 )
            && frame.samplerate == frame3.samplerate
            && frame.channels == frame3.channels
          )
        )
      ) {
        // Found a valid frame
        DEBUG_TRACE("  valid frame\n");

        found_first_frame = 1;
      }
      else {
        DEBUG_TRACE("  false sync\n");
      }
    }

    if (!found_first_frame) {
      // Not a valid frame, stray 0xFF
      DEBUG_TRACE("  invalid frame\n");
      
      buffer_consume(mp3->buf, 1);
      mp3->audio_offset++;
    }
  }

  if ( !found_first_frame ) {
    warn("Unable to find any MP3 frames in file (checked 4K): %s\n", file);
    goto out;
  }

  mp3->audio_size = mp3->file_size - mp3->audio_offset;
  
  memcpy(mp3->first_frame, &frame, sizeof(mp3frame));

  // now check for Xing/Info/VBRI/LAME headers
  if ( !_parse_xing(mp3) ) {
    goto out;
  }

  // use LAME CBR/ABR value for bitrate if available
  if ( (mp3->vbr == CBR || mp3->vbr == ABR) && mp3->xing_frame->lame_abr_rate ) {
    if (mp3->xing_frame->lame_abr_rate >= 255) {
      // ABR rate field only codes up to 255, use preset value instead
      if (mp3->xing_frame->lame_preset <= 320) {
        mp3->bitrate = mp3->xing_frame->lame_preset;
        DEBUG_TRACE("bitrate from lame_preset: %d\n", mp3->bitrate);
      }
    }
    else {
      mp3->bitrate = mp3->xing_frame->lame_abr_rate;
      DEBUG_TRACE("bitrate from lame_abr_rate: %d\n", mp3->bitrate);
    }
  }

  // Or if we have a Xing header, use it to determine bitrate
  if (!mp3->bitrate && (mp3->xing_frame->xing_frames && mp3->xing_frame->xing_bytes)) {
    float mfs = (float)frame.samplerate / ( frame.mpegID == MPEG2_ID || frame.mpegID == MPEG25_ID ? 72000. : 144000. );
    mp3->bitrate = ( mp3->xing_frame->xing_bytes / mp3->xing_frame->xing_frames * mfs );
    DEBUG_TRACE("bitrate from Xing header: %d\n", mp3->bitrate);
  }

  // Or use VBRI header
  else if (mp3->xing_frame->vbri_frames && mp3->xing_frame->vbri_bytes) {
    float mfs = (float)frame.samplerate / ( frame.mpegID == MPEG2_ID || frame.mpegID == MPEG25_ID ? 72000. : 144000. );
    mp3->bitrate = ( mp3->xing_frame->vbri_bytes / mp3->xing_frame->vbri_frames * mfs );
    DEBUG_TRACE("bitrate from VBRI header: %d\n", mp3->bitrate);
  }

  // check if last 128 bytes is ID3v1.0 or ID3v1.1 tag
  PerlIO_seek(infile, mp3->file_size - 128, SEEK_SET);
  if (PerlIO_read(infile, id3v1taghdr, 4) == 4) {
    if (id3v1taghdr[0]=='T' && id3v1taghdr[1]=='A' && id3v1taghdr[2]=='G') {
      DEBUG_TRACE("ID3v1 tag found\n");
      mp3->audio_size -= 128;
    }
  }

  // If we don't know the bitrate from Xing/LAME/VBRI, calculate average
  if ( !mp3->bitrate ) {    
    DEBUG_TRACE("Calculating average bitrate starting from %d...\n", (int)mp3->audio_offset);
    mp3->bitrate = _mp3_get_average_bitrate(mp3, mp3->audio_offset, mp3->audio_size);

    if (mp3->bitrate <= 0) {
      // Couldn't determine bitrate, just use
      // the bitrate from the last frame we parsed
      DEBUG_TRACE("Unable to determine bitrate, using bitrate of most recent frame (%d)\n", frame.bitrate_kbps);
      mp3->bitrate = frame.bitrate_kbps;
    }
  }

  if (mp3->xing_frame->xing_frames) {
    total_samples = mp3->xing_frame->xing_frames * frame.samples_per_frame;
        
    if (mp3->xing_frame->lame_tag) {
      // subtract delay/padding to get accurate sample count
      total_samples -= (mp3->xing_frame->lame_encoder_delay + mp3->xing_frame->lame_encoder_padding);
    }
    
    song_length_ms = (int) ((double)(total_samples * 1000.) / (double) frame.samplerate);
  }
  else if (mp3->xing_frame->vbri_frames) {
    song_length_ms = (int) ((double)(mp3->xing_frame->vbri_frames * frame.samples_per_frame * 1000.)/
			(double) frame.samplerate);
    total_samples = mp3->xing_frame->vbri_frames * frame.samples_per_frame;
	}
  else {
    song_length_ms = (int) ((double)mp3->audio_size * 8. /
			(double)mp3->bitrate);
  }
  
  mp3->song_length_ms = song_length_ms;
  
  my_hv_store( info, "song_length_ms", newSVuv(song_length_ms) );
  my_hv_store( info, "layer", newSVuv(frame.layerID) );
  my_hv_store( info, "stereo", newSVuv(frame.channels == 2 ? 1 : 0) );
  my_hv_store( info, "samples_per_frame", newSVuv(frame.samples_per_frame) );
  my_hv_store( info, "padding", newSVuv(frame.padding) );
  my_hv_store( info, "audio_size", newSVuv(mp3->audio_size) );
  my_hv_store( info, "audio_offset", newSVuv(mp3->audio_offset) );
  my_hv_store( info, "bitrate", newSVuv( mp3->bitrate * 1000 ) );
  my_hv_store( info, "samplerate", newSVuv( frame.samplerate ) );

  if (mp3->xing_frame->xing_tag || mp3->xing_frame->info_tag) {
    if (mp3->xing_frame->xing_frames) {
      my_hv_store( info, "xing_frames", newSVuv(mp3->xing_frame->xing_frames) );
    }

    if (mp3->xing_frame->xing_bytes) {
      my_hv_store( info, "xing_bytes", newSVuv(mp3->xing_frame->xing_bytes) );
    }
    
    if (mp3->xing_frame->has_toc) {
      uint8_t i;
      AV *xing_toc = newAV();

      for (i = 0; i < 100; i++) {
        av_push( xing_toc, newSVuv(mp3->xing_frame->xing_toc[i]) );
      }

      my_hv_store( info, "xing_toc", newRV_noinc( (SV *)xing_toc ) );
    }

    if (mp3->xing_frame->xing_quality) {
      my_hv_store( info, "xing_quality", newSVuv(mp3->xing_frame->xing_quality) );
    }
  }

  if (mp3->xing_frame->vbri_tag) {
    my_hv_store( info, "vbri_delay", newSVuv(mp3->xing_frame->vbri_delay) );
    my_hv_store( info, "vbri_frames", newSVuv(mp3->xing_frame->vbri_frames) );
    my_hv_store( info, "vbri_bytes", newSVuv(mp3->xing_frame->vbri_bytes) );
    my_hv_store( info, "vbri_quality", newSVuv(mp3->xing_frame->vbri_quality) );
  }

  if (mp3->xing_frame->lame_tag) {
    my_hv_store( info, "lame_encoder_version", newSVpvn(mp3->xing_frame->lame_encoder_version, 9) );
    my_hv_store( info, "lame_tag_revision", newSViv(mp3->xing_frame->lame_tag_revision) );
    my_hv_store( info, "lame_vbr_method", newSVpv( vbr_methods[mp3->xing_frame->lame_vbr_method], 0 ) );
    my_hv_store( info, "lame_lowpass", newSViv(mp3->xing_frame->lame_lowpass) );

    if (mp3->xing_frame->lame_replay_gain[0]) {
      my_hv_store( info, "lame_replay_gain_radio", newSVpvf( "%.1f dB", mp3->xing_frame->lame_replay_gain[0] ) );
    }

    if (mp3->xing_frame->lame_replay_gain[1]) {
      my_hv_store( info, "lame_replay_gain_audiophile", newSVpvf( "%.1f dB", mp3->xing_frame->lame_replay_gain[1] ) );
    }

    my_hv_store( info, "lame_encoder_delay", newSViv(mp3->xing_frame->lame_encoder_delay) );
    my_hv_store( info, "lame_encoder_padding", newSViv(mp3->xing_frame->lame_encoder_padding) );

    my_hv_store( info, "lame_noise_shaping", newSViv(mp3->xing_frame->lame_noise_shaping) );
    my_hv_store( info, "lame_stereo_mode", newSVpv( stereo_modes[mp3->xing_frame->lame_stereo_mode], 0 ) );
    my_hv_store( info, "lame_unwise_settings", newSViv(mp3->xing_frame->lame_unwise) );
    my_hv_store( info, "lame_source_freq", newSVpv( source_freqs[mp3->xing_frame->lame_source_freq], 0 ) );

//    my_hv_store( info, "lame_mp3gain", newSViv(mp3->xing_frame->lame_mp3gain) );
//    my_hv_store( info, "lame_mp3gain_db", newSVnv(mp3->xing_frame->lame_mp3gain_db) );

    my_hv_store( info, "lame_surround", newSVpv( surround[mp3->xing_frame->lame_surround], 0 ) );

    if (mp3->xing_frame->lame_preset < 8) {
      my_hv_store( info, "lame_preset", newSVpvn( "Unknown", 7 ) );
    }
    else if (mp3->xing_frame->lame_preset <= 320) {
      my_hv_store( info, "lame_preset", newSVpvf( "ABR %d", mp3->xing_frame->lame_preset ) );
    }
    else if (mp3->xing_frame->lame_preset <= 500) {
      mp3->xing_frame->lame_preset /= 10;
      mp3->xing_frame->lame_preset -= 41;
      if ( presets_v[mp3->xing_frame->lame_preset] ) {
        my_hv_store( info, "lame_preset", newSVpv( presets_v[mp3->xing_frame->lame_preset], 0 ) );
      }
    }
    else if (mp3->xing_frame->lame_preset >= 1000 && mp3->xing_frame->lame_preset <= 1007) {
      mp3->xing_frame->lame_preset -= 1000;
      if ( presets_old[mp3->xing_frame->lame_preset] ) {
        my_hv_store( info, "lame_preset", newSVpv( presets_old[mp3->xing_frame->lame_preset], 0 ) );
      }
    }
  }
  
  if (mp3->vbr == ABR || mp3->vbr == VBR) {
    my_hv_store( info, "vbr", newSViv(1) );
  }
  
  // DLNA profile detection
  if (_is_mp3x_profile(mp3))
    my_hv_store( info, "dlna_profile", newSVpvn( "MP3X", 4 ) );
  else if (_is_mp3_profile(mp3))
    my_hv_store( info, "dlna_profile", newSVpvn( "MP3", 3 ) );
  
out:

  return mp3;
}

int
mp3_find_frame(PerlIO *infile, char *file, int offset)
{
  Buffer mp3_buf;
  unsigned char *bptr;
  unsigned int buf_size;
  struct mp3frame frame;
  int frame_offset = -1;
  HV *info = newHV();
  
  mp3info *mp3 = _mp3_parse(infile, file, info);
  
  buffer_init(&mp3_buf, MP3_BLOCK_SIZE);
  
  if (!mp3->song_length_ms)
    goto out;
  
  // (undocumented) If offset is negative, treat it as an absolute file offset in bytes
  // This is a bit ugly but avoids the need to write an entirely new method
  if (offset < 0) {
    frame_offset = abs(offset);
    if (frame_offset < mp3->audio_offset) {
      // Force offset to be at least audio_offset, so we don't end up in an ID3 tag
      frame_offset = mp3->audio_offset;
    }
    DEBUG_TRACE("find_frame: using absolute offset value %d\n", frame_offset);
  }
  else {
    if (offset >= mp3->song_length_ms) {
      goto out;
    }
    
    // Use Xing TOC if available
    if ( mp3->xing_frame->has_toc ) {
      float percent;
      uint8_t ipercent;
      uint16_t tva;
      uint16_t tvb;
      float tvx;
  
      percent = (offset * 1.0 / mp3->song_length_ms) * 100;
      ipercent = (int)percent;
  
      if (ipercent > 99)
        ipercent = 99;
      
      // Interpolate between 2 TOC points
      tva = mp3->xing_frame->xing_toc[ipercent];
      if (ipercent < 99) {
        tvb = mp3->xing_frame->xing_toc[ipercent + 1];
      }
      else {
        tvb = 256;
      }
    
      tvx = tva + (tvb - tva) * (percent - ipercent);
  
      frame_offset = (int)((1.0/256.0) * tvx * mp3->xing_frame->xing_bytes);
  
      frame_offset += mp3->audio_offset;
  
      // Don't return offset == audio_offset, because that would be the Xing frame
      if (frame_offset == mp3->audio_offset) {
        DEBUG_TRACE("find_frame: frame_offset == audio_offset, skipping to next frame\n");
        frame_offset += 1;
      }
  
      DEBUG_TRACE("find_frame: using Xing TOC, song_length_ms: %d, percent: %f, tva: %d, tvb: %d, tvx: %f, frame offset: %d\n",
        mp3->song_length_ms, percent, tva, tvb, tvx, frame_offset
      );
    }
    else {
      // calculate offset using bitrate
      float bytes_per_ms = mp3->bitrate / 8.0;
    
      frame_offset = (int)(bytes_per_ms * offset);
    
      frame_offset += mp3->audio_offset;
    
      DEBUG_TRACE("find_frame: using bitrate %d, bytes_per_ms: %f, frame offset: %d\n", mp3->bitrate, bytes_per_ms, frame_offset);
    }
  }
  
  // If frame_offset is too near the end of the file we won't find a valid frame
  // so require offset to be at least 1000 bytes from the end of the file
  // XXX this would be more accurate if we determined max_frame_len
  if ((mp3->file_size - frame_offset) < 1000) {
    frame_offset -= 1000 - (mp3->file_size - frame_offset);
    if (frame_offset < 0)
      frame_offset = 0;
    DEBUG_TRACE("find_frame: offset too close to end of file, adjusted to %d\n", frame_offset);
  }
  
  PerlIO_seek(infile, frame_offset, SEEK_SET);

  if ( !_check_buf(infile, &mp3_buf, 4, MP3_BLOCK_SIZE) ) {
    frame_offset = -1;
    goto out;
  }
  
  bptr = (unsigned char *)buffer_ptr(&mp3_buf);
  buf_size = buffer_len(&mp3_buf);
  
  // Find 0xFF sync and verify it's a valid mp3 frame header
  while (1) {
    if (
      buf_size < 4
      ||
      ( bptr[0] == 0xFF && !_decode_mp3_frame( bptr, &frame ) )
    ) {
      break;
    }
    
    bptr++;
    buf_size--;
  }
  
  if (buf_size >= 4) {
    frame_offset += buffer_len(&mp3_buf) - buf_size;
    DEBUG_TRACE("find_frame: frame_offset: %d\n", frame_offset);
  }
  else {
    // Didn't find a valid frame, probably too near the end of the file
    DEBUG_TRACE("find_frame: did not find a valid frame\n");
    frame_offset = -1;
  }

out:
  buffer_free(&mp3_buf);
  SvREFCNT_dec(info);
  
  buffer_free(mp3->buf);
  Safefree(mp3->buf);
  Safefree(mp3->first_frame);
  Safefree(mp3->xing_frame);
  Safefree(mp3);

  return frame_offset;
}

void
_mp3_skip(mp3info *mp3, uint32_t size)
{
  if ( buffer_len(mp3->buf) >= size ) {
    buffer_consume(mp3->buf, size);
    
    DEBUG_TRACE("  skipped buffer data size %d\n", size);
  }
  else {
    PerlIO_seek(mp3->infile, size - buffer_len(mp3->buf), SEEK_CUR);
    buffer_clear(mp3->buf);
    
    DEBUG_TRACE("  seeked past %d bytes to %d\n", size, (int)PerlIO_tell(mp3->infile));
  }
}
