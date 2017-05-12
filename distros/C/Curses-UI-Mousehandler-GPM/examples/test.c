
#include "handler-gpm.h"
#include <stdlib.h>
#include <stdio.h>

int main(int argc, char* argv[]) {
  int retval;
  MEVENT* eventp;
  MEVENT event;

  retval = gpm_enable();
  printf("Gpm_enable: %d\n", retval);

  if (!retval) {
    exit (0);
  }

  while (1) {
    eventp = gpm_get_mouse_event(&event);
    if (eventp != NULL) {
      printf("Event: x=%d,y=%d,buttons=%ld\n", eventp->x, eventp->y, 
	     (long)eventp->bstate);
    }
  }
}
