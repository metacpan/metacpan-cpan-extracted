/* hey emacs, this is a -*- C -*- file
 *
 * Audio::SndFile - perl glue to libsndfile
 *
 * Copyright (C) 2006 by Joost Diepenmaat, Zeekat Softwareontwikkeling

 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public License
 * as published by the Free Software Foundation; either version 2
 * of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
 */
 
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <sndfile.h>
#include <stdio.h>

typedef SF_INFO* Audio_SndFile_Info;

typedef struct {
    SNDFILE* sndfile;
    SF_INFO* info;
    double* datas;
} Audio_SndFile_t;

typedef Audio_SndFile_t* Audio_SndFile;

SV* to_obj(const char* package, void* p) {
  SV* ref;
  SV* iv;
  iv = newSViv(PTR2IV(p));
  ref = sv_bless(newRV_noinc(iv),gv_stashpv(package,0));
  SvREADONLY_on(iv);
  return ref;
}


MODULE = Audio::SndFile::Info      PACKAGE = Audio::SndFile::Info

PROTOTYPES: DISABLE

SV*
new(package)
    const char* package
    PREINIT:
    SF_INFO* info;
    CODE:
    Newz(0,info, 1, SF_INFO);
    if (!info) croak("Error allocating SF_INFO struct.");
    RETVAL = to_obj("Audio::SndFile::Info",info);
    OUTPUT:
    RETVAL

sf_count_t
frames(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = self->frames;
    OUTPUT:
    RETVAL

int
get_samplerate(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = self->samplerate;
    OUTPUT:
    RETVAL

void
set_samplerate(self, samplerate)
    Audio_SndFile_Info self
    int samplerate
    CODE:
    self->samplerate = samplerate;

int
get_channels(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = self->channels;
    OUTPUT:
    RETVAL

void
set_channels(self, channels)
    Audio_SndFile_Info self
    int channels
    CODE:
    self->channels = channels;

int
get_format(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = self->format;
    OUTPUT:
    RETVAL

void
set_format(self, format)
    Audio_SndFile_Info self
    int format
    CODE:
    self->format = format;

int
sections(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = self->sections;
    OUTPUT:
    RETVAL

int
seekable(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = self->seekable;
    OUTPUT:
    RETVAL

int
format_check(self)
    Audio_SndFile_Info self
    CODE:
    RETVAL = sf_format_check(self);
    OUTPUT:
    RETVAL

MODULE = Audio::SndFile::Constants PACKAGE = Audio::SndFile::Constants

PROTOTYPES: ENABLE
    
INCLUDE: constants.xs 

MODULE = Audio::SndFile            PACKAGE = Audio::SndFile   PREFIX=sf_

PROTOTYPES: DISABLE

SV*
open_fd(package, fd, mode, info,close)
    const char* package
    int fd
    int mode
    Audio_SndFile_Info info;
    int close
    PREINIT:
    Audio_SndFile self;
    CODE:
    if (mode == SFM_WRITE && !sf_format_check(info)) croak("invalid format for writing");
    Newz(0,self, 1, Audio_SndFile_t);
    if(!self) croak("Error allocating Audio_SndFile struct");
    self->info = info;
    self->sndfile = sf_open_fd(fd,mode,info,close);
    if(!self->sndfile) croak("Error opening filehandle: %s",sf_strerror(NULL));
    RETVAL = to_obj(package,self);
    OUTPUT:
    RETVAL
 
SV*
info(self)
    Audio_SndFile self
    CODE:
    RETVAL = to_obj("Audio::SndFile::Info",self->info);
    OUTPUT:
    RETVAL

void
sf_close( self )
    SNDFILE* self

sf_count_t
sf_seek(self, frames, whence)
    SNDFILE* self
    sf_count_t frames
    int whence

int
sf_command(self, cmd, data, datasize)
    SNDFILE* self
    int cmd
    void* data
    int datasize

int
sf_error(self)
    SNDFILE* self

const char*
sf_strerror(self)
    SNDFILE* self

#ifdef sf_write_sync

void
sf_write_sync(self)
    SNDFILE* self

#endif

sf_count_t
read_raw(self, buff, bytes)
    SNDFILE* self
    SV* buff
    sf_count_t bytes
    CODE:
    RETVAL = sf_read_raw(self, (void*) SvGROW(buff, bytes+1),bytes);
    SvCUR_set(buff,RETVAL);
    OUTPUT:
    RETVAL

sf_count_t
write_raw(self, buff)
    SNDFILE* self
    SV* buff
    CODE:
    RETVAL = sf_write_raw(self, (void*) SvPV_nolen(buff), SvCUR(buff));
    OUTPUT:
    RETVAL


INCLUDE: functions.xs

SV*
lib_version()
    PREINIT:
    char buff[2048];
    CODE:
    sf_command(NULL, SFC_GET_LIB_VERSION, buff, sizeof(buff));
    RETVAL = newSVpv(buff,0);
    OUTPUT:
    RETVAL

#ifdef SFC_GET_LOG_INFO

SV*
log_info(self)
    SNDFILE* self
    PREINIT:
    SV* log;
    int len;
    CODE:
    log  = newSV( 4096 );
    len = sf_command(self, SFC_GET_LOG_INFO, SvPVX(log) , SvLEN(log));
    while ( len == SvLEN(log) ) {
        SvGROW(log,SvLEN(log) + 4096);
        len = sf_command(NULL, SFC_GET_LOG_INFO, SvPVX(log) , SvLEN(log));
    }
    SvLEN_set(log, len);
    SvPOK_on(log);
    RETVAL = log;
    OUTPUT:
    RETVAL
    
#endif

#ifdef SFC_FILE_TRUNCATE

int
truncate(self, frames)
    SNDFILE* self
    sf_count_t frames
    CODE:
    RETVAL = sf_command(self, SFC_FILE_TRUNCATE, &frames, sizeof(sf_count_t));

#endif

#ifdef SFC_SET_RAW_START_OFFSET

int
set_raw_start_offset(self, offset)
    SNDFILE* self
    sf_count_t offset
    CODE:
    RETVAL = sf_command(self, SFC_SET_RAW_START_OFFSET, &offset, sizeof(sf_count_t));

#endif

#ifdef SFC_SET_CLIPPING

int
set_clipping(self, boolean)
    SNDFILE* self
    int boolean
    CODE:
    RETVAL = sf_command(self, SFC_SET_CLIPPING, NULL, boolean ? SF_TRUE : SF_FALSE );

#endif

#ifdef SFC_GET_CLIPPING

int
get_clipping(self)
    SNDFILE* self
    CODE:
    RETVAL = sf_command(self, SFC_GET_CLIPPING, NULL, 0 );

#endif


