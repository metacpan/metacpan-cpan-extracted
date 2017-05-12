/* -*- mode: C++; c-file-style: "bsd" -*- */

#include "pmico.h"
#include "dispatcher.h"

PMicoDispatcherCallback::~PMicoDispatcherCallback ()
{
    SvREFCNT_dec (_callback);
    SvREFCNT_dec (_args);
}
  
void
PMicoDispatcherCallback::callback (CORBA::Dispatcher *dispatcher, CORBA::Dispatcher::Event event)
{
    const char *ev;

    switch (event) {
    case CORBA::Dispatcher::Timer:
	ev = "Timer";
	break;
    case CORBA::Dispatcher::Read:
	ev = "Read";
	break;
    case CORBA::Dispatcher::Write:
	ev = "Write";
	break;
    case CORBA::Dispatcher::Except:
	ev = "Write";
	break;
    case CORBA::Dispatcher::All:
	ev = "All"; /* Should never get here? */
	break;
    case CORBA::Dispatcher::Remove:
	ev = "Remove";
	break;
    case CORBA::Dispatcher::Moved:
	ev = "Moved";
	break;
    }
    
    dSP;
  
    ENTER;
    SAVETMPS;

    PUSHMARK(sp);

    XPUSHs(sv_2mortal(newSVpv((char *)ev, 0)));
    for (int i=0; i<av_len(_args); i++)
	XPUSHs(sv_2mortal(newSVsv(*av_fetch(_args,i,0))));

    PUTBACK;

    perl_call_sv(_callback, G_DISCARD);

    FREETMPS;
    LEAVE;
}


