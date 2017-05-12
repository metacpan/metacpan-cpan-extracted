#define PERL_NO_GET_CONTEXT
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"

//#include "ppport.h"

MODULE = Algorithm::NCS               PACKAGE = Algorithm::NCS

PROTOTYPES: ENABLE

unsigned int
xs_ncs(a, b)
INPUT:
    AV * a
    AV * b
INIT:    
    const unsigned int xl = 2 + av_len(a);
    const unsigned int yl = 2 + av_len(b);
    unsigned int i;
    unsigned int j;
    unsigned int k;
    unsigned int* x;
    unsigned int* y;
    unsigned int** c;
    Newx(x, xl-1, unsigned int);
    for(i=0; i<xl-1; i++){
        x[i] = SvUVx(av_shift(a));
    }

    Newx(y, yl-1, unsigned int);
    for(i=0; i<yl-1; i++){
        y[i] = SvUVx(av_shift(b));
        }

    Newx(c, xl, unsigned int*);
    for(i=0; i < xl; i++){
        Newxz(c[i], yl, unsigned int);
        }
CODE:

    for( i=1; i<xl; i++){
        for( j=1; j<yl; j++){
            c[i][j] = c[i-1][j] > c[i][j-1] ? 
                      c[i-1][j] : c[i][j-1]; 
            for(k=1; k<i+1  &&  k<j+1  &&  x[i-k] == y[j-k] ; k++)
               if (c[i][j] < c[i-k][j-k] + (k+1)*k/2 ) 
                   c[i][j] = c[i-k][j-k] + (k+1)*k/2;
        }
    }
    RETVAL = c[xl-1][yl-1];
    Safefree(x);
    Safefree(y);
    for(unsigned int i=0; i<xl; i++)
        Safefree(c[i]);
    Safefree(c);
OUTPUT:
    RETVAL


