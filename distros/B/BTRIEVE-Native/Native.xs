#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#define MAX_KEY_SIZE   255
#define POS_BLOCK_SIZE 128

extern short int __stdcall BTRCALL
(
  unsigned short operation
, void*          posBlock
, void*          dataBuffer
, unsigned long* dataLength
, void*          keyBuffer
, unsigned char  keyLength
, char           ckeynum
);

MODULE = BTRIEVE::Native PACKAGE = BTRIEVE::Native

PROTOTYPES: DISABLE

short
Call( operation, posBlock, dataBuffer, dataLength, keyBuffer, keyNumber )
  unsigned short operation
  char*          posBlock
  char*          dataBuffer
  unsigned long  dataLength
  char*          keyBuffer
  short          keyNumber
  CODE:
  if ( SvCUR(ST(1)) != POS_BLOCK_SIZE ) {
    croak("posBlock length must be %d", POS_BLOCK_SIZE );
  }
  RETVAL = BTRCALL( operation, posBlock, dataBuffer, &dataLength, keyBuffer, SvCUR(ST(4)), keyNumber );
  OUTPUT:
  posBlock   ;
  dataBuffer SvCUR_set( (SV*)ST(2), dataLength );
  dataLength
  keyBuffer  ;
  RETVAL
