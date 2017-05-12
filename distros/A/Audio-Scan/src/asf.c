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
  TODO:
  These will be added when I see a real file that uses them.

  Header objects:

  Marker (3.7)
  Bitrate Mutual Exclusion (3.8)
  Content Branding (3.13)

  Header Extension objects:

  Group Mutual Exclusion (4.3)
  Stream Prioritization (4.4)
  Bandwidth Sharing (4.5)
  Media Object Index Parameters (4.10)
  Timecode Index Parameters (4.11)
  Advanced Content Encryption (4.13)

  Index objects:

  Media Object Index (6.3)
  Timecode Index (6.4)
*/

#include "asf.h"

static void
print_guid(GUID guid)
{
  PerlIO_printf(PerlIO_stderr(),
    "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x ",
    guid.Data1, guid.Data2, guid.Data3,
    guid.Data4[0], guid.Data4[1], guid.Data4[2], guid.Data4[3],
    guid.Data4[4], guid.Data4[5], guid.Data4[6], guid.Data4[7]
  );
}

int
get_asf_metadata(PerlIO *infile, char *file, HV *info, HV *tags)
{
  asfinfo *asf = _asf_parse(infile, file, info, tags, 0);

  Safefree(asf);

  return 0;
}

asfinfo *
_asf_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking)
{
  ASF_Object hdr;
  ASF_Object data;
  ASF_Object tmp;
  asfinfo *asf;

  Newz(0, asf, sizeof(asfinfo), asfinfo);
  Newz(0, asf->buf, sizeof(Buffer), Buffer);
  Newz(0, asf->scratch, sizeof(Buffer), Buffer);

  asf->file_size     = _file_size(infile);
  asf->audio_offset  = 0;
  asf->object_offset = 0;
  asf->infile        = infile;
  asf->file          = file;
  asf->info          = info;
  asf->tags          = tags;
  asf->seeking       = seeking;

  buffer_init(asf->buf, ASF_BLOCK_SIZE);

  if ( !_check_buf(infile, asf->buf, 30, ASF_BLOCK_SIZE) ) {
    goto out;
  }

  buffer_get_guid(asf->buf, &hdr.ID);

  if ( !IsEqualGUID(&hdr.ID, &ASF_Header_Object) ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid ASF header: %s\n", file);
    PerlIO_printf(PerlIO_stderr(), "  Expecting: ");
      print_guid(ASF_Header_Object);
    PerlIO_printf(PerlIO_stderr(), "\n        Got: ");
      print_guid(hdr.ID);
    PerlIO_printf(PerlIO_stderr(), "\n");
    goto out;
  }

  hdr.size        = buffer_get_int64_le(asf->buf);
  hdr.num_objects = buffer_get_int_le(asf->buf);
  hdr.reserved1   = buffer_get_char(asf->buf);
  hdr.reserved2   = buffer_get_char(asf->buf);

  if ( hdr.reserved2 != 0x02 ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid ASF header: %s\n", file);
    goto out;
  }

  asf->object_offset += 30;

  while ( hdr.num_objects-- ) {
    if ( !_check_buf(infile, asf->buf, 24, ASF_BLOCK_SIZE) ) {
      goto out;
    }

    buffer_get_guid(asf->buf, &tmp.ID);
    tmp.size = buffer_get_int64_le(asf->buf);

    if ( !_check_buf(infile, asf->buf, tmp.size - 24, ASF_BLOCK_SIZE) ) {
      goto out;
    }

    asf->object_offset += 24;

    DEBUG_TRACE("object_offset %d\n", asf->object_offset);

    if ( IsEqualGUID(&tmp.ID, &ASF_Content_Description) ) {
      DEBUG_TRACE("Content_Description\n");
      _parse_content_description(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_File_Properties) ) {
      DEBUG_TRACE("File_Properties\n");
      _parse_file_properties(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Stream_Properties) ) {
      DEBUG_TRACE("Stream_Properties\n");
      _parse_stream_properties(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Extended_Content_Description) ) {
      DEBUG_TRACE("Extended_Content_Description\n");
      _parse_extended_content_description(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Codec_List) ) {
      DEBUG_TRACE("Codec_List\n");
      _parse_codec_list(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Stream_Bitrate_Properties) ) {
      DEBUG_TRACE("Stream_Bitrate_Properties\n");
      _parse_stream_bitrate_properties(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Content_Encryption) ) {
      DEBUG_TRACE("Content_Encryption\n");
      _parse_content_encryption(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Extended_Content_Encryption) ) {
      DEBUG_TRACE("Extended_Content_Encryption\n");
      _parse_extended_content_encryption(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Script_Command) ) {
      DEBUG_TRACE("Script_Command\n");
      _parse_script_command(asf);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Digital_Signature) ) {
      DEBUG_TRACE("Skipping Digital_Signature\n");
      buffer_consume(asf->buf, tmp.size - 24);
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Header_Extension) ) {
      DEBUG_TRACE("Header_Extension\n");
      if ( !_parse_header_extension(asf, tmp.size) ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid ASF file: %s (invalid header extension object)\n", file);
        goto out;
      }
    }
    else if ( IsEqualGUID(&tmp.ID, &ASF_Error_Correction) ) {
      DEBUG_TRACE("Skipping Error_Correction\n");
      buffer_consume(asf->buf, tmp.size - 24);
    }
    else {
      // Unhandled GUID
      PerlIO_printf(PerlIO_stderr(), "** Unhandled GUID: ");
      print_guid(tmp.ID);
      PerlIO_printf(PerlIO_stderr(), "size: %llu\n", tmp.size);

      buffer_consume(asf->buf, tmp.size - 24);
    }

    asf->object_offset += tmp.size - 24;
  }

  // We should be at the start of the Data object.
  // Seek past it to find more objects
  if ( !_check_buf(infile, asf->buf, 24, ASF_BLOCK_SIZE) ) {
    goto out;
  }

  buffer_get_guid(asf->buf, &data.ID);

  if ( !IsEqualGUID(&data.ID, &ASF_Data) ) {
    PerlIO_printf(PerlIO_stderr(), "Invalid ASF file: %s (no Data object after Header)\n", file);
    goto out;
  }

  // Store offset to beginning of data (50 goes past the top-level data packet)
  asf->audio_offset = hdr.size + 50;
  my_hv_store( info, "audio_offset", newSVuv(asf->audio_offset) );

  my_hv_store( info, "file_size", newSVuv(asf->file_size) );

  data.size = buffer_get_int64_le(asf->buf);
  asf->audio_size = data.size;

  // Check audio_size is not larger than file
  if (asf->audio_size > asf->file_size - asf->audio_offset) {
    asf->audio_size = asf->file_size - asf->audio_offset;
    DEBUG_TRACE("audio_size too large, fixed to %lld\n", asf->audio_size);
  }
  my_hv_store( info, "audio_size", newSVuv(asf->audio_size) );

  if (seeking) {
    if ( hdr.size + data.size < asf->file_size ) {
      DEBUG_TRACE("Seeking past data: %llu\n", hdr.size + data.size);

      if ( PerlIO_seek(infile, hdr.size + data.size, SEEK_SET) != 0 ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid ASF file: %s (Invalid Data object size)\n", file);
        goto out;
      }

      buffer_clear(asf->buf);

      if ( !_parse_index_objects(asf, asf->file_size - hdr.size - data.size) ) {
        PerlIO_printf(PerlIO_stderr(), "Invalid ASF file: %s (Invalid Index object)\n", file);
        goto out;
      }
    }
  }

