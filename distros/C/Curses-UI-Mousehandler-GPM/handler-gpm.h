/* Copyright (C) 2004 by Marcis Thiesen (marcus@thiesen.org
Roughly based on MC mouse.c, Copyright (C) 1994 Miguel de Icaza.
and key.c written by: 1994, 1995 Miguel de Icaza.
                      1994, 1995 Janne Kukonlehto.
	              1995  Jakub Jelinek.
	              1997  Norbert Warmuth

   This program is free software; you can redistribute it and/or modify
   it under the terms of the GNU General Public License as published by
   the Free Software Foundation; either version 2 of the License, or
   (at your option) any later version.
   
   This program is distributed in the hope that it will be useful,
   but WITHOUT ANY WARRANTY; without even the implied warranty of
   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
   GNU General Public License for more details.

   You should have received a copy of the GNU General Public License
   along with this program; if not, write to the Free Software
   Foundation, Inc., 59 Temple Place - Suite 330, Boston, MA 02111-1307, USA.  */

#ifndef HANDLER_GPM_H
#define HANDLER_GPM_H
#ifdef instr
#undef instr
#endif
#include <curses.h>

MEVENT* gpm_get_mouse_event( MEVENT* in_event );
int gpm_enable( void );


#endif
