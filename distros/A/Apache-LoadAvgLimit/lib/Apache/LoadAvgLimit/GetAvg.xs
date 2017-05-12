/* Apache::LoadAvgLimit::GetAvg */
#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <stdlib.h>
#ifdef __cplusplus
}
#endif

/* PROTOTYPES: DISABLE */
MODULE = Apache::LoadAvgLimit::GetAvg	PACKAGE = Apache::LoadAvgLimit::GetAvg

void
get_loadavg()
	PREINIT:
	double avenrun[3];
	char avg[3][8];
	int i;

	PPCODE:
	if (getloadavg(avenrun, sizeof(avenrun) / sizeof(avenrun[0])) != -1){
		EXTEND(SP, 3);
		for(i=0; i<=2; i++){
			sprintf(avg[i], "%.2f", avenrun[i]);
			PUSHs(sv_2mortal(newSVpv( avg[i], 0 )));
		}
	}

