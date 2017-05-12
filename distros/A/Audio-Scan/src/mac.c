#include "mac.h"

static int
get_macfileinfo(PerlIO *infile, char *file, HV *info)
{
  Buffer header;
  char *bptr;
  int32_t ret = 0;
  int32_t header_end;

  mac_streaminfo *si;
  Newz(0, si, sizeof(mac_streaminfo), mac_streaminfo);

  /*
    There are two possible variations here.
    1.  There's an ID3V2 tag present at the beginning of the file
    2.  There's an APE tag present at the beginning of the file
        (deprecated, but still possible)
    For each type of tag, check for existence and then skip it before
    looking for the MPC header
  */
  if ((header_end = skip_id3v2(infile)) < 0) {
    PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't skip ID3v2]: %s\n", file);
    Safefree(si);
    return -1;
  }

  // seek to first byte of MAC data
  if (PerlIO_seek(infile, header_end, SEEK_SET) < 0) {
    PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't seek to offset %d]: %s\n", header_end, file);
    Safefree(si);
    return -1;
  }

  // Offset + MAC. Does this need the space as well, to be +4 ?
  si->audio_start_offset = PerlIO_tell(infile) + 3;

  // Skip the APETAGEX if it exists.
  buffer_init(&header, APE_HEADER_LEN);

  if (!_check_buf(infile, &header, APE_HEADER_LEN, APE_HEADER_LEN)) {
    PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't read tag header]: %s\n", file);
    goto out;
  }

  bptr = buffer_ptr(&header);

  if (memcmp(bptr, "APETAGEX", 8) == 0) {
    // Skip the ape tag structure
    // XXXX - need to test this code path.
    buffer_get_int_le(&header);
    PerlIO_seek(infile, buffer_get_int_le(&header), SEEK_CUR);

  } else {
    // set the pointer back to original location
    PerlIO_seek(infile, -APE_HEADER_LEN, SEEK_CUR);
  }

  buffer_clear(&header);

  if (!_check_buf(infile, &header, 32, 32)) {
    PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't read stream header]: %s\n", file);
    goto out;
  }

  bptr = buffer_ptr(&header);

  if (memcmp(bptr, "MAC ", 4) != 0) {
    PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't couldn't find stream header]: %s\n", file);
    goto out;
  }

  buffer_consume(&header, 4);
  si->version = buffer_get_short_le(&header);

  if (si->version < 3980) {
    uint16_t compression_id = buffer_get_short_le(&header);
    if (compression_id % 1000) {
      si->compression = "";
    }
    else {
      si->compression = mac_profile_names[ compression_id / 1000 ];
    }

    if (!_check_buf(infile, &header, MAC_397_HEADER_LEN, MAC_397_HEADER_LEN)) {
      PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't read < 3.98 stream header]: %s\n", file);
      goto out;
    }

    buffer_consume(&header, 2); // flags

    si->channels = buffer_get_short_le(&header);

    si->sample_rate = buffer_get_int_le(&header);

    buffer_consume(&header, 4); // header size
    buffer_consume(&header, 4); // terminating data bytes

    si->total_frames      = buffer_get_int_le(&header);
    si->final_frame       = buffer_get_int_le(&header);
    si->blocks_per_frame  = si->version >= 3950 ? (73728 * 4) : 73728;

  } else {
    unsigned char md5[16];
    uint16_t profile;

    if (!_check_buf(infile, &header, MAC_398_HEADER_LEN, MAC_398_HEADER_LEN)) {
      PerlIO_printf(PerlIO_stderr(), "MAC: [Couldn't read > 3.98 stream header]: %s\n", file);
      goto out;
    }

    buffer_consume(&header, 2);

    // unused.
    buffer_get_int_le(&header); // desc bytes
    buffer_get_int_le(&header); // header bytes
    buffer_get_int_le(&header); // seek table bytes
    buffer_get_int_le(&header); // header data bytes
    buffer_get_int_le(&header); // ape frame data bytes
    buffer_get_int_le(&header); // ape frame data bytes high
    buffer_get_int_le(&header); // terminating data bytes
    buffer_get(&header, &md5, sizeof(md5));

    // Header block
    profile = buffer_get_short_le(&header);
    if (profile % 1000) {
      si->compression = "";
    }
    else {
      si->compression = mac_profile_names[ profile / 1000 ];
    }

    buffer_get_short_le(&header); // flags

    si->blocks_per_frame  = buffer_get_int_le(&header);
    si->final_frame       = buffer_get_int_le(&header);
    si->total_frames      = buffer_get_int_le(&header);
    si->bits              = buffer_get_short_le(&header);
    si->channels          = buffer_get_short_le(&header);
    si->sample_rate       = buffer_get_int_le(&header);
  }

  si->file_size = _file_size(infile);

  if (si->sample_rate) {
    double total_samples = (double)(((si->blocks_per_frame * (si->total_frames - 1)) + si->final_frame));
    uint32_t total_ms = (total_samples * 1000) / si->sample_rate;

    my_hv_store(info, "samplerate", newSViv(si->sample_rate));
    my_hv_store(info, "channels", newSViv(si->channels));
    my_hv_store(info, "song_length_ms", newSVuv(total_ms));
    my_hv_store(info, "bitrate", newSVuv( _bitrate(si->file_size - si->audio_start_offset, total_ms) ));

    my_hv_store(info, "file_size", newSVnv(si->file_size));
    my_hv_store(info, "audio_offset", newSVuv(si->audio_start_offset));
    my_hv_store(info, "audio_size", newSVuv(si->file_size - si->audio_start_offset));
    my_hv_store(info, "compression", newSVpv(si->compression, 0));
    my_hv_store(info, "version", newSVpvf( "%0.2f", si->version * 1.0 / 1000 ) );
  }

out:
  buffer_free(&header);
  Safefree(si);

  return ret;
}
