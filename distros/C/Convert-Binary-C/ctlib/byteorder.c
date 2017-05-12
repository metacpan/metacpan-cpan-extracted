/*******************************************************************************
*
* MODULE: ctype.c
*
********************************************************************************
*
* DESCRIPTION: ANSI C data type objects
*
********************************************************************************
*
* Copyright (c) 2002-2015 Marcus Holland-Moritz. All rights reserved.
* This program is free software; you can redistribute it and/or modify
* it under the same terms as Perl itself.
*
*******************************************************************************/

/*===== GLOBAL INCLUDES ======================================================*/

#include <ctype.h>
#include <assert.h>


/*===== LOCAL INCLUDES =======================================================*/

#include "byteorder.h"


/*===== DEFINES ==============================================================*/

#ifndef NULL
#define NULL ((void *) 0)
#endif

/*----------------------------------------------------------*/
/* reading/writing integers in big/little endian byte order */
/* depending on the native byte order of the system         */
/*----------------------------------------------------------*/

#if ARCH_NATIVE_BYTEORDER == ARCH_BYTEORDER_BIG_ENDIAN

/*--------------------*/
/* big endian systems */
/*--------------------*/

#define GET_LE_WORD(ptr, value, sign)                                          \
          value = (sign ## _16)                                                \
                  ( ( (u_16) *( (const u_8 *) ((ptr)+0) ) <<  0)               \
                  | ( (u_16) *( (const u_8 *) ((ptr)+1) ) <<  8)               \
                  )

#define GET_LE_LONG(ptr, value, sign)                                          \
          value = (sign ## _32)                                                \
                  ( ( (u_32) *( (const u_8 *) ((ptr)+0) ) <<  0)               \
                  | ( (u_32) *( (const u_8 *) ((ptr)+1) ) <<  8)               \
                  | ( (u_32) *( (const u_8 *) ((ptr)+2) ) << 16)               \
                  | ( (u_32) *( (const u_8 *) ((ptr)+3) ) << 24)               \
                  )

#if ARCH_NATIVE_64_BIT_INTEGER

#define GET_LE_LONGLONG(ptr, value, sign)                                      \
          value = (sign ## _64)                                                \
                  ( ( (u_64) *( (const u_8 *) ((ptr)+0) ) <<  0)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+1) ) <<  8)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+2) ) << 16)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+3) ) << 24)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+4) ) << 32)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+5) ) << 40)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+6) ) << 48)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+7) ) << 56)               \
                  )

#endif

#define SET_LE_WORD(ptr, value)                                                \
          do {                                                                 \
            register u_16 v = value;                                           \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >>  0) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >>  8) & 0xFF);                   \
          } while (0)

#define SET_LE_LONG(ptr, value)                                                \
          do {                                                                 \
            register u_32 v = value;                                           \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >>  0) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+2)) = (u_8) ((v >> 16) & 0xFF);                   \
            *((u_8 *) ((ptr)+3)) = (u_8) ((v >> 24) & 0xFF);                   \
          } while (0)

#if ARCH_NATIVE_64_BIT_INTEGER

#define SET_LE_LONGLONG(ptr, value)                                            \
          do {                                                                 \
            register u_64 v = value;                                           \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >>  0) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+2)) = (u_8) ((v >> 16) & 0xFF);                   \
            *((u_8 *) ((ptr)+3)) = (u_8) ((v >> 24) & 0xFF);                   \
            *((u_8 *) ((ptr)+4)) = (u_8) ((v >> 32) & 0xFF);                   \
            *((u_8 *) ((ptr)+5)) = (u_8) ((v >> 40) & 0xFF);                   \
            *((u_8 *) ((ptr)+6)) = (u_8) ((v >> 48) & 0xFF);                   \
            *((u_8 *) ((ptr)+7)) = (u_8) ((v >> 56) & 0xFF);                   \
          } while (0)

#endif

#ifdef CAN_UNALIGNED_ACCESS

