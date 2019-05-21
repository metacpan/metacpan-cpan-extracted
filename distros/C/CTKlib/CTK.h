#ifndef O_NOCTTY
# define O_NOCTTY 0  /* This is a very optional frill */
#endif

/* Some systems don't support some file types. */
#ifndef S_ISFIFO
# define S_ISFIFO(mode) 0
#endif
#ifndef S_ISLNK
# define S_ISLNK(mode) 0
#endif
#ifndef S_ISSOCK
# define S_ISSOCK(mode) 0
#endif

#ifndef rerr
#define rerr errtostr(errno)
#endif

static char *
errtostr( int errnum ) {
    static char *serr;
    if (errnum > 0) { // && errnum <= sys_nerr
        //serr = (char *) sys_errlist[errnum];
        serr = (char *) strerror(errnum);
    } else {
        serr = "Unknown error";
    }
    return serr;
}
