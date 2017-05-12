/* This is a program that 'test.syms' test-compiles to determine if a type
   is defined in curses.h.

   'test.syms' defines macro SYM on the compile command.
*/

#define _XOPEN_SOURCE_EXTENDED  /* We expect wide character functions */

#include "c-config.h"

main() {
  typedef SYM c_sym_t;
}
