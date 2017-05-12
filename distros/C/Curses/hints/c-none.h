/* Change <curses.h> below to the proper "include" file for curses. */
#include <curses.h>

/* Change <panel.h> below to the proper "include" file for panels. */
#ifdef C_PANELFUNCTION
#include <panel.h>
#endif

/* Change <menu.h> below to the proper "include" file for menus. */
#ifdef C_MENUFUNCTION
#include <menu.h>
#endif

/* Change <form.h> below to the proper "include" file for forms. */
#ifdef C_FORMFUNCTION
#include <form.h>
#endif

/* Change each #undef below to #define if the answer to the question
 * beside it is "yes".
 */
#undef  C_LONGNAME	/* Does longname() exist?		*/
#undef  C_LONG0ARGS	/* Does longname() take 0 arguments?	*/
#undef  C_LONG2ARGS	/* Does longname() take 2 arguments?	*/

#undef  C_TOUCHLINE	/* Does touchline() exist?		*/
#undef  C_TOUCH3ARGS	/* Does touchline() take 3 arguments?	*/
#undef  C_TOUCH4ARGS	/* Does touchline() take 4 arguments?	*/

/* Some Curses include files have problems interacting with perl,
 * some are missing basic functionality, and some just plain do
 * weird things.  Unfortunately, there's no way to anticipate all
 * of the problems the curses include file + "perl.h" might create.
 *
 * If you find that you can't compile Curses.c because of these
 * conflicts, you should insert C code before and after the "include"
 * file above to try and fix the problems.  "See c-sunos.sysv.h"
 * for an example of this.
 */

