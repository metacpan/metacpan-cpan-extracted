/*
  Copyright (c) 1997 by Steffen Beyer. All rights reserved.
  This package is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.
*/


#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"


#include "lib_defs.h"


static N_char BIT_byte;
static N_char LSB_byte = 1;
static N_char MSB_byte;

static N_short BIT_short;
static N_short LSB_short = 1;
static N_short MSB_short;

static N_int   BIT_int;
static N_int   LSB_int = 1;
static N_int   MSB_int;

static N_long  BIT_long;
static N_long  LSB_long = 1;
static N_long  MSB_long;


void config_byte(void)
{
    N_char sample = LSB_byte;

    BIT_byte = 0;

    while (sample <<= 1) BIT_byte++;   /* determine # of bits */

    MSB_byte = (LSB_byte << BIT_byte++);
}


void config_short(void)
{
    N_short sample = LSB_short;

    BIT_short = 0;

    while (sample <<= 1) BIT_short++;   /* determine # of bits */

    MSB_short = (LSB_short << BIT_short++);
}


void config_int(void)
{
    N_int sample = LSB_int;

    BIT_int = 0;

    while (sample <<= 1) BIT_int++;   /* determine # of bits */

    MSB_int = (LSB_int << BIT_int++);
}


void config_long(void)
{
    N_long sample = LSB_long;

    BIT_long = 0;

    while (sample <<= 1) BIT_long++;   /* determine # of bits */

    MSB_long = (LSB_long << BIT_long++);
}


MODULE = Bit::ShiftReg		PACKAGE = Bit::ShiftReg


PROTOTYPES: DISABLE


BOOT:
{
    config_byte();
    config_short();
    config_int();
    config_long();
}


void
Version()
PPCODE:
{
    EXTEND(sp,1);
    PUSHs(sv_2mortal(newSVpv("2.0",0)));
}


N_char
bits_of_byte()
CODE:
{
    RETVAL = BIT_byte;
}
OUTPUT:
RETVAL


N_short
bits_of_short()
CODE:
{
    RETVAL = BIT_short;
}
OUTPUT:
RETVAL


N_int
bits_of_int()
CODE:
{
    RETVAL = BIT_int;
}
OUTPUT:
RETVAL


N_long
bits_of_long()
CODE:
{
    RETVAL = BIT_long;
}
OUTPUT:
RETVAL


boolean
LSB_byte(value)
N_char	value
CODE:
{
    RETVAL = ((value AND LSB_byte) != 0);
}
OUTPUT:
RETVAL


boolean
MSB_byte(value)
N_char	value
CODE:
{
    RETVAL = ((value AND MSB_byte) != 0);
}
OUTPUT:
RETVAL


boolean
LSB_short(value)
N_short	value
CODE:
{
    RETVAL = ((value AND LSB_short) != 0);
}
OUTPUT:
RETVAL


boolean
MSB_short(value)
N_short	value
CODE:
{
    RETVAL = ((value AND MSB_short) != 0);
}
OUTPUT:
RETVAL


boolean
LSB_int(value)
N_int	value
CODE:
{
    RETVAL = ((value AND LSB_int) != 0);
}
OUTPUT:
RETVAL


boolean
MSB_int(value)
N_int	value
CODE:
{
    RETVAL = ((value AND MSB_int) != 0);
}
OUTPUT:
RETVAL


boolean
LSB_long(value)
N_long	value
CODE:
{
    RETVAL = ((value AND LSB_long) != 0);
}
OUTPUT:
RETVAL


boolean
MSB_long(value)
N_long	value
CODE:
{
    RETVAL = ((value AND MSB_long) != 0);
}
OUTPUT:
RETVAL


boolean
ROL_byte(value)
N_char	value
CODE:
{
    RETVAL = ((value AND MSB_byte) != 0);

    value <<= 1;
    if (RETVAL) value |= LSB_byte;
}
OUTPUT:
RETVAL
value


