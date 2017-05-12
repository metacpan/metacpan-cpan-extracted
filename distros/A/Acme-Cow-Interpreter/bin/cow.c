/*
  cow.c - a C wrapper for the Cow interpreter written in Perl.

  If your system does not allow you to use a script as an
  interpreter on the `#!' line, e.g., using the Cow interpreter
  written in Perl at the top of a Cow program with
  `#!/usr/local/bin/cow', rename the Perl program to
  `/usr/local/bin/cow.pl' and compile this script with, e.g.,

      gcc -Wall -o cow cow.c

  and move the resulting executable program to `/usr/local/bin/cow'
  og `/usr/local/bin/cow.exe', depending on your operating
  system. Then you should be able to put `#!/usr/local/bin/cow' on
  top of your Cow programs.

  If you rename the Perl program to something other than
  `/usr/local/bin/cow.pl', you must change the code below
  accordingly.

  Author:      Peter John Acklam
  Time-stamp:  2010-05-26 10:45:05 +02:00
  E-mail:      pjacklam@online.no
  URL:         http://home.online.no/~pjacklam
*/

#include <unistd.h>     /* for execv */
#include <stdio.h>      /* for stderr */
#include <errno.h>      /* for errno */
#include <string.h>     /* for strerror */
#include <stdlib.h>     /* for EXIT_FAILURE */

extern int main(int argc, char **argv);

int main(argc, argv)
    int argc;
    char **argv;
{
    int ret;
    static char file[] = "/usr/local/bin/cow.pl";
    ret = execv(file, argv);
    fprintf(stderr, "execv() of %s failed: %s\n",
            file, strerror(errno));
    exit(EXIT_FAILURE);
}
