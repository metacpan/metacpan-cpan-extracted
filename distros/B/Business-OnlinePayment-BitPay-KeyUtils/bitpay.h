/*
 * File:   bitpay.h
 * Author: paul
 *
 * Created on April 27, 2015, 3:44 PM
 */


#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <string.h>
#include <openssl/ec.h>
#include <openssl/bn.h>
#include <openssl/sha.h>
#include <openssl/ripemd.h>
#include <openssl/ecdsa.h>
#include <openssl/pem.h>

#define	NOERROR	0
#define	ERROR 	-1
#define SHA256_STRING 33
#define SHA256_HEX_STRING 65
#define RIPEMD_AND_PADDING 22
#define RIPEMD_AND_PADDING_STRING 23
#define RIPEMD_HEX 40
#define RIPEMD_HEX_STRING 41
#define RIPEMD_AND_PADDING_HEX 44
#define RIPEMD_AND_PADDING_HEX_STRING 45
#define CHECKSUM 8
#define CHECKSUM_STRING 9
#define SIN 35 
#define SIN_STRING 36 

int generatePem(char **pem);
int generateSinFromPem(char *pem, char **sin);
int getPublicKeyFromPem(char *pemstring, char **pubkey);
int signMessageWithPem(char *pem, char *message, char **signature); 