out:
  buffer_free(asf->buf);
  Safefree(asf->buf);

  if (asf->scratch->alloc)
    buffer_free(asf->scratch);
  Safefree(asf->scratch);

  return asf;
}

void
_parse_content_description(asfinfo *asf)
{
  int i;
  uint16_t len[5];
  char fields[5][12] = {
    { "Title" },
    { "Author" },
    { "Copyright" },
    { "Description" },
    { "Rating" }
  };

  for (i = 0; i < 5; i++) {
    len[i] = buffer_get_short_le(asf->buf);
  }

  buffer_init_or_clear(asf->scratch, len[0]);

  for (i = 0; i < 5; i++) {
    SV *value;

    if ( len[i] ) {
      buffer_clear(asf->scratch);
      buffer_get_utf16_as_utf8(asf->buf, asf->scratch, len[i], UTF16_BYTEORDER_LE);
      value = newSVpv( buffer_ptr(asf->scratch), 0 );
      sv_utf8_decode(value);

      DEBUG_TRACE("  %s / %s\n", fields[i], SvPVX(value));

      _store_tag( asf->tags, newSVpv(fields[i], 0), value );
    }
  }
}

void
_parse_extended_content_description(asfinfo *asf)
{
  uint16_t count = buffer_get_short_le(asf->buf);
  uint32_t picture_offset = 0;

  buffer_init_or_clear(asf->scratch, 32);

  while ( count-- ) {
    uint16_t name_len;
    uint16_t data_type;
    uint16_t value_len;
    SV *key = NULL;
    SV *value = NULL;

    name_len = buffer_get_short_le(asf->buf);

    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, name_len, UTF16_BYTEORDER_LE);
    key = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(key);

    data_type = buffer_get_short_le(asf->buf);
    value_len = buffer_get_short_le(asf->buf);

    picture_offset += 2 + name_len + 4;

    if (data_type == TYPE_UNICODE) {
      buffer_clear(asf->scratch);
      buffer_get_utf16_as_utf8(asf->buf, asf->scratch, value_len, UTF16_BYTEORDER_LE);
      value = newSVpv( buffer_ptr(asf->scratch), 0 );
      sv_utf8_decode(value);
    }
    else if (data_type == TYPE_BYTE) {
      // handle picture data, interestingly it is compatible with the ID3v2 APIC frame
      if ( !strcmp( SvPVX(key), "WM/Picture" ) ) {
        value = _parse_picture(asf, picture_offset);
      }
      else {
        value = newSVpvn( buffer_ptr(asf->buf), value_len );
        buffer_consume(asf->buf, value_len);
      }
    }
    else if (data_type == TYPE_BOOL) {
      value = newSViv( buffer_get_int_le(asf->buf) );
    }
    else if (data_type == TYPE_DWORD) {
      value = newSViv( buffer_get_int_le(asf->buf) );
    }
    else if (data_type == TYPE_QWORD) {
      value = newSViv( buffer_get_int64_le(asf->buf) );
    }
    else if (data_type == TYPE_WORD) {
      value = newSViv( buffer_get_short_le(asf->buf) );
    }
    else {
      PerlIO_printf(PerlIO_stderr(), "Unknown extended content description data type %d\n", data_type);
      buffer_consume(asf->buf, value_len);
    }

    picture_offset += value_len;

    if (value != NULL) {
#ifdef AUDIO_SCAN_DEBUG
      if ( data_type == 0 ) {
        DEBUG_TRACE("  %s / type %d / %s\n", SvPVX(key), data_type, SvPVX(value));
      }
      else if ( data_type > 1 ) {
        DEBUG_TRACE("  %s / type %d / %d\n", SvPVX(key), data_type, (int)SvIV(value));
      }
      else {
        DEBUG_TRACE("  %s / type %d / <binary>\n", SvPVX(key), data_type);
      }
#endif

      _store_tag( asf->tags, key, value );
    }
  }
}

void
_parse_file_properties(asfinfo *asf)
{
  GUID file_id;
  uint64_t file_size;
  uint64_t creation_date;
  uint64_t data_packets;
  uint64_t play_duration;
  uint64_t send_duration;
  uint64_t preroll;
  uint32_t flags;
  uint32_t min_packet_size;
  uint32_t max_packet_size;
  uint32_t max_bitrate;
  uint8_t broadcast;
  uint8_t seekable;

  buffer_get_guid(asf->buf, &file_id);
  my_hv_store(
    asf->info, "file_id", newSVpvf( "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
      file_id.Data1, file_id.Data2, file_id.Data3,
      file_id.Data4[0], file_id.Data4[1], file_id.Data4[2], file_id.Data4[3],
      file_id.Data4[4], file_id.Data4[5], file_id.Data4[6], file_id.Data4[7]
    )
  );

  file_size       = buffer_get_int64_le(asf->buf);
  creation_date   = buffer_get_int64_le(asf->buf);
  data_packets    = buffer_get_int64_le(asf->buf);
  play_duration   = buffer_get_int64_le(asf->buf);
  send_duration   = buffer_get_int64_le(asf->buf);
  preroll         = buffer_get_int64_le(asf->buf);
  flags           = buffer_get_int_le(asf->buf);
  min_packet_size = buffer_get_int_le(asf->buf);
  max_packet_size = buffer_get_int_le(asf->buf);
  max_bitrate     = buffer_get_int_le(asf->buf);

  broadcast = flags & 0x01 ? 1 : 0;
  seekable  = flags & 0x02 ? 1 : 0;

  if ( !broadcast ) {
    creation_date = (creation_date - 116444736000000000ULL) / 10000000;
    play_duration /= 10000;
    send_duration /= 10000;

    // Don't overwrite the actual file size we found from stat
    //my_hv_store( info, "file_size", newSViv(file_size) );

    my_hv_store( asf->info, "creation_date", newSViv(creation_date) );
    my_hv_store( asf->info, "data_packets", newSViv(data_packets) );
    my_hv_store( asf->info, "play_duration_ms", newSViv(play_duration) );
    my_hv_store( asf->info, "send_duration_ms", newSViv(send_duration) );

    // Calculate actual song duration
    my_hv_store( asf->info, "song_length_ms", newSViv( play_duration - preroll ) );
  }

  my_hv_store( asf->info, "preroll", newSViv(preroll) );
  my_hv_store( asf->info, "broadcast", newSViv(broadcast) );
  my_hv_store( asf->info, "seekable", newSViv(seekable) );
  my_hv_store( asf->info, "min_packet_size", newSViv(min_packet_size) );
  my_hv_store( asf->info, "max_packet_size", newSViv(max_packet_size) );
  my_hv_store( asf->info, "max_bitrate", newSViv(max_bitrate) );

  // DLNA, need to store max_bitrate for later
  asf->max_bitrate = max_bitrate;
}

