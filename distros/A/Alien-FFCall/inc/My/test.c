#include <stdio.h>
#include <avcall.h>

int
main(int argc, char *argv[])
{
  printf("version=%d.%d\n", LIBFFCALL_VERSION >> 8, LIBFFCALL_VERSION & 0xff);
  return 0;
}
