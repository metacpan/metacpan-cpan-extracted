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

#define WAV_BLOCK_SIZE 4096

static int get_wav_metadata(PerlIO *infile, char *file, HV *info, HV *tags);
void _parse_wav(PerlIO *infile, Buffer *buf, char *file, uint32_t file_size, HV *info, HV *tags);
void _parse_wav_fmt(Buffer *buf, uint32_t chunk_size, HV *info);
void _parse_wav_list(Buffer *buf, uint32_t chunk_size, HV *tags);
void _parse_wav_peak(Buffer *buf, uint32_t chunk_size, HV *info, uint8_t big_endian);

void _parse_aiff(PerlIO *infile, Buffer *buf, char *file, uint32_t file_size, HV *info, HV *tags);
void _parse_aiff_comm(Buffer *buf, uint32_t chunk_size, HV *info);
