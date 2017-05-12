/******************************************************************************* 
*	This source code "SEED_test_KISA.c" is not the official souce code.
*	This source code is the only example.
*	This source code show how the encryption and decryption functions are operated.
*	This source code can compare the standard test vector with the result.
*
*******************************************************************************/


/******************************* Include files ********************************/

#include "SEED_KISA.h"


/*******************************SEED test code ********************************/

void main()
{
	DWORD pdwRoundKey[32];								/* Round keys for encryption or decryption */
	BYTE pbUserKey[16] = {0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 		/* User secret key                         */
                        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00};
	BYTE pbData[16]    = {0x00, 0x01, 0x02, 0x03, 0x04, 0x05, 0x06, 0x07, 		/* input plaintext to be encrypted */
                        0x08, 0x09, 0x0A, 0x0B, 0x0C, 0x0D, 0x0E, 0x0F};
	int i;

/* Print user secret key */
	printf ("Key        : ");
	for (i=0;i<16;i++)	
		printf("%02X ",pbUserKey[i]);

/* Print plaintext to be encrypted */
	printf ("\nPlaintext  : ");
	for (i=0;i<16;i++)	
		printf("%02X ",pbData[i]);
		
/* Derive roundkeys from user secret key */
	SeedRoundKey(
		pdwRoundKey, 
		pbUserKey);
	
/* Encryption */
	printf ("\n\nEncryption....\n");
	SeedEncrypt(
		pbData, 
		pdwRoundKey);

/* print encrypted data(ciphertext) */
	printf ("Ciphertext : ");
	for (i=0;i<16;i++)	
		printf("%02X ",pbData[i]);

/* Decryption */
	printf ("\n\nDecryption....\n");
	SeedDecrypt(
		pbData, 
		pdwRoundKey);

/* Print decrypted data(plaintext) */
	printf ("Plaintext  : ");
	for (i=0;i<16;i++)	
		printf("%02X ",pbData[i]);

/* Print round keys at round i */
	printf ("\n\nRound Key  : \n");
	for (i=0;i<16;i++) {
		printf("K%2d,0 : %08X\t", i+1, pdwRoundKey[2*i]);
		printf("K%2d,1 : %08X\n", i+1, pdwRoundKey[2*i+1]);
	}
}

