# Initialize and destroy an instance to the library
use Test2::Bundle::More;
use Test::Alien 0.05;
use Alien::raylib5;

# windows.h (included via perl.h) and the raylib.h header clash,
# thus skip this test
skip_all "Test skipped"
  if 1
  or $^O eq 'MSWin32' and not $ENV{ALIEN_RAYLIB_FORCE_TEST_HEADER};

alien_ok 'Alien::raylib5';
my $xs = do { local $/; <DATA> };
diag "Trying out GetRandomValue via header";
xs_ok { xs => $xs, verbose => 1 }, with_subtest {
    my $r = My::Raylib::xs_rand( 42, 45 );
    ok 42 <= $r && $r <= 45;

};

done_testing;

__DATA__

#ifdef _WIN32
#define NOGDICAPMASKS     // CC_*, LC_*, PC_*, CP_*, TC_*, RC_
#define NOVIRTUALKEYCODES // VK_*
#define NOWINMESSAGES     // WM_*, EM_*, LB_*, CB_*
#define NOWINSTYLES       // WS_*, CS_*, ES_*, LBS_*, SBS_*, CBS_*
#define NOSYSMETRICS      // SM_*
#define NOMENUS           // MF_*
#define NOICONS           // IDI_*
#define NOKEYSTATES       // MK_*
#define NOSYSCOMMANDS     // SC_*
#define NORASTEROPS       // Binary and Tertiary raster ops
#define NOSHOWWINDOW      // SW_*
#define OEMRESOURCE       // OEM Resource values
#define NOATOM            // Atom Manager routines
#define NOCLIPBOARD       // Clipboard routines
#define NOCOLOR           // Screen colors
#define NOCTLMGR          // Control and Dialog routines
#define NODRAWTEXT        // DrawText() and DT_*
#define NOGDI             // All GDI defines and routines
#define NOKERNEL          // All KERNEL defines and routines
#define NOUSER            // All USER defines and routines
/*#define NONLS             // All NLS defines and routines*/
#define NOMB              // MB_* and MessageBox()
#define NOMEMMGR          // GMEM_*, LMEM_*, GHND, LHND, associated routines
#define NOMETAFILE        // typedef METAFILEPICT
#define NOMINMAX          // Macros min(a,b) and max(a,b)
#define NOMSG             // typedef MSG and associated routines
#define NOOPENFILE        // OpenFile(), OemToAnsi, AnsiToOem, and OF_*
#define NOSCROLL          // SB_* and scrolling routines
#define NOSERVICE         // All Service Controller routines, SERVICE_ equates, etc.
#define NOSOUND           // Sound driver routines
#define NOTEXTMETRIC      // typedef TEXTMETRIC and associated routines
#define NOWH              // SetWindowsHook and WH_*
#define NOWINOFFSETS      // GWL_*, GCL_*, associated routines
#define NOCOMM            // COMM driver routines
#define NOKANJI           // Kanji support stuff.
#define NOHELP            // Help engine interface.
#define NOPROFILER        // Profiler interface.
#define NODEFERWINDOWPOS  // DeferWindowPos routines
#define NOMCX             // Modem Configuration Extensions

/* Type required before windows.h inclusion  */
typedef struct tagMSG *LPMSG;

#include <windows.h>

/* Type required by some unused function...  */
typedef struct tagBITMAPINFOHEADER {
  DWORD biSize;
  LONG  biWidth;
  LONG  biHeight;
  WORD  biPlanes;
  WORD  biBitCount;
  DWORD biCompression;
  DWORD biSizeImage;
  LONG  biXPelsPerMeter;
  LONG  biYPelsPerMeter;
  DWORD biClrUsed;
  DWORD biClrImportant;
} BITMAPINFOHEADER, *PBITMAPINFOHEADER;

#include <objbase.h>
#include <mmreg.h>
#include <mmsystem.h>

/* @raysan5: Some required types defined for MSVC/TinyC compiler */
#if defined(_MSC_VER) || defined(__TINYC__)
    #include "propidl.h"
#endif
#endif

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include <raylib.h>

int xs_rand(int min, int max)
{
    return GetRandomValue(min, max);
}

int __cpu_model;

MODULE = My::Raylib PACKAGE = My::Raylib

int xs_rand(min, max);
 int min;
 int max;


