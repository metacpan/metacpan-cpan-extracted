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


#ifndef HANDLER_GPM_C
#define HANDLER_GPM_C

#include "handler-gpm.h"

#include <gpm.h>
#include <curses.h>

#include <sys/select.h>
#include <stdlib.h>
#include <limits.h>

static int mouse_enabled = 0;

int gpm_enable (void) {
  int mouse_d;
  Gpm_Connect conn;

  conn.eventMask   = ~GPM_MOVE;
  conn.defaultMask = GPM_MOVE;
  conn.minMod      = 0;
  conn.maxMod      = 0;

  mouse_d = Gpm_Open (&conn, 0);
  if (mouse_d == -1) {
        return 0;
   }
  mouse_enabled = 1;
  return 1;
}

void __gpm_to_curses(Gpm_Event ev, MEVENT* event) {
  switch (ev.buttons) {
  case GPM_B_LEFT:
    switch (ev.type) {
    case (GPM_UP + GPM_SINGLE): event->bstate = BUTTON1_RELEASED; break;
    case (GPM_DOWN + GPM_SINGLE): event->bstate = BUTTON1_CLICKED; break;
    case (GPM_DOWN + GPM_DOUBLE): event->bstate = BUTTON1_DOUBLE_CLICKED; break;
    case (GPM_DOWN + GPM_TRIPLE): event->bstate = BUTTON1_DOUBLE_CLICKED; break;
    default: event->bstate = BUTTON1_CLICKED; break;
    }
    break;

  case GPM_B_MIDDLE:
    switch (ev.type) {
    case (GPM_UP + GPM_SINGLE): event->bstate = BUTTON2_RELEASED; break;
    case (GPM_DOWN + GPM_SINGLE): event->bstate = BUTTON2_CLICKED; break;
    case (GPM_DOWN + GPM_DOUBLE): event->bstate = BUTTON2_DOUBLE_CLICKED; break;
    case (GPM_DOWN + GPM_TRIPLE): event->bstate = BUTTON2_DOUBLE_CLICKED; break;
    default: event->bstate = BUTTON3_CLICKED; break;
    }
    break;

  case GPM_B_RIGHT:
    switch (ev.type) {
    case (GPM_UP + GPM_SINGLE): event->bstate = BUTTON3_RELEASED; break;
    case (GPM_DOWN + GPM_SINGLE): event->bstate = BUTTON3_CLICKED; break;
    case (GPM_DOWN + GPM_DOUBLE): event->bstate = BUTTON3_DOUBLE_CLICKED; break;
    case (GPM_DOWN + GPM_TRIPLE): event->bstate = BUTTON3_DOUBLE_CLICKED; break;
    default: event->bstate = BUTTON3_CLICKED; break;
    }
    break;
  }
}


MEVENT* gpm_get_mouse_event( MEVENT* event )
{
    struct Gpm_Event ev;	/* Mouse event */
    struct timeval timeout;
    struct timeval *time_addr = NULL;
    
    int flag;
    fd_set select_set;

    if (!mouse_enabled) {
      return NULL;
    }

    FD_ZERO (&select_set);

    if (gpm_fd < 0) {
	mouse_enabled = 0;
	return NULL;
     } else {
	FD_SET (gpm_fd, &select_set);
     }

    time_addr = &timeout;
    timeout.tv_sec = 0;
    timeout.tv_usec = 200;

    flag = select (gpm_fd + 1, &select_set, NULL, NULL, time_addr);

    if (flag <= 0) {
	return NULL;
    }

    if (gpm_fd > 0 && FD_ISSET (gpm_fd, &select_set)) {
	    Gpm_GetEvent (&ev);
	    Gpm_FitEvent (&ev);
	    Gpm_DrawPointer (ev.x, ev.y, gpm_consolefd);
	    event->id = 0;
	    event->x = ev.x -1;
	    event->y = ev.y -1;
	    __gpm_to_curses(ev, event);
	    return event;
      }

    return NULL;
}

#endif
