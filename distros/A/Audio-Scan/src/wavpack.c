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

#include "wavpack.h"

static int
get_wavpack_info(PerlIO *infile, char *file, HV *info)
{
  wvpinfo *wvp = _wavpack_parse(infile, file, info, 0);

  Safefree(wvp);

  return 0;
}

wvpinfo *
_wavpack_parse(PerlIO *infile, char *file, HV *info, uint8_t seeking)
{
  int err = 0;
  int done = 0;
  u_char *bptr;

  wvpinfo *wvp;
  Newz(0, wvp, sizeof(wvpinfo), wvpinfo);
  Newz(0, wvp->buf, sizeof(Buffer), Buffer);
  Newz(0, wvp->header, sizeof(WavpackHeader), WavpackHeader);

  wvp->infile         = infile;
  wvp->file           = file;
  wvp->info           = info;
  wvp->file_offset    = 0;
  wvp->audio_offset   = 0;
  wvp->seeking        = seeking ? 1 : 0;

  buffer_init(wvp->buf, WAVPACK_BLOCK_SIZE);

  wvp->file_size = _file_size(infile);
  my_hv_store( info, "file_size", newSVuv(wvp->file_size) );

  // Loop through each wvpk block until we find a good one
  while (!done) {
    if ( !_check_buf(infile, wvp->buf, 32, WAVPACK_BLOCK_SIZE) ) {
      err = -1;
      goto out;
    }

    bptr = buffer_ptr(wvp->buf);

    // If first byte is 'R', assume old version
    if ( bptr[0] == 'R' ) {
      if ( !_wavpack_parse_old(wvp) ) {
        err = -1;
        goto out;
      }

      break;
    }

    // May need to read past some junk before wvpk header
    while ( bptr[0] != 'w' || bptr[1] != 'v' || bptr[2] != 'p' || bptr[3] != 'k' ) {
      buffer_consume(wvp->buf, 1);

      wvp->audio_offset++;

      if ( !buffer_len(wvp->buf) ) {
        if ( !_check_buf(infile, wvp->buf, 32, WAVPACK_BLOCK_SIZE) ) {
          PerlIO_printf(PerlIO_stderr(), "Unable to find a valid WavPack block in file: %s\n", file);
          err = -1;
          goto out;
        }
      }

      bptr = buffer_ptr(wvp->buf);
    }

    if ( _wavpack_parse_block(wvp) ) {
      done = 1;
    }
  }

  my_hv_store( info, "audio_offset", newSVuv(wvp->audio_offset) );
  my_hv_store( info, "audio_size", newSVuv(wvp->file_size - wvp->audio_offset) );

out:
  buffer_free(wvp->buf);
  Safefree(wvp->buf);
  Safefree(wvp->header);

  return wvp;
}

