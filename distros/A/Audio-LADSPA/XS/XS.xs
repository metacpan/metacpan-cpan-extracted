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

/*
    This module contains a lot of references to functions
    and structures in ladspa.h - if you're interested in
    the ladspa C api, take a look in there. It will
    probably help in understanding parts of the code here.
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "../ladspa.h"
#include "../ppport.h"
#include "../Buffer/Buffer.h"
#include "Plugin.h"
#include <limits.h>

/*
    this is function is trying to get at the plugin descriptor
    regardless of whether the self SV is a package name or a
    blessed object, so that we can handle class method calls
    where appropriate

    TODO: fix it so this will also work when called from an
    inherited object or class.
    
    This needs to be done in quite a few places, because perl 
    doesn't have property inheritance, and the most obvious 
    place for storing class-wide properties (such as the plugin
    descriptor in this case) is as a package variable, which
    doesn't get inherited.

    This, by the way, is one of the reasons most of the
    public API for these extensions uses methods instead of
    documented ('public') properties; they get inherited just
    fine.
*/

LADSPA_Descriptor* my_descriptor(SV* self) {
    SV* descriptor_store = NULL;
    SV* package;
    if (sv_isobject(self) && sv_derived_from(self,"Audio::LADSPA::Plugin::XS")) {
	HV* stash = SvSTASH(SvRV(self));
	package = newSVpv(HvNAME(stash),0);
	sv_2mortal(package);
    }
    else if (SvPOK(self) && SvCUR(self) > 0) {
	package = self;
    }
    else {
	croak("not a valid Audio::LADSPA::Plugin::XS");
    }
    
    descriptor_store = get_sv(form("%_::_ladspa_descriptor",package),0);
    if (descriptor_store && SvIOK(descriptor_store) && SvREADONLY(descriptor_store)) {
	return INT2PTR(LADSPA_Descriptor* ,SvIVX(descriptor_store));
    }
    croak("No valid descriptor in %_",package);
}


/*
    Instantiate a plugin and return pointer to Audio_LADSPA_Plugin struct as a blessed
    scalar ref
*/

SV* new_with_uid(SV* package, unsigned long sample_rate, SV* uid) {
    Audio_LADSPA_Plugin plugin = NULL;
    SV* self;
    SV* ref;
    LADSPA_Descriptor* descriptor = my_descriptor(package);
    LADSPA_Handle* handle = descriptor->instantiate(descriptor,sample_rate);
    if (handle == NULL)
	croak("Cannot create plugin handle\n");
    Newz(0,plugin,1,Audio_LADSPA_Plugin_t);
    if (plugin == NULL)
	croak("Cannot create Plugin struct");
    plugin->handle = handle;
    plugin->descriptor = descriptor;
    plugin->monitor = &PL_sv_undef;
    plugin->uniqid = newSVsv(uid);
    Newz(0,plugin->buffers,descriptor->PortCount,SV*);	/* reserve space for buffer sv's - one for each port */
    self = newSViv(PTR2IV(plugin));
    ref = sv_bless(newRV_noinc(self),gv_stashsv(package,0));
    SvREADONLY_on(self);
    return ref;
}


Audio_LADSPA_Buffer AL_Buffer_from_sv( SV* sv ) {
    if (sv_derived_from(sv, "Audio::LADSPA::Buffer"))
       return (Audio_LADSPA_Buffer) SvIV((SV*)SvRV(sv));
    croak("Not an Audio::LADSPA::Buffer");
}



void deactivate(Audio_LADSPA_Plugin self) {
    if (self->active && self->descriptor->deactivate) {
        self->descriptor->deactivate(self->handle);
    }
    self->active = 0;
}


void activate(Audio_LADSPA_Plugin self) {
    if (! self->active && self->descriptor->activate) {
        self->descriptor->activate(self->handle);
    }
    self->active = 1;
}

/*
    On destruction, deactivate plugin if needed and
    call cleanup() function on it.
*/

