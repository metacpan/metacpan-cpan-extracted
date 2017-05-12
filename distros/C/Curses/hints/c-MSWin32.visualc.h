/*  Hint file for the MSWin32 platform, Visual C compiler.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* These hints thanks to Gurusamy Sarathy <gsar@engin.umich.edu> */

/* We used to include <pdcurses.h>, but users found it is actually
   installed as <curses.h>.  Maybe it changed at some point.
   2007.09.29
*/
/* We used to undef macro SP, (which is defined by perl.h), but in September
   2007, we found that a) SP is needed; and 2) SP doesn't hurt
   the #includes below.
*/

#include <curses.h>

#ifdef C_PANELFUNCTION
#include <panel.h>
#endif

#ifdef C_MENUFUNCTION
#include <menu.h>
#endif

#ifdef C_FORMFUNCTION
#include <form.h>
#endif

#define C_LONGNAME
#define C_LONG0ARGS
#undef  C_LONG2ARGS

#define C_TOUCHLINE
#define C_TOUCH3ARGS
#undef  C_TOUCH4ARGS
