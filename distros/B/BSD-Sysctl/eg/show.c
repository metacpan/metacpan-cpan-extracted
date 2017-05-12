/* show.c - fetch a sysctl variable and display the results
 *
 * Copyright (C) 2006 David Landgren, all rights reserved
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
        fprintf(stderr, "sysctlnametomib for %s failed\n", arg);
        return;
    }

    if (sysctl(mib, miblen, buf, &buflen, NULL, 0) == -1) {
        fprintf(stderr, "sysctl lookup for %s failed\n", arg);
        return;
    }

    qoid[0] = 0;
    qoid[1] = 4;
    memcpy(qoid+2, mib, miblen * sizeof(int));
    if (sysctl(qoid, miblen+2, mibfmt, &mibfmtlen, NULL, 0) == -1) {
        fprintf(stderr, "sysctl format for %s failed\n", arg);
        return;
    }
    f += sizeof(unsigned int);

    /* printf( "%c\n", *f ); */
    switch (*f) {
    case 'A':
        printf( "%s=%s\n", arg, buf );
        break;
    case 'I':
        {
            char *b = buf;
            char *sep = "=";
            fputs(arg, stdout);
            while (buflen >= sizeof(int)) {
                fputs(sep, stdout);
                printf( "%d", *(int *)b);
                buflen -= sizeof(int);
                b      += sizeof(int);
                sep = " ";
            }
            fputs("\n", stdout);
        }
        break;
    case 'L':
        ++f;
        if (*f == 'U') {
            char *b = buf;
            char *sep = "=";
            fputs(arg, stdout);
            while (buflen >= sizeof(long)) {
                fputs(sep, stdout);
                printf( "%lu", *(unsigned long *)b);
                buflen -= sizeof(long);
                b      += sizeof(long);
                sep = " ";
            }
            fputs("\n", stdout);

        }
        else {
             fprintf(stderr, "%s requires a L:%c handler\n", arg, *f);
        }
        break;
    case 'S':
        if (strcmp(f, "S,clockinfo") == 0) {
            struct clockinfo *inf = (struct clockinfo *)buf;
            printf( "%s=[%dhz %dtick %dprofhz %dstathz]\n",
                arg,
                inf->hz,
                inf->tick,
                inf->profhz,
                inf->stathz
            );
        }
        else if (strcmp(f, "S,timeval") == 0) {
            struct timeval *inf = (struct timeval *)buf;
            printf( "%s=%ld.%ld\n",
                arg,
                inf->tv_sec,
                inf->tv_usec
            );
        }
        else if (strcmp(f, "S,vmtotal") == 0) {
            struct vmtotal *inf = (struct vmtotal *)buf;
            printf("%s proc-runq=%hu proc-diskw=%hu proc-pagew=%hu proc-sleep=%hu\n",
                arg, inf->t_rq, inf->t_dw, inf->t_pw, inf->t_sl
            );
            printf("  pgsz=%d vm-tot=%lu vm-act=%lld mem-real=%lld mem-act=%lld\n",
                getpagesize(),
                (unsigned long)inf->t_vm,
                (long long)inf->t_avm,
                (long long)inf->t_rm,
                (long long)inf->t_arm
            );
            printf("  shrvm-tot=%lld shrvm-act=%lld shrmem-tot=%lld shrmem-act=%lld\n",
                (long long)inf->t_vmshr,
                (long long)inf->t_avmshr,
                (long long)inf->t_rmshr,
                (long long)inf->t_armshr
            );
        }
        else if (strcmp(f, "S,loadavg") == 0) {
            struct loadavg *inf = (struct loadavg *)buf;
            double scale = inf->fscale;
            printf("%f %f %f\n",
                (double)inf->ldavg[0]/scale,
                (double)inf->ldavg[1]/scale,
                (double)inf->ldavg[2]/scale
            );
        }
        else {
             fprintf(stderr, "%s requires a %s handler\n", arg, f);
        }
        break;
    default:
        fprintf(stderr, "%s requires a %c handler\n", arg, *f);
    }
}

int main(int argc, char **argv) {
    while(--argc) {
        const char *arg;
        arg = *++argv;
        show(arg);
    }
    exit(0);
}
