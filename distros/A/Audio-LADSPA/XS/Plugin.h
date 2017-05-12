#ifndef AUDIO_LADSPA_PLUGIN_H
#define AUDIO_LADSPA_PLUGIN_H

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


#include "perl.h"

typedef struct audio_ladspa_plugin_s {
    LADSPA_Descriptor* descriptor;
    LADSPA_Handle* handle;
    SV** buffers;
    unsigned long max_samples;
    int active;
    int ready;
    SV* monitor;
    SV* uniqid;
} Audio_LADSPA_Plugin_t;

typedef Audio_LADSPA_Plugin_t * Audio_LADSPA_Plugin;

#endif

