/* c-isc.h:  Hint file for curses on Interactive System V, release 3.2.
   This was tested on version 3.01, but probably will work for most
   generic SysV curses.
   Andy Dougherty	doughera@lafcol.lafayette.edu
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


