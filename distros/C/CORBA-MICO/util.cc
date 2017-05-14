#include "pmico.h"
#include <mico/util.h>

/*!
 * uses MICO::Logger (debug level Info) to log messages
 */ 
void 
cm_log( const char* format, ... ) 
{
#define LOGBUF_SIZE	500
    char buf[LOGBUF_SIZE];
    
    if (MICO::Logger::IsLogged (MICO::Logger::Info)) {
      va_list ap;
      va_start(ap, format);
      vsnprintf( buf, LOGBUF_SIZE, format, ap);
      va_end(ap);
      MICOMT::AutoDebugLock __lock;
      MICO::Logger::Stream (MICO::Logger::Info) << "(CM) " << buf;
    }
}

/*!
 * mutex to serialize servant calls from MICO
 */
MICOMT::Mutex cmPerlEntryLock;
