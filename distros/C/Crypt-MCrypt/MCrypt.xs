#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <mcrypt.h>

#include <stdio.h>
#include <stdlib.h>
#include <math.h>
#include <stdint.h>

#include "const-c.inc"


int _encrypt(
    char* algorithm,
    char* mode,
    void* buffer,
    int buffer_len, /* Because the plaintext could include null bytes*/
    char* IV,
    char* key,
    int key_len
    ){
  int v;
  MCRYPT td = mcrypt_module_open(algorithm, NULL, mode, NULL);
  int blocksize = mcrypt_enc_get_block_size(td);
  if( buffer_len % blocksize != 0 ){return 1;}
   
  mcrypt_generic_init(td, key, key_len, IV);
  mcrypt_generic(td, buffer, buffer_len);
  mcrypt_generic_deinit (td);
  mcrypt_module_close(td);

  return 1;
}
 
int _decrypt(
    char* algorithm,
    char* mode,
    void* buffer,
    int buffer_len, /* Because the plaintext could include null bytes*/
    char* IV,
    char* key,
    int key_len
    ){
  int v;
  MCRYPT td = mcrypt_module_open(algorithm, NULL, mode, NULL);
  int blocksize = mcrypt_enc_get_block_size(td);
  if( buffer_len % blocksize != 0 ){return ;}

  mcrypt_generic_init(td, key, key_len, IV);
  mdecrypt_generic(td, buffer, buffer_len);
  mcrypt_generic_deinit (td);
  mcrypt_module_close(td);

  return 1;
}
 

MODULE = Crypt::MCrypt		PACKAGE = Crypt::MCrypt	PREFIX = _mcrypt_
PROTOTYPES: DISABLE

char *_mcrypt__encrypt(algorithm,mode,plaintext,key,plaintext_len,IV)
    char *algorithm
    char *mode
    char *plaintext
    char *key
    int  &plaintext_len
    char *IV
  INIT:
    char* buffer;
    int keysize=24;
    int v=0;
    char byte[9];
    char* hextext;
    char* ptr;
    unsigned int char_int;
  CODE:
    buffer = calloc(1, plaintext_len);
    hextext = calloc(1, plaintext_len*2+1);
    //strncpy(buffer, plaintext, plaintext_len);
    for (v=0; v<plaintext_len; v++){
        buffer[v] = plaintext[v];
    }
    _encrypt(algorithm,mode,buffer, plaintext_len, IV, key, keysize);

    char_int = buffer[0];
    for (v=0; v<plaintext_len; v++){
      sprintf(byte,"%02X",(unsigned char)buffer[v]);
      hextext[v*2] = byte[0];
      hextext[v*2+1] = byte[1];
    }
    free(buffer);
    // return hexcode to avoid truncation when there are null charachters 
    // in returned ciphertext string.
    RETVAL = hextext;
  OUTPUT:
    RETVAL
    
char *_mcrypt__decrypt(algorithm,mode,ciphertext,key,ciphertext_len,IV)
    char *algorithm
    char *mode
    char *ciphertext
    char *key
    int  &ciphertext_len
    char *IV
  INIT:
    char* buffer;
    int keysize=24;
    int v=0;
    char byte[3];
    char* hextext;
    char* ptr;
  CODE:
    buffer = calloc(1, ciphertext_len);
    hextext = calloc(1, ciphertext_len*2+1);
    strncpy(buffer, ciphertext, ciphertext_len);
    _decrypt(algorithm,mode,buffer, ciphertext_len, IV, key, keysize);

    for (v=0; v<ciphertext_len; v++){
      sprintf(byte,"%02X",(unsigned char)buffer[v]);
      hextext[v*2] = byte[0];
      hextext[v*2+1] = byte[1];
    }
    free(buffer);
    // return hexcode to avoid truncation when there are null charachters 
    // in returned plaintext string.
    RETVAL = hextext;
  OUTPUT:
    RETVAL
    
