#define _GNU_SOURCE
#include <unistd.h>
#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>
#include <stdlib.h>
#include <errno.h>
#include <dlfcn.h>
#include <string.h>

#define OUT_FD 1

uint64_t total = 0;
ssize_t (*original_write)(int, const void *, size_t) = NULL;
int (*original_close)(int) = NULL;
void print_total(void)
{
    char buf[256];
    snprintf(buf, 256, "%" PRIu64 "\n", total);
    original_write(1, buf, strlen(buf));
}

int close(int fd)
{     
    if(! original_close)
    {
        original_close = dlsym(RTLD_NEXT, "close");
    }
    if(fd == OUT_FD)
    {       
        print_total();        
    }
    return original_close(fd);
}

ssize_t read(int fd, void *buf, size_t count)
{
    return count;
}

ssize_t write(int fd, const void *buf, size_t count)
{
    if(!original_write)
    {
        original_write = dlsym(RTLD_NEXT, "write");
    }
    if(fd == OUT_FD)
    {
        total += count;
        return count;
    }
    return original_write(fd, buf, count);
}



