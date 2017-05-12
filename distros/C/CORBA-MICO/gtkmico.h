// -*- c++ -*-
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

#ifndef __mico_gtk_h__
#define __mico_gtk_h__

#include <gtk/gtk.h>

struct GtkFunctions {
    gint  (*gtk_main_iteration) (void);
    guint (*gtk_timeout_add)	(guint32           interval,
				 GtkFunction	   function,
				 gpointer	   data);
    void  (*gtk_timeout_remove)	(guint	           timeout_handler_id);
    gint  (*gdk_input_add)      (gint		   source,
			         GdkInputCondition condition,
			         GdkInputFunction  function,
				 gpointer	   data);
    void  (*gdk_input_remove)   (gint		   tag);
};

class GtkDispatcher : public CORBA::Dispatcher {

    struct FileEvent {
        GtkDispatcher *disp;
        gint tag;
	CORBA::DispatcherCallback *cb;
	Event ev;

	FileEvent () {}
	FileEvent (GtkDispatcher *_disp, gint _tag, 
		   CORBA::DispatcherCallback *_cb, Event _ev)
	    : disp (_disp), tag (_tag), cb (_cb), ev (_ev)
	{}
    };
    struct TimerEvent {
        GtkDispatcher *disp;
        guint tag;
	CORBA::DispatcherCallback *cb;

	TimerEvent () {}
	TimerEvent (GtkDispatcher *_disp, guint _tag, 
		    CORBA::DispatcherCallback *_cb)
	    : disp (_disp), tag (_tag), cb (_cb)
	{}
    };
    list<FileEvent *>  fevents;
    list<TimerEvent *> tevents;
    GtkFunctions       funcs;

    static void input_callback (gpointer, int, GdkInputCondition);
    static int timer_callback (gpointer);
public:
    GtkDispatcher (GtkFunctions *_funcs);
    virtual ~GtkDispatcher ();

    virtual void rd_event (CORBA::DispatcherCallback *, CORBA::Long fd);
    virtual void wr_event (CORBA::DispatcherCallback *, CORBA::Long fd);
    virtual void ex_event (CORBA::DispatcherCallback *, CORBA::Long fd);
    virtual void tm_event (CORBA::DispatcherCallback *, CORBA::ULong tmout);
    virtual void remove (CORBA::DispatcherCallback *, Event);
    virtual void run (CORBA::Boolean infinite = TRUE);
    virtual void move (CORBA::Dispatcher *);
    virtual CORBA::Boolean idle () const;
};

#endif __mico_gtk_h__