void DESTROY(Audio_LADSPA_Plugin self) {
    unsigned long i;
    deactivate(self);
    for (i=0;i<self->descriptor->PortCount;i++) {
	if (self->buffers[i]) {
	    SvREFCNT_dec(self->buffers[i]);
	}
    }
    self->descriptor->cleanup(self->handle);
    Safefree(self->buffers); 
    Safefree(self);
}

/* set the buffer status after a run() / run_adding()  call */

void set_buffers_filled( Audio_LADSPA_Plugin self, unsigned long count ) {
    unsigned long i = 0;
    for (i =0 ; i < self->descriptor->PortCount; i++) {
	if (! LADSPA_IS_PORT_INPUT(self->descriptor->PortDescriptors[i])) {
	    Audio_LADSPA_Buffer buffer = AL_Buffer_from_sv(self->buffers[i]);
	    if ( LADSPA_IS_PORT_CONTROL(self->descriptor->PortDescriptors[i])) {
	        buffer->filled = 1;
	    }
	    else {
		buffer->filled = count;
	    }
	}
    }
}




void run_adding(Audio_LADSPA_Plugin self, unsigned long count) {
    if (!self->descriptor->run_adding) {
        croak("Plugin has no run_adding method!");
    }
    if (!self->ready) {
	croak("Plugin not connected on all ports!");
    }
    if (self->max_samples < count) {
	croak("Cannot run for more than %d samples",self->max_samples);
    }
    if (!self->active) {
	activate(self);
    }
    self->descriptor->run_adding(self->handle, count);
    set_buffers_filled(self,count);
}

void set_run_adding_gain(Audio_LADSPA_Plugin self, float gain) {
    if (!self->descriptor->run_adding) {
        croak("Plugin has no run_adding method!");
    }
    self->descriptor->set_run_adding_gain(self->handle, gain);
}

void run(Audio_LADSPA_Plugin self, unsigned long count) {
    if (!self->descriptor->run) {
        croak("Plugin has no run method!");
    }
    if (!self->ready) {
	croak("Plugin not connected on all ports!");
    }
    if (self->max_samples < count) {
	croak("Cannot run for more than %d samples",self->max_samples);
    }
    if (!self->active) {
	activate(self);
    }
    self->descriptor->run(self->handle, count);
    set_buffers_filled(self,count);
}

/* return port index from name or number */

unsigned long port_index(LADSPA_Descriptor* descriptor, SV* buffer) {
    unsigned long i;
    char* string;
    if (SvPOK(buffer)) {
        i = 0;
        string = SvPVX(buffer);
        while (string[i] != 0) {
            if (string[i] < '0' || string[i] > '9') {
                for (i = 0; i < descriptor->PortCount; i++) {
                    if (strcmp(descriptor->PortNames[i],string) == 0) {
                        return i;
                    }
                }
                croak("Port %_ not found", buffer);
            }
            i++;
        }
    }
    else {
        i = SvIV(buffer);
        if (i >= descriptor->PortCount) {
            croak("Port index %d out of bounds",i);
        }
    }
    return i;
}



MODULE = Audio::LADSPA::Plugin::XS PACKAGE = Audio::LADSPA::Plugin::XS

PROTOTYPES: DISABLE


SV*
new_with_uid(package,sample_rate, uid)
    SV* package 
    unsigned long sample_rate
    SV* uid


void
DESTROY(self)
    Audio_LADSPA_Plugin self

void activate(self)
    Audio_LADSPA_Plugin self

void deactivate(self)
    Audio_LADSPA_Plugin self

void run(self, count)
    Audio_LADSPA_Plugin self
    unsigned long count

void run_adding(self, count)
    Audio_LADSPA_Plugin self
    unsigned long count

void set_run_adding_gain(self, gain)
    Audio_LADSPA_Plugin self
    float gain


