/*
**  Copyright (C) 1998-2022 D&D Corporation. All Rights Reserved
**
**  This program is free software; you can redistribute it and/or
**  modify it under the same terms as Perl itself.
**
**  See <LICENSE> file and <https://dev.perl.org/licenses>
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "CTK.h"

#define PROGRAM_NAME "shred"
#define PROGRAM_VERSION "1.01"
#define AUTHORS "Serz Minus"

#define PASSES 3
#define BUFFSIZE 512

static char *
rnds(int n) {
    int pid = getpid();
    int i;
    static char rndch[BUFFSIZE];

    if (pid < 0) pid = pid * -1;
    pid += n;
    srand(pid % 255);

    for (i = 0; i < BUFFSIZE; i++) {
        rndch[i] = (rand() % 255);
    }

    return rndch;
}

static int
pass( int fd, off_t *sizep, int n) {
    off_t size = *sizep;
    off_t blksize = (off_t) BUFFSIZE;
    off_t blks = (off_t) 0;
    off_t blkn = (off_t) 0;
    off_t blka = size % blksize;
    ssize_t ssize; /* Return value from write */
    char *buf;
    if (blka == 0) {
        blks = size / blksize;
    } else {
        blks = (size - blka) / blksize;
    }

    if (lseek (fd, (off_t) 0, SEEK_SET) == -1) {
        fprintf(stderr, "Error. Can't rewind\n");
        fflush (stderr);
      return 0;
    }

    /* Loop to retry partial writes. */
    buf = rnds(n);
    for (blkn = 0; blkn < blks; blkn ++) {
        ssize = write (fd, buf, blksize);
    }
    if (blka > 0) {
        ssize = write (fd, buf, blka);
    }

    return 1;
}

static int
wipe(char *fn, size_t sz) {
    int fd;
    off_t size;
    size_t i;
    unsigned int n;

    fd = open (fn, O_WRONLY | O_NOCTTY);
    if (fd < 0) {
        fprintf(stderr, "Can't open file \"%s\": %s\n", fn, rerr);
        fflush (stderr);
        return 0;
    }

    size = sz;
    /* printf("SIZE: %d\n",size); */

    if (size < 0) {
        fprintf(stderr, "File \"%s\" has negative size\n", fn);
        fflush (stderr);
        return 0;
    }

    /* Do the work */
    n = PASSES;

    for (i = 0; i < n; i++) {
        if (pass(fd, &size, i))	{
            /*printf("Pass %d on %d\n", i+1, n);*/
        } else {
            /*printf("Fault %d on %d\n", i+1, n);*/
        }
    }

    if (close (fd) != 0) {
        fprintf(stderr, "Can't close \"%s\": %s\n", fn, rerr);
        fflush (stderr);
        return 0;
    }

    return 1;
}

MODULE = CTK    PACKAGE = CTK::UtilXS


SV *
xstest()
ALIAS:
    xsver = 1
CODE:
{
    RETVAL = newSVpv(PROGRAM_VERSION,0);
}
OUTPUT:
    RETVAL

int
wipef(str,sz)
    SV * str
    size_t sz
PROTOTYPE: $
PREINIT:
    char *rstr;
    STRLEN rlen;
CODE:
{
    int wres;
    rstr = SvPV(str, rlen); /* SvPV(sv, len) gives warning for signed len */
    /* printf("String: %s\n",rstr); */
    wres = wipe(rstr,sz);
    RETVAL = wres;
}
OUTPUT:
    RETVAL
