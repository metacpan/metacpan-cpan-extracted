#ifndef _UTIL_CONFIG_H
#define _UTIL_CONFIG_H

#include <stdlib.h>

extern void *CBC_malloc(size_t size);
extern void *CBC_calloc(size_t count, size_t size);
extern void *CBC_realloc(void *ptr, size_t size);
extern void  CBC_free(void *ptr);

#define UTIL_MALLOC(size)          CBC_malloc(size)
#define UTIL_CALLOC(count, size)   CBC_calloc(count, size)
#define UTIL_REALLOC(ptr, size)    CBC_realloc(ptr, size)
#define UTIL_FREE(ptr)             CBC_free(ptr)

#define ABORT_IF_NO_MEM

#endif
