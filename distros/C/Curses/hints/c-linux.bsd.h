/*  Hint file for the Linux platform, BSD version of libcurses.
 *
 *  If this configuration doesn't work, look at the file "c-none.h"
 *  for how to set the configuration options.
 */

#include <curses.h>

#undef  C_LONGNAME
#define C_LONG0ARGS
#undef  C_LONG2ARGS

#define C_TOUCHLINE
#undef  C_TOUCH3ARGS
#define C_TOUCH4ARGS
