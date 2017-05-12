/*  Hint file for the Cygwin platform.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* These hints thanks to Federico Spinazzi <spinazzi@databankgroup.it>
   (2001) and yselkowitz@users.sourceforge.net (October 2005)
*/

#include <ncurses.h>

#ifdef C_PANELFUNCTION
#include <panel.h>
#endif

#ifdef C_MENUFUNCTION
#include <menu.h>
#endif

#ifdef C_FORMFUNCTION
#include <form.h>
#endif

#undef  C_LONGNAME
#undef  C_LONG0ARGS
#undef  C_LONG2ARGS

#undef  C_TOUCHLINE
#undef  C_TOUCH3ARGS
#undef  C_TOUCH4ARGS
