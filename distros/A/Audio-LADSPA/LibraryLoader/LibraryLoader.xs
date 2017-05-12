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
#include <dlfcn.h>
#include "assert.h"
#include "../ppport.h"


/*
    creates a package for a given plugin descriptor
    will make it inherit from Audio::LADSPA::Plugin::XS

    See Audio::LADSPA::Plugin::XS for object instantiation

    returns the package name as a perl scalar
*/

SV* setup_plugin(const LADSPA_Descriptor* desc, const char * filename) {
    SV* store_descriptor;
    SV* package = newSVpv(form("Audio::LADSPA::Plugin::XS::%s_%lu",desc->Label,desc->UniqueID),0);
#ifdef DEBUGGING
    fprintf(stderr,"package for plugin: %s\n",SvPVX(package));
#endif
    char* isa_arr_name = form("%_::ISA",package);
    AV* isa_arr = get_av(isa_arr_name,0);
    if (isa_arr) {
/*	warn(form("Plugin %s (%s): already loaded.\n"),SvPVX(package),filename); */
	return package;
    }
    isa_arr = get_av(isa_arr_name,1);
    
    av_push(isa_arr,newSVpv("Audio::LADSPA::Plugin::XS",0)); 

    /* store the plugin descriptor in $package::_ladspa_descriptor */

    store_descriptor = get_sv(form("%_::_ladspa_descriptor",package),1);
    sv_setiv(store_descriptor,PTR2IV(desc));
    SvREADONLY_on(store_descriptor);

    return package;
}

/*
    loads a ladspa plugin shared library into a given package
    will make it inherit from Audio::LADSPA::Library and
    call setup_plugin() on all plugin descriptors found
*/

void load_lib_to_package(SV* self, const char* filename, const char* package) {
    int i;
    const LADSPA_Descriptor * desc = NULL;
    AV* plugins_array;
    SV* store_descriptor;
    SV* store_filename;
    SV* store_handle;
    AV* isa_array;
    LADSPA_Descriptor_Function descF;

    /* try to open the library and get the descriptor function */
    
    void* handle = dlopen(filename, RTLD_NOW);
    if (handle == NULL) {
        croak("Error loading %s into package %s: %s",filename,package,dlerror());
    }

    dlerror();
    descF = (LADSPA_Descriptor_Function)dlsym(handle, "ladspa_descriptor");
    if (!descF) {
        const char * pcError = dlerror();
        if (pcError) {
            croak( 
                    "Unable to find ladspa_descriptor() function in library: %s."
                    "Are you sure this is a LADSPA plugin file?", 
                    pcError);
        }
    }

    
    isa_array = (AV*) get_av(form("%s::ISA",package),1); /* @package::ISA */
    av_push(isa_array,newSVpvn("Audio::LADSPA::Library",22));

    /* store the dlopen handle in $library_package::_ladspa_handle */

    store_handle = get_sv(form("%s::_ladspa_handle",package),1);  /* create handle */
    sv_setiv(store_handle, PTR2IV(handle));
    SvREADONLY_on(store_handle);

    /* store the filename of the library in $library_package::LIBRARY_FILE */

    store_filename = get_sv(form("%s::LIBRARY_FILE",package),1);
    sv_setpvn(store_filename,filename,strlen(filename));
    SvREADONLY_on(store_filename);

    /* store descriptor function */

    store_descriptor = get_sv(form("%s::_ladspa_descriptor_function",package),1);
    sv_setiv(store_descriptor, PTR2IV(descF));
    SvREADONLY_on(store_descriptor);

    /* create plugin classes, and store their names in @library_package::PLUGINS */
    
    plugins_array = get_av(form("%s::PLUGINS",package),1);
    i = 0;
    while (desc = descF(i++), desc != NULL) {
    	av_push(plugins_array,setup_plugin(desc,filename));
    
    }
}

/*
    unload a library given the package that contains its handle.
    this is a dangerous action if there are *any* plugins or
    plugin-classes still loaded, so by default, the Audio::LADSPA
    module will call this only in an END block.
*/

void unload(SV* self,const char* package) {
    SV* store_handle = get_sv(form("%s::_ladspa_handle",package),0);
    if (store_handle && SvREADONLY(store_handle) && SvIOK(store_handle)) {
        void * handle = INT2PTR(void *, SvIVX(store_handle));
	if (handle)
	    dlclose(handle);
    }
}

MODULE = Audio::LADSPA::LibraryLoader PACKAGE = Audio::LADSPA::LibraryLoader

PROTOTYPES: DISABLE

void
load_lib_to_package(self, filename, package)
    SV* self
    const char* filename
    const char* package

void
unload(self, package)
    SV* self
    const char* package


    