#define GET_BE_WORD(ptr, value, sign) \
          value = (sign ## _16) ( *( (const u_16 *) (ptr) ) )

#define GET_BE_LONG(ptr, value, sign) \
          value = (sign ## _32) ( *( (const u_32 *) (ptr) ) )

#if ARCH_NATIVE_64_BIT_INTEGER

#define GET_BE_LONGLONG(ptr, value, sign) \
          value = (sign ## _64) ( *( (const u_64 *) (ptr) ) )

#endif

#define SET_BE_WORD(ptr, value) \
          *( (u_16 *) (ptr) ) = (u_16) value

#define SET_BE_LONG(ptr, value) \
          *( (u_32 *) (ptr) ) = (u_32) value

#if ARCH_NATIVE_64_BIT_INTEGER

#define SET_BE_LONGLONG(ptr, value) \
          *( (u_64 *) (ptr) ) = (u_64) value

#endif

#else

#define GET_BE_WORD(ptr, value, sign)                                          \
          do {                                                                 \
            if (((unsigned long) (ptr)) % 2)                                   \
              value = (sign ## _16)                                            \
                      ( ( (u_16) *( (const u_8 *) ((ptr)+0) ) <<  8)           \
                      | ( (u_16) *( (const u_8 *) ((ptr)+1) ) <<  0)           \
                      );                                                       \
            else                                                               \
              value = (sign ## _16) ( *( (const u_16 *) (ptr) ) );             \
          } while (0)

#define GET_BE_LONG(ptr, value, sign)                                          \
          do {                                                                 \
            switch (((unsigned long) (ptr)) % 4)                               \
            {                                                                  \
              case 0:                                                          \
                value = (sign ## _32) ( *( (const u_32 *) (ptr) ) );           \
                break;                                                         \
                                                                               \
              case 2:                                                          \
                value = (sign ## _32)                                          \
                        ( ( (u_32) *( (const u_16 *) ((ptr)+0) ) << 16)        \
                        | ( (u_32) *( (const u_16 *) ((ptr)+2) ) <<  0)        \
                        );                                                     \
                break;                                                         \
                                                                               \
              default:                                                         \
                value = (sign ## _32)                                          \
                        ( ( (u_32) *( (const u_8 *)  ((ptr)+0) ) << 24)        \
                        | ( (u_32) *( (const u_16 *) ((ptr)+1) ) <<  8)        \
                        | ( (u_32) *( (const u_8 *)  ((ptr)+3) ) <<  0)        \
                        );                                                     \
                break;                                                         \
            }                                                                  \
          } while (0)

#if ARCH_NATIVE_64_BIT_INTEGER

#define GET_BE_LONGLONG(ptr, value, sign)                                      \
          do {                                                                 \
            value = (sign ## _64)                                              \
                    ( ( (u_64) *( (const u_8 *)  ((ptr)+0) ) << 56)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+1) ) << 48)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+2) ) << 40)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+3) ) << 32)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+4) ) << 24)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+5) ) << 16)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+6) ) <<  8)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+7) ) <<  0)            \
                    );                                                         \
          } while (0)

#endif

#define SET_BE_WORD(ptr, value)                                                \
          do {                                                                 \
            if (((unsigned long) (ptr)) % 2)                                   \
            {                                                                  \
              register u_16 v = (u_16) value;                                  \
              *((u_8 *) ((ptr)+0)) = (u_8) ((v >> 8) & 0xFF);                  \
              *((u_8 *) ((ptr)+1)) = (u_8) ((v >> 0) & 0xFF);                  \
            }                                                                  \
            else                                                               \
              *( (u_16 *) (ptr) ) = (u_16) value;                              \
          } while (0)

#define SET_BE_LONG(ptr, value)                                                \
          do {                                                                 \
            switch (((unsigned long) (ptr)) % 4)                               \
            {                                                                  \
              case 0:                                                          \
                *( (u_32 *) (ptr) ) = (u_32) value;                            \
                break;                                                         \
                                                                               \
              case 2:                                                          \
                {                                                              \
                  register u_32 v = (u_32) value;                              \
                  *((u_16 *) ((ptr)+0)) = (u_16) ((v >> 16) & 0xFFFF);         \
                  *((u_16 *) ((ptr)+2)) = (u_16) ((v >>  0) & 0xFFFF);         \
                }                                                              \
                break;                                                         \
                                                                               \
              default:                                                         \
                {                                                              \
                  register u_32 v = (u_32) value;                              \
                  *((u_8 *)  ((ptr)+0)) = (u_8)  ((v >> 24) & 0xFF  );         \
                  *((u_16 *) ((ptr)+1)) = (u_16) ((v >>  8) & 0xFFFF);         \
                  *((u_8 *)  ((ptr)+3)) = (u_8)  ((v >>  0) & 0xFF  );         \
                }                                                              \
                break;                                                         \
            }                                                                  \
          } while (0)

#if ARCH_NATIVE_64_BIT_INTEGER

