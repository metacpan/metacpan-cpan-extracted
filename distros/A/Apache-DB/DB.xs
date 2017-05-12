#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#ifdef WIN32
#define SIGINT 2
#endif

static void my_init_debugger()
{
    dTHR;
    PL_curstash = PL_debstash;
    PL_dbargs = 
	GvAV(gv_AVadd((gv_fetchpv("DB::args", GV_ADDMULTI, SVt_PVAV))));
    AvREAL_off(PL_dbargs);
    PL_DBgv = gv_fetchpv("DB::DB", GV_ADDMULTI, SVt_PVGV);
    PL_DBline = gv_fetchpv("DB::dbline", GV_ADDMULTI, SVt_PVAV);
    PL_DBsub = gv_HVadd(gv_fetchpv("DB::sub", GV_ADDMULTI, SVt_PVHV));
    PL_DBsingle = GvSV((gv_fetchpv("DB::single", GV_ADDMULTI, SVt_PV)));
    sv_setiv(PL_DBsingle, 0); 
    PL_DBtrace = GvSV((gv_fetchpv("DB::trace", GV_ADDMULTI, SVt_PV)));
    sv_setiv(PL_DBtrace, 0); 
    PL_DBsignal = GvSV((gv_fetchpv("DB::signal", GV_ADDMULTI, SVt_PV)));
    sv_setiv(PL_DBsignal, 0); 
    PL_curstash = PL_defstash;

}

static Sighandler_t ApacheSIGINT = NULL;

MODULE = Apache::DB		PACKAGE = Apache::DB		

PROTOTYPES: DISABLE

BOOT:
    ApacheSIGINT = rsignal_state(whichsig("INT"));

int
init_debugger()

    CODE:
    if (!PL_perldb) {
	PL_perldb = PERLDB_ALL;
	my_init_debugger();
	RETVAL = TRUE;
    }
    else 
	RETVAL = FALSE;

    OUTPUT:
    RETVAL

MODULE = Apache::DB            PACKAGE = DB

void
ApacheSIGINT(...)

    CODE:
#if ((PERL_REVISION == 5) && (PERL_VERSION >= 10))
    if (ApacheSIGINT) (*ApacheSIGINT)(SIGINT, NULL, NULL); 
#else 
    if (ApacheSIGINT) (*ApacheSIGINT)(SIGINT);
#endif 
