#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include <alpm.h>
#include "cb.h"

SV * logcb_ref, * dlcb_ref, * totaldlcb_ref, * fetchcb_ref;

void c2p_logcb(alpm_loglevel_t lvl, const char * fmt, va_list args)
{
	SV * svlvl, * svmsg;
	const char *str;
	char buf[256];
	dSP;

	if(!logcb_ref) return;

	/* convert log level bitflag to a string */
	switch(lvl){
	case ALPM_LOG_ERROR: str = "error"; break;
	case ALPM_LOG_WARNING: str = "warning"; break;
	case ALPM_LOG_DEBUG: str = "debug"; break;
	case ALPM_LOG_FUNCTION: str = "function"; break;
	default: str = "unknown"; break;
	}

	ENTER;
	SAVETMPS;

	/* We can't use sv_vsetpvfn because it doesn't like j's: %jd or %ji, etc... */
	svlvl = sv_2mortal(newSVpv(str, 0));
	vsnprintf(buf, 255, fmt, args);
	svmsg = sv_2mortal(newSVpv(buf, 0));
	
	PUSHMARK(SP);
	XPUSHs(svlvl);
	XPUSHs(svmsg);
	PUTBACK;

	call_sv(logcb_ref, G_DISCARD);

	FREETMPS;
	LEAVE;
	return;
}

void
c2p_dlcb(const char * name, off_t curr, off_t total)
{
	SV * svname, * svcurr, * svtotal;
	dSP;

	if(!dlcb_ref){
		return;
	}

	ENTER;
	SAVETMPS;
	svname = sv_2mortal(newSVpv(name, 0));
	svcurr = sv_2mortal(newSViv(curr));
	svtotal = sv_2mortal(newSViv(total));

	PUSHMARK(SP);
	XPUSHs(svname);
	XPUSHs(svcurr);
	XPUSHs(svtotal);
	PUTBACK;
	call_sv(dlcb_ref, G_DISCARD);

	FREETMPS;
	LEAVE;
	return;
}

int
c2p_fetchcb(const char * url, const char * dest, int force)
{
	SV * svret;
	int ret;
	dSP;

	if(!fetchcb_ref){
		return -1;
	}

	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 3);
	PUSHs(sv_2mortal(newSVpv(url, 0)));
	PUSHs(sv_2mortal(newSVpv(dest, 0)));
	PUSHs(sv_2mortal(newSViv(force)));
	PUTBACK;

	ret = 0;
	if(call_sv(fetchcb_ref, G_SCALAR | G_EVAL) == 1){
		svret = POPs;
		if(SvTRUE(ERRSV)){
			/* the callback died, return an error to libalpm */
			ret = -1;
		}else{
			ret = (SvTRUE(svret) ? 1 : 0);
		}
	}

	FREETMPS;
	LEAVE;
	return ret;
}

void
c2p_totaldlcb(off_t total)
{
	dSP;
	if(!totaldlcb_ref){
		return;
	}
	ENTER;
	SAVETMPS;

	PUSHMARK(SP);
	EXTEND(SP, 1);
	PUSHs(sv_2mortal(newSViv(total)));
	PUTBACK;
	call_sv(totaldlcb_ref, G_DISCARD);

	FREETMPS;
	LEAVE;
	return;
	
}

