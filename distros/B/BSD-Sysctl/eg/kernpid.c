/* kernpid.c - display info about processes
 *
 * Copyright (C) 2006 David Landgren, all rights reserved
 */

#include <stdio.h>
#include <sys/param.h>
#include <sys/types.h>
#include <sys/user.h>
#include <sys/sysctl.h>

void printkproc(struct kinfo_proc *kp) {
    printf("%5d %s\n",
        kp->ki_pid,
        kp->ki_comm
    );
}

void show(const char *arg) {
    int i;
    int mib[4];
    struct kinfo_proc kp;
    size_t len = 4;

    sysctlnametomib(arg, mib, &len);

    for(i = 0; i < 10000; i++) {
        mib[3] = i;
        len = sizeof(kp);
        if (sysctl(mib, 4, &kp, &len, NULL, 0) == -1) {
            /* perror("sysctl"); */
        }
        else if (len > 0) {
            printkproc(&kp);
        }
    }
}

int main(int argc, char **argv) {
    const char *arg = "kern.proc.pid";
    show(arg);
    exit(0);
}
