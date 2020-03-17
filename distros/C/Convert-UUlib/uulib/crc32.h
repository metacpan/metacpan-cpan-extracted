#ifndef __CRC32_H__
#define __CRC32_H__

#ifndef _ANSI_ARGS_
#ifdef PROTOTYPES
#define _ANSI_ARGS_(c)	c
#else
#define _ANSI_ARGS_(c)	()
#endif
#endif

#include "ecb.h"

#ifdef __cplusplus
extern "C" {
#endif

typedef uint32_t crc32_t;

#define CRC32_INIT ((crc32_t)0)

crc32_t uu_crc32 _ANSI_ARGS_((crc32_t prev, const void *data, unsigned int len));
/*
     Update a running crc with the bytes buf[0..len-1] and return the updated
   crc. If buf is NULL, this function returns the required initial value
   for the crc. Pre- and post-conditioning (one's complement) is performed
   within this function so it shouldn't be done by the application.
   Usage example:

     uLong crc = CRC32_INIT;

     while (read_buffer(buffer, length) != EOF) {
       crc = crc32(crc, buffer, length);
     }
     if (crc != original_crc) error();
*/

uint32_t uu_crc32_combine(uint32_t crcA, uint32_t crcB, size_t lengthB);

#ifdef __cplusplus
}
#endif
#endif
