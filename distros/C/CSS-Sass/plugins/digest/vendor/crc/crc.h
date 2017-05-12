/*
**  CRC.H - header file for SNIPPETS CRC and checksum functions
*/

#ifndef CRC__H
#define CRC__H

#include <stdlib.h>           /* For size_t                 */

/*
**  File: ARCCRC16.C
*/

void init_crc_table(void);
unsigned short int crc_calc(unsigned short int crc, char *buf, unsigned nbytes);
void do_file(char *fn);

/*
**  File: CRC-16.C
*/

// CRC-16/XMODEM
unsigned short int crc16x(const char* data_p, size_t length, unsigned short int crc = 0x0000);
unsigned short int crc16(const char *data_p, size_t length, unsigned short int crc = 0xffff);

/*
**  File: CRC-16F.C
*/

short int updcrc(short int icrc, unsigned char *icp, size_t icnt);

/*
**  File: CRC_32.C
*/

#define UPDC32(octet,crc) (crc_32_tab[((crc)\
     ^ ((unsigned char)octet)) & 0xff] ^ ((crc) >> 8))

unsigned long int updateCRC32(const unsigned char ch, unsigned long int crc);
bool crc32file(const char *name, unsigned long int *crc, long *charcnt);
unsigned long int crc32buf(const char *buf, size_t len, unsigned long int oldcrc32 = 0xFFFFFFFF);

/*
**  File: CHECKSUM.C
*/

unsigned checksum(void *buffer, size_t len, unsigned int seed);

/*
**  File: CHECKEXE.C
*/

void checkexe(char *fname);



#endif /* CRC__H */