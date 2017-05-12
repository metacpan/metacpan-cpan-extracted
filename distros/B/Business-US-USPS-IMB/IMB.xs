#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <./libs/usps4cb.h>

MODULE = Business::US::USPS::IMB		PACKAGE = Business::US::USPS::IMB		

int
usps4cb(TrackPtr, RoutePtr, BarPtr)
		char *	TrackPtr
		char *	RoutePtr
		char *	BarPtr
	OUTPUT:
		RETVAL
		BarPtr
