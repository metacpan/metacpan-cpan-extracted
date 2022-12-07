#pragma once

#include <stdio.h>
#include <string.h>
#include <math.h>
#include <stdbool.h>
#include <stddef.h> // offsetof

#define warn(FORMAT, ...)                                                                          \
    fprintf(stderr, FORMAT " in %s at line %i\n", ##__VA_ARGS__, __FILE__, __LINE__)

#if defined _WIN32 || defined __CYGWIN__
#include <BaseTsd.h>
typedef SSIZE_T ssize_t;
typedef signed __int64 int64_t;
#ifdef __GNUC__
#define DLLEXPORT __attribute__((dllexport))
#else
#define DLLEXPORT __declspec(dllexport)
#endif
#else
#ifdef __GNUC__
#if __GNUC__ >= 4
#define DLLEXPORT __attribute__((visibility("default")))
#else
#define DLLEXPORT __attribute__((dllimport))
#endif
#else
#define DLLEXPORT __declspec(dllimport)
#endif
#include <inttypes.h>
#include <sys/types.h>
#endif