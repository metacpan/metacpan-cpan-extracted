/*  Hint file for the NeXT platform.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* These hints thanks to Anno Siegel <anno4000@w172zrz.zrz.tu-berlin.d400.de>*/

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

#define C_TOUCHLINE
#undef  C_TOUCH3ARGS
#define C_TOUCH4ARGS
