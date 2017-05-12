
#include <mod_perl.h>

typedef request_rec *Apache2__RequestRec;

MODULE = Apache2::RequestRec::Time	PACKAGE = Apache2::RequestRec	PREFIX = mpxs_Apache2__RequestRec_

double
mpxs_Apache2__RequestRec_request_duration_microseconds(r)
		Apache2::RequestRec r
	CODE:
		RETVAL = (double)(apr_time_now() - r->request_time);
	OUTPUT:
		RETVAL

long
mpxs_Apache2__RequestRec_request_duration(r)
		Apache2::RequestRec r
	CODE:
		apr_time_t duration = apr_time_now() - r->request_time;
		RETVAL = apr_time_sec(duration);
	OUTPUT:
		RETVAL

double
mpxs_Apache2__RequestRec_request_time_microseconds(r)
		Apache2::RequestRec r
	CODE:
		RETVAL = (double)(r->request_time);
	OUTPUT:
		RETVAL

