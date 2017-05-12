#ifdef __MINGW32__
#include <stdint.h>
#endif

#ifdef _MSC_VER
#include <stdlib.h>
typedef __int64 int64_t;
typedef unsigned __int64 uint64_t;

#ifndef INT64_MAX
#define INT64_MAX _I64_MAX
#endif
#ifndef INT64_MIN
#define INT64_MIN _I64_MIN
#endif
#ifndef UINT64_MAX
#define UINT64_MAX _UI64_MAX
#endif
#ifndef UINT32_MAX
#define UINT32_MAX _UI32_MAX
#endif

#endif
