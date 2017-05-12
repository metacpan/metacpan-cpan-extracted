#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

/*dont run CRT init code on MSVC, see note in API.xs*/
#ifdef _MSC_VER
BOOL WINAPI _DllMainCRTStartup(
#else
BOOL WINAPI DllMain(
#endif
    HINSTANCE hinstDLL,
    DWORD fdwReason,
    LPVOID lpReserved )
{
    return TRUE;
}

MODULE = Win32::PEPM::Test		PACKAGE = Win32::PEPM::Test

PROTOTYPES: DISABLE

void
hello_world()
CODE:
    PerlIO_printf(PerlIO_stderr(), "Hello world from XS\n");

void
time()
CODE:
    PerlIO_printf(PerlIO_stderr(), __DATE__ " " __TIME__ "\n");
