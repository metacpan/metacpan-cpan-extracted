/* This is a program that 'testsyms' test-compiles to determine if a function
   has an integer return value.

   'testsyms' defines macro SYM on the compile command.
*/

#define _XOPEN_SOURCE_EXTENDED 1  /* We expect wide character functions */

#include "config.h"
#include "c-config.h"

int
main() {
  int ret;

  ret = SYM;
}
