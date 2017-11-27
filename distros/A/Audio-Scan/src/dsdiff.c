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

#define PROP_CK  (uint8_t)1
#define DSD_CK   (uint8_t)2
#define DIIN_CK  (uint8_t)4
#define ERROR_CK (uint8_t)128
#include "dsdiff.h"

typedef struct {
  PerlIO *infile;
  Buffer *buf;
  char *file;
  HV *info;
  HV *tags;
  uint32_t channel_num;
  uint32_t sampling_frequency;
  uint64_t metadata_offset;
  uint64_t sample_count;
  uint64_t offset;
  uint64_t audio_offset;
  char *tag_diar_artist;
  char *tag_diti_title;
} dsdiff_info;

static uint8_t
parse_diin_chunk(dsdiff_info *dsdiff, uint64_t size)
{
  uint64_t ck_offset = 0;

  while (ck_offset < size) {
    char chunk_id[5];
		uint64_t chunk_size;
		uint32_t count;

		buffer_clear(dsdiff->buf);
		PerlIO_seek(dsdiff->infile, dsdiff->offset + ck_offset, SEEK_SET);

		if ( !_check_buf(dsdiff->infile, dsdiff->buf, 12, DSDIFF_BLOCK_SIZE) ) return ERROR_CK;
		strncpy(chunk_id, (char *)buffer_ptr(dsdiff->buf), 4);
		chunk_id[4] = '\0';
		buffer_consume(dsdiff->buf, 4);
		chunk_size = buffer_get_int64(dsdiff->buf);
		ck_offset += 12;

		DEBUG_TRACE("  diin: %s : %" PRIu64 ",%" PRIu64 "\n", chunk_id, dsdiff->offset + ck_offset, chunk_size);

		if ( !strcmp(chunk_id, "DIAR") ) {
  		if ( !_check_buf(dsdiff->infile, dsdiff->buf, chunk_size, DSDIFF_BLOCK_SIZE) ) return ERROR_CK;
			count = buffer_get_int(dsdiff->buf);;
			dsdiff->tag_diar_artist = (char *)malloc(count + 1);
			strncpy(dsdiff->tag_diar_artist, (char *)buffer_ptr(dsdiff->buf), count);
			dsdiff->tag_diar_artist[count] = '\0';
		} else if ( !strcmp(chunk_id, "DITI") ) {
			if ( !_check_buf(dsdiff->infile, dsdiff->buf, chunk_size, DSDIFF_BLOCK_SIZE) ) return ERROR_CK;
			count = buffer_get_int(dsdiff->buf);;
			dsdiff->tag_diti_title = (char *)malloc(count + 1);
			strncpy(dsdiff->tag_diti_title, (char *)buffer_ptr(dsdiff->buf), count);
			dsdiff->tag_diti_title[count] = '\0';
		}

		ck_offset += chunk_size;
  }

  return DIIN_CK;
}

static uint8_t
parse_prop_chunk(dsdiff_info *dsdiff, uint64_t size)
{
  uint64_t ck_offset = 0;

  if ( !_check_buf(dsdiff->infile, dsdiff->buf, 4, DSDIFF_BLOCK_SIZE) ) return ERROR_CK;
  if ( strncmp( (char *)buffer_ptr(dsdiff->buf), "SND ", 4 ) ) return 0;
  ck_offset += 4;

  while (ck_offset < size) {
		char chunk_id[5];
		uint64_t chunk_size;

		buffer_clear(dsdiff->buf);
		PerlIO_seek(dsdiff->infile, dsdiff->offset + ck_offset, SEEK_SET);

		if ( !_check_buf(dsdiff->infile, dsdiff->buf, 16, DSDIFF_BLOCK_SIZE) ) return ERROR_CK;
		strncpy(chunk_id, (char *)buffer_ptr(dsdiff->buf), 4);
		chunk_id[4] = '\0';
		buffer_consume(dsdiff->buf, 4);
		chunk_size = buffer_get_int64(dsdiff->buf);
		ck_offset += 12;

		DEBUG_TRACE("  prop: %s : %" PRIu64 ",%" PRIu64 "\n", chunk_id, dsdiff->offset + ck_offset, chunk_size);

		if ( !strcmp(chunk_id, "FS  ") ) {
			dsdiff->sampling_frequency = buffer_get_int(dsdiff->buf);
		} else if ( !strcmp(chunk_id, "CHNL") ) {
			dsdiff->channel_num = (uint32_t)buffer_get_short(dsdiff->buf);
		} else if ( !strcmp(chunk_id, "ID3 ") ) {
		        dsdiff->metadata_offset = dsdiff->offset + ck_offset;
		}
		ck_offset += chunk_size;
  }

  if (dsdiff->channel_num == 0 || dsdiff->sampling_frequency == 0) return ERROR_CK;

  return PROP_CK;
}

