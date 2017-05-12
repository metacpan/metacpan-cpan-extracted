/********************************************************************\
 *
 *      FILE:     mactest.c
 *
 *      CONTENTS: test file for sample C-implementation of
 *                RIPEMD160-MAC and RIPEMD128-MAC
 *        * command line arguments:                                         
 *           filename keyfilename -- compute MAC of file binary read using 
 *                                   key in keyfilename (hexadecimal format)
 *           -sstring  -- print string & MAC for default key
 *           -t        -- perform time trial                        
 *           -x        -- execute standard test suite, ASCII input
 *        * for linkage with rmd128mc.c: define RMDsize as 128
 *          for linkage with rmd160mc.c: define RMDsize as 160 (default)
 *      TARGET:   any computer with an ANSI C compiler
 *
 *      AUTHOR:   Antoon Bosselaers, ESAT-COSIC
 *      DATE:     26 March 1998
 *      VERSION:  1.0
 *
 *      Copyright (c) Katholieke Universiteit Leuven
 *      1998, All Rights Reserved
 *
\********************************************************************/
#ifndef RMDsize
#define RMDsize 160
#endif

#include <stdio.h>
#include <stdlib.h>
#include <time.h>
#include <string.h>
#if RMDsize == 128
#include "rmd128mc.h"
#elif RMDsize == 160
#include "rmd160mc.h"
#endif

#define TEST_BLOCK_SIZE 8000
#define TEST_BLOCKS 1250
#define TEST_BYTES ((long)TEST_BLOCK_SIZE * (long)TEST_BLOCKS)

/********************************************************************/

byte *RMDMAC(byte *key, byte *message)
/*
 * returns RMDMAC(key, message)
 * message should be a string terminated by '\0'
 */
{
   dword         MDbuf[RMDsize/32];   /* contains (A, B, C, D(, E))   */
   static byte   rmdmac[RMDsize/8];   /* for final mac-value          */
   dword         X[16];               /* current 16-word chunk        */
   unsigned int  i;                   /* counter                      */
   dword         length;              /* length in bytes of message   */
   dword         nbytes;              /* # of bytes not yet processed */
   dword        *MDK;                 /* pointer to expanded key      */

   /* key setup */
   MDK = MDMACsetup(key);

   /* initialize */
   MDMACinit(MDK, MDbuf);
   length = (dword)strlen((char *)message);

   /* process message in 16-word chunks */
   for (nbytes=length; nbytes > 63; nbytes-=64) {
      for (i=0; i<16; i++) {
         X[i] = BYTES_TO_DWORD(message);
         message += 4;
      }
      compress(MDK, MDbuf, X);
   }                                    /* length mod 64 bytes left */

   /* finish: */
   MDMACfinish(MDK, MDbuf, message, length, 0);

   for (i=0; i<RMDsize/8; i+=4) {
      rmdmac[i]   =  MDbuf[i>>2];         /* implicit cast to byte  */
      rmdmac[i+1] = (MDbuf[i>>2] >>  8);  /*  extracts the 8 least  */
      rmdmac[i+2] = (MDbuf[i>>2] >> 16);  /*  significant bits.     */
      rmdmac[i+3] = (MDbuf[i>>2] >> 24);
   }

   return (byte *)rmdmac;
}

/********************************************************************/

byte *RMDMACbinary(byte *key, char *fname)
/*
 * returns RMDMAC(key, message in file fname)
 * fname is read as binary data.
 */
{
   FILE         *mf;                  /* pointer to file <fname>      */
   byte          data[1024];          /* contains current mess. block */
   dword         nbytes;              /* length of this block         */
   dword         MDbuf[RMDsize/32];   /* contains (A, B, C, D(, E))   */
   static byte   rmdmac[RMDsize/8];   /* for final mac-value          */
   dword         X[16];               /* current 16-word chunk        */
   unsigned int  i, j;                /* counters                     */
   dword         length[2];           /* length in bytes of message   */
   dword         offset;              /* # of unprocessed bytes at    */
                                      /*          call of MDMACfinish */
   dword        *MDK;                 /* pointer to expanded key      */

   /* key setup */
   MDK = MDMACsetup(key);

   /* initialize */
   if ((mf = fopen(fname, "rb")) == NULL) {
      fprintf(stderr, "\nRMDbinary: cannot open file \"%s\".\n",
              fname);
      exit(1);
   }
   MDMACinit(MDK, MDbuf);
   length[0] = 0;
   length[1] = 0;

   while ((nbytes = fread(data, 1, 1024, mf)) != 0) {
      /* process all complete blocks */
      for (i=0; i<(nbytes>>6); i++) {
         for (j=0; j<16; j++)
            X[j] = BYTES_TO_DWORD(data+64*i+4*j);
         compress(MDK, MDbuf, X);
      }
      /* update length[] */
      if (length[0] + nbytes < length[0])
         length[1]++;                  /* overflow to msb of length */
      length[0] += nbytes;
   }

   /* finish: */
   offset = length[0] & 0x3C0;   /* extract bytes 6 to 10 inclusive */
   MDMACfinish(MDK, MDbuf, data+offset, length[0], length[1]);

   for (i=0; i<RMDsize/8; i+=4) {
      rmdmac[i]   =  MDbuf[i>>2];
      rmdmac[i+1] = (MDbuf[i>>2] >>  8);
      rmdmac[i+2] = (MDbuf[i>>2] >> 16);
      rmdmac[i+3] = (MDbuf[i>>2] >> 24);
   }

   fclose(mf);

   return (byte *)rmdmac;
}

