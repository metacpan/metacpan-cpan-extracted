#include <stdio.h>
#include <stdlib.h>
#include <unistd.h>
#include <errno.h>
#include <string.h>

int main(int argc, char* argv[]) {
    execvp( "app_dispatch", argv );
    printf( "Could not exec 'app_dispatch': %s\n", strerror(errno) );
    exit(errno);
}

