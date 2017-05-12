#include "mpg123.h"
#include "common.h"

void backbits(struct bitstream_info *bitbuf,int number_of_bits)
{
  bitbuf->bitindex    -= number_of_bits;
  bitbuf->wordpointer += (bitbuf->bitindex>>3);
  bitbuf->bitindex    &= 0x7;
}

int getbitoffset(struct bitstream_info *bitbuf) 
{
  return (-bitbuf->bitindex)&0x7;
}

int getbyte(struct bitstream_info *bitbuf)
{
#ifdef DEBUG_GETBITS
  if(bitbuf->bitindex) 
    fprintf(stderr,"getbyte called unsynched!\n");
#endif
  return *bitbuf->wordpointer++;
}

unsigned int getbits(struct bitstream_info *bitbuf,int number_of_bits)
{
  unsigned long rval;

#ifdef DEBUG_GETBITS
fprintf(stderr,"g%d",number_of_bits);
#endif

  if(!number_of_bits)
    return 0;

#if 0
   check_buffer_range(number_of_bits+bitbuf->bitindex);
#endif

  {
    rval = bitbuf->wordpointer[0];
    rval <<= 8;
    rval |= bitbuf->wordpointer[1];
    rval <<= 8;
    rval |= bitbuf->wordpointer[2];

    rval <<= bitbuf->bitindex;
    rval &= 0xffffff;

    bitbuf->bitindex += number_of_bits;

    rval >>= (24-number_of_bits);

    bitbuf->wordpointer += (bitbuf->bitindex>>3);
    bitbuf->bitindex &= 7;
  }

#ifdef DEBUG_GETBITS
fprintf(stderr,":%x ",rval);
#endif

  return rval;
}

unsigned int getbits_fast(struct bitstream_info *bitbuf,int number_of_bits)
{
  unsigned int rval;
#ifdef DEBUG_GETBITS
fprintf(stderr,"g%d",number_of_bits);
#endif

#if 0
   check_buffer_range(number_of_bits+bitbuf->bitindex);
#endif

  rval =  (unsigned char) (bitbuf->wordpointer[0] << bitbuf->bitindex);
  rval |= ((unsigned int) bitbuf->wordpointer[1]<<bitbuf->bitindex)>>8;
  rval <<= number_of_bits;
  rval >>= 8;

  bitbuf->bitindex += number_of_bits;

  bitbuf->wordpointer += (bitbuf->bitindex>>3);
  bitbuf->bitindex &= 7;

#ifdef DEBUG_GETBITS
fprintf(stderr,":%x ",rval);
#endif
  return rval;
}

unsigned int get1bit(struct bitstream_info *bitbuf)
{
  unsigned char rval;

#ifdef DEBUG_GETBITS
fprintf(stderr,"g%d",1);
#endif

#if 0
   check_buffer_range(1+bitbuf->bitindex);
#endif

  rval = *(bitbuf->wordpointer) << bitbuf->bitindex;

  bitbuf->bitindex++;
  bitbuf->wordpointer += (bitbuf->bitindex>>3);
  bitbuf->bitindex &= 7;

#ifdef DEBUG_GETBITS
fprintf(stderr,":%d ",rval>>7);
#endif

  return rval>>7;
}

