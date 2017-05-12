# Audio::SndFile - perl glue to libsndfile
#
# Copyright (C) 2006 by Joost Diepenmaat, Zeekat Softwareontwikkeling
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program; if not, write to the Free Software
# Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.


#
# Note: do not use this module directly. you won't need to, and this code 
# is subject to change without notice.
# 

package Audio::SndFile::Constants;
use strict;
use base 'Exporter';
our @FORMAT_TYPES = qw(
        SF_FORMAT_WAV SF_FORMAT_AIFF SF_FORMAT_AU SF_FORMAT_RAW SF_FORMAT_PAF SF_FORMAT_SVX SF_FORMAT_NIST
        SF_FORMAT_VOC SF_FORMAT_IRCAM SF_FORMAT_W64 SF_FORMAT_MAT4 SF_FORMAT_MAT5 SF_FORMAT_PVF SF_FORMAT_XI
        SF_FORMAT_HTK SF_FORMAT_SDS SF_FORMAT_AVR SF_FORMAT_WAVEX SF_FORMAT_SD2 SF_FORMAT_FLAC SF_FORMAT_CAF
);

our @FORMAT_SUBTYPES = qw(
        SF_FORMAT_PCM_S8 SF_FORMAT_PCM_16 SF_FORMAT_PCM_24 SF_FORMAT_PCM_32 SF_FORMAT_PCM_U8 
        SF_FORMAT_FLOAT SF_FORMAT_DOUBLE SF_FORMAT_ULAW SF_FORMAT_ALAW SF_FORMAT_IMA_ADPCM
        SF_FORMAT_MS_ADPCM SF_FORMAT_GSM610 SF_FORMAT_VOX_ADPCM SF_FORMAT_G721_32 SF_FORMAT_G723_24
        SF_FORMAT_G723_40 SF_FORMAT_DWVW_12 SF_FORMAT_DWVW_16 SF_FORMAT_DWVW_24 SF_FORMAT_DWVW_N
        SF_FORMAT_DPCM_8 SF_FORMAT_DPCM_16 
);

our @ENDIANNESS = qw(SF_ENDIAN_FILE SF_ENDIAN_LITTLE SF_ENDIAN_BIG SF_ENDIAN_CPU);

our @FORMAT_MASKS = qw( SF_FORMAT_SUBMASK SF_FORMAT_TYPEMASK SF_FORMAT_ENDMASK );

our @OPEN_MODES = qw(SFM_READ SFM_WRITE SFM_RDWR); 

our @EXPORT_OK = (@FORMAT_TYPES, @FORMAT_SUBTYPES, @ENDIANNESS, @FORMAT_MASKS, @OPEN_MODES);

our %EXPORT_TAGS = (
    format_types => \@FORMAT_TYPES, 
    format_subtypes => \@FORMAT_SUBTYPES, 
    endianness => \@ENDIANNESS, 
    format_masks => \@FORMAT_MASKS,
    open_modes => \@OPEN_MODES,
    all => \@EXPORT_OK,
);

1;
