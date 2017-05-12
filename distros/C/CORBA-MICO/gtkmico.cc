/*
 *  MICO --- a CORBA 2.0 implementation
 *  Copyright (C) 1997 Kay Roemer & Arno Puder
 *
 *  This program is free software; you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation; either version 2 of the License, or
 *  (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program; if not, write to the Free Software
 *  Foundation, Inc., 675 Mass Ave, Cambridge, MA 02139, USA.
 *
 *  Send comments and/or bug reports to:
 *                 mico@informatik.uni-frankfurt.de
 */

#undef bool

#include <CORBA.h>
#include <mico/template_impl.h>

#include "gtkmico.h"

void
GtkDispatcher::input_callback (gpointer _event, gint fd, GdkInputCondition o)
{
    FileEvent *event = (FileEvent *)_event;

    event->cb->callback (event->disp, event->ev);
}

gint
GtkDispatcher::timer_callback (gpointer _event)
{
    TimerEvent *event = (TimerEvent *)_event;
    GtkDispatcher *disp = event->disp;

    list<TimerEvent *>::iterator i;
    for (i = disp->tevents.begin(); i != disp->tevents.end(); ++i) {
        if ((*i) == event) {
	  disp->tevents.erase(i);
	  break;
	}
    }
    event->cb->callback (disp, Timer);
    delete event;

    return FALSE;
}

GtkDispatcher::GtkDispatcher (GtkFunctions *_funcs)
{
  funcs = *_funcs;
}

GtkDispatcher::~GtkDispatcher ()
{
    list<FileEvent *>::iterator i;
    for (i = fevents.begin(); i != fevents.end(); ++i) {
	(*i)->cb->callback (this, Remove);
	delete *i;
    }

    list<TimerEvent *>::iterator j;
    for (j = tevents.begin(); j != tevents.end(); ++j) {
	(*j)->cb->callback (this, Remove);
	delete *j;
    }
}

void
GtkDispatcher::rd_event (CORBA::DispatcherCallback *cb, CORBA::Long fd)
{
    FileEvent *ev = new FileEvent (this, 0, cb, Read);

    ev->tag = funcs.gdk_input_add (fd, GDK_INPUT_READ, 
				   input_callback, (gpointer)ev);
    fevents.push_back (ev);
}

void
GtkDispatcher::wr_event (CORBA::DispatcherCallback *cb, CORBA::Long fd)
{
    FileEvent *ev = new FileEvent (this, 0, cb, Write);

    ev->tag = funcs.gdk_input_add (fd, GDK_INPUT_WRITE, 
				   input_callback, (gpointer)ev);

    fevents.push_back (ev);
}

void
GtkDispatcher::ex_event (CORBA::DispatcherCallback *cb, CORBA::Long fd)
{
    FileEvent *ev = new FileEvent (this, 0, cb, Except);

    ev->tag = gdk_input_add (fd, GDK_INPUT_EXCEPTION, 
			     input_callback, (gpointer)ev);
    fevents.push_back (ev);
}

void
GtkDispatcher::tm_event (CORBA::DispatcherCallback *cb, CORBA::ULong tmout)
{
    TimerEvent *ev = new TimerEvent (this, 0, cb);

    ev->tag = funcs.gtk_timeout_add (tmout, timer_callback, (gpointer)ev);
    tevents.push_back (ev);
}

void
GtkDispatcher::remove (CORBA::DispatcherCallback *cb, Event e)
{
    if (e == All || e == Timer) {
	list<TimerEvent *>::iterator i, next;
	for (i = tevents.begin(); i != tevents.end(); i = next) {
	    next = i;
	    ++next;
	    if ((*i)->cb == cb) {
	        funcs.gtk_timeout_remove ((*i)->tag);
		delete *i;
		tevents.erase (i);
	    }
	}
    }
    if (e == All || e == Read || e == Write || e == Except) {
	list<FileEvent *>::iterator i, next;
	for (i = fevents.begin(); i != fevents.end(); i = next) {
	    next = i;
	    ++next;
	    if ((*i)->cb == cb && (e == All || e == (*i)->ev)) {
		funcs.gdk_input_remove ((*i)->tag);
		delete *i;
		fevents.erase (i);
	    }
	}
    }
}

void
GtkDispatcher::run (CORBA::Boolean infinite)
{
  do {
      funcs.gtk_main_iteration ();
  } while (infinite);
}

void
GtkDispatcher::move (CORBA::Dispatcher *)
{
    assert (0);
}

CORBA::Boolean
GtkDispatcher::idle () const
{
    return fevents.size() + tevents.size() == 0;
}