#define SET_BE_LONGLONG(ptr, value)                                            \
          do {                                                                 \
            register u_64 v = value;                                           \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >> 56) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >> 48) & 0xFF);                   \
            *((u_8 *) ((ptr)+2)) = (u_8) ((v >> 40) & 0xFF);                   \
            *((u_8 *) ((ptr)+3)) = (u_8) ((v >> 32) & 0xFF);                   \
            *((u_8 *) ((ptr)+4)) = (u_8) ((v >> 24) & 0xFF);                   \
            *((u_8 *) ((ptr)+5)) = (u_8) ((v >> 16) & 0xFF);                   \
            *((u_8 *) ((ptr)+6)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+7)) = (u_8) ((v >>  0) & 0xFF);                   \
          } while (0)

#endif

#endif

#elif ARCH_NATIVE_BYTEORDER == ARCH_BYTEORDER_LITTLE_ENDIAN

/*-----------------------*/
/* little endian systems */
/*-----------------------*/

#define GET_BE_WORD(ptr, value, sign)                                          \
          value = (sign ## _16)                                                \
                  ( ( (u_16) *( (const u_8 *) ((ptr)+0) ) <<  8)               \
                  | ( (u_16) *( (const u_8 *) ((ptr)+1) ) <<  0)               \
                  )

#define GET_BE_LONG(ptr, value, sign)                                          \
          value = (sign ## _32)                                                \
                  ( ( (u_32) *( (const u_8 *) ((ptr)+0) ) << 24)               \
                  | ( (u_32) *( (const u_8 *) ((ptr)+1) ) << 16)               \
                  | ( (u_32) *( (const u_8 *) ((ptr)+2) ) <<  8)               \
                  | ( (u_32) *( (const u_8 *) ((ptr)+3) ) <<  0)               \
                  )

#if ARCH_NATIVE_64_BIT_INTEGER

#define GET_BE_LONGLONG(ptr, value, sign)                                      \
          value = (sign ## _64)                                                \
                  ( ( (u_64) *( (const u_8 *) ((ptr)+0) ) << 56)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+1) ) << 48)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+2) ) << 40)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+3) ) << 32)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+4) ) << 24)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+5) ) << 16)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+6) ) <<  8)               \
                  | ( (u_64) *( (const u_8 *) ((ptr)+7) ) <<  0)               \
                  )

#endif

#define SET_BE_WORD(ptr, value)                                                \
          do {                                                                 \
            register u_16 v = (u_16) value;                                    \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >>  0) & 0xFF);                   \
          } while (0)

#define SET_BE_LONG(ptr, value)                                                \
          do {                                                                 \
            register u_32 v = (u_32) value;                                    \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >> 24) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >> 16) & 0xFF);                   \
            *((u_8 *) ((ptr)+2)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+3)) = (u_8) ((v >>  0) & 0xFF);                   \
          } while (0)

#if ARCH_NATIVE_64_BIT_INTEGER

#define SET_BE_LONGLONG(ptr, value)                                            \
          do {                                                                 \
            register u_64 v = value;                                           \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >> 56) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >> 48) & 0xFF);                   \
            *((u_8 *) ((ptr)+2)) = (u_8) ((v >> 40) & 0xFF);                   \
            *((u_8 *) ((ptr)+3)) = (u_8) ((v >> 32) & 0xFF);                   \
            *((u_8 *) ((ptr)+4)) = (u_8) ((v >> 24) & 0xFF);                   \
            *((u_8 *) ((ptr)+5)) = (u_8) ((v >> 16) & 0xFF);                   \
            *((u_8 *) ((ptr)+6)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+7)) = (u_8) ((v >>  0) & 0xFF);                   \
          } while (0)

#endif

#ifdef CAN_UNALIGNED_ACCESS

