#include "pomni.h"

#ifdef __WIN32__
#define vsnprintf _vsnprintf
#endif

/*!
 * uses omniORB::logger (debug level Info) to log messages
 */ 
void 
cm_log( const char* format, ... ) 
{
    if( omniORB::trace(5) ) {
#define LOGBUF_SIZE	500
	char buf[LOGBUF_SIZE];
	omniORB::logger l("CM: ");
	
	va_list ap;
	va_start(ap, format);
	vsnprintf( buf, LOGBUF_SIZE, format, ap);
	va_end(ap);
	l << buf;
    }
}