int
_wavpack_parse_block(wvpinfo *wvp)
{
  unsigned char *bptr;
  uint16_t remaining;

  bptr = buffer_ptr(wvp->buf);

  // Verify wvpk signature
  if ( bptr[0] != 'w' || bptr[1] != 'v' || bptr[2] != 'p' || bptr[3] != 'k' ) {
    DEBUG_TRACE("Invalid wvpk header at %llu\n", wvp->file_offset);
    return 1;
  }

  buffer_consume(wvp->buf, 4);

  wvp->header->ckSize        = buffer_get_int_le(wvp->buf);
  wvp->header->version       = buffer_get_short_le(wvp->buf);
  wvp->header->track_no      = buffer_get_char(wvp->buf);
  wvp->header->index_no      = buffer_get_char(wvp->buf);
  wvp->header->total_samples = buffer_get_int_le(wvp->buf);
  wvp->header->block_index   = buffer_get_int_le(wvp->buf);
  wvp->header->block_samples = buffer_get_int_le(wvp->buf);
  wvp->header->flags         = buffer_get_int_le(wvp->buf);
  wvp->header->crc           = buffer_get_int_le(wvp->buf);

  DEBUG_TRACE("wvpk header @ %llu:\n", wvp->file_offset);
  DEBUG_TRACE("  size: %u\n", wvp->header->ckSize);
  DEBUG_TRACE("  version: 0x%x\n", wvp->header->version);
  DEBUG_TRACE("  track_no: 0x%x\n", wvp->header->track_no);
  DEBUG_TRACE("  index_no: 0x%x\n", wvp->header->index_no);
  DEBUG_TRACE("  total_samples: %u\n", wvp->header->total_samples);
  DEBUG_TRACE("  block_index: %u\n", wvp->header->block_index);
  DEBUG_TRACE("  block_samples: %u\n", wvp->header->block_samples);
  DEBUG_TRACE("  flags: 0x%x\n", wvp->header->flags);
  DEBUG_TRACE("  crc: 0x%x\n", wvp->header->crc);

  wvp->file_offset += 32;

  my_hv_store( wvp->info, "encoder_version", newSVuv(wvp->header->version) );

  if (wvp->header->version < 0x4) {
    // XXX old version and not handled by 'R' check above for old version
    PerlIO_printf(PerlIO_stderr(), "Unsupported old WavPack version: 0x%x\n", wvp->header->version);
    return 1;
  }

  // Read data from flags
  my_hv_store( wvp->info, "bits_per_sample", newSVuv( 8 * ((wvp->header->flags & 0x3) + 1) ) );

  // Encoding mode
  my_hv_store( wvp->info, (wvp->header->flags & 0x8) ? "hybrid" : "lossless", newSVuv(1) );

  {
    // samplerate, may be overridden by a later ID_SAMPLE_RATE metadata block
    uint32_t samplerate_index = (wvp->header->flags & 0x7800000) >> 23;
    if ( samplerate_index < 0xF ) {
      my_hv_store( wvp->info, "samplerate", newSVuv( wavpack_sample_rates[samplerate_index] ) );
    }
    else {
      // Default to 44.1 just in case
      my_hv_store( wvp->info, "samplerate", newSVuv(44100) );
    }
  }

  // Channels, may be overridden by a later ID_CHANNEL_INFO metadata block
  my_hv_store( wvp->info, "channels", newSVuv( (wvp->header->flags & 0x4) ? 1 : 2 ) );

  // Parse metadata sub-blocks
  remaining = wvp->header->ckSize - 24; // ckSize is 8 less than the block size

  // If block_samples is 0, we need to skip to the next block
  if ( !wvp->header->block_samples ) {
    wvp->file_offset += remaining;
    _wavpack_skip(wvp, remaining);
    return 0;
  }

  while (remaining > 0) {
    // Read sub-block header (2-4 bytes)
    unsigned char id;
    uint32_t size;

    DEBUG_TRACE("remaining: %d\n", remaining);

    if ( !_check_buf(wvp->infile, wvp->buf, 4, WAVPACK_BLOCK_SIZE) ) {
      return 0;
    }

    id = buffer_get_char(wvp->buf);
    remaining--;

    // Size is in words
    if (id & ID_LARGE) {
      // 24-bit large size
      id &= ~ID_LARGE;
      size = buffer_get_int24_le(wvp->buf) << 1;
      remaining -= 3;
      DEBUG_TRACE("  ID_LARGE, changed to %x\n", id);
    }
    else {
      // 8-bit size
      size = buffer_get_char(wvp->buf) << 1;
      remaining--;
    }

    if (id & ID_ODD_SIZE) {
      id &= ~ID_ODD_SIZE;
      size--;
      DEBUG_TRACE("  ID_ODD_SIZE, changed to %x\n", id);
    }

    if ( id == ID_WV_BITSTREAM || !size ) {
      // Found the bitstream, don't read any farther
      DEBUG_TRACE("  Sub-Chunk: WV_BITSTREAM (size %u)\n", size);
      break;
    }

    // We only care about 0x27 (ID_SAMPLE_RATE) and 0xd (ID_CHANNEL_INFO)
    switch (id) {
    case ID_SAMPLE_RATE:
      DEBUG_TRACE("  Sub-Chunk: ID_SAMPLE_RATE (size: %u)\n", size);
      _wavpack_parse_sample_rate(wvp, size);
      break;

    case ID_CHANNEL_INFO:
      DEBUG_TRACE("  Sub-Chunk: ID_CHANNEL_INFO (size: %u)\n", size);
      _wavpack_parse_channel_info(wvp, size);
      break;

    default:
      // Skip it
      DEBUG_TRACE("  Sub-Chunk: %x (size: %u) (skipped)\n", id, size);
      _wavpack_skip(wvp, size);
    }

    remaining -= size;

    // If size was odd, skip a byte
    if (size & 0x1) {
      if ( buffer_len(wvp->buf) ) {
        buffer_consume(wvp->buf, 1);
      }
      else {
        _wavpack_skip(wvp, 1);
      }

      remaining--;
    }
  }

  // Calculate bitrate
  if ( wvp->header->total_samples && wvp->file_size > 0 ) {
    SV **samplerate = my_hv_fetch( wvp->info, "samplerate" );
    if (samplerate != NULL) {
      uint32_t song_length_ms = ((wvp->header->total_samples * 1.0) / SvIV(*samplerate)) * 1000;
      my_hv_store( wvp->info, "song_length_ms", newSVuv(song_length_ms) );
      my_hv_store( wvp->info, "bitrate", newSVuv( _bitrate(wvp->file_size - wvp->audio_offset, song_length_ms) ) );
      my_hv_store( wvp->info, "total_samples", newSVuv(wvp->header->total_samples) );
    }
  }

  return 1;
}

