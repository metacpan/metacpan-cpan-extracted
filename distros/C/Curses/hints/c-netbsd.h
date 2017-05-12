/*  Hint file for the NETBSD platform.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* These hints thanks to matthew green <mrg@mame.mu.oz.au> */

/* Note to NETBSD users: I have gotten several conflicting reports
 * about the correct number of arguments for longname() and
 * touchline().  You may have to look them up and edit this file to
 * reflect the reality for your system.
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

#define C_LONGNAME      /* Does longname() exist?               */
#define C_LONG0ARGS     /* Does longname() take 0 arguments?    */
#undef  C_LONG2ARGS     /* Does longname() take 2 arguments?    */

#define C_TOUCHLINE     /* Does touchline() exist?              */
#define C_TOUCH3ARGS    /* Does touchline() take 3 arguments?   */
#undef  C_TOUCH4ARGS    /* Does touchline() take 4 arguments?   */
