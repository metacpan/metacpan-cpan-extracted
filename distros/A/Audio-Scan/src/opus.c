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

#include "opus.h"

int
get_opus_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  return _opus_parse(infile, file, info, tags, 0);
}

#define OGG_HEADER_SIZE 28
int
_opus_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking)
{
  Buffer ogg_buf, vorbis_buf;
  unsigned char *bptr;
  unsigned char *last_bptr;
  unsigned int buf_size;

  unsigned int id3_size = 0; // size of leading ID3 data

  off_t file_size;           // total file size
  off_t audio_size;          // total size of audio without tags
  off_t audio_offset = 0;    // offset to audio
  off_t seek_position;
  
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
  
  unsigned char opushdr[11];
  unsigned char channels;
  unsigned int samplerate = 0;
  unsigned int preskip = 0;
  unsigned int input_samplerate = 0;
  uint64_t granule_pos = 0;
  
  unsigned char TOC_byte = 0;

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
    
    DEBUG_TRACE("OggS page %d / packet %d at %d\n", pagenum, packets, (int)(audio_offset - 28));
    DEBUG_TRACE("  granule_pos: %llu\n", granule_pos);
    
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
    TOC_byte = buffer_get_char(&vorbis_buf);
    if ( TOC_byte == 'O' ) {
      if ( strncmp( buffer_ptr(&vorbis_buf), "pusTags", 7 ) == 0) {
        buffer_consume(&vorbis_buf, 7);
        DEBUG_TRACE("  Found Opus tags TOC packet type\n");
      	if ( !seeking ) {
                _parse_vorbis_comments(infile, &vorbis_buf, tags, 0);
      	}
        DEBUG_TRACE("  parsed vorbis comments\n");

        buffer_clear(&vorbis_buf);
      }
      else {
      	// Verify 'OpusHead' string
      	if ( strncmp( buffer_ptr(&vorbis_buf), "pusHead", 7 ) ) {
      	  PerlIO_printf(PerlIO_stderr(), "Not an Opus file (bad opus header): %s\n", file);
      	  goto out;
      	}
      	buffer_consume( &vorbis_buf, 7 );

      	DEBUG_TRACE("  Found Opus header TOC packet type\n");
      	// Parse info
      	// Grab 23-byte Vorbis header
      	if ( buffer_len(&vorbis_buf) < 11 ) {
      	  PerlIO_printf(PerlIO_stderr(), "Not an Opus file (opus header too short): %s\n", file);
      	  goto out;
      	}

      	buffer_get(&vorbis_buf, opushdr, 11);

      	my_hv_store( info, "version", newSViv( opushdr[0] ) );

      	channels = opushdr[1];
      	my_hv_store( info, "channels", newSViv(channels) );
      	my_hv_store( info, "stereo", newSViv( channels == 2 ? 1 : 0 ) );

      	preskip = CONVERT_INT16LE((opushdr+2));
      	my_hv_store( info, "preskip", newSViv(preskip) );

      	my_hv_store( info, "samplerate", newSViv(48000) );
      	samplerate = 48000; // Opus only supports 48k

      	input_samplerate = CONVERT_INT32LE((opushdr+4));
      	my_hv_store( info, "input_samplerate", newSViv(input_samplerate) );

      	DEBUG_TRACE("  parsed opus info header\n");
      }
      buffer_clear(&vorbis_buf);
    }
    
    // Skip rest of this page
    buffer_consume( &ogg_buf, pagelen );
  }
  
  buffer_clear(&ogg_buf);
  DEBUG_TRACE("Buffer clear");
  
  // audio_offset is 28 less because we read the Ogg header
  audio_offset -= 28;
  
  // from the first packet past the comments
  my_hv_store( info, "audio_offset", newSViv(audio_offset) );
  
  audio_size = file_size - audio_offset;
  my_hv_store( info, "audio_size", newSVuv(audio_size) );
  
  my_hv_store( info, "serial_number", newSVuv(serialno) );
  DEBUG_TRACE("serial number\n");
#define BUF_SIZE 8500 // from vlc
  seek_position = file_size - BUF_SIZE;
  while (1) {
    if ( seek_position < audio_offset ) {
      seek_position = audio_offset;
    }

    // calculate average bitrate and duration
    DEBUG_TRACE("Seeking to %d to calculate bitrate/duration\n", (int)seek_position);
    PerlIO_seek(infile, seek_position, SEEK_SET);

    buf_size = PerlIO_read(infile, buffer_append_space(&ogg_buf, BUF_SIZE), BUF_SIZE);
    if ( buf_size == 0 ) {
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
        DEBUG_TRACE("found granule_pos %llu / samplerate %d to calculate bitrate/duration\n", granule_pos, samplerate);
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

    if ( granule_pos && samplerate && serialno == final_serialno ) {
      // XXX: needs to adjust for initial granule value if file does not start at 0 samples
      int length = (int)(((granule_pos-preskip) * 1.0 / samplerate) * 1000);
      my_hv_store( info, "song_length_ms", newSVuv(length) );
      my_hv_store( info, "bitrate_average", newSVuv( _bitrate(audio_size, length) ) );

      DEBUG_TRACE("Using granule_pos %llu / samplerate %d to calculate bitrate/duration\n", granule_pos, samplerate);
      break;
    }
    if ( seek_position == audio_offset ) {
      DEBUG_TRACE("Packet not found we won't be able to determine the length\n");
      break;
    }
    // seek backwards by BUF_SIZE - OGG_HEADER_SIZE so that if our previous sync happened to include the end
    // of page header we will include it in the next read
    seek_position -= (BUF_SIZE - OGG_HEADER_SIZE);
  }
out:
  buffer_free(&ogg_buf);
  buffer_free(&vorbis_buf);

  DEBUG_TRACE("Err %d\n", err);
  if (err) return err;

  return 0;
}

static int
opus_find_frame(PerlIO *infile, char *file, int offset)
{
  int frame_offset = -1;
  uint32_t samplerate;
  uint32_t song_length_ms;
  uint64_t target_sample;
  
  // We need to read all metadata first to get some data we need to calculate
  HV *info = newHV();
  HV *tags = newHV();
  if ( _opus_parse(infile, file, info, tags, 1) != 0 ) {
    goto out;
  }
  
  song_length_ms = SvIV( *(my_hv_fetch( info, "song_length_ms" )) );
  if (offset >= song_length_ms) {
    goto out;
  }
  
  samplerate = SvIV( *(my_hv_fetch( info, "samplerate" )) );
  
  // Determine target sample we're looking for
  target_sample = ((offset - 1) / 10) * (samplerate / 100);
  DEBUG_TRACE("Looking for target sample %llu\n", target_sample);
  
  frame_offset = _ogg_binary_search_sample(infile, file, info, target_sample);

out:  
  // Don't leak
  SvREFCNT_dec(info);
  SvREFCNT_dec(tags);

  return frame_offset;
}
