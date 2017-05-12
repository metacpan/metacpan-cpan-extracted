/*  Hint file for the OSF1 platform.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* These hints thanks to Lamont Granquist <lamontg@becker1.u.washington.edu> */

#include <curses.h>
/* #include <term.h> */

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

#undef  C_TOUCHLINE
#undef  C_TOUCH3ARGS
#undef  C_TOUCH4ARGS
