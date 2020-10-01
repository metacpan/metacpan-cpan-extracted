#include <stdio.h>

#ifndef VERSION
#define VERSION "unspecified"
#endif

/* main */
int main (void) {
	printf( "Hello world! Version: %s\n", VERSION);
	return 0;
}
