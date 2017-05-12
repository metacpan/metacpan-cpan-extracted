/* show.c - show the contents of a sysctl variable
 * Copyright (C) 2006 David Landgren, all rights reserved.
 */

#include <stdio.h>
#include <sys/types.h>
#include <sys/sysctl.h>

#include <sys/time.h>     /* clockinfo struct */
#include <sys/vmmeter.h>  /* vmtotal struct */
#include <sys/resource.h> /* loadavg struct */

void show(const char *arg) {
    int mib[CTL_MAXNAME];
    size_t miblen = (sizeof(mib)/sizeof(mib[0]));

    char buf[BUFSIZ];
    int buflen = BUFSIZ;

    int qoid[CTL_MAXNAME+2];
    unsigned char mibfmt[BUFSIZ];
    int mibfmtlen = sizeof(mibfmt);
    char *f = mibfmt;
    int j;

    if (sysctlnametomib(arg, mib, &miblen) == -1) {
        return;
    }

    if (sysctl(mib, miblen, buf, &buflen, NULL, 0) == -1) {
        return;
    }

    qoid[0] = 0;
    qoid[1] = 4;
    memcpy(qoid+2, mib, miblen * sizeof(int));
    if (sysctl(qoid, miblen+2, mibfmt, &mibfmtlen, NULL, 0) == -1) {
        return;
    }
    f += sizeof(unsigned int);

    printf( "%s %s\n", arg, f );
}

int main(int argc, char **argv) {
    while(--argc) {
        const char *arg;
        arg = *++argv;
        show(arg);
    }
    exit(0);
}
