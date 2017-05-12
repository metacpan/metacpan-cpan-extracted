// ace.h
//
// Main header for file ACE.xs

// Dont always have RSA headers:
#define SD_NO_RSA

#define USE_ACE_AGENT_API_PROTOTYPES
#if defined UNIX && SD_VERSION == 4
#include "sdtype.h"
#include "sdsize.h"
#endif

#if defined WIN32
#include <windows.h>
#endif

#include "acexport.h"



