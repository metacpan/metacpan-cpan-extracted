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

int get_ogf_metadata(PerlIO *infile, char *file, HV *info, HV *tags);
int ogf_find_frame_return_info(PerlIO *infile, char *file, int offset, HV *info);
off_t ogf_find_frame(PerlIO *infile, char *file, int offset);

static int _ogf_parse(PerlIO *infile, char *file, HV *info, HV *tags, uint8_t seeking);
static off_t _ogf_find_frame(PerlIO *infile, char *file, int offset, HV *info, HV *tags);
