#ifndef WINCOMPAT_H
#define WINCOMPAT_H

#include <stdint.h>
#include <Winsock2.h>
#include <ws2tcpip.h>
#include <malloc.h>

#ifdef __MINGW32__

#include <sys/time.h>

#ifndef strcasecmp
#define strcasecmp _stricmp
#endif

#else

#define ssize_t int

#ifndef gettimeofday
#define gettimeofday wintimeofday

#ifndef __attribute__
#define __attribute__(X)
#endif

#ifdef __cplusplus
extern "C" {
#endif

struct timezone {
    int tz_minuteswest;
    int tz_dsttime;
};

int wintimeofday(struct timeval *tv, struct timezone *tz);

#ifndef strcasecmp
#define strcasecmp _stricmp
#endif

#ifdef __cplusplus
}
#endif

#endif

#endif

#endif
