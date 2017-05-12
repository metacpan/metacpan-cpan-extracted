#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include <stdio.h>
#include <ctype.h>
#include <string.h>

int
NetCheck(char *net, char *msk, char *dst) {
 
 char *network     ;
 char *mask        ;
 char *destination ;       
 int x = 0;
 int i = 0;
 int y = 0;
 int netCnt  = 0;
 int maskCnt = 0;
 int dstCnt  = 0;
 int raj = 0;
 int netComp = 0;
 int dstComp = 0;
 
        
  network     = (char *) malloc(5 * sizeof(char));
  mask        = (char *) malloc(5 * sizeof(char));
  destination = (char *) malloc(5 * sizeof(char));
 
  for (; i < 4  ;i++,netCnt++,maskCnt++,dstCnt++) {
 
        y = 0;
    while (isdigit(net[netCnt])) {
        network[y] = net[netCnt];
        netCnt++; y++;
        network[y] = 0; /* Pointer Termination */
    }
      
    y = 0;
    while (isdigit(msk[maskCnt])) {
       mask[y] = msk[maskCnt]; 
       maskCnt++; y++;
       mask[y] = 0;
    }
      
    y = 0;
    while (isdigit(dst[dstCnt])) {
       destination[y] = dst[dstCnt];
       dstCnt++;y++;
       destination[y] = 0;
    }
      
                        
   /*
     Does the comparence. Initiates a binary and of mask and destination
     If the integer value equals the network number, then we have a match
   */
   netComp = atoi(network) ;
   dstComp = atoi(mask) & atoi(destination);
 
   if (netComp != dstComp) {
    // printf("Does not Match!\n");
    //exit(1);
    return 0;
   }
 
  }
  
    // printf("Matches!!\n");
    return 1;
 
}

static int
not_here(char *s)
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static double
constant(char *name, int len, int arg)
{
    errno = EINVAL;
    return 0;
}


MODULE = Cisco::ShowIPRoute::Parser PACKAGE = Cisco::ShowIPRoute::Parser

PROTOTYPES: ENABLE

int
NetCheck(a, b, c)
	char *  a
	char *  b
	char *  c