int
_wavpack_parse_sample_rate(wvpinfo *wvp, uint32_t size)
{
  uint32_t samplerate = buffer_get_int24_le(wvp->buf);

  my_hv_store( wvp->info, "samplerate", newSVuv(samplerate) );

  return 1;
}

int
_wavpack_parse_channel_info(wvpinfo *wvp, uint32_t size)
{
  uint32_t channels;
  unsigned char *bptr = buffer_ptr(wvp->buf);

  if (size == 6) {
    channels = (bptr[0] | ((bptr[2] & 0xf) << 8)) + 1;
  }
  else {
    channels = bptr[0];
  }

  my_hv_store( wvp->info, "channels", newSVuv(channels) );

  buffer_consume(wvp->buf, size);

  return 1;
}

void
_wavpack_skip(wvpinfo *wvp, uint32_t size)
{
  if ( buffer_len(wvp->buf) >= size ) {
    //buffer_dump(mp4->buf, size);
    buffer_consume(wvp->buf, size);

    DEBUG_TRACE("  skipped buffer data size %d\n", size);
  }
  else {
    PerlIO_seek(wvp->infile, size - buffer_len(wvp->buf), SEEK_CUR);
    buffer_clear(wvp->buf);

    DEBUG_TRACE("  seeked past %d bytes to %d\n", size, (int)PerlIO_tell(wvp->infile));
  }
}

