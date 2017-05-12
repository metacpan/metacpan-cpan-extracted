#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

#include "ppport.h"

#include <ctapi.h>
#include <ctbcs.h>

#include "const-c.inc"

MODULE = Chipcard::CTAPI		PACKAGE = Chipcard::CTAPI		

INCLUDE: const-xs.inc

PROTOTYPES: DISABLE

int
CT_init(context, port)
    unsigned short context
    unsigned short port
    CODE:
        RETVAL = CT_init(context, port);
    OUTPUT:
        RETVAL

int
CT_close(context)
    unsigned short context
    CODE:
        RETVAL = CT_close(context);
    OUTPUT:
        RETVAL

void
CT_data(context, dest, src, cmdlen, cmd, rsplen)
    unsigned short context
    unsigned char  dest
    unsigned char  src
    unsigned short cmdlen
    unsigned char  *cmd
    unsigned short rsplen

    INIT:
        unsigned char response[256]; /* Buffer for response from CTAPI */
        int  res;                    /* Numeric ctapi call result      */
        /*
        int  i;
        */
        
    PPCODE:
        /* automatic response length handling */
        if (rsplen == 0) {
            rsplen = 255;
        }
        
        /* call CTAPI */
        res = CT_data(context, &dest, &src, cmdlen, cmd, &rsplen, response);

        /* some debugging output */
        /*
        printf("Context    : %d\n", context);
        printf("Destination: %d\n", dest);
        printf("Source     : %d\n", src);
        printf("Cmdlength  : %d\n", cmdlen);
        printf("Result     : %d\n", res);
        printf("Rsp length : %d\n", rsplen);
        
        printf("Response   : ");
        for (i=0; i<rsplen; i++) {
            printf ("%X ", response[i]);
        }
        printf("\n");
        */
        
        /* prepare return values */
        XPUSHs(sv_2mortal(newSVnv(res)));       /* numerical return value */
        XPUSHs(sv_2mortal(newSVnv(rsplen)));    /* response length */
        XPUSHs(sv_2mortal(newSVpv(response, rsplen)));  /* response */
        
        