void
_parse_stream_properties(asfinfo *asf)
{
  GUID stream_type;
  GUID ec_type;
  uint64_t time_offset;
  uint32_t type_data_len;
  uint32_t ec_data_len;
  uint16_t flags;
  uint16_t stream_number;
  Buffer type_data_buf;

  buffer_get_guid(asf->buf, &stream_type);
  buffer_get_guid(asf->buf, &ec_type);
  time_offset = buffer_get_int64_le(asf->buf);
  type_data_len = buffer_get_int_le(asf->buf);
  ec_data_len   = buffer_get_int_le(asf->buf);
  flags         = buffer_get_short_le(asf->buf);
  stream_number = flags & 0x007f;

  // skip reserved bytes
  buffer_consume(asf->buf, 4);

  // type-specific data
  buffer_init(&type_data_buf, type_data_len);
  buffer_append(&type_data_buf, buffer_ptr(asf->buf), type_data_len);
  buffer_consume(asf->buf, type_data_len);

  // skip error-correction data
  buffer_consume(asf->buf, ec_data_len);

  if ( IsEqualGUID(&stream_type, &ASF_Audio_Media) ) {
    uint8_t is_wma = 0;
    uint16_t codec_id, channels;
    uint32_t samplerate;

    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_Audio_Media", 0) );

    // Parse WAVEFORMATEX data
    codec_id = buffer_get_short_le(&type_data_buf);
    switch (codec_id) {
      case 0x000a:
        is_wma = 1;
        break;

      case 0x0161:
        is_wma = 1;
        asf->valid_profiles |= IS_VALID_WMA_BASE | IS_VALID_WMA_FULL;
        break;

      case 0x0162:
        is_wma = 1;
        asf->valid_profiles |= IS_VALID_WMA_PRO;
        break;

      case 0x0163:
        is_wma = 1;
        asf->valid_profiles |= IS_VALID_WMA_LSL;
        break;
    }

    _store_stream_info( stream_number, asf->info, newSVpv("codec_id", 0), newSViv(codec_id) );

    channels = buffer_get_short_le(&type_data_buf);
    _store_stream_info( stream_number, asf->info, newSVpv("channels", 0), newSViv(channels) );

    samplerate = buffer_get_int_le(&type_data_buf);
    _store_stream_info( stream_number, asf->info, newSVpv("samplerate", 0), newSViv(samplerate) );

    // Determine DLNA profile
    if (channels > 2) {
      asf->valid_profiles &= ~IS_VALID_WMA_BASE;
      asf->valid_profiles &= ~IS_VALID_WMA_FULL;

      if (codec_id == 0x0163) {
        asf->valid_profiles &= ~IS_VALID_WMA_LSL;
        asf->valid_profiles |= IS_VALID_WMA_LSL_MULT5;
      }
    }

    if (samplerate > 48000) {
      asf->valid_profiles &= ~IS_VALID_WMA_BASE;
      asf->valid_profiles &= ~IS_VALID_WMA_FULL;

      if (samplerate > 96000) {
        asf->valid_profiles &= ~IS_VALID_WMA_PRO;
        asf->valid_profiles &= ~IS_VALID_WMA_LSL; // XXX check N1/N2 defs
        asf->valid_profiles &= ~IS_VALID_WMA_LSL_MULT5;
      }
    }

    if (asf->max_bitrate > 192999) {
      asf->valid_profiles &= ~IS_VALID_WMA_BASE;

      if (asf->max_bitrate > 384999) {
        asf->valid_profiles &= ~IS_VALID_WMA_FULL;

        if (asf->max_bitrate > 1499999) {
          asf->valid_profiles &= ~IS_VALID_WMA_PRO;
          asf->valid_profiles &= ~IS_VALID_WMA_LSL; // XXX check N1/N2 defs
          asf->valid_profiles &= ~IS_VALID_WMA_LSL_MULT5;
        }
      }
    }

    if (asf->valid_profiles & IS_VALID_WMA_BASE)
      my_hv_store( asf->info, "dlna_profile", newSVpvn("WMABASE", 7) );
    else if (asf->valid_profiles & IS_VALID_WMA_FULL)
      my_hv_store( asf->info, "dlna_profile", newSVpvn("WMAFULL", 7) );
    else if (asf->valid_profiles & IS_VALID_WMA_PRO)
      my_hv_store( asf->info, "dlna_profile", newSVpvn("WMAPRO", 6) );
    else if (asf->valid_profiles & IS_VALID_WMA_LSL)
      my_hv_store( asf->info, "dlna_profile", newSVpvn("WMALSL", 6) );
    else if (asf->valid_profiles & IS_VALID_WMA_LSL_MULT5)
      my_hv_store( asf->info, "dlna_profile", newSVpvn("WMALSL_MULT5", 12) );

    _store_stream_info( stream_number, asf->info, newSVpv("avg_bytes_per_sec", 0), newSViv( buffer_get_int_le(&type_data_buf) ) );
    _store_stream_info( stream_number, asf->info, newSVpv("block_alignment", 0), newSViv( buffer_get_short_le(&type_data_buf) ) );
    _store_stream_info( stream_number, asf->info, newSVpv("bits_per_sample", 0), newSViv( buffer_get_short_le(&type_data_buf) ) );

    // Read WMA-specific data
    if (is_wma) {
      buffer_consume(&type_data_buf, 2);
      _store_stream_info( stream_number, asf->info, newSVpv("samples_per_block", 0), newSViv( buffer_get_int_le(&type_data_buf) ) );
      _store_stream_info( stream_number, asf->info, newSVpv("encode_options", 0), newSViv( buffer_get_short_le(&type_data_buf) ) );
      _store_stream_info( stream_number, asf->info, newSVpv("super_block_align", 0), newSViv( buffer_get_int_le(&type_data_buf) ) );
    }
  }
  else if ( IsEqualGUID(&stream_type, &ASF_Video_Media) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_Video_Media", 0) );

    DEBUG_TRACE("type_data_len: %d\n", type_data_len);

    // Read video-specific data
    _store_stream_info( stream_number, asf->info, newSVpv("width", 0), newSVuv( buffer_get_int_le(&type_data_buf) ) );
    _store_stream_info( stream_number, asf->info, newSVpv("height", 0), newSVuv( buffer_get_int_le(&type_data_buf) ) );

    // Skip format size, width, height, reserved
    buffer_consume(&type_data_buf, 17);

    _store_stream_info( stream_number, asf->info, newSVpv("bpp", 0), newSVuv( buffer_get_short_le(&type_data_buf) ) );

    _store_stream_info( stream_number, asf->info, newSVpv("compression_id", 0), newSVpv( buffer_ptr(&type_data_buf), 4 ) );

    // Rest of the data does not seem to apply to video
  }
  else if ( IsEqualGUID(&stream_type, &ASF_Command_Media) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_Command_Media", 0) );
  }
  else if ( IsEqualGUID(&stream_type, &ASF_JFIF_Media) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_JFIF_Media", 0) );

    // type-specific data
    _store_stream_info( stream_number, asf->info, newSVpv("width", 0), newSVuv( buffer_get_int_le(&type_data_buf) ) );
    _store_stream_info( stream_number, asf->info, newSVpv("height", 0), newSVuv( buffer_get_int_le(&type_data_buf) ) );
  }
  else if ( IsEqualGUID(&stream_type, &ASF_Degradable_JPEG_Media) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_Degradable_JPEG_Media", 0) );

    // XXX: type-specific data (section 9.4.2)
  }
  else if ( IsEqualGUID(&stream_type, &ASF_File_Transfer_Media) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_File_Transfer_Media", 0) );

    // XXX: type-specific data (section 9.5)
  }
  else if ( IsEqualGUID(&stream_type, &ASF_Binary_Media) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("stream_type", 0), newSVpv("ASF_Binary_Media", 0) );

    // XXX: type-specific data (section 9.5)
  }

  if ( IsEqualGUID(&ec_type, &ASF_No_Error_Correction) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("error_correction_type", 0), newSVpv("ASF_No_Error_Correction", 0) );
  }
  else if ( IsEqualGUID(&ec_type, &ASF_Audio_Spread) ) {
    _store_stream_info( stream_number, asf->info, newSVpv("error_correction_type", 0), newSVpv("ASF_Audio_Spread", 0) );
  }

  _store_stream_info( stream_number, asf->info, newSVpv("time_offset", 0), newSViv(time_offset) );
  _store_stream_info( stream_number, asf->info, newSVpv("encrypted", 0), newSVuv( flags & 0x8000 ? 1 : 0 ) );

  buffer_free(&type_data_buf);
}

