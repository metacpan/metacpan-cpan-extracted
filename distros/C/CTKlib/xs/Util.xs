/*
  Copyright (C) 1998-2013 D&D Corporation. All Rights Reserved

  This program is free software; you can redistribute it and/or
  modify it under the same terms as Perl itself.

  This program is distributed under the GNU LGPL v3 (GNU Lesser
  General Public License version 3).
*/

#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define PROGRAM_NAME "shred"
#define AUTHORS "Serz Minus"
#define VERSION "1.00"

#define PASSES 3
#define BUFFSIZE 512

#ifndef O_NOCTTY
# define O_NOCTTY 0  /* This is a very optional frill */
#endif

/* Some systems don't support some file types.  */
#ifndef S_ISFIFO
# define S_ISFIFO(mode) 0
#endif
#ifndef S_ISLNK
# define S_ISLNK(mode) 0
#endif
#ifndef S_ISSOCK
# define S_ISSOCK(mode) 0
#endif

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

static char *
errtostr( int errnum ) {
  static char *serr;
  if (errnum > 0 && errnum <= sys_nerr) {
    serr = (char *) sys_errlist[errnum];
  } else {
    serr = "Unknown error";
  }
  return serr;
}

static int
pass( int fd, off_t *sizep, int n) {
  off_t size = *sizep;
  /* off_t offset; */
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
    fprintf(stderr, "XS-Error: %s. Can't open file \"%s\"\n", errtostr(errno), fn);
    fflush (stderr);
    return 0;
  }

  size = sz;
  /* printf("SIZE: %d\n",size); */

  if (size < 0) {
      fprintf(stderr, "XS-Error. File \"%s\" has negative size\n", fn);
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
    fprintf(stderr, "XS-Error: %s. Can't close \"%s\"\n", errtostr(errno), fn);
    fflush (stderr);
    return 0;
  }

  return 1;
}

MODULE = CTK::XS::Util    PACKAGE = CTK::XS::Util

SV *
xstest()
ALIAS:
  xsver = 1
CODE:
{
  RETVAL = newSVpv(VERSION,0);
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