int
_wavpack_parse_old(wvpinfo *wvp)
{
  int ret = 1;
  char chunk_id[5];
  uint32_t chunk_size;
  WavpackHeader3 wphdr;
  WaveHeader3 wavhdr;
  unsigned char *bptr;
  uint32_t total_samples;
  uint32_t song_length_ms;

  Zero(&wavhdr, sizeof(wavhdr), char);
  Zero(&wphdr, sizeof(wphdr), char);

  DEBUG_TRACE("Parsing old WavPack version\n");

  // Verify RIFF header
  if ( strncmp( (char *)buffer_ptr(wvp->buf), "RIFF", 4 ) ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid WavPack file: missing RIFF header: %s\n", wvp->file);
    ret = 0;
    goto out;
  }

  buffer_consume(wvp->buf, 4);

  chunk_size = buffer_get_int_le(wvp->buf);

  // Check format
  if ( strncmp( (char *)buffer_ptr(wvp->buf), "WAVE", 4 ) ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid WavPack file: missing WAVE header: %s\n", wvp->file);
    ret = 0;
    goto out;
  }

  buffer_consume(wvp->buf, 4);

  wvp->file_offset += 12;

  // Verify we have at least 8 bytes
  if ( !_check_buf(wvp->infile, wvp->buf, 8, WAVPACK_BLOCK_SIZE) ) {
    ret = 0;
    goto out;
  }

  // loop through all chunks, read fmt, and break at data
  while ( buffer_len(wvp->buf) >= 8 ) {
    strncpy( chunk_id, (char *)buffer_ptr(wvp->buf), 4 );
    chunk_id[4] = '\0';
    buffer_consume(wvp->buf, 4);

    chunk_size = buffer_get_int_le(wvp->buf);

    wvp->file_offset += 8;

    // Adjust for padding
    if ( chunk_size % 2 ) {
      chunk_size++;
    }

    DEBUG_TRACE("  %s size %d\n", chunk_id, chunk_size);

    if ( !strcmp( chunk_id, "data" ) ) {
      break;
    }

    wvp->file_offset += chunk_size;

    if ( !strcmp( chunk_id, "fmt " ) ) {
      if ( !_check_buf(wvp->infile, wvp->buf, chunk_size, WAV_BLOCK_SIZE) ) {
        ret = 0;
        goto out;
      }

      if (chunk_size < sizeof(wavhdr)) {
        ret = 0;
        goto out;
      }

      // Read wav header
      wavhdr.FormatTag      = buffer_get_short_le(wvp->buf);
      wavhdr.NumChannels    = buffer_get_short_le(wvp->buf);
      wavhdr.SampleRate     = buffer_get_int_le(wvp->buf);
      wavhdr.BytesPerSecond = buffer_get_int_le(wvp->buf);
      wavhdr.BlockAlign     = buffer_get_short_le(wvp->buf);
      wavhdr.BitsPerSample  = buffer_get_short_le(wvp->buf);

      // Skip rest of fmt chunk if necessary
      if (chunk_size > 16) {
        _wavpack_skip(wvp, chunk_size - 16);
      }
    }
    else {
      // Skip it
      _wavpack_skip(wvp, chunk_size);
    }

    // Verify we have at least 8 bytes
    if ( !_check_buf(wvp->infile, wvp->buf, 8, WAVPACK_BLOCK_SIZE) ) {
      ret = 0;
      goto out;
    }
  }

  // Verify wav header, this code comes from unpack3.c
  if (
    wavhdr.FormatTag != 1 || !wavhdr.NumChannels || wavhdr.NumChannels > 2 ||
    !wavhdr.SampleRate || wavhdr.BitsPerSample < 16 || wavhdr.BitsPerSample > 24 ||
    wavhdr.BlockAlign / wavhdr.NumChannels > 3 || wavhdr.BlockAlign % wavhdr.NumChannels ||
    wavhdr.BlockAlign / wavhdr.NumChannels < (wavhdr.BitsPerSample + 7) / 8
  ) {
    ret = 0;
    goto out;
  }

  // chunk_size here is the size of the data chunk
  total_samples = chunk_size / wavhdr.NumChannels / ((wavhdr.BitsPerSample > 16) ? 3 : 2);

  // read WavpackHeader3 (differs for each version)
  bptr = buffer_ptr(wvp->buf);
  if ( bptr[0] != 'w' || bptr[1] != 'v' || bptr[2] != 'p' || bptr[3] != 'k' ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid WavPack file: missing wvpk header: %s\n", wvp->file);
    ret = 0;
    goto out;
  }

  buffer_consume(wvp->buf, 4);

  wphdr.ckSize  = buffer_get_int_le(wvp->buf);
  wphdr.version = buffer_get_short_le(wvp->buf);

  if (wphdr.version >= 2) {
    wphdr.bits = buffer_get_short_le(wvp->buf);
  }

  if (wphdr.version == 3) {
    wphdr.flags         = buffer_get_short_le(wvp->buf);
    wphdr.shift         = buffer_get_short_le(wvp->buf);
    wphdr.total_samples = buffer_get_int_le(wvp->buf);

    total_samples = wphdr.total_samples;
  }

  DEBUG_TRACE("wvpk header @ %llu:\n", wvp->file_offset);
  DEBUG_TRACE("  size: %u\n", wphdr.ckSize);
  DEBUG_TRACE("  version: %d\n", wphdr.version);
  DEBUG_TRACE("  bits: 0x%x\n", wphdr.bits);
  DEBUG_TRACE("  flags: 0x%x\n", wphdr.flags);
  DEBUG_TRACE("  shift: 0x%x\n", wphdr.shift);
  DEBUG_TRACE("  total_samples: %d\n", wphdr.total_samples);

  my_hv_store( wvp->info, "encoder_version", newSVuv(wphdr.version) );
  my_hv_store( wvp->info, "bits_per_sample", newSVuv(wavhdr.BitsPerSample) );
  my_hv_store( wvp->info, "channels", newSVuv(wavhdr.NumChannels) );
  my_hv_store( wvp->info, "samplerate", newSVuv(wavhdr.SampleRate) );
  my_hv_store( wvp->info, "total_samples", newSVuv(total_samples) );

  song_length_ms = ((total_samples * 1.0) / wavhdr.SampleRate) * 1000;
  my_hv_store( wvp->info, "song_length_ms", newSVuv(song_length_ms) );
  my_hv_store( wvp->info, "bitrate", newSVuv( _bitrate(wvp->file_size - wvp->audio_offset, song_length_ms) ) );

out:
  return ret;
}

