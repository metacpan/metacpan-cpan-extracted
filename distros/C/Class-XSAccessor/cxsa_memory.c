
#include "cxsa_memory.h"

void* _cxa_realloc(void *ptr, STRLEN size) {
    return realloc(ptr, size);
}

void* _cxa_malloc(STRLEN size) {
    return malloc(size);
}

void* _cxa_zmalloc(STRLEN size) {
    return calloc(1, size);
}

void _cxa_free(void *ptr) {
    free(ptr);
}

void* _cxa_memcpy(void *dest, void *src, STRLEN size) {
    return memcpy(dest, src, size);
}

void* _cxa_memzero(void *ptr, STRLEN size) {
    return memset(ptr, 0, size);
}