int
_parse_header_extension(asfinfo *asf, uint64_t len)
{
  int ext_size;
  GUID hdr;
  uint64_t hdr_size;
  uint32_t tmp_offset = asf->object_offset;

  // Skip reserved fields
  buffer_consume(asf->buf, 18);

  ext_size = buffer_get_int_le(asf->buf);

  // Sanity check ext size
  // Must be 0 or 24+, and 46 less than header extension object size
  if (ext_size > 0) {
    if (ext_size < 24) {
      return 0;
    }
    if (ext_size != len - 46) {
      return 0;
    }
  }

  DEBUG_TRACE("  size: %d\n", ext_size);

  // Header Extension is always 46 bytes, and we've already counted 24 of it
  asf->object_offset += 46 - 24;

  while (ext_size > 0) {
    buffer_get_guid(asf->buf, &hdr);
    hdr_size = buffer_get_int64_le(asf->buf);
    ext_size -= hdr_size;

    asf->object_offset += 24;

    DEBUG_TRACE("  object_offset %d\n", asf->object_offset);

    if ( IsEqualGUID(&hdr, &ASF_Metadata) ) {
      DEBUG_TRACE("  Metadata\n");
      _parse_metadata(asf);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Extended_Stream_Properties) ) {
      DEBUG_TRACE("  Extended_Stream_Properties\n");
      _parse_extended_stream_properties(asf, hdr_size);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Language_List) ) {
      DEBUG_TRACE("  Language_List\n");
      _parse_language_list(asf);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Advanced_Mutual_Exclusion) ) {
      DEBUG_TRACE("  Advanced_Mutual_Exclusion\n");
      _parse_advanced_mutual_exclusion(asf);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Metadata_Library) ) {
      DEBUG_TRACE("  Metadata_Library\n");
      _parse_metadata_library(asf);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Index_Parameters) ) {
      DEBUG_TRACE("  Index_Parameters\n");
      _parse_index_parameters(asf);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Compatibility) ) {
      // reserved for future use, just ignore
      DEBUG_TRACE("  Skipping Compatibility\n");
      buffer_consume(asf->buf, 2);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Padding) ) {
      // skip padding
      DEBUG_TRACE("  Skipping Padding\n");
      buffer_consume(asf->buf, hdr_size - 24);
    }
    else if ( IsEqualGUID(&hdr, &ASF_Index_Placeholder) ) {
      // skip undocumented placeholder
      DEBUG_TRACE("  Skipping Index_Placeholder\n");
      buffer_consume(asf->buf, hdr_size - 24);
    }
    else {
      // Unhandled
      PerlIO_printf(PerlIO_stderr(), "  ** Unhandled extended header: ");
      print_guid(hdr);
      PerlIO_printf(PerlIO_stderr(), "size: %llu\n", hdr_size);

      buffer_consume(asf->buf, hdr_size - 24);
    }

    asf->object_offset += hdr_size - 24;
  }

  // Put back the original offset, or calcs will be wrong in _asf_parse
  asf->object_offset = tmp_offset;

  return 1;
}

void
_parse_metadata(asfinfo *asf)
{
  uint16_t count = buffer_get_short_le(asf->buf);

  buffer_init_or_clear(asf->scratch, 32);

  while ( count-- ) {
    uint16_t stream_number;
    uint16_t name_len;
    uint16_t data_type;
    uint32_t data_len;
    SV *key = NULL;
    SV *value = NULL;

    // Skip reserved
    buffer_consume(asf->buf, 2);

    stream_number = buffer_get_short_le(asf->buf);
    name_len      = buffer_get_short_le(asf->buf);
    data_type     = buffer_get_short_le(asf->buf);
    data_len      = buffer_get_int_le(asf->buf);

    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, name_len, UTF16_BYTEORDER_LE);
    key = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(key);

    if (data_type == TYPE_UNICODE) {
      buffer_clear(asf->scratch);
      buffer_get_utf16_as_utf8(asf->buf, asf->scratch, data_len, UTF16_BYTEORDER_LE);
      value = newSVpv( buffer_ptr(asf->scratch), 0 );
      sv_utf8_decode(value);
    }
    else if (data_type == TYPE_BYTE) {
      value = newSVpvn( buffer_ptr(asf->buf), data_len );
      buffer_consume(asf->buf, data_len);
    }
    else if (data_type == TYPE_BOOL || data_type == TYPE_WORD) {
      value = newSViv( buffer_get_short_le(asf->buf) );
    }
    else if (data_type == TYPE_DWORD) {
      value = newSViv( buffer_get_int_le(asf->buf) );
    }
    else if (data_type == TYPE_QWORD) {
      value = newSViv( buffer_get_int64_le(asf->buf) );
    }
    else {
      DEBUG_TRACE("Unknown metadata data type %d\n", data_type);
      buffer_consume(asf->buf, data_len);
    }

    if (value != NULL) {
#ifdef AUDIO_SCAN_DEBUG
      if ( data_type == 0 ) {
        DEBUG_TRACE("    %s / type %d / stream_number %d / %s\n", SvPVX(key), data_type, stream_number, SvPVX(value));
      }
      else if ( data_type > 1 ) {
        DEBUG_TRACE("    %s / type %d / stream_number %d / %d\n", SvPVX(key), data_type, stream_number, (int)SvIV(value));
      }
      else {
        DEBUG_TRACE("    %s / type %d / stream_number %d / <binary>\n", SvPVX(key), stream_number, data_type);
      }
#endif

      // If stream_number is available, store the data with the stream info
      if (stream_number > 0) {
        _store_stream_info( stream_number, asf->info, key, value );
      }
      else {
        my_hv_store_ent( asf->info, key, value );
        SvREFCNT_dec(key);
      }
    }
  }
}

