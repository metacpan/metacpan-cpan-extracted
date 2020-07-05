#include <stdio.h>

#define IMPORT_BAR_BAZ __attribute__((import_module("Bar::Baz")))

IMPORT_BAR_BAZ extern int answer();

int
main()
{
  printf("perl reports the answer to life, the universe and everything is: %d\n", answer());
}
