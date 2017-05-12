/*  Hint file for the SunOS platform, SysV version of libcurses.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

/* The combined set of lines below between * vvvv * and * ^^^^ *
 * below is one example of how to fix compiler errors between the
 * curses include file and the perl include files.  It turns out that
 * for the SunOS platform, SysV curses, there were these problems:
 *
 * 1) sprintf() was declared as returning different types in <curses.h>
 *    and "perl.h"
 * 3) Lots of redefined warnings, because <sys/ioctl.h> was included by
 *    both <curses.h> and "perl.h"
 *
 * You can see by looking at the fixes how each problem was resolved.
 *
 * Note that "perl.h" is always included after this file when deciding
 * how to fix the conflicts.
 */

/* vvvv */
#define sprintf stupid_stupid_stupid
/* ^^^^ */

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

/* vvvv */
#undef sprintf
#define _sys_ioctl_h
/* ^^^^ */

#define C_LONGNAME
#define C_LONG0ARGS
#undef  C_LONG2ARGS

#define C_TOUCHLINE
#define C_TOUCH3ARGS
#undef  C_TOUCH4ARGS