void
_parse_extended_stream_properties(asfinfo *asf, uint64_t len)
{
  uint64_t start_time          = buffer_get_int64_le(asf->buf);
  uint64_t end_time            = buffer_get_int64_le(asf->buf);
  uint32_t bitrate             = buffer_get_int_le(asf->buf);
  uint32_t buffer_size         = buffer_get_int_le(asf->buf);
  uint32_t buffer_fullness     = buffer_get_int_le(asf->buf);
  uint32_t alt_bitrate         = buffer_get_int_le(asf->buf);
  uint32_t alt_buffer_size     = buffer_get_int_le(asf->buf);
  uint32_t alt_buffer_fullness = buffer_get_int_le(asf->buf);
  uint32_t max_object_size     = buffer_get_int_le(asf->buf);
  uint32_t flags               = buffer_get_int_le(asf->buf);
  uint16_t stream_number       = buffer_get_short_le(asf->buf);
  uint16_t lang_id             = buffer_get_short_le(asf->buf);
  uint64_t avg_time_per_frame  = buffer_get_int64_le(asf->buf);
  uint16_t stream_name_count   = buffer_get_short_le(asf->buf);
  uint16_t payload_ext_count   = buffer_get_short_le(asf->buf);

  len -= 88;

  if (start_time > 0) {
    _store_stream_info( stream_number, asf->info, newSVpv("start_time", 0), newSViv(start_time) );
  }

  if (end_time > 0) {
    _store_stream_info( stream_number, asf->info, newSVpv("end_time", 0), newSViv(end_time) );
  }

  _store_stream_info( stream_number, asf->info, newSVpv("bitrate", 0), newSViv(bitrate) );
  _store_stream_info( stream_number, asf->info, newSVpv("buffer_size", 0), newSViv(buffer_size) );
  _store_stream_info( stream_number, asf->info, newSVpv("buffer_fullness", 0), newSViv(buffer_fullness) );
  _store_stream_info( stream_number, asf->info, newSVpv("alt_bitrate", 0), newSViv(alt_bitrate) );
  _store_stream_info( stream_number, asf->info, newSVpv("alt_buffer_size", 0), newSViv(alt_buffer_size) );
  _store_stream_info( stream_number, asf->info, newSVpv("alt_buffer_fullness", 0), newSViv(alt_buffer_fullness) );
  _store_stream_info( stream_number, asf->info, newSVpv("alt_buffer_size", 0), newSViv(alt_buffer_size) );
  _store_stream_info( stream_number, asf->info, newSVpv("max_object_size", 0), newSViv(max_object_size) );

  if ( flags & 0x01 )
    _store_stream_info( stream_number, asf->info, newSVpv("flag_reliable", 0), newSViv(1) );

  if ( flags & 0x02 )
    _store_stream_info( stream_number, asf->info, newSVpv("flag_seekable", 0), newSViv(1) );

  if ( flags & 0x04 )
    _store_stream_info( stream_number, asf->info, newSVpv("flag_no_cleanpoint", 0), newSViv(1) );

  if ( flags & 0x08 )
    _store_stream_info( stream_number, asf->info, newSVpv("flag_resend_cleanpoints", 0), newSViv(1) );

  _store_stream_info( stream_number, asf->info, newSVpv("language_index", 0), newSViv(lang_id) );

  if (avg_time_per_frame > 0) {
    // XXX: can't get this to divide properly (?!)
    //_store_stream_info( stream_number, asf->info, newSVpv("avg_time_per_frame", 0), newSVuv(avg_time_per_frame / 10000) );
  }

  while ( stream_name_count-- ) {
    uint16_t stream_name_len;

    // stream_name_lang_id
    buffer_consume(asf->buf, 2);
    stream_name_len = buffer_get_short_le(asf->buf);

    DEBUG_TRACE("stream_name_len: %d\n", stream_name_len);

    // XXX, store this?
    buffer_consume(asf->buf, stream_name_len);

    len -= 4 + stream_name_len;
  }

  while ( payload_ext_count-- ) {
    // Skip
    uint32_t payload_len;

    buffer_consume(asf->buf, 18);
    payload_len = buffer_get_int_le(asf->buf);
    buffer_consume(asf->buf, payload_len);

    len -= 22 + payload_len;
  }

  if (len) {
    // Anything left over means we have an embedded Stream Properties Object
    DEBUG_TRACE("      embedded Stream_Properties, size %llu\n", len);
    buffer_consume(asf->buf, 24);
    _parse_stream_properties(asf);
  }
}

void
_parse_language_list(asfinfo *asf)
{
  AV *list = newAV();
  uint16_t count = buffer_get_short_le(asf->buf);

  buffer_init_or_clear(asf->scratch, 32);

  while ( count-- ) {
    SV *value;

    uint8_t len = buffer_get_char(asf->buf);
    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, len, UTF16_BYTEORDER_LE);
    value = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(value);

    av_push( list, value );
  }

  my_hv_store( asf->info, "language_list", newRV_noinc( (SV*)list ) );
}

void
_parse_advanced_mutual_exclusion(asfinfo *asf)
{
  GUID mutex_type;
  uint16_t count;
  AV *mutex_list;
  HV *mutex_hv = newHV();
  SV *mutex_type_sv;
  AV *mutex_streams = newAV();

  buffer_get_guid(asf->buf, &mutex_type);
  count = buffer_get_short_le(asf->buf);

  if ( IsEqualGUID(&mutex_type, &ASF_Mutex_Language) ) {
    mutex_type_sv = newSVpv( "ASF_Mutex_Language", 0 );
  }
  else if ( IsEqualGUID(&mutex_type, &ASF_Mutex_Bitrate) ) {
    mutex_type_sv = newSVpv( "ASF_Mutex_Bitrate", 0 );
  }
  else {
    mutex_type_sv = newSVpv( "ASF_Mutex_Unknown", 0 );
  }

  while ( count-- ) {
    av_push( mutex_streams, newSViv( buffer_get_short_le(asf->buf) ) );
  }

  my_hv_store_ent( mutex_hv, mutex_type_sv, newRV_noinc( (SV *)mutex_streams ) );
  SvREFCNT_dec(mutex_type_sv);

  if ( !my_hv_exists( asf->info, "mutex_list" ) ) {
    mutex_list = newAV();
    av_push( mutex_list, newRV_noinc( (SV *)mutex_hv ) );
    my_hv_store( asf->info, "mutex_list", newRV_noinc( (SV *)mutex_list ) );
  }
  else {
    SV **entry = my_hv_fetch( asf->info, "mutex_list" );
    if (entry != NULL) {
      mutex_list = (AV *)SvRV(*entry);
    }
    else {
      return;
    }

    av_push( mutex_list, newRV_noinc( (SV *)mutex_hv ) );
  }
}

void
_parse_codec_list(asfinfo *asf)
{
  uint32_t count;
  AV *list = newAV();

  buffer_init_or_clear(asf->scratch, 32);

  // Skip reserved
  buffer_consume(asf->buf, 16);

  count = buffer_get_int_le(asf->buf);

  while ( count-- ) {
    HV *codec_info = newHV();
    uint16_t name_len;
    uint16_t desc_len;
    SV *name = NULL;
    SV *desc = NULL;

    uint16_t codec_type = buffer_get_short_le(asf->buf);

    switch (codec_type) {
      case 0x0001:
        my_hv_store( codec_info, "type", newSVpv("Video", 0) );
        break;
      case 0x0002:
        my_hv_store( codec_info, "type", newSVpv("Audio", 0) );
        break;
      default:
        my_hv_store( codec_info, "type", newSVpv("Unknown", 0) );
    }

    // Unlike other objects, these lengths are the
    // "number of Unicode chars", not bytes, so we need to double it
    name_len = buffer_get_short_le(asf->buf) * 2;
    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, name_len, UTF16_BYTEORDER_LE);
    name = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(name);
    my_hv_store( codec_info, "name", name );

    // Set a 'lossless' flag in info if Lossless codec is used
    if ( strstr( buffer_ptr(asf->scratch), "Lossless" ) ) {
      my_hv_store( asf->info, "lossless", newSVuv(1) );
    }

    desc_len = buffer_get_short_le(asf->buf) * 2;
    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, desc_len, UTF16_BYTEORDER_LE);
    desc = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(desc);
    my_hv_store( codec_info, "description", desc );

    // Skip info
    buffer_consume(asf->buf, buffer_get_short_le(asf->buf));

    av_push( list, newRV_noinc( (SV *)codec_info ) );
  }

  my_hv_store( asf->info, "codec_list", newRV_noinc( (SV *)list ) );
}

void
_parse_stream_bitrate_properties(asfinfo *asf)
{
  uint16_t count = buffer_get_short_le(asf->buf);

  while ( count-- ) {
    uint16_t stream_number = buffer_get_short_le(asf->buf) & 0x007f;

    _store_stream_info( stream_number, asf->info, newSVpv("avg_bitrate", 0), newSViv( buffer_get_int_le(asf->buf) ) );
  }
}

