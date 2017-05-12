#define POLY 0x8408
/*
//                                      16   12   5
// this is the CCITT CRC 16 polynomial X  + X  + X  + 1.
// This works out to be 0x1021, but the way the algorithm works
// lets us use 0x8408 (the reverse of the bit pattern).  The high
// bit is always assumed to be set, thus we only use 16 bits to
// represent the 17 bit value.
*/

#include "crc.h"

// CRC-16/XMODEM
unsigned short int crc16x(const char* data_p, size_t length, unsigned short int crc)
{
    const unsigned short int generator = 0x1021; /* divisor is 16bit */

    for (size_t i = 0; i < length; i++)
    {
        const char b = data_p[i];
        crc ^= (b << 8); /* move byte into MSB of 16bit CRC */

        for (int i = 0; i < 8; i++)
        {
            if ((crc & 0x8000) != 0) /* test for MSB = bit 15 */
            {
                crc = (crc << 1) ^ generator;
            }
            else
            {
                crc <<= 1;
            }
        }
    }

    return crc;
}

// CRC-16/X-25
unsigned short int crc16(const char *data_p, size_t length, unsigned short int crc)
{
      char i;
      unsigned short int data;

      if (length == 0)
            return (~crc);

      do
      {
            for (i=0, data=(short int)0xff & *data_p++;
                 i < 8;
                 i++, data >>= 1)
            {
                  if ((crc & 0x0001) ^ (data & 0x0001))
                        crc = (crc >> 1) ^ POLY;
                  else  crc >>= 1;
            }
      } while (--length);

      crc = ~crc;
      data = crc;
      crc = (crc << 8) | ((data >> 8) & 0xff);

      return (crc);
}