/***********************************************************************/

byte *RMDMACreadkey(char *fname)
/*
 * reads 128-bit MAC key from fname
 * key should be given in hexadecimal format
 */
{
   FILE         *file;
   unsigned int  i, temp;
   static byte   key[16];

   if ( (file = fopen(fname, "r")) == NULL ) {
      fprintf(stderr, "RMDMACreadkey: cannot open file \"%s\".\n", fname);
      exit(1);
   }

   for (i=0;i < 16;i++) {
      if (fscanf(file, "%02x", &temp) == EOF)
         fprintf(stderr, "RMDMACreadkey: EOF encountered before read was "
                         "completed in \"%s\".\n", fname);
      key[i] = (byte)temp;
   }

   fclose(file);

   return key;
}

/********************************************************************/

void speedtest(void)
/*
 * A time trial routine, to measure the speed of RIPEMD160/128-MAC.
 * Measures processor time required to process TEST_BLOCKS times
 *  a message of TEST_BLOCK_SIZE characters.
 */
{
   clock_t      t0, t1;
   byte        *data;
   byte         rmdmac[RMDsize/8];
   dword        X[16];
   dword        MDbuf[RMDsize/32];
   unsigned int i, j, k;
   byte         MDMACkey[16];
   dword       *MDK;

   srand(time(NULL));

   /* pick a random key and perform key setup */
   for (i=0; i<16; i++)
      MDMACkey[i] = (byte)(rand() >> 7);
   MDK = MDMACsetup(MDMACkey);

   /* allocate and initialize test data */
   if ((data = (byte*)malloc(TEST_BLOCK_SIZE)) == NULL) {
      fprintf(stderr, "speedtest: allocation error\n");
      exit(1);
   }
   for (i=0; i<TEST_BLOCK_SIZE; i++)
      data[i] = (byte)(rand() >> 7);

   /* start timer */
   printf("\n\nRIPEMD-%uMAC time trial. Processing %ld characters...\n",
          RMDsize, TEST_BYTES);
   t0 = clock();

   /* process data */
   MDMACinit(MDK, MDbuf);
   for (i=0; i<TEST_BLOCKS; i++) {
      for (j=0; j<TEST_BLOCK_SIZE; j+=64) {
         for (k=0; k<16; k++)
            X[k] = BYTES_TO_DWORD(data+j+4*k);
         compress(MDK, MDbuf, X);
      }
   }
   MDMACfinish(MDK, MDbuf, data, TEST_BYTES, 0);

   /* stop timer, get time difference */
   t1 = clock();
   printf("\nTest input processed in %g seconds.\n",
          (double)(t1-t0)/(double)CLOCKS_PER_SEC);
   printf("Characters processed per second: %g\n",
          (double)CLOCKS_PER_SEC*TEST_BYTES/((double)t1-t0));

   for (i=0; i<RMDsize/8; i+=4) {
      rmdmac[i]   =  MDbuf[i>>2];
      rmdmac[i+1] = (MDbuf[i>>2] >>  8);
      rmdmac[i+2] = (MDbuf[i>>2] >> 16);
      rmdmac[i+3] = (MDbuf[i>>2] >> 24);
   }
   printf("\nMAC: ");
   for (i=0; i<RMDsize/8; i++)
      printf("%02x", rmdmac[i]);
   printf("\n");

   free(data);
   return;
}

/********************************************************************/