#define GET_LE_WORD(ptr, value, sign) \
          value = (sign ## _16) ( *( (const u_16 *) (ptr) ) )

#define GET_LE_LONG(ptr, value, sign) \
          value = (sign ## _32) ( *( (const u_32 *) (ptr) ) )

#if ARCH_NATIVE_64_BIT_INTEGER

#define GET_LE_LONGLONG(ptr, value, sign) \
          value = (sign ## _64) ( *( (const u_64 *) (ptr) ) )

#endif

#define SET_LE_WORD(ptr, value) \
          *( (u_16 *) (ptr) ) = (u_16) value

#define SET_LE_LONG(ptr, value) \
          *( (u_32 *) (ptr) ) = (u_32) value

#if ARCH_NATIVE_64_BIT_INTEGER

#define SET_LE_LONGLONG(ptr, value) \
          *( (u_64 *) (ptr) ) = (u_64) value

#endif

#else

#define GET_LE_WORD(ptr, value, sign)                                          \
          do {                                                                 \
            if (((unsigned long) (ptr)) % 2)                                   \
              value = (sign ## _16)                                            \
                      ( ( (u_16) *( (const u_8 *) ((ptr)+0) ) <<  0)           \
                      | ( (u_16) *( (const u_8 *) ((ptr)+1) ) <<  8)           \
                      );                                                       \
            else                                                               \
              value = (sign ## _16) ( *( (const u_16 *) (ptr) ) );             \
          } while (0)

#define GET_LE_LONG(ptr, value, sign)                                          \
          do {                                                                 \
            switch (((unsigned long) (ptr)) % 4)                               \
            {                                                                  \
              case 0:                                                          \
                value = (sign ## _32) ( *( (const u_32 *) (ptr) ) );           \
                break;                                                         \
                                                                               \
              case 2:                                                          \
                value = (sign ## _32)                                          \
                        ( ( (u_32) *( (const u_16 *) ((ptr)+0) ) <<  0)        \
                        | ( (u_32) *( (const u_16 *) ((ptr)+2) ) << 16)        \
                        );                                                     \
                break;                                                         \
                                                                               \
              default:                                                         \
                value = (sign ## _32)                                          \
                        ( ( (u_32) *( (const u_8 *)  ((ptr)+0) ) <<  0)        \
                        | ( (u_32) *( (const u_16 *) ((ptr)+1) ) <<  8)        \
                        | ( (u_32) *( (const u_8 *)  ((ptr)+3) ) << 24)        \
                        );                                                     \
                break;                                                         \
            }                                                                  \
          } while (0)

#if ARCH_NATIVE_64_BIT_INTEGER

#define GET_LE_LONGLONG(ptr, value, sign)                                      \
          do {                                                                 \
            value = (sign ## _64)                                              \
                    ( ( (u_64) *( (const u_8 *)  ((ptr)+0) ) <<  0)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+1) ) <<  8)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+2) ) << 16)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+3) ) << 24)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+4) ) << 32)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+5) ) << 40)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+6) ) << 48)            \
                    | ( (u_64) *( (const u_8 *)  ((ptr)+7) ) << 56)            \
                    );                                                         \
          } while (0)

#endif

#define SET_LE_WORD(ptr, value)                                                \
          do {                                                                 \
            if (((unsigned long) (ptr)) % 2)                                   \
            {                                                                  \
              register u_16 v = (u_16) value;                                  \
              *((u_8 *) ((ptr)+0)) = (u_8) ((v >> 0) & 0xFF);                  \
              *((u_8 *) ((ptr)+1)) = (u_8) ((v >> 8) & 0xFF);                  \
            }                                                                  \
            else                                                               \
              *( (u_16 *) (ptr) ) = (u_16) value;                              \
          } while (0)

#define SET_LE_LONG(ptr, value)                                                \
          do {                                                                 \
            switch (((unsigned long) (ptr)) % 4)                               \
            {                                                                  \
              case 0:                                                          \
                *( (u_32 *) (ptr) ) = (u_32) value;                            \
                break;                                                         \
                                                                               \
              case 2:                                                          \
                {                                                              \
                  register u_32 v = (u_32) value;                              \
                  *((u_16 *) ((ptr)+0)) = (u_16) ((v >>  0) & 0xFFFF);         \
                  *((u_16 *) ((ptr)+2)) = (u_16) ((v >> 16) & 0xFFFF);         \
                }                                                              \
                break;                                                         \
                                                                               \
              default:                                                         \
                {                                                              \
                  register u_32 v = (u_32) value;                              \
                  *((u_8 *)  ((ptr)+0)) = (u_8)  ((v >>  0) & 0xFF  );         \
                  *((u_16 *) ((ptr)+1)) = (u_16) ((v >>  8) & 0xFFFF);         \
                  *((u_8 *)  ((ptr)+3)) = (u_8)  ((v >> 24) & 0xFF  );         \
                }                                                              \
                break;                                                         \
            }                                                                  \
          } while (0)

#if ARCH_NATIVE_64_BIT_INTEGER

