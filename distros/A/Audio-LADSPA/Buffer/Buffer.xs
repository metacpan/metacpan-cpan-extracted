/*
 * Audio::LADSPA perl modules for interfacing with LADSPA plugins
 * Copyright (C) 2003  Joost Diepenmaat.
 *
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
 *
 * See the COPYING file for more information.
 */

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../ladspa.h"
#include "../ppport.h"
#include "Buffer.h"

SV* new(SV* package, unsigned long size) {
    LADSPA_Data *data = NULL;
    Audio_LADSPA_Buffer buffer = NULL;
    SV* self;
    SV* ref;
    if (size == 0) croak("Buffer size must be > 0");
    New(0,data,size,LADSPA_Data);
    if (data == NULL) croak("Could not allocate memory for buffer data");
    New(0,buffer,1,Audio_LADSPA_Buffer_t);
    if (buffer == NULL) croak("Could not allocate memory for Buffer struct");
    buffer->data = data;
    buffer->size = size;
    buffer->filled = 0;
    self = newSViv(PTR2IV(buffer));
    ref = sv_bless(newRV_noinc(self),gv_stashsv(package,1));
    return ref;
}

Audio_LADSPA_Buffer AL_Buffer_from_sv( SV* sv ) {
    if (sv_derived_from(sv, "Audio::LADSPA::Buffer"))
       return (Audio_LADSPA_Buffer) SvIV((SV*)SvRV(sv));
    croak("Not an Audio::LADSPA::Buffer");
}


void set_1(Audio_LADSPA_Buffer buffer, LADSPA_Data value) {
/*    if (buffer->size != 1) croak("Buffer size != 1"); */
    *(buffer->data) = (LADSPA_Data) value;
    buffer->filled = 1;
}

SV* get_1(Audio_LADSPA_Buffer buffer) {
/*    if (buffer->size != 1) {
	croak("Buffer size != 1");
    } */
    if (buffer->filled > 0) {
	return newSVnv((NV) buffer->data[0]);
    }
    return &PL_sv_undef;
}  

SV* get_raw(Audio_LADSPA_Buffer buffer) {
    if (buffer->filled > 0) {
	return newSVpvn((const char*)buffer->data,sizeof(LADSPA_Data) * buffer->filled);
    }
    else {
	return &PL_sv_undef;
    }
}

void set_raw(Audio_LADSPA_Buffer buffer, SV* data_sv) {
    STRLEN str_size;
    LADSPA_Data* data = (LADSPA_Data*) SvPV(data_sv,str_size);
    unsigned long size = (str_size / sizeof(LADSPA_Data));
    if (size > buffer->size) {
	croak("Buffer size < %lu",size);
    }
    Copy(data,buffer->data,size,LADSPA_Data);
    buffer->filled = size;
}


void DESTROY(Audio_LADSPA_Buffer buffer) {
    Safefree(buffer->data);
    Safefree(buffer);
}

unsigned long filled(Audio_LADSPA_Buffer buffer) {
    return buffer->filled;
}


/*  math functions */

SV* is_mult(SV* self_sv, LADSPA_Data val, SV* order) {
    unsigned long i;
    Audio_LADSPA_Buffer self = AL_Buffer_from_sv(self_sv);
    SvREFCNT_inc(self_sv);  /* '*=' operator should still return its value, so we inc the refcount on $self */
    i = self->filled;
    if (i == 0) {
	return self_sv;
    }
    while(i--) {
	self->data[i] *= val;
    }
    return self_sv;
}


/*
  create a Audio::LADSPA::Buffer object
  of the same size and package,
  but WITHOUT copying the data in the buffer
*/

SV* undef_copy(SV* sv) {
    LADSPA_Data *data = NULL;
    Audio_LADSPA_Buffer buffer = NULL;
    SV* new;
    SV* ref;
    Audio_LADSPA_Buffer self = AL_Buffer_from_sv(sv);
    if (self->size == 0) croak("Buffer size must be > 0");
    New(0,data,self->size,LADSPA_Data);
    if (data == NULL) croak("Could not allocate memory for buffer data");
    New(0,buffer,1,Audio_LADSPA_Buffer_t);
    if (buffer == NULL) croak("Could not allocate memory for Buffer struct");
    buffer->data = data;
    buffer->size = self->size;
    buffer->filled = 0;
    new = newSViv(PTR2IV(buffer));
    ref = sv_bless(newRV_noinc(new),SvSTASH(SvRV(sv)));
    return ref;
}
    
   

SV* mult(SV* sv, LADSPA_Data val, SV* order) {
    Audio_LADSPA_Buffer self = AL_Buffer_from_sv(sv);
    SV* copy_sv = undef_copy(sv);
    Audio_LADSPA_Buffer copy = AL_Buffer_from_sv(copy_sv);
    unsigned long i = self->filled;
    copy->filled = i;
    if (i == 0)
	return copy_sv;
    while (i--) { 
	copy->data[i] = self->data[i] * val;
    }
    return copy_sv;
}

MODULE = Audio::LADSPA::Buffer PACKAGE = Audio::LADSPA::Buffer

PROTOTYPES: DISABLE

SV* new(package,size)
    SV* package
    unsigned long size

void DESTROY(self)
    Audio_LADSPA_Buffer self

void set_1(self,val)
    Audio_LADSPA_Buffer self
    LADSPA_Data val

SV* get_1(self)
    Audio_LADSPA_Buffer self

SV* get_raw(self)
    Audio_LADSPA_Buffer self

void set_raw(self, val)
    Audio_LADSPA_Buffer self
    SV* val

unsigned long filled(self)
    Audio_LADSPA_Buffer self

SV* is_mult(self, val, order)
    SV* self
    LADSPA_Data val
    SV*	order

SV* undef_copy(self)
    SV* self


SV* mult(self, val, order)
    SV* self
    LADSPA_Data val
    SV*	order

unsigned long size(self)
    Audio_LADSPA_Buffer self
    CODE:
    RETVAL = self->size;
    OUTPUT:
    RETVAL

