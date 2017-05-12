#ifndef AUDIO_LADSPA_BUFFER_H
#define AUDIO_LADSPA_BUFFER_H

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


typedef struct audio_ladspa_buffer_s {
    unsigned long size;
    unsigned long filled;
    LADSPA_Data * data;
} Audio_LADSPA_Buffer_t;

typedef Audio_LADSPA_Buffer_t* Audio_LADSPA_Buffer;



#endif

