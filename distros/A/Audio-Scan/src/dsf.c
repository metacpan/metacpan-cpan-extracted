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

#include "dsf.h"

int
get_dsf_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  Buffer buf;
  off_t file_size;
  int err = 0;
  uint64_t chunk_size, total_size, metadata_offset, sample_count, sample_bytes;
  uint32_t format_version, format_id, channel_type, channel_num,
    sampling_frequency, block_size_per_channel, bits_per_sample, song_length_ms;
  unsigned char *bptr;

  file_size = _file_size(infile);

  buffer_init(&buf, DSF_BLOCK_SIZE);

  if ( !_check_buf(infile, &buf, 80, DSF_BLOCK_SIZE) ) {
    err = -1;
    goto out;
  }

  if ( !strncmp( (char *)buffer_ptr(&buf), "DSD ", 4 ) ) {
    buffer_consume(&buf, 4);

    my_hv_store( info, "file_size", newSVuv(file_size) );

    chunk_size = buffer_get_int64_le(&buf);
    total_size = buffer_get_int64_le(&buf);
    metadata_offset = buffer_get_int64_le(&buf);

    if ((chunk_size != 28) ||
				metadata_offset > total_size) {
      PerlIO_printf(PerlIO_stderr(), "Invalid DSF file header: %s\n", file);
      err = -1;
      goto out;
    }

    if ( strncmp( (char *)buffer_ptr(&buf), "fmt ", 4 ) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid DSF file: missing fmt header: %s\n", file);
      err = -1;
      goto out;
    }

    buffer_consume(&buf, 4);
    chunk_size = buffer_get_int64_le(&buf);
    format_version = buffer_get_int_le(&buf);
    format_id = buffer_get_int_le(&buf);
    channel_type = buffer_get_int_le(&buf);
    channel_num = buffer_get_int_le(&buf);
    sampling_frequency = buffer_get_int_le(&buf);
    bits_per_sample = buffer_get_int_le(&buf);
    sample_count = buffer_get_int64_le(&buf);
    block_size_per_channel = buffer_get_int_le(&buf);

    if ( (chunk_size != 52) ||
				 (format_version != 1) ||
				 (format_id != 0) ||
				 (block_size_per_channel != 4096) ||
				 strncmp( (char *)buffer_ptr(&buf), "\0\0\0\0", 4 ) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid DSF file: unsupported fmt header: %s\n", file);
      err = -1;
      goto out;
    }

    buffer_consume(&buf, 4);

    if ( strncmp( (char *)buffer_ptr(&buf), "data", 4 ) ) {
      PerlIO_printf(PerlIO_stderr(), "Invalid DSF file: missing data header: %s\n", file);
      err = -1;
      goto out;
    }

    buffer_consume(&buf, 4);

    sample_bytes = buffer_get_int64_le(&buf) - 12;

    song_length_ms = ((sample_count * 1.0) / sampling_frequency) * 1000;

    my_hv_store( info, "audio_offset", newSVuv( 28 + 52 + 12 ) );
    my_hv_store( info, "audio_size", newSVuv(sample_bytes) );
    my_hv_store( info, "samplerate", newSVuv(sampling_frequency) );
    my_hv_store( info, "song_length_ms", newSVuv(song_length_ms) );
    my_hv_store( info, "channels", newSVuv(channel_num) );
    my_hv_store( info, "bits_per_sample", newSVuv(1) );
    my_hv_store( info, "block_size_per_channel", newSVuv(block_size_per_channel) );
    my_hv_store( info, "bitrate", newSVuv( _bitrate(file_size - (28 + 52 + 12), song_length_ms) ) );

    if (metadata_offset) {
      PerlIO_seek(infile, metadata_offset, SEEK_SET);
      buffer_clear(&buf);
      if ( !_check_buf(infile, &buf, 10, DSF_BLOCK_SIZE) ) {
				goto out;
      }

      bptr = buffer_ptr(&buf);
      if (
					(bptr[0] == 'I' && bptr[1] == 'D' && bptr[2] == '3') &&
					bptr[3] < 0xff && bptr[4] < 0xff &&
					bptr[6] < 0x80 && bptr[7] < 0x80 && bptr[8] < 0x80 && bptr[9] < 0x80
					) {
				parse_id3(infile, file, info, tags, metadata_offset, file_size);
      }
    }
  }
  else {
    PerlIO_printf(PerlIO_stderr(), "Invalid DSF file: missing DSD header: %s\n", file);
    err = -1;
    goto out;
  }

 out:
  buffer_free(&buf);

  if (err) return err;

  return 0;
}
