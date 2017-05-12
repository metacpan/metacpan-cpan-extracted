/*  Hint file for VMS.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* These hints thanks to Peter Prymmer <pvhp@forte.com> */

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
#undef  C_LONG0ARGS
#define C_LONG2ARGS

#undef  C_TOUCHLINE
#undef  C_TOUCH3ARGS
#undef  C_TOUCH4ARGS

#define cbreak()   crmode()
#define nocbreak() nocrmode()
