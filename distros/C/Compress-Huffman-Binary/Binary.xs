#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#include "ppport.h"

#include "compress-huffman-binary-perl.c"

typedef compress_huffman_binary_t * Compress__Huffman__Binary;

MODULE=Compress::Huffman::Binary PACKAGE=Compress::Huffman::Binary

PROTOTYPES: DISABLE

BOOT:
	/* Compress__Huffman__Binary_error_handler = perl_error_handler; */

SV *
huffman_encode (in)
	SV * in;
CODE:
	RETVAL = perl_huffman_encode (in);
OUTPUT:
	RETVAL

SV *
huffman_decode (in)
	SV * in;
CODE:
	RETVAL = perl_huffman_decode (in);
OUTPUT:
	RETVAL
