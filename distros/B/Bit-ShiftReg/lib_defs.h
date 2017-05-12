#ifndef LIB_DEFINITIONS
#define LIB_DEFINITIONS
/*****************************************************************************/
/*  MODULE NAME:  lib_defs.h                            MODULE TYPE:  (dat)  */
/*****************************************************************************/
/*  MODULE IMPORTS:                                                          */
/*****************************************************************************/

/*****************************************************************************/
/*  MODULE INTERFACE:                                                        */
/*****************************************************************************/

/* Note: weird names are used here in order to avoid name conflicts! */

typedef  unsigned   char    base;

/* = a BYTE, the BASE for everything (mnemonic: also starts with a "b") */

typedef  unsigned   int     unit;

/* = a machine WORD, the basic UNIT (mnemonic: unit is an anagram of uint!) */

typedef  unsigned   long    longunit;
typedef  unsigned   short   shortunit;

typedef  unsigned   char    N_char;
typedef  unsigned   int     N_int;
typedef  unsigned   long    N_long;
typedef  unsigned   short   N_short;

/* mnemonic 1: the natural numbers, N = { 0, 1, 2, 3, ... } */
/* mnemonic 2: Nnnn = u_N_signed, _N_ot signed */

typedef  signed     char    Z_char;
typedef  signed     int     Z_int;
typedef  signed     long    Z_long;
typedef  signed     short   Z_short;

/* mnemonic 1: the whole numbers, Z = { 0, -1, 1, -2, 2, -3, 3, ... } */
/* mnemonic 2: Zzzz = Ssss_igned */

typedef  void               *voidptr;

typedef  base               *baseptr;
typedef  unit               *unitptr;
typedef  longunit           *longunitptr;
typedef  shortunit          *shortunitptr;

typedef  unsigned   char    *N_charptr;
typedef  unsigned   int     *N_intptr;
typedef  unsigned   long    *N_longptr;
typedef  unsigned   short   *N_shortptr;

typedef  signed     char    *Z_charptr;
typedef  signed     int     *Z_intptr;
typedef  signed     long    *Z_longptr;
typedef  signed     short   *Z_shortptr;

#undef  FALSE
#define FALSE       (0==1)

#undef  TRUE
#define TRUE        (0==0)

typedef enum { false = FALSE , true = TRUE } boolean;

#define blockdef(name,size)         unsigned char name[size]
#define blocktypedef(name,size)     typedef unsigned char name[size]

#define and         &&      /* logical (boolean) operators: lower case */
#define or          ||
#define not         !

#define AND         &       /* binary (bitwise) operators: UPPER CASE */
#define OR          |
#define XOR         ^
#define NOT         ~
#define SHL         <<
#define SHR         >>

#ifdef EXTENDED_LIB_DEFINITIONS

#define mod         %       /* arithmetic operators */

#define BELL        '\a'    /* bell             0x07 */
#define BEL         '\a'    /* bell             0x07 */
#define BACKSPACE   '\b'    /* backspace        0x08 */
#define BS          '\b'    /* backspace        0x08 */
#define TAB         '\t'    /* tab              0x09 */
#define HT          '\t'    /* horizontal tab   0x09 */
#define LINEFEED    '\n'    /* linefeed         0x0A */
#define NEWLINE     '\n'    /* newline          0x0A */
#define LF          '\n'    /* linefeed         0x0A */
#define VTAB        '\v'    /* vertical tab     0x0B */
#define VT          '\v'    /* vertical tab     0x0B */
#define FORMFEED    '\f'    /* formfeed         0x0C */
#define NEWPAGE     '\f'    /* newpage          0x0C */
#define CR          '\r'    /* carriage return  0x0D */

typedef             struct
{
    base        l;
    base        h;
}                   twobases;

typedef             struct
{
    base        a;
    base        b;
    base        c;
    base        d;
}                   fourbases;

typedef             struct
{
    unit        l;
    unit        h;
}                   twounits;

/*******************************/
/* implementation dependent!!! */
/*   (assumes int = 2 bytes)   */
/*******************************/

typedef             union
{
    unit        x;
    twobases    z;
}                   unitreg;

/**********************************************/
/*        implementation dependent!!!         */
/* (assumes long = 4 bytes and int = 2 bytes) */
/**********************************************/

typedef             union
{
    longunit    x;
    twounits    y;
    fourbases   z;
}                   longunitreg;

#define lobyte(x)           (((int)(x)) & 0xFF)
#define hibyte(x)           ((((int)(x)) >> 8) & 0xFF)

#endif

/*****************************************************************************/
/*  MODULE RESOURCES:                                                        */
/*****************************************************************************/

/*****************************************************************************/
/*  MODULE IMPLEMENTATION:                                                   */
/*****************************************************************************/

/*****************************************************************************/
/*  AUTHOR:  Steffen Beyer                                                   */
/*****************************************************************************/
/*  VERSION:  3.0                                                            */
/*****************************************************************************/
/*  VERSION HISTORY:                                                         */
/*****************************************************************************/
/*    01.11.93    Created                                                    */
/*    16.02.97    Version 3.0                                                */
/*****************************************************************************/
/*  COPYRIGHT (C) 1993-1997 BY:  Steffen Beyer                               */
/*****************************************************************************/
#endif