int
get_dsdiff_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  Buffer buf;
  uint8_t flags = 0;
  off_t file_size;
  int err = 0;
  uint64_t total_size;
  dsdiff_info dsdiff;
  unsigned char *bptr;
  uint32_t song_length_ms;

  dsdiff.infile = infile;
  dsdiff.buf = &buf;
  dsdiff.file = file;
  dsdiff.info = info;
  dsdiff.tags = tags;
  dsdiff.channel_num = 0;
  dsdiff.sampling_frequency = 0;
  dsdiff.metadata_offset = 0;
  dsdiff.sample_count = 0;
  dsdiff.offset = 0;
  dsdiff.audio_offset = 0;
  dsdiff.tag_diar_artist = NULL;
  dsdiff.tag_diti_title = NULL;

  file_size = _file_size(infile);

  buffer_init(&buf, DSDIFF_BLOCK_SIZE);

  if ( !_check_buf(infile, &buf, 16, DSDIFF_BLOCK_SIZE) ) {
    err = -1;
    goto out;
  }

  if ( !strncmp( (char *)buffer_ptr(&buf), "FRM8", 4 ) ) {
    buffer_consume(&buf, 4);
    total_size = buffer_get_int64(&buf) + 12;
    dsdiff.offset += 12;

    if (strncmp( (char *)buffer_ptr(&buf), "DSD ", 4 ) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid DSDIFF file header: %s\n", file);
      err = -1;
      goto out;
    }
    dsdiff.offset += 4;

    my_hv_store( info, "file_size", newSVuv(file_size) );

    while (dsdiff.offset <= total_size - 12) {
      char chunk_id[5];
      uint64_t chunk_size;

      buffer_clear(&buf);
      PerlIO_seek(infile, dsdiff.offset, SEEK_SET);

      if ( !_check_buf(infile, &buf, 12, DSDIFF_BLOCK_SIZE) ) {
				PerlIO_printf(PerlIO_stderr(), "DSDIFF file error: %s\n", file);
				err = -1;
				goto out;
      };

      strncpy(chunk_id, (char *)buffer_ptr(&buf), 4);
      chunk_id[4] = '\0';
      buffer_consume(&buf, 4);
      chunk_size = buffer_get_int64(&buf);
      dsdiff.offset += 12;

      DEBUG_TRACE("%s: %" PRIu64 ",%" PRIu64 "\n", chunk_id, dsdiff.offset, chunk_size);

      if (!strcmp(chunk_id, "PROP")) {
				flags |= parse_prop_chunk(&dsdiff, chunk_size);
      } else if (!strcmp(chunk_id, "DIIN")) {
				flags |= parse_diin_chunk(&dsdiff, chunk_size);
      } else if (!strcmp(chunk_id, "DSD ")) {
				dsdiff.sample_count = 8 * chunk_size / dsdiff.channel_num;
				dsdiff.audio_offset = dsdiff.offset;
				flags |= DSD_CK;
      }	else if ( !strcmp(chunk_id, "ID3 ") ) {
				dsdiff.metadata_offset = dsdiff.offset;
      }

      if ( flags & ERROR_CK ) {
				PerlIO_printf(PerlIO_stderr(), "DSDIFF chunk error: %s\n", file);
				err = -1;
				goto out;
      };

      dsdiff.offset += chunk_size;
    }

    DEBUG_TRACE("Finished parsing...\n");

    if ((flags & DSD_CK) == 0 || (flags & PROP_CK) == 0) {
      PerlIO_printf(PerlIO_stderr(), "DSDIFF file error: %s\n", file);
      err = -1;
      goto out;
    };

    song_length_ms = ((dsdiff.sample_count * 1.0) / dsdiff.sampling_frequency) * 1000;

    DEBUG_TRACE("audio_offset: %" PRIu64 "\n", dsdiff.audio_offset);
    DEBUG_TRACE("audio_size: %" PRIu64 "\n", dsdiff.sample_count / 8 * dsdiff.channel_num);
    DEBUG_TRACE("samplerate: %" PRIu32 "\n", dsdiff.sampling_frequency);
    DEBUG_TRACE("song_length_ms: %u\n", song_length_ms);
    DEBUG_TRACE("channels: %" PRIu32 "\n", dsdiff.channel_num);

    my_hv_store( info, "audio_offset", newSVuv(dsdiff.audio_offset) );
    my_hv_store( info, "audio_size", newSVuv(dsdiff.sample_count / 8 * dsdiff.channel_num) );
    my_hv_store( info, "samplerate", newSVuv(dsdiff.sampling_frequency) );
    my_hv_store( info, "song_length_ms", newSVuv(song_length_ms) );
    my_hv_store( info, "channels", newSVuv(dsdiff.channel_num) );
    my_hv_store( info, "bits_per_sample", newSVuv(1) );
    my_hv_store( info, "bitrate", newSVuv( _bitrate(file_size - dsdiff.audio_offset, song_length_ms) ) );

    if (dsdiff.tag_diar_artist) {
      my_hv_store( info, "tag_diar_artist", newSVpv(dsdiff.tag_diar_artist, 0) );
      free(dsdiff.tag_diar_artist);
    }

    if (dsdiff.tag_diti_title) {
      my_hv_store( info, "tag_diti_title", newSVpv(dsdiff.tag_diti_title, 0) );
      free(dsdiff.tag_diti_title);
    }

    DEBUG_TRACE("Stored info values...\n");

    if (dsdiff.metadata_offset) {
      PerlIO_seek(infile, dsdiff.metadata_offset, SEEK_SET);
      buffer_clear(&buf);
      if ( !_check_buf(infile, &buf, 10, DSDIFF_BLOCK_SIZE) ) {
				goto out;
      }

      bptr = buffer_ptr(&buf);
      if (
					(bptr[0] == 'I' && bptr[1] == 'D' && bptr[2] == '3') &&
					bptr[3] < 0xff && bptr[4] < 0xff &&
					bptr[6] < 0x80 && bptr[7] < 0x80 && bptr[8] < 0x80 && bptr[9] < 0x80
					) {
				parse_id3(infile, file, info, tags, dsdiff.metadata_offset, file_size);
      }
    }
  } else {
    PerlIO_printf(PerlIO_stderr(), "Invalid DSF file: missing DSD header: %s\n", file);
    err = -1;
    goto out;
  }

 out:
  buffer_free(&buf);

  if (err) return err;

  return 0;
}