void RMDMAConemillion(byte *key)
/*
 * returns RMDMAC() of message consisting of 1 million 'a' characters
 */
{
   dword         MDbuf[RMDsize/32];   /* contains (A, B, C, D(, E)) */
   static byte   rmdmac[RMDsize/8];   /* for final mac-value        */
   dword         X[16];               /* current 16-word chunk      */
   unsigned int  i;                   /* counter                    */
   dword        *MDK;                 /* pointer to expanded key    */

   /* key setup */
   MDK = MDMACsetup(key);

   MDMACinit(MDK, MDbuf);
   memcpy(X, "aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa", 32);
   memcpy(X+8, X, 32);
   for (i=15625; i>0; i--)
      compress(MDK, MDbuf, X);
   MDMACfinish(MDK, MDbuf, NULL, 1000000UL, 0);
   for (i=0; i<RMDsize/8; i+=4) {
      rmdmac[i]   =  MDbuf[i>>2];
      rmdmac[i+1] = (MDbuf[i>>2] >>  8);
      rmdmac[i+2] = (MDbuf[i>>2] >> 16);
      rmdmac[i+3] = (MDbuf[i>>2] >> 24);
   }
   printf("\n* message: 1 million times \"a\"\n  MAC: ");
   for (i=0; i<RMDsize/8; i++)
      printf("%02x", rmdmac[i]);

}

/********************************************************************/

void RMDMACstring(byte *key, char *message, char *print)
{
   unsigned int  i;
   byte         *rmdmac;

   rmdmac = RMDMAC(key, (byte *)message);
   printf("\n* message: %s\n  MAC: ", print);
   for (i=0; i<RMDsize/8; i++)
      printf("%02x", rmdmac[i]);
}

/********************************************************************/

void testsuite (byte *key)
/*
 *   standard test suite
 */
{
   unsigned int i;

   printf("\n\nRIPEMD-%uMAC test suite results (ASCII):\n", RMDsize);

   printf("\nkey = ");
   for (i=0; i<16; i++)
      printf("%02x", key[i]);
   printf("\n");

   RMDMACstring(key, "", "\"\" (empty string)");
   RMDMACstring(key, "a", "\"a\"");
   RMDMACstring(key, "abc", "\"abc\"");
   RMDMACstring(key, "message digest", "\"message digest\"");
   RMDMACstring(key, "abcdefghijklmnopqrstuvwxyz", "\"abcdefghijklmnopqrstuvwxyz\"");
   RMDMACstring(key, "abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq",
             "\"abcdbcdecdefdefgefghfghighijhijkijkljklmklmnlmnomnopnopq\"");
   RMDMACstring(key, "ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789",
             "\"A...Za...z0...9\"");
   RMDMACstring(key, "1234567890123456789012345678901234567890"
             "1234567890123456789012345678901234567890", 
             "8 times \"1234567890\"");
   RMDMAConemillion(key);
   printf("\n");

   return;
}

/********************************************************************/

main (int argc, char *argv[])
/*
 *  main program. calls one or more of the test routines depending
 *  on command line arguments. see the header of this file.
 *
 */
{
  unsigned int   i, j;
  byte          *rmdmac, *key;
  byte Ktest1[16] = {0x00, 0x11, 0x22, 0x33, 0x44, 0x55, 0x66, 0x77,
                     0x88, 0x99, 0xaa, 0xbb, 0xcc, 0xdd, 0xee, 0xff};
  byte Ktest2[16] = {0x01, 0x23, 0x45, 0x67, 0x89, 0xab, 0xcd, 0xef,
                     0xfe, 0xdc, 0xba, 0x98, 0x76, 0x54, 0x32, 0x10};

   if (argc == 1) {
      printf("For each command line argument in turn:\n");
      printf("  filename keyfilename -- compute MAC of file binary read using\n"
             "                          key in keyfilename (hexadecimal format)\n");
      printf("  -sstring             -- print string & MAC for default key\n");
      printf("  -t                   -- perform time trial\n");
      printf("  -x                   -- execute standard test suite, ASCII input\n");
      return 0;
   }

   MDMACconstT();
   for (i = 1; i < argc; i++) {
      if (argv[i][0] == '-' && argv[i][1] == 's') {
         printf("\n\ndefault key = ");
         for (j=0; j<16; j++)
            printf("%02x", Ktest1[j]);
         printf("\nmessage: %s", argv[i]+2);
         rmdmac = RMDMAC(Ktest1, (byte *)argv[i] + 2);
         printf("\nMAC: ");
         for (j=0; j<RMDsize/8; j++)
            printf("%02x", rmdmac[j]);
         printf("\n");
      }
      else if (strcmp (argv[i], "-t") == 0)
         speedtest ();
      else if (strcmp (argv[i], "-x") == 0) {
         testsuite (Ktest1);
         testsuite (Ktest2);
      }
      else {
         key = RMDMACreadkey(argv[i+1]);
         printf("\n\nkey = ");
         for (j=0; j<16; j++)
            printf("%02x", key[j]);
         rmdmac = RMDMACbinary(key, argv[i]);
         printf("\nmessagefile (binary): %s", argv[i]);
         printf("\nMAC: ");
         for (j=0; j<RMDsize/8; j++)
            printf("%02x", rmdmac[j]);
         printf("\n");
         i++;  /* one extra input was used for the key file */
      }
   }
   printf("\n");

   return 0;
}

/********************** end of file mactest.c ***********************/

