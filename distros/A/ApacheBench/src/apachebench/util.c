#include <sys/time.h>
#include <string.h>

#include "types.h"
#include "util.h"

/* --------------------------------------------------------- */

/* keep warn and error massege */

void
myerr(char *warn_and_error, char *s) {
    if ((strlen(warn_and_error) + strlen(s)) < (WARN_BUFFSIZE - 35)) {
	strcat(warn_and_error, "\n[Warn:] ");
	strcat(warn_and_error, s);
    } else if(strlen(warn_and_error) < (WARN_BUFFSIZE - 35))
	strcat(warn_and_error, "\nToo many warn and error messages!");
}

/* --------------------------------------------------------- */

/* returns the time in ms between two timevals */

int
timedif(struct timeval a, struct timeval b) {
    register int us, s;

    us = a.tv_usec - b.tv_usec;
    us /= 1000;
    s = a.tv_sec - b.tv_sec;
    s *= 1000;
    return s + us;
}

/* --------------------------------------------------------- */

/* converts a double precision number of seconds to a timeval */

static struct timeval
double2timeval(double secs) {
    register struct timeval retval;

    retval.tv_sec = (long)secs;
    retval.tv_usec = (long)((secs - (long)secs) * 1000000);
    return retval;
}

/* converts a timeval to a double precision number of seconds */

static double
timeval2double(struct timeval a) {
    return (double)a.tv_sec + (double)a.tv_usec / 1000000;
}

/* --------------------------------------------------------- */

/* simple implementation of strnstr for c libraries without it, e.g. glibc */

char *
strnstr(const char *big, const char *little, size_t len) {
    char * found = strstr(big, little);
    if (found && (found - big > len))
        return 0;
    return found;
}
