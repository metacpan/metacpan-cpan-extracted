#ifndef _H_UTIL_LIBWCS_PERL
#define _H_UTIL_LIBWCS_PERL

#include "wcs.h"

#define TBYTE        11
#define TLOGICAL     14
#define TSTRING      16
#define TUSHORT      20
#define TSHORT       21
#define TUINT        30
#define TINT         31
#define TULONG       40
#define TLONG        41
#define TFLOAT       42
#define TDOUBLE      82
#define TCOMPLEX     83
#define TDBLCOMPLEX 163

#define FIXME(s)

typedef char logical;
typedef unsigned char byte;
typedef float cmp;
typedef double dblcmp;

void * pack1D( SV * arg, int datatype );
void * packND( SV * arg, int datatype );
void pack_element( SV* work, SV** arg, int datatype );

void* get_mortalspace( long n, int datatype );
AV* coerce1D ( SV* arg, long n );
AV* coerceND ( SV* arg, int ndims, long *dims );
void unpack1D ( SV* arg, void * var, long n, int datatype );
void unpack2D ( SV* arg, void * var, long *dims, int datatype );
void unpack3D ( SV* arg, void * var, long *dims, int datatype );
void unpackND ( SV* arg, void * var, int ndims, long *dims, int datatype );
void unpack2scalar ( SV* arg, void * var, long n, int datatype );
void unpackScalar( SV* arg, void *var, int datatype );
void swap_dims(int ndims, long *dims);
int PerlyUnpacking(int value);
int sizeof_datatype(int datatype);

#endif /* _H_UTIL_LIBWCS_PERL */
