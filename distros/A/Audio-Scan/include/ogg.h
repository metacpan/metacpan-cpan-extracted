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

#define OGG_BLOCK_SIZE 4500

int get_ogg_metadata(PerlIO *infile, char *file, HV *info, HV *tags);
int _ogg_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking);
static int ogg_find_frame(PerlIO *infile, char *file, int offset);
void _parse_vorbis_comments(PerlIO *infile, Buffer *vorbis_buf, HV *tags, int has_framing);
int _ogg_binary_search_sample(PerlIO *infile, char *file, HV *info, uint64_t target_sample);