void
_parse_metadata_library(asfinfo *asf)
{
  uint16_t count = buffer_get_short_le(asf->buf);
  uint32_t picture_offset = 0;

  buffer_init_or_clear(asf->scratch, 32);

  while ( count-- ) {
    SV *key = NULL;
    SV *value = NULL;
    uint16_t stream_number, name_len, data_type;
    uint32_t data_len;

#ifdef AUDIO_SCAN_DEBUG
    uint16_t lang_index    = buffer_get_short_le(asf->buf);
#else
    buffer_consume(asf->buf, 2);
#endif

    stream_number = buffer_get_short_le(asf->buf);
    name_len      = buffer_get_short_le(asf->buf);
    data_type     = buffer_get_short_le(asf->buf);
    data_len      = buffer_get_int_le(asf->buf);

    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, name_len, UTF16_BYTEORDER_LE);
    key = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(key);

    picture_offset += 12 + name_len;

    if (data_type == TYPE_UNICODE) {
      buffer_clear(asf->scratch);
      buffer_get_utf16_as_utf8(asf->buf, asf->scratch, data_len, UTF16_BYTEORDER_LE);
      value = newSVpv( buffer_ptr(asf->scratch), 0 );
      sv_utf8_decode(value);
    }
    else if (data_type == TYPE_BYTE) {
      // handle picture data
      if ( !strcmp( SvPVX(key), "WM/Picture" ) ) {
        value = _parse_picture(asf, picture_offset);
      }
      else {
        value = newSVpvn( buffer_ptr(asf->buf), data_len );
        buffer_consume(asf->buf, data_len);
      }
    }
    else if (data_type == TYPE_BOOL || data_type == TYPE_WORD) {
      value = newSViv( buffer_get_short_le(asf->buf) );
    }
    else if (data_type == TYPE_DWORD) {
      value = newSViv( buffer_get_int_le(asf->buf) );
    }
    else if (data_type == TYPE_QWORD) {
      value = newSViv( buffer_get_int64_le(asf->buf) );
    }
    else if (data_type == TYPE_GUID) {
      GUID g;
      buffer_get_guid(asf->buf, &g);
      value = newSVpvf(
        "%08x-%04x-%04x-%02x%02x-%02x%02x%02x%02x%02x%02x",
        g.Data1, g.Data2, g.Data3,
        g.Data4[0], g.Data4[1], g.Data4[2], g.Data4[3],
        g.Data4[4], g.Data4[5], g.Data4[6], g.Data4[7]
      );
    }
    else {
      PerlIO_printf(PerlIO_stderr(), "Unknown metadata library data type %d\n", data_type);
      buffer_consume(asf->buf, data_len);
    }

    picture_offset += data_len;

    if (value != NULL) {
#ifdef AUDIO_SCAN_DEBUG
      if ( data_type == 0 || data_type == 6 ) {
        DEBUG_TRACE("    %s / type %d / lang_index %d / stream_number %d / %s\n", SvPVX(key), data_type, lang_index, stream_number, SvPVX(value));
      }
      else if ( data_type > 1 ) {
        DEBUG_TRACE("    %s / type %d / lang_index %d / stream_number %d / %d\n", SvPVX(key), data_type, lang_index, stream_number, (int)SvIV(value));
      }
      else {
        DEBUG_TRACE("    %s / type %d / lang_index %d / stream_number %d / <binary>\n", SvPVX(key), lang_index, stream_number, data_type);
      }
#endif

      // If stream_number is available, store the data with the stream info
      // XXX: should store lang_index?
      if (stream_number > 0) {
        _store_stream_info( stream_number, asf->info, key, value );
      }
      else {
        _store_tag( asf->tags, key, value );
      }
    }
  }
}

void
_parse_index_parameters(asfinfo *asf)
{
  uint16_t count;

  my_hv_store( asf->info, "index_entry_interval", newSViv( buffer_get_int_le(asf->buf) ) );

  count = buffer_get_short_le(asf->buf);

  while ( count-- ) {
    uint16_t stream_number = buffer_get_short_le(asf->buf);
    uint16_t index_type    = buffer_get_short_le(asf->buf);

    switch (index_type) {
      case 0x0001:
        _store_stream_info( stream_number, asf->info, newSVpv("index_type", 0), newSVpv("Nearest Past Data Packet", 0) );
        break;
      case 0x0002:
        _store_stream_info( stream_number, asf->info, newSVpv("index_type", 0), newSVpv("Nearest Past Media Object", 0) );
        break;
      case 0x0003:
        _store_stream_info( stream_number, asf->info, newSVpv("index_type", 0), newSVpv("Nearest Past Cleanpoint", 0) );
        break;
      default:
        _store_stream_info( stream_number, asf->info, newSVpv("index_type", 0), newSViv(index_type) );
    }
  }
}

void
_store_stream_info(int stream_number, HV *info, SV *key, SV *value )
{
  AV *streams;
  HV *streaminfo;
  uint8_t found = 0;
  int i = 0;

  if ( !my_hv_exists( info, "streams" ) ) {
    // Create
    streams = newAV();
    my_hv_store( info, "streams", newRV_noinc( (SV*)streams ) );
  }
  else {
    SV **entry = my_hv_fetch( info, "streams" );
    if (entry != NULL) {
      streams = (AV *)SvRV(*entry);
    }
    else {
      return;
    }
  }

  if (streams != NULL) {
    // Find entry for this stream number
    for (i = 0; av_len(streams) >= 0 && i <= av_len(streams); i++) {
      SV **stream = av_fetch(streams, i, 0);
      if (stream != NULL) {
        SV **sn;

        streaminfo = (HV *)SvRV(*stream);
        sn = my_hv_fetch( streaminfo, "stream_number" );
        if (sn != NULL) {
          if ( SvIV(*sn) == stream_number ) {
            // XXX: if item exists, create array
            my_hv_store_ent( streaminfo, key, value );
            SvREFCNT_dec(key);

            found = 1;
            break;
          }
        }
      }
    }

    if ( !found ) {
      // New stream number
      streaminfo = newHV();

      my_hv_store( streaminfo, "stream_number", newSViv(stream_number) );
      my_hv_store_ent( streaminfo, key, value );
      SvREFCNT_dec(key);

      av_push( streams, newRV_noinc( (SV *)streaminfo ) );
    }
  }
}

void
_store_tag(HV *tags, SV *key, SV *value)
{
  // if key exists, create array
  if ( my_hv_exists_ent( tags, key ) ) {
    SV **entry = my_hv_fetch( tags, SvPVX(key) );
    if (entry != NULL) {
      if ( SvROK(*entry) && SvTYPE(SvRV(*entry)) == SVt_PVAV ) {
        av_push( (AV *)SvRV(*entry), value );
      }
      else {
      // A non-array entry, convert to array.
        AV *ref = newAV();
        av_push( ref, newSVsv(*entry) );
        av_push( ref, value );
        my_hv_store_ent( tags, key, newRV_noinc( (SV*)ref ) );
      }
    }
  }
  else {
    my_hv_store_ent( tags, key, value );
  }

  SvREFCNT_dec(key);
}