boolean
SHL_byte(value,carry)
N_char	value
boolean	carry
CODE:
{
    RETVAL = ((value AND MSB_byte) != 0);

    carry &= LSB_byte;

    value <<= 1;
    if (carry) value |= LSB_byte;
}
OUTPUT:
RETVAL
value


boolean
ROR_byte(value)
N_char	value
CODE:
{
    RETVAL = ((value AND LSB_byte) != 0);

    value >>= 1;
    if (RETVAL) value |= MSB_byte;
}
OUTPUT:
RETVAL
value


boolean
SHR_byte(value,carry)
N_char	value
boolean	carry
CODE:
{
    RETVAL = ((value AND LSB_byte) != 0);

    carry &= LSB_byte;

    value >>= 1;
    if (carry) value |= MSB_byte;
}
OUTPUT:
RETVAL
value


boolean
ROL_short(value)
N_short	value
CODE:
{
    RETVAL = ((value AND MSB_short) != 0);

    value <<= 1;
    if (RETVAL) value |= LSB_short;
}
OUTPUT:
RETVAL
value


boolean
SHL_short(value,carry)
N_short	value
boolean	carry
CODE:
{
    RETVAL = ((value AND MSB_short) != 0);

    carry &= LSB_short;

    value <<= 1;
    if (carry) value |= LSB_short;
}
OUTPUT:
RETVAL
value


boolean
ROR_short(value)
N_short	value
CODE:
{
    RETVAL = ((value AND LSB_short) != 0);

    value >>= 1;
    if (RETVAL) value |= MSB_short;
}
OUTPUT:
RETVAL
value


boolean
SHR_short(value,carry)
N_short	value
boolean	carry
CODE:
{
    RETVAL = ((value AND LSB_short) != 0);

    carry &= LSB_short;

    value >>= 1;
    if (carry) value |= MSB_short;
}
OUTPUT:
RETVAL
value


boolean
ROL_int(value)
N_int	value
CODE:
{
    RETVAL = ((value AND MSB_int) != 0);

    value <<= 1;
    if (RETVAL) value |= LSB_int;
}
OUTPUT:
RETVAL
value


boolean
SHL_int(value,carry)
N_int	value
boolean	carry
CODE:
{
    RETVAL = ((value AND MSB_int) != 0);

    carry &= LSB_int;

    value <<= 1;
    if (carry) value |= LSB_int;
}
OUTPUT:
RETVAL
value


boolean
ROR_int(value)
N_int	value
CODE:
{
    RETVAL = ((value AND LSB_int) != 0);

    value >>= 1;
    if (RETVAL) value |= MSB_int;
}
OUTPUT:
RETVAL
value


boolean
SHR_int(value,carry)
N_int	value
boolean	carry
CODE:
{
    RETVAL = ((value AND LSB_int) != 0);

    carry &= LSB_int;

    value >>= 1;
    if (carry) value |= MSB_int;
}
OUTPUT:
RETVAL
value


boolean
ROL_long(value)
N_long	value
CODE:
{
    RETVAL = ((value AND MSB_long) != 0);

    value <<= 1;
    if (RETVAL) value |= LSB_long;
}
OUTPUT:
RETVAL
value


boolean
SHL_long(value,carry)
N_long	value
boolean	carry
CODE:
{
    RETVAL = ((value AND MSB_long) != 0);

    carry &= LSB_long;

    value <<= 1;
    if (carry) value |= LSB_long;
}
OUTPUT:
RETVAL
value


boolean
ROR_long(value)
N_long	value
CODE:
{
    RETVAL = ((value AND LSB_long) != 0);

    value >>= 1;
    if (RETVAL) value |= MSB_long;
}
OUTPUT:
RETVAL
value


boolean
SHR_long(value,carry)
N_long	value
boolean	carry
CODE:
{
    RETVAL = ((value AND LSB_long) != 0);

    carry &= LSB_long;

    value >>= 1;
    if (carry) value |= MSB_long;
}
OUTPUT:
RETVAL
value


