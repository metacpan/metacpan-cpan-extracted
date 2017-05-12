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

#define AAC_BLOCK_SIZE 4096

static int adts_sample_rates[] = {
  96000,
  88200,
  64000,
  48000,
  44100,
  32000,
  24000,
  22050,
  16000,
  12000,
  11025,
  8000,
  7350,
  0,
  0,
  0
};

const char *aac_profiles[] = {
  "Main",
  "LC",
  "SSR",
  "reserved"
};

static int get_aacinfo(PerlIO *infile, char *file, HV *info, HV *tags);

int aac_parse_adts(PerlIO *infile, char *file, off_t audio_size, Buffer *buf, HV *info);