int
_parse_index_objects(asfinfo *asf, int index_size)
{
  GUID tmp;
  uint64_t size;

  while (index_size > 0) {
    // Make sure we have enough data
    if ( !_check_buf(asf->infile, asf->buf, 24, ASF_BLOCK_SIZE) ) {
      return 0;
    }

    buffer_get_guid(asf->buf, &tmp);
    size = buffer_get_int64_le(asf->buf);

    if ( !_check_buf(asf->infile, asf->buf, size - 24, ASF_BLOCK_SIZE) ) {
      return 0;
    }

    if ( IsEqualGUID(&tmp, &ASF_Index) ) {
      DEBUG_TRACE("Index size %llu\n", size);
      _parse_index(asf, size - 24);
    }
    else if ( IsEqualGUID(&tmp, &ASF_Simple_Index) ) {
      DEBUG_TRACE("Skipping Simple_Index size %llu\n", size);
      // Simple Index is used for video files only
      buffer_consume(asf->buf, size - 24);
    }
    else {
      // Unhandled GUID
      PerlIO_printf(PerlIO_stderr(), "** Unhandled Index GUID: ");
      print_guid(tmp);
      PerlIO_printf(PerlIO_stderr(), "size: %llu\n", size);

      buffer_consume(asf->buf, size - 24);
    }

    index_size -= size;
  }

  return 1;
}

void
_parse_index(asfinfo *asf, uint64_t size)
{
  uint32_t time_interval;
  uint16_t spec_count;
  uint32_t block_count;
  uint32_t entry_count;
  int i, ec;

  time_interval = buffer_get_int_le(asf->buf);
  spec_count    = buffer_get_short_le(asf->buf);
  block_count   = buffer_get_int_le(asf->buf);

  // XXX ignore block_count > 1 for now, for files larger than 2^32
  if (block_count > 1) {
    buffer_consume(asf->buf, size);
    return;
  }

  DEBUG_TRACE("  time_interval %d, spec_count %d\n", time_interval, spec_count);

  asf->spec_count = spec_count;

  New(0, asf->specs, spec_count * sizeof(*asf->specs), struct asf_index_specs);

  DEBUG_TRACE("  Index Specifiers:\n");
  for (i = 0; i < spec_count; i++) {
    asf->specs[i].stream_number = buffer_get_short_le(asf->buf);
    asf->specs[i].index_type    = buffer_get_short_le(asf->buf);
    asf->specs[i].time_interval = time_interval;
    DEBUG_TRACE("    stream_number %d, index_type %d\n", asf->specs[i].stream_number, asf->specs[i].index_type);
  }

  entry_count = buffer_get_int_le(asf->buf);

  DEBUG_TRACE("  entry_count %d\n", entry_count);

  for (i = 0; i < spec_count; i++) {
    asf->specs[i].block_pos   = buffer_get_int64_le(asf->buf);
    asf->specs[i].entry_count = entry_count;
    DEBUG_TRACE("  specs[%d].block_pos %llu\n", i, asf->specs[i].block_pos);

    // allocate space for this spec's offsets
    New(0, asf->specs[i].offsets, entry_count * sizeof(uint32_t), uint32_t);
  }

  for (ec = 0; ec < entry_count; ec++) {
    for (i = 0; i < spec_count; i++) {
      // These are byte offsets relative to start of the first data packet,
      // so we add audio_offset here.  An additional 50 bytes are already added
      // to skip past the top-level Data Object
      asf->specs[i].offsets[ec] = asf->audio_offset + buffer_get_int_le(asf->buf);
      DEBUG_TRACE("  entry %d spec %d offset: %d\n", ec, i, asf->specs[i].offsets[ec]);
    }
  }
}

void
_parse_content_encryption(asfinfo *asf)
{
  uint32_t protection_type_len;
  uint32_t key_len;
  uint32_t license_url_len;

  // Skip secret data
  buffer_consume(asf->buf, buffer_get_int_le(asf->buf));

  protection_type_len = buffer_get_int_le(asf->buf);
  my_hv_store( asf->info, "drm_protection_type", newSVpvn( buffer_ptr(asf->buf), protection_type_len - 1 ) );
  buffer_consume(asf->buf, protection_type_len);

  key_len = buffer_get_int_le(asf->buf);
  my_hv_store( asf->info, "drm_key", newSVpvn( buffer_ptr(asf->buf), key_len - 1 ) );
  buffer_consume(asf->buf, key_len);

  license_url_len = buffer_get_int_le(asf->buf);
  my_hv_store( asf->info, "drm_license_url", newSVpvn( buffer_ptr(asf->buf), license_url_len - 1 ) );
  buffer_consume(asf->buf, license_url_len);
}

void
_parse_extended_content_encryption(asfinfo *asf)
{
  uint32_t len = buffer_get_int_le(asf->buf);
  SV *value;
  unsigned char *tmp_ptr = buffer_ptr(asf->buf);

  if ( tmp_ptr[0] == 0xFF && tmp_ptr[1] == 0xFE ) {
    buffer_consume(asf->buf, 2);
    buffer_init_or_clear(asf->scratch, len - 2);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, len - 2, UTF16_BYTEORDER_LE);
    value = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(value);

    my_hv_store( asf->info, "drm_data", value );
  }
  else {
    buffer_consume(asf->buf, len);
  }
}

void
_parse_script_command(asfinfo *asf)
{
  uint16_t command_count;
  uint16_t type_count;
  AV *types = newAV();
  AV *commands = newAV();

  buffer_init_or_clear(asf->scratch, 32);

  // Skip reserved
  buffer_consume(asf->buf, 16);

  command_count = buffer_get_short_le(asf->buf);
  type_count    = buffer_get_short_le(asf->buf);

  while ( type_count-- ) {
    SV *value;
    uint16_t len = buffer_get_short_le(asf->buf);

    buffer_clear(asf->scratch);
    buffer_get_utf16_as_utf8(asf->buf, asf->scratch, len * 2, UTF16_BYTEORDER_LE);
    value = newSVpv( buffer_ptr(asf->scratch), 0 );
    sv_utf8_decode(value);

    av_push( types, value );
  }

  while ( command_count-- ) {
    HV *command = newHV();
    SV *value;

    uint32_t pres_time  = buffer_get_int_le(asf->buf);
    uint16_t type_index = buffer_get_short_le(asf->buf);
    uint16_t name_len   = buffer_get_short_le(asf->buf);

    if (name_len) {
      buffer_clear(asf->scratch);
      buffer_get_utf16_as_utf8(asf->buf, asf->scratch, name_len * 2, UTF16_BYTEORDER_LE);
      value = newSVpv( buffer_ptr(asf->scratch), 0 );
      sv_utf8_decode(value);
      my_hv_store( command, "command", value );
    }

    my_hv_store( command, "time", newSVuv(pres_time) );
    my_hv_store( command, "type", newSVuv(type_index) );

    av_push( commands, newRV_noinc( (SV *)command ) );
  }

  my_hv_store( asf->info, "script_types", newRV_noinc( (SV *)types ) );
  my_hv_store( asf->info, "script_commands", newRV_noinc( (SV *)commands ) );
}

