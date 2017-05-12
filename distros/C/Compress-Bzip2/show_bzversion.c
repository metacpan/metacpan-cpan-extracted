#include <stdio.h>

#include <bzlib.h>

/****************************************************
 * This is a simple program to
 * 1. test the bzip2 installation
 *    - if it compiles and links, we're in
 * 2. run this to get the bzip2 version string
 ****************************************************/

int main(void) {
  printf("%s\n", BZ2_bzlibVersion());
}