unsigned long
id(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->UniqueID;
    OUTPUT:
    RETVAL

const char*
label(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->Label;
    OUTPUT:
    RETVAL


const char*
name(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->Name;
    OUTPUT:
    RETVAL

const char*
maker(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->Maker;
    OUTPUT:
    RETVAL


const char*
copyright(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->Copyright;
    OUTPUT:
    RETVAL


unsigned long
port_count(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->PortCount;
    OUTPUT:
    RETVAL


SV*
is_realtime(self)
    SV* self
    CODE:
    RETVAL = LADSPA_IS_REALTIME(my_descriptor(self)->Properties) ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL


SV*
is_inplace_broken(self)
    SV* self
    CODE:
    RETVAL = LADSPA_IS_INPLACE_BROKEN(my_descriptor(self)->Properties) ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL

SV*
is_hard_rt_capable(self)
    SV* self
    CODE:
    RETVAL = LADSPA_IS_HARD_RT_CAPABLE(my_descriptor(self)->Properties) ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL


SV*
has_run(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->run ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL


SV*
has_run_adding(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->run_adding ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL

SV*
has_activate(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->activate ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL


SV*
has_deactivate(self)
    SV* self
    CODE:
    RETVAL = my_descriptor(self)->deactivate ? &PL_sv_yes : &PL_sv_no;
    OUTPUT:
    RETVAL


void
_unregistered_connect(self, port, buffer_sv)
    Audio_LADSPA_Plugin self
    SV* port
    SV* buffer_sv
    PREINIT:
    Audio_LADSPA_Buffer buffer;
    unsigned long index;
    CODE:
    buffer = AL_Buffer_from_sv(buffer_sv);
    index = port_index(self->descriptor, port);
    self->descriptor->connect_port(self->handle, port_index(self->descriptor, port), buffer->data);
    SvREFCNT_inc(SvRV(buffer_sv));
    self->buffers[index] = newSVsv(buffer_sv);
    
    self->ready = 1;
    self->max_samples = ULONG_MAX;
    for (index = 0; index < self->descriptor->PortCount; index++) {
	if (self->buffers[index] == NULL) {
	    self->ready =0;
	    break;
	}
	if (LADSPA_IS_PORT_CONTROL(self->descriptor->PortDescriptors[index])) {
	    continue;
	}
	buffer = AL_Buffer_from_sv(self->buffers[index]);
	if (buffer->size < self->max_samples) {
	    self->max_samples = buffer->size;
	}
    }


void
_unregistered_disconnect(self, port)
    Audio_LADSPA_Plugin self
    SV* port
    PREINIT:
    unsigned long index;
    CODE:
    index = port_index(self->descriptor, port);
    deactivate(self);
    if (self->buffers[index] != NULL) {
	SvREFCNT_dec(self->buffers[index]);
	self->buffers[index] = NULL;
    }
    self->ready = 0;

SV* 
get_buffer(self, port)
    Audio_LADSPA_Plugin self
    SV* port
    PREINIT:
    unsigned long index;
    CODE:
    index = port_index(self->descriptor, port);
    if (self->buffers[index]) {
        RETVAL = newSVsv(self->buffers[index]);
    }
    else {
	RETVAL = &PL_sv_undef;
    }
    OUTPUT:
    RETVAL

const char*
port_name(self, index)
    SV* self
    unsigned long index
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    RETVAL = descriptor->PortNames[index];
    OUTPUT:
    RETVAL

bool
is_input(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    RETVAL = LADSPA_IS_PORT_INPUT(descriptor->PortDescriptors[index]);
    OUTPUT:
    RETVAL

bool
is_control(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    RETVAL = LADSPA_IS_PORT_CONTROL(descriptor->PortDescriptors[index]);
    OUTPUT:
    RETVAL


SV*
lower_bound(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    if(LADSPA_IS_HINT_BOUNDED_BELOW(descriptor->PortRangeHints[index].HintDescriptor))
	RETVAL = newSVnv(descriptor->PortRangeHints[index].LowerBound);
    else
	RETVAL = &PL_sv_undef;
    OUTPUT:
    RETVAL


SV*
upper_bound(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    if(LADSPA_IS_HINT_BOUNDED_ABOVE(descriptor->PortRangeHints[index].HintDescriptor)) {
	RETVAL = newSVnv(descriptor->PortRangeHints[index].UpperBound);
    }
    else {
	RETVAL = &PL_sv_undef;
    }
    OUTPUT:
    RETVAL


bool
is_toggled(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    RETVAL = LADSPA_IS_HINT_TOGGLED(descriptor->PortRangeHints[index].HintDescriptor);
    OUTPUT:
    RETVAL


bool
is_integer(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    RETVAL = LADSPA_IS_HINT_INTEGER(descriptor->PortRangeHints[index].HintDescriptor);
    OUTPUT:
    RETVAL


bool
is_sample_rate(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    RETVAL = LADSPA_IS_HINT_SAMPLE_RATE(descriptor->PortRangeHints[index].HintDescriptor);
    OUTPUT:
    RETVAL

bool
is_logarithmic(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    RETVAL = LADSPA_IS_HINT_LOGARITHMIC(descriptor->PortRangeHints[index].HintDescriptor);
    OUTPUT:
    RETVAL


SV *
default(self, port)
    SV* self
    SV* port
    CODE:
    LADSPA_Descriptor* descriptor = my_descriptor(self);
    unsigned long index = port_index(descriptor, port);
    const LADSPA_PortRangeHint hint = descriptor->PortRangeHints[index];
    if (!LADSPA_IS_HINT_HAS_DEFAULT(hint.HintDescriptor))
    	RETVAL = &PL_sv_undef;
    else if (LADSPA_IS_HINT_DEFAULT_MINIMUM(hint.HintDescriptor))
	RETVAL = newSVpvn("minimum",7);
    else if (LADSPA_IS_HINT_DEFAULT_LOW(hint.HintDescriptor))
	RETVAL = newSVpvn("low",3);
    else if (LADSPA_IS_HINT_DEFAULT_MIDDLE(hint.HintDescriptor))
	RETVAL = newSVpvn("middle",6);
    else if (LADSPA_IS_HINT_DEFAULT_HIGH(hint.HintDescriptor))
	RETVAL = newSVpvn("high",4);
    else if (LADSPA_IS_HINT_DEFAULT_MAXIMUM(hint.HintDescriptor))
	RETVAL = newSVpvn("maximum",7);
    else if (LADSPA_IS_HINT_DEFAULT_0(hint.HintDescriptor))
	RETVAL = newSVpvn("0",1);
    else if (LADSPA_IS_HINT_DEFAULT_1(hint.HintDescriptor))
	RETVAL = newSVpvn("1",1);
    else if (LADSPA_IS_HINT_DEFAULT_100(hint.HintDescriptor))
	RETVAL = newSVpvn("100",3);
    else if (LADSPA_IS_HINT_DEFAULT_440(hint.HintDescriptor))
	RETVAL = newSVpvn("440",3);
    else 
	croak("Port hintdescriptor error, value is: %lx",hint.HintDescriptor);
    OUTPUT:
    RETVAL

void
set_monitor( self, monitor )
    Audio_LADSPA_Plugin self
    SV* monitor
    CODE:
    if (! SvTRUE(monitor)) {
	self->monitor = &PL_sv_undef;
    }
    else {
	self->monitor = newSVsv(monitor);
	SvREFCNT_dec(SvRV(monitor));	/* weaken ref */
    }


SV*
monitor( self )
    Audio_LADSPA_Plugin self
    CODE:
    RETVAL = newSVsv(self->monitor);
    OUTPUT:
    RETVAL


unsigned long
port2index( self, port )
    SV* self
    SV* port
    CODE:
    RETVAL = port_index(my_descriptor(self), port);
    OUTPUT:
    RETVAL


void
set_uniqid( self, uid )
    Audio_LADSPA_Plugin self
    SV* uid
    CODE:
    self->uniqid = newSVsv(uid);

SV*
get_uniqid( self )
    Audio_LADSPA_Plugin self
    CODE:
    RETVAL = newSVsv(self->uniqid);
    OUTPUT:
    RETVAL

    