SV *
_parse_picture(asfinfo *asf, uint32_t picture_offset)
{
  char *tmp_ptr;
  uint16_t mime_len = 2; // to handle double-null
  uint16_t desc_len = 2;
  uint32_t image_len;
  SV *mime;
  SV *desc;
  HV *picture = newHV();

  buffer_init_or_clear(asf->scratch, 32);

  my_hv_store( picture, "image_type", newSVuv( buffer_get_char(asf->buf) ) );

  image_len = buffer_get_int_le(asf->buf);

  // MIME type is a double-null-terminated UTF-16 string
  tmp_ptr = buffer_ptr(asf->buf);
  while ( tmp_ptr[0] != '\0' || tmp_ptr[1] != '\0' ) {
    mime_len += 2;
    tmp_ptr += 2;
  }

  buffer_get_utf16_as_utf8(asf->buf, asf->scratch, mime_len, UTF16_BYTEORDER_LE);
  mime = newSVpv( buffer_ptr(asf->scratch), 0 );
  sv_utf8_decode(mime);
  my_hv_store( picture, "mime_type", mime );

  // Description is a double-null-terminated UTF-16 string
  tmp_ptr = buffer_ptr(asf->buf);
  while ( tmp_ptr[0] != '\0' || tmp_ptr[1] != '\0' ) {
    desc_len += 2;
    tmp_ptr += 2;
  }

  buffer_clear(asf->scratch);
  buffer_get_utf16_as_utf8(asf->buf, asf->scratch, desc_len, UTF16_BYTEORDER_LE);
  desc = newSVpv( buffer_ptr(asf->scratch), 0 );
  sv_utf8_decode(desc);
  my_hv_store( picture, "description", desc );

  if ( _env_true("AUDIO_SCAN_NO_ARTWORK") ) {
    my_hv_store( picture, "image", newSVuv(image_len) );
    picture_offset += 5 + mime_len + desc_len + 2;
    my_hv_store( picture, "offset", newSVuv(asf->object_offset + picture_offset) );
  }
  else {
    my_hv_store( picture, "image", newSVpvn( buffer_ptr(asf->buf), image_len ) );
  }

  buffer_consume(asf->buf, image_len);

  return newRV_noinc( (SV *)picture );
}

// offset is in ms
// Based on some code from Rockbox
int
asf_find_frame(PerlIO *infile, char *file, int time_offset)
{
  int frame_offset = -1;
  uint32_t song_length_ms;
  int32_t offset_index = 0;
  uint32_t min_packet_size, max_packet_size;
  uint8_t found = 0;

  // We need to read all info first to get some data we need to calculate
  HV *info = newHV();
  HV *tags = newHV();
  asfinfo *asf = _asf_parse(infile, file, info, tags, 1);

  // We'll need to reuse the scratch buffer
  Newz(0, asf->scratch, sizeof(Buffer), Buffer);

  // No seeking without at least 1 stream
  if ( !my_hv_exists(info, "streams") ) {
    DEBUG_TRACE("No streams found in file, not seeking\n");
    goto out;
  }

  min_packet_size = SvIV( *(my_hv_fetch(info, "min_packet_size")) );
  max_packet_size = SvIV( *(my_hv_fetch(info, "max_packet_size")) );

  // No seeking if min != max, according to the ASF spec these must be the same
  // and without this value we can't find the data packets properly
  if (min_packet_size != max_packet_size) {
    DEBUG_TRACE("min_packet_size != max_packet_size, cannot seek\n");
    goto out;
  }

  song_length_ms = SvIV( *(my_hv_fetch( info, "song_length_ms" )) );

  if (time_offset > song_length_ms)
    time_offset = song_length_ms;

  // Use ASF_Index if available
  if ( asf->spec_count ) {
    // Use the index to find the nearest offset
    offset_index = time_offset / asf->specs[0].time_interval;

    if (offset_index >= asf->specs[0].entry_count)
      offset_index = asf->specs[0].entry_count - 1;

    // An offset may be -1 so look backwards if we find one of those
    while (frame_offset == -1 && offset_index >= 0) {
      frame_offset = asf->specs[0].offsets[offset_index];

      // XXX should add asf->specs[0].block_pos here, but since we
      // aren't supporting 64-bit it should always be 0

      DEBUG_TRACE(
        "offset_index for %d / %d: %d = %d\n",
        time_offset, asf->specs[0].time_interval, offset_index, frame_offset
      );

      offset_index--;
    }
  }

  // Calculate seek position using bitrate
  else if (asf->max_bitrate) {
    float bytes_per_ms = asf->max_bitrate / 8000.0;
    int packet = (int)((bytes_per_ms * time_offset) / max_packet_size);

    frame_offset = asf->audio_offset + (packet * max_packet_size);

    DEBUG_TRACE("seeking to data packet %d @ %d, via max_bitrate (bytes_per_ms %.2f, time_offset %d, packet size %d)\n",
      packet, frame_offset, bytes_per_ms, time_offset, max_packet_size);
  }
  else {
    // No ASF_Index, no max_bitrate, probably an invalid file
    goto out;
  }

  // Double-check above frame, make sure we have the right one
  // with a timestamp within our desired range
  while ( !found && frame_offset >= 0 ) {
    int time, duration;

    DEBUG_TRACE("Checking for frame with timestamp %d at %d\n", time_offset, frame_offset);

    if ( frame_offset > asf->file_size - 64 ) {
      DEBUG_TRACE("  Offset too large: %d\n", frame_offset);
      break;
    }

    time = _timestamp(asf, frame_offset, &duration);

    DEBUG_TRACE("  Timestamp for frame at %d: %d, duration: %d\n", frame_offset, time, duration);

    if (time < 0) {
      DEBUG_TRACE("  Invalid timestamp, giving up\n");
      break;
    }

    if ( time + duration >= time_offset && time <= time_offset ) {
      DEBUG_TRACE("  Found frame at offset %d\n", frame_offset);
      found = 1;
    }
    else {
      int delta = time_offset - time;

      DEBUG_TRACE("  Wrong frame, delta: %d\n", delta);

      if (
        (delta < 0 && (frame_offset - max_packet_size) < asf->audio_offset)
        ||
        (delta > 0 && (frame_offset + max_packet_size) > (asf->audio_offset + asf->audio_size - 64))
      ) {
        // Reached the first/last audio packet, break out
        DEBUG_TRACE("  Giving up, reached the beginning or end of audio\n");
        break;
      }

      // XXX probably could be more efficient using a binary search,
      // but with the use of an index we should already be very close to the right place
      if (delta > 0) {
        frame_offset += max_packet_size;
      }
      else {
        frame_offset -= max_packet_size;
      }
    }
  }

out:
  // Don't leak
  SvREFCNT_dec(info);
  SvREFCNT_dec(tags);

  if (asf->spec_count) {
    int i;
    for (i = 0; i < asf->spec_count; i++) {
      DEBUG_TRACE("Freeing specs[%d] offsets\n", i);
      Safefree(asf->specs[i].offsets);
    }

    DEBUG_TRACE("Freeing specs\n");
    Safefree(asf->specs);
  }

  if (asf->scratch->alloc)
    buffer_free(asf->scratch);
  Safefree(asf->scratch);

  Safefree(asf);

  return frame_offset;
}

// Return the timestamp of the data packet at offset
int
_timestamp(asfinfo *asf, int offset, int *duration)
{
  int timestamp = -1;
  uint8_t tmp;

  if ((PerlIO_seek(asf->infile, offset, SEEK_SET)) != 0) {
    return -1;
  }

  buffer_init_or_clear(asf->scratch, 64);

  if ( !_check_buf(asf->infile, asf->scratch, 64, 64) ) {
    goto out;
  }

  // Read Error Correction Flags
  tmp = buffer_get_char(asf->scratch);

  if (tmp & 0x80) {
    // Skip error correction data
    buffer_consume(asf->scratch, tmp & 0x0f);

    // Read Length Type Flags
    tmp = buffer_get_char(asf->scratch);
  }
  else {
    // The byte we already read is Length Type Flags
  }

  // Skip Property Flags, Packet Length, Sequence, Padding Length
  buffer_consume( asf->scratch,
    1 + GETLEN2b((tmp >> 1) & 0x03) +
        GETLEN2b((tmp >> 3) & 0x03) +
        GETLEN2b((tmp >> 5) & 0x03)
  );

  timestamp = buffer_get_int_le(asf->scratch);
  *duration = buffer_get_short_le(asf->scratch);

out:
  return timestamp;
}