#define SET_LE_LONGLONG(ptr, value)                                            \
          do {                                                                 \
            register u_64 v = value;                                           \
            *((u_8 *) ((ptr)+0)) = (u_8) ((v >>  0) & 0xFF);                   \
            *((u_8 *) ((ptr)+1)) = (u_8) ((v >>  8) & 0xFF);                   \
            *((u_8 *) ((ptr)+2)) = (u_8) ((v >> 16) & 0xFF);                   \
            *((u_8 *) ((ptr)+3)) = (u_8) ((v >> 24) & 0xFF);                   \
            *((u_8 *) ((ptr)+4)) = (u_8) ((v >> 32) & 0xFF);                   \
            *((u_8 *) ((ptr)+5)) = (u_8) ((v >> 40) & 0xFF);                   \
            *((u_8 *) ((ptr)+6)) = (u_8) ((v >> 48) & 0xFF);                   \
            *((u_8 *) ((ptr)+7)) = (u_8) ((v >> 56) & 0xFF);                   \
          } while (0)

#endif

#endif

#else /* ARCH_NATIVE_BYTEORDER */

#error "unknown native byte order"

#endif /* ARCH_NATIVE_BYTEORDER */

#define GET_BE_BYTE(ptr, value, sign) \
          value = *((const sign ## _8 *) (ptr))

#define GET_LE_BYTE(ptr, value, sign) \
          value = *((const sign ## _8 *) (ptr))

#define SET_BE_BYTE(ptr, value) \
          *((u_8 *) (ptr)) = (u_8) value

#define SET_LE_BYTE(ptr, value) \
          *((u_8 *) (ptr)) = (u_8) value

#define ALL_64_BITS (~((u_64) 0)) 
#define ALL_32_BITS (~((u_32) 0)) 


/*===== TYPEDEFS =============================================================*/

enum shift_direction {
  SHIFT_LEFT,
  SHIFT_RIGHT
};


/*===== STATIC FUNCTION PROTOTYPES ===========================================*/

/*===== EXTERNAL VARIABLES ===================================================*/

/*===== GLOBAL VARIABLES =====================================================*/

/*===== STATIC VARIABLES =====================================================*/

/*===== STATIC FUNCTIONS =====================================================*/

static int  integer2string(IntValue *pInt);
static void string2integer(IntValue *pInt);


/*===== FUNCTIONS ============================================================*/

/*******************************************************************************
*
*   ROUTINE: integer2string
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Turn an integer into a string.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static int integer2string(IntValue *pInt)
{
#if ARCH_NATIVE_64_BIT_INTEGER
  register u_64 val;
#else
  register u_32 hval, lval, tval, umod, lmod;
#endif

  int stack[20], len, sp;
  char *pStr = pInt->string;

  if (pStr == NULL)
    return 0;

  len = sp = 0;

#if ARCH_NATIVE_64_BIT_INTEGER

  if (pInt->sign && pInt->value.s < 0)
  {
    val = -pInt->value.s;
    *pStr++ = '-';
    len++;
  }
  else
    val = pInt->value.u;

  while (val > 0)
    stack[sp++] = val % 10, val /= 10;

#else

  hval = pInt->value.u.h;
  lval = pInt->value.u.l;

  if (pInt->sign && pInt->value.s.h < 0)
  {
    *pStr++ = '-';
    len++;

    if (lval-- == 0)
      hval--;

    hval = ~hval;
    lval = ~lval;
  }

  while (hval > 0)
  {
    static const u_32 CDIV[10] = {
      0x00000000, 0x19999999, 0x33333333, 0x4CCCCCCC, 0x66666666,
      0x80000000, 0x99999999, 0xB3333333, 0xCCCCCCCC, 0xE6666666
    };
    static const u_32 CMOD[10] =
    { 0U, 6U, 2U, 8U, 4U, 0U, 6U, 2U, 8U, 4U };

    umod  = hval % 10; hval /= 10;
    lmod  = lval % 10; lval /= 10;

    lmod += CMOD[umod];
    tval  = CDIV[umod];

    if (lmod >= 10)
      lmod -= 10, tval++;

    lval += tval;

    if (lval < tval)
      hval++;

    stack[sp++] = lmod;
  }

  while (lval > 0)
    stack[sp++] = lval % 10, lval /= 10;

#endif

  len += sp;

  if (sp == 0)
    *pStr++ = '0';
  else
    while(sp-- > 0)
      *pStr++ = (char) ('0' + stack[sp]);

  *pStr = '\0';

  return len;
}

/*******************************************************************************
*
*   ROUTINE: string2integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Nov 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Turn a dec/hex/oct string into an integer.
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

static void string2integer(IntValue *pInt)
{
  register int val;
  register const char *pStr = pInt->string;

#if ARCH_NATIVE_64_BIT_INTEGER
  register u_64 iv = 0;
#else
  register u_32 hval = 0, lval = 0;
#endif

  pInt->sign = 0;

  while (isspace(*pStr))  /* ignore leading whitespace */
    pStr++;

  switch (*pStr)
  {
    default : break;
    case '-': pInt->sign = 1;
    case '+': while(isspace(*++pStr));
  }

  if (*pStr == '0')  /* seems to be hex or octal */
  {
    pStr++;

    if (*pStr == 'x')  /* must be hex */
    {
      while (isxdigit(val = *++pStr))
      {
        if (isdigit(val))
          val -= (int) '0';
        else if (isupper(val))
          val -= (int) 'A' - 10;
        else
          val -= (int) 'a' - 10;

#if ARCH_NATIVE_64_BIT_INTEGER

        iv = (iv << 4) | (val & 0xF);

#else

        hval = (hval << 4) | (lval >> 28);
        lval = (lval << 4) | (val & 0xF);

#endif
      }
    }
    else if (*pStr == 'b')  /* must be binary */
    {
      pStr++;

      while (*pStr == '0' || *pStr == '1')
      {
        val = (int) (*pStr - '0');

#if ARCH_NATIVE_64_BIT_INTEGER

        iv = (iv << 1) | (val & 0x1);

#else

        hval = (hval << 1) | (lval >> 31);
        lval = (lval << 1) | (val & 0x1);

#endif

        pStr++;
      }
    }
    else  /* must be octal */
    {
      while (isdigit(*pStr) && *pStr != '8' && *pStr != '9')
      {
        val = (int) (*pStr - '0');

#if ARCH_NATIVE_64_BIT_INTEGER

        iv = (iv << 3) | (val & 0x7);

#else

        hval = (hval << 3) | (lval >> 29);
        lval = (lval << 3) | (val & 0x7);

#endif

        pStr++;
      }
    }
  }
  else  /* must be decimal */
  {

#if ARCH_NATIVE_64_BIT_INTEGER

    while (isdigit(val = *pStr++))
      iv = 10*iv + (val - (int) '0');

#else

    register u_32 temp;

    do
    {
      if (!isdigit(val = *pStr++))
        goto end_of_string;

      lval = 10*lval + (val - (int) '0');
    }
    while (lval < 429496729);

    while (isdigit(val = *pStr++))
    {
      hval = ((hval << 3) | (lval >> 29))
           + ((hval << 1) | (lval >> 31));

      lval <<= 1;

      temp = lval + (lval << 2);

      if (temp < lval)
        hval++;

      lval = temp + (int) (val - '0');

      if (lval < temp)
        hval++;
    }

#endif

  }

#if ARCH_NATIVE_64_BIT_INTEGER

  if (pInt->sign)
    pInt->value.s = -iv;
  else
    pInt->value.u = iv;

#else

  end_of_string:

  if (pInt->sign && (hval || lval))
  {
    if (lval-- == 0)
      hval--;

    pInt->value.u.h = ~hval;
    pInt->value.u.l = ~lval;
  }
  else
  {
    pInt->value.u.h = hval;
    pInt->value.u.l = lval;
  }

#endif
}

/*******************************************************************************
*
*   ROUTINE: shift_integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Apr 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Bit-shift an u_64 value left or right.
*
*   ARGUMENTS:
*
*     RETURNS: 
*
*******************************************************************************/

static void shift_integer(u_64 *pval, unsigned bits, enum shift_direction dir)
{
  assert(bits <= 64);

#if ARCH_NATIVE_64_BIT_INTEGER

  switch (dir)
  {
    case SHIFT_LEFT:
      *pval <<= bits;
      break;

    case SHIFT_RIGHT:
      *pval >>= bits;
      break;
  }

#else

  switch (dir)
  {
    case SHIFT_LEFT:
      if (bits >= 32)
      {
        pval->h = pval->l << (bits - 32);
        pval->l = 0;
      }
      else
      {
        pval->h = (pval->h << bits) | (pval->l >> (32 - bits));
        pval->l <<= bits;
      }
      break;

    case SHIFT_RIGHT:
      if (bits >= 32)
      {
        pval->l = pval->h >> (bits - 32);
        pval->h = 0;
      }
      else
      {
        pval->l = (pval->l >> bits) | (pval->h << (32 - bits));
        pval->h >>= bits;
      }
      break;
  }

#endif
}

/*******************************************************************************
*
*   ROUTINE: mask_integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Apr 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Bit-mask an u_64 value.
*
*   ARGUMENTS:
*
*     RETURNS: 
*
*******************************************************************************/

static void mask_integer(u_64 *pval, unsigned bits, unsigned shift, int extend_msb)
{
  u_64 mask;
  const unsigned msb = bits + shift - 1;

  assert(bits <= 64);
  assert(shift <= 64);
  assert((bits + shift) <= 64);

#if ARCH_NATIVE_64_BIT_INTEGER

  mask = (ALL_64_BITS >> (64 - bits)) << shift;
  *pval &= mask;

  if (extend_msb && bits > 0)
    if (*pval & (((u_64)1) << msb))
      *pval |= ALL_64_BITS << msb;

#else

  if (bits > 32)
  {
    mask.h = (ALL_32_BITS >> (64 - bits));
    mask.l = ALL_32_BITS;
  }
  else
  {
    mask.h = 0;
    mask.l = (ALL_32_BITS >> (32 - bits));
  }

  if (shift > 0)
    shift_integer(&mask, shift, SHIFT_LEFT);

  pval->h &= mask.h;
  pval->l &= mask.l;

  if (extend_msb && bits > 0)
  {
    if (msb >= 32)
    {
      if (pval->h & (((u_32)1) << (msb - 32)))
        pval->h |= ALL_32_BITS << (msb - 32);
    }
    else
    {
      if (pval->l & (((u_32)1) << msb))
      {
        pval->h  = ALL_32_BITS;
        pval->l |= ALL_32_BITS << msb;
      }
    }
  }

#endif
}

/*******************************************************************************
*
*   ROUTINE: merge_integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Apr 2005
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Merge an u_64 value into another one.
*
*   ARGUMENTS:
*
*     RETURNS: 
*
*******************************************************************************/

static void merge_integer(u_64 *dest, const u_64 *src, unsigned bits, unsigned shift)
{
  u_64 mask;

  assert(bits <= 64);
  assert(shift <= 64);
  assert((bits + shift) <= 64);

#if ARCH_NATIVE_64_BIT_INTEGER

  mask = (ALL_64_BITS >> (64 - bits)) << shift;
  *dest = (*dest & (~mask)) | (*src & mask);

#else

  if (bits > 32)
  {
    mask.h = (ALL_32_BITS >> (64 - bits));
    mask.l = ALL_32_BITS;
  }
  else
  {
    mask.h = 0;
    mask.l = (ALL_32_BITS >> (32 - bits));
  }

  if (shift > 0)
    shift_integer(&mask, shift, SHIFT_LEFT);

  dest->h = (dest->h & (~mask.h)) | (src->h & mask.h);
  dest->l = (dest->l & (~mask.l)) | (src->l & mask.l);

#endif
}

/*******************************************************************************
*
*   ROUTINE: string_is_integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Mar 2004
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION: Decide if a string contains a dec/hex/oct integer.
*
*   ARGUMENTS:
*
*     RETURNS: Zero if the string doesn't hold an interpretable number.
*              The base (i.e. 2, 8, 10 or 16) if the string is a number.
*
*******************************************************************************/

int string_is_integer(const char *pStr)
{
  int rval;

  /* ignore leading whitespace */
  while (isspace(*pStr))
    pStr++;

  switch (*pStr)
  {
    default : break;
    case '-':
    case '+': while (isspace(*++pStr));
  }

  if (*pStr == '0')  /* seems to be hex or octal */
  {
    pStr++;

    if (*pStr == 'x')  /* must be hex */
    {
      pStr++;
      while (isxdigit(*pStr))
        pStr++;
      rval = 16;
    }
    else if (*pStr == 'b')  /* must be binary */
    {
      pStr++;
      while (*pStr == '0' || *pStr == '1')
        pStr++;
      rval = 2;
    }
    else  /* must be octal */
    {
      while (isdigit(*pStr) && *pStr != '8' && *pStr != '9')
        pStr++;
      rval = 8;
    }
  }
  else  /* must be decimal */
  {
    while (isdigit(*pStr))
      pStr++;
    rval = 10;
  }

  /* ignore trailing whitespace */
  while (isspace(*pStr))
    pStr++;

  return *pStr ? 0 : rval;
}

/*******************************************************************************
*
*   ROUTINE: fetch_integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

#if ARCH_NATIVE_64_BIT_INTEGER

#define FETCH(bo, what)                                                        \
        do {                                                                   \
          if (sign)                                                            \
            GET_ ## bo ## _ ## what (ptr, iv.value.s, i);                      \
          else                                                                 \
            GET_ ## bo ## _ ## what (ptr, iv.value.u, u);                      \
        } while (0)

#else

#define FETCH(bo, what)                                                        \
        do {                                                                   \
          if(sign)                                                             \
          {                                                                    \
            GET_ ## bo ## _ ## what (ptr, iv.value.s.l, i);                    \
            iv.value.s.h = ((i_32) iv.value.s.l) < 0 ? -1 : 0;                 \
          }                                                                    \
          else                                                                 \
          {                                                                    \
            GET_ ## bo ## _ ## what (ptr, iv.value.u.l, u);                    \
            iv.value.u.h = 0;                                                  \
          }                                                                    \
        } while (0)

#endif

void fetch_integer(unsigned size, unsigned sign, unsigned bits, unsigned shift,
                   CByteOrder bo, const void *src, IntValue *pIV)
{
  register const u_8 *ptr = (const u_8 *) src;
  IntValue iv = *pIV;

  switch (size)
  {
    case 1:
      FETCH(BE, BYTE);
      break;

    case 2:
      if (bo == CBO_BIG_ENDIAN)
        FETCH(BE, WORD);
      else
        FETCH(LE, WORD);
      break;

    case 4:
      if (bo == CBO_BIG_ENDIAN)
        FETCH(BE, LONG);
      else
        FETCH(LE, LONG);
      break;

    case 8:
#if ARCH_NATIVE_64_BIT_INTEGER
      if (bo == CBO_BIG_ENDIAN)
        FETCH(BE, LONGLONG);
      else
        FETCH(LE, LONGLONG);
#else
      if (bo == CBO_BIG_ENDIAN)
      {
        GET_BE_LONG(ptr,   iv.value.u.h, u);
        GET_BE_LONG(ptr+4, iv.value.u.l, u);
      }
      else
      {
        GET_LE_LONG(ptr,   iv.value.u.l, u);
        GET_LE_LONG(ptr+4, iv.value.u.h, u);
      }
#endif
      break;

    default:
      break;
  }

  iv.sign = sign;

  if (bits > 0)
  {
    if (shift > 0)
      shift_integer(&iv.value.u, shift, SHIFT_RIGHT);

    mask_integer(&iv.value.u, bits, 0, sign);
  }

  if (iv.string)
    (void) integer2string(&iv);

  *pIV = iv;
}

#undef FETCH

/*******************************************************************************
*
*   ROUTINE: store_integer
*
*   WRITTEN BY: Marcus Holland-Moritz             ON: Oct 2002
*   CHANGED BY:                                   ON:
*
********************************************************************************
*
* DESCRIPTION:
*
*   ARGUMENTS:
*
*     RETURNS:
*
*******************************************************************************/

#if ARCH_NATIVE_64_BIT_INTEGER

#define STORE(bo, what)                                                        \
        do {                                                                   \
          SET_ ## bo ## _ ## what (ptr, iv.value.u);                           \
        } while (0)

#else

#define STORE(bo, what)                                                        \
        do {                                                                   \
          SET_ ## bo ## _ ## what (ptr, iv.value.u.l);                         \
        } while (0)

#endif

void store_integer(unsigned size, unsigned bits, unsigned shift,
                   CByteOrder bo, void *dest, const IntValue *pIV)
{
  register u_8 *ptr = (u_8 *) dest;
  IntValue iv = *pIV;

  if (iv.string)
    string2integer(&iv);

  if (bits > 0)
  {
    IntValue orig;

    orig.string = NULL;

    fetch_integer(size, 0, 0, 0, bo, dest, &orig);

    if (shift > 0)
      shift_integer(&iv.value.u, shift, SHIFT_LEFT);

    merge_integer(&orig.value.u, &iv.value.u, bits, shift);

    iv = orig;
  }

  switch (size)
  {
    case 1:
      STORE(BE, BYTE);
      break;

    case 2:
      if (bo == CBO_BIG_ENDIAN)
        STORE(BE, WORD);
      else
        STORE(LE, WORD);
      break;

    case 4:
      if (bo == CBO_BIG_ENDIAN)
        STORE(BE, LONG);
      else
        STORE(LE, LONG);
      break;

    case 8:
#if ARCH_NATIVE_64_BIT_INTEGER
      if (bo == CBO_BIG_ENDIAN)
        STORE(BE, LONGLONG);
      else
        STORE(LE, LONGLONG);
#else
      if (bo == CBO_BIG_ENDIAN)
      {
        SET_BE_LONG(ptr,   iv.value.u.h);
        SET_BE_LONG(ptr+4, iv.value.u.l);
      }
      else
      {
        SET_LE_LONG(ptr,   iv.value.u.l);
        SET_LE_LONG(ptr+4, iv.value.u.h);
      }
#endif
      break;

    default:
      break;
  }
}

#undef STORE

