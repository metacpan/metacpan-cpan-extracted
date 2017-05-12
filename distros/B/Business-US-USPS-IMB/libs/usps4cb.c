/*******************************************************************************
**      usps4cb.c
**
**      U.S. Postal Service Intelligent Mail Barcode Encoder V1R2M2
**
**      warning - as written, this code generates correct barcodes - changes must
**                        be verified as producing valid barcodes
*******************************************************************************/
 
#pragma map(usps4cb,"USPS4CB")
#pragma map(uspsvcb,"USPSVCB")
 
/*******************************************************************************
**                     Change Record
**                     -------------
**    Date    Change Flag Who          Description
** ---------- ----------- --- --------------------------------------------------
** 2005/10/26   TPG009   RBP Update eyecatcher version & date V1R2M2 2011/05/14
** 2011/05/14   TPG008   RBP Remove null termination BarStringPtr[65], caused overlay
** 2005/10/26   TPG007   RBP Update eyecatcher version & date V1R2M0 2008/03/03
** 2005/10/26   TPG006   RBP Add entry point 'uspsvcb'
** 2005/10/22   TPG005   RBP Change entry point to 'usps4cb'
** 2005/10/19   TPG004   RBP Add eyecatcher to identify this module
** 2005/10/18   TPG003   RBP Fix check for NULL parameters
** 2005/10/10   TPG002   RBP Add SAS/C control cards like <resident.h>
** 2005/10/10   TPG001   RBP D.Self:changes for mainframe input string nulls
** 2005/09/01   None     RBP Upload Windows code ASCII -> EBCDIC unchanged
**
*******************************************************************************/
 
#define NO_ABEND                          /* TPG002 */
#define NO_IO                             /* TP0002 */
/*#include <resident.h>*/                     /* TPG002 */
 
/*******************************************************************************
**
** Includes
**
*******************************************************************************/
 
#include <stdio.h>
#include <string.h>
#include "usps4cb.h"                       /* TPG005 */
 
/*******************************************************************************
**
** Compilation Control
**
*******************************************************************************/
 
#define SELF_TEST
/* #define USE_64_BIT_MATH */
 
 
/*******************************************************************************
**
** Definitions
**
*******************************************************************************/
 
#ifndef BOOLEAN
#define BOOLEAN  int
#endif
#ifndef TRUE
#define TRUE     (0==0)
#endif
#ifndef FALSE
#define FALSE    (0==1)
#endif
 
#define unsigned32  unsigned int
#ifdef USE_64_BIT_MATH
#define unsigned64  unsigned long long
#endif
 
 
 
 
/*******************************************************************************
**
** Constants
**
*******************************************************************************/
 
#define TABLE_2_OF_13_SIZE    78
#define TABLE_5_OF_13_SIZE  1287
 
 
 
 
/*******************************************************************************
**
** Debug Control
**
*******************************************************************************/
 
/* #define SHOW_TABLE_GENERATION */
/* #define SHOW_INTERMEDIATES */
 
 
 
 
/*******************************************************************************
**
** Internal Types
**
*******************************************************************************/
 
typedef struct NumberRecordType
{
  int  Base;
  int  Number;
} NumberRecordType;
 
 
 
 
/*******************************************************************************
**
** Local Variables
**
*******************************************************************************/
 
const  char EyeCatcher[] = "USPS4CB V1R2M2 2011/05/14";  /* TPG004, TPG007, TPG009 */
 
static int  BarTopCharacterIndexArray[65]    = {  4, 0, 2, 6, 3,  5, 1, 9, 8, 7,  1, 2, 0, 6, 4,  8, 2, 9, 5, 3,  0, 1, 3, 7, 4,  6, 8, 9, 2, 0,  5, 1, 9, 4, 3,  8, 6, 7, 1, 2,  4, 3, 9, 5, 7,  8, 3, 0, 2, 1,  4, 0, 9, 1, 7,  0, 2, 4, 6, 3,  7, 1, 9, 5, 8 };
static int  BarBottomCharacterIndexArray[65] = {  7, 1, 9, 5, 8,  0, 2, 4, 6, 3,  5, 8, 9, 7, 3,  0, 6, 1, 7, 4,  6, 8, 9, 2, 5,  1, 7, 5, 4, 3,  8, 7, 6, 0, 2,  5, 4, 9, 3, 0,  1, 6, 8, 2, 0,  4, 5, 9, 6, 7,  5, 2, 6, 3, 8,  5, 1, 9, 8, 7,  4, 0, 2, 6, 3 };
static int  BarTopCharacterShiftArray[65]    = {  3, 0, 8,11, 1, 12, 8,11,10, 6,  4,12, 2, 7, 9,  6, 7, 9, 2, 8,  4, 0,12, 7,10,  9, 0, 7,10, 5,  7, 9, 6, 8, 2, 12, 1, 4, 2, 0,  1, 5, 4, 6,12,  1, 0, 9, 4, 7,  5,10, 2, 6, 9, 11, 2,12, 6, 7,  5,11, 0, 3, 2 };
static int  BarBottomCharacterShiftArray[65] = {  2,10,12, 5, 9,  1, 5, 4, 3, 9, 11, 5,10, 1, 6,  3, 4, 1,10, 0,  2,11, 8, 6, 1, 12, 3, 8, 6, 4,  4,11, 0, 6, 1,  9,11, 5, 3, 7,  3,10, 7,11, 8,  2,10, 3, 5, 8,  0, 3,12,11, 8,  4, 5, 1, 3, 0,  7,12, 9, 8,10 };
 
 
static BOOLEAN Table2of13InitializedFlag = FALSE;
static BOOLEAN Table5of13InitializedFlag = FALSE;
 
static int  Table2of13[TABLE_2_OF_13_SIZE];
static int  Table5of13[TABLE_5_OF_13_SIZE];
 
#ifdef SELF_TEST
static BOOLEAN EncoderSelfTestedFlag = FALSE;
#endif
 
 
 
 
/*******************************************************************************
**
** Internal Functions
**
*******************************************************************************/
 
/*******************************************************************************
** MultiplyBytesByShort
*******************************************************************************/
 
static BOOLEAN
MultiplyBytesByShort( unsigned char  *ByteArrayPtr  ,
                      int             NumberOfBytes ,
                      unsigned short  Multiplicand  )
 
{
  int         ByteIndex;
  unsigned32  Carry32,Temp32;
 
 
  /* Check for obviously incorrect inputs */
  if ( ByteArrayPtr == NULL )
    return FALSE;
  if ( NumberOfBytes < 1 )
    return FALSE;
 
  /* Do groups of two bytes */
  Carry32 = 0;
  for ( ByteIndex = NumberOfBytes-1; ByteIndex > 0; ByteIndex -= 2 )
  {
    /* Fill two low bytes of four byte variable with packed data */
    Temp32  = (unsigned32)ByteArrayPtr[ByteIndex];
    Temp32 |= (unsigned32)ByteArrayPtr[ByteIndex-1] << 8;
 
    /* 0x0000???? * 0x0000???? = 0xCCCCRRRR (C-carry data, R-result data) */
    Temp32 *= (unsigned32)Multiplicand;
    Temp32 += Carry32;
 
    /* The two low bytes (result) go back into the packed data */
    ByteArrayPtr[ByteIndex  ] = (unsigned char)Temp32;
    ByteArrayPtr[ByteIndex-1] = (unsigned char)(Temp32 >> 8);
 
    /* The two high bytes will be the carry data for the next pass */
    Carry32 = Temp32 >> 16;
  }
 
  /* Single byte left over? */
  if ( ByteIndex == 0 )
  {
    Temp32  = (unsigned32)ByteArrayPtr[0];
    Temp32 *= (unsigned32)Multiplicand;
    Temp32 += Carry32;
 
    /* The low byte goes back into the packed data */
    ByteArrayPtr[0] = (unsigned char)(Temp32 & 0xFF);
  }
 
  return TRUE;
}
 
 
 
 
/*******************************************************************************
** DivideBytesByShort
*******************************************************************************/
 
static BOOLEAN
DivideBytesByShort( unsigned char  *ByteArrayPtr  ,
                    int             NumberOfBytes ,
                    unsigned short  Divisor       ,
                    unsigned short *RemainderPtr  )
 
{
  int         ByteIndex;
  unsigned32  Temp32,Remainder32;
 
 
  /* Check for obviously incorrect inputs */
  if ( ByteArrayPtr == NULL )
    return FALSE;
  if ( NumberOfBytes < 2 )
    return FALSE;
  if ( Divisor == 0 )
    return FALSE;
 
  /* If we do not have an even number of bytes, do the first byte separately */
  if ( (NumberOfBytes % 2) == 1 )
  {
    Temp32 = (unsigned32)ByteArrayPtr[0];
    Remainder32  = Temp32 % Divisor;
    Temp32      /= Divisor;
 
    ByteArrayPtr[0] = (unsigned char)Temp32;
    ByteIndex = 1;
  }
  else
  {
    Remainder32 = 0;
    ByteIndex   = 0;
  }
 
  /* Now that we have an even number of bytes left, go from left to right in
  groups of two */
  for ( ; ByteIndex < NumberOfBytes; ByteIndex += 2 )
  {
    /* Build up a slice consisting of the previous slices remainder in the
        top 16 and data in the low 16 */
    Temp32  = Remainder32 << 16;
    Temp32 |= (unsigned32)ByteArrayPtr[ByteIndex] << 8;
    Temp32 |= (unsigned32)ByteArrayPtr[ByteIndex+1];
 
    Remainder32  = Temp32 % Divisor;
    Temp32      /= Divisor;
 
    /* Replace slice of dividend with slice of quotient */
    ByteArrayPtr[ByteIndex  ] = (unsigned char)(Temp32 >> 8);
    ByteArrayPtr[ByteIndex+1] = (unsigned char)Temp32;
  }
 
  *RemainderPtr = Remainder32;
  return TRUE;
}
 
 
 
 
/*******************************************************************************
** AddShortToBytes
*******************************************************************************/
 
static BOOLEAN
AddShortToBytes( unsigned char  *ByteArrayPtr  ,
                 int             NumberOfBytes ,
                 unsigned short  Addend        )
 
{
  int         ByteIndex;
  unsigned32  Carry32,Temp32;
 
 
  /* Check for obviously incorrect inputs */
  if ( ByteArrayPtr == NULL )
    return FALSE;
  if ( NumberOfBytes < 1 )
    return FALSE;
 
  /* Fill two low bytes of four byte variable with packed data */
  Temp32  = (unsigned32)ByteArrayPtr[NumberOfBytes-1];
  Temp32 |= (unsigned32)ByteArrayPtr[NumberOfBytes-2] << 8;
 
  /* Add a two byte value into the four byte variable */
  Temp32 += (unsigned32)Addend;
 
  /* The two low bytes go back into the packed area */
  ByteArrayPtr[NumberOfBytes-1] = (unsigned char)Temp32;
  ByteArrayPtr[NumberOfBytes-2] = (unsigned char)(Temp32 >> 8);
 
  /* A single bit carry may be generated */
  Carry32 = Temp32 > 0xFFFF;
 
  /* Propagate carry up */
  for (ByteIndex = NumberOfBytes-3;(Carry32 == 1)&&(ByteIndex > 0);ByteIndex--)
  {
    Temp32 = Carry32 + (unsigned32) ByteArrayPtr[ByteIndex];
 
    ByteArrayPtr[ByteIndex] = (unsigned char)Temp32;
 
    Carry32 = Temp32 > 0xFF;
  }
 
  return TRUE;
}
 
 
 
 
/*******************************************************************************
** ConvertFromBytesToMultiBase
*******************************************************************************/
 
static BOOLEAN
ConvertFromBytesToMultiBase( unsigned char    *ByteArrayPtr    ,
                             int               NumberOfBytes   ,
                             NumberRecordType *NumberArrayPtr  ,
                             int               NumberOfNumbers )
 
{
  unsigned short  Remainder;
  int             NumberIndex;
 
 
  for ( NumberIndex = NumberOfNumbers-1; NumberIndex >= 0; NumberIndex-- )
  {
    if ( DivideBytesByShort( ByteArrayPtr                                     ,
                             NumberOfBytes                                    ,
                             (unsigned short)NumberArrayPtr[NumberIndex].Base ,
                             &Remainder                                       ) != TRUE)
      return FALSE;
    NumberArrayPtr[NumberIndex].Number = (int) Remainder;
  }
 
  return TRUE;
}
 
 
 
 
#ifndef USE_64_BIT_MATH
/*******************************************************************************
** ConvertFromMultiBaseToBytes
*******************************************************************************/
 
static BOOLEAN
ConvertFromMultiBaseToBytes( NumberRecordType *NumberArrayPtr  ,
                             int               NumberOfNumbers ,
                             unsigned char    *ByteArrayPtr    ,
                             int               NumberOfBytes   )
 
{
  int  NumberIndex;
 
 
  memset( ByteArrayPtr, 0, NumberOfBytes );
 
  for ( NumberIndex = 0; NumberIndex < NumberOfNumbers; NumberIndex++ )
  {
    if ( MultiplyBytesByShort( ByteArrayPtr                                     ,
                               NumberOfBytes                                    ,
                               (unsigned short)NumberArrayPtr[NumberIndex].Base ) != TRUE )
      return FALSE;
    if ( AddShortToBytes( ByteArrayPtr                                       ,
                          NumberOfBytes                                      ,
                          (unsigned short)NumberArrayPtr[NumberIndex].Number ) != TRUE)
      return FALSE;
  }
 
  return TRUE;
}
#endif
 
 
 
 
/*******************************************************************************
** ReverseShort
*******************************************************************************/
 
static unsigned short
ReverseShort( unsigned short  Input )
 
{
  unsigned short  Reverse = 0;
  int             Index;
 
 
  for ( Index = 0; Index < 16; Index++ )
  {
    Reverse <<= 1;
    Reverse  |= Input & 1;
    Input   >>= 1;
  }
 
  return Reverse;
}
 
 
 
 
/*******************************************************************************
** InitializeNof13Table
*******************************************************************************/
 
static BOOLEAN
InitializeNof13Table( int *TableNof13  ,
                      int  N           ,
                      int  TableLength )
 
{
  int      Count,Reverse;
  int      LUT_LowerIndex,LUT_UpperIndex;
  int      BitCount;
  int      BitIndex;
  BOOLEAN  SymmetricFlag;
 
 
  /* Count up to 2^13 and find all those values that have N bits on */
  LUT_LowerIndex = 0;
  LUT_UpperIndex = TableLength - 1;
 
  for ( Count = 0; Count < 8192; Count++ )
  {
    BitCount = 0;
    for ( BitIndex = 0; BitIndex < 13; BitIndex++ )
      BitCount += ((Count & (1 << BitIndex)) != 0);
 
    /* If we don't have the right number of bits on, go on to the next value */
    if ( BitCount != N )
      continue;
 
    Reverse = ReverseShort( Count ) >> 3;
 
    SymmetricFlag = Count == Reverse;
 
#ifdef SHOW_TABLE_GENERATION
    printf("Count %4d  Value %4.4X  Reverse %4.4X ",Count,Count,Reverse);
    if ( SymmetricFlag == TRUE )
      printf("Symmetric\n");
    else
      printf("\n");
#endif
 
    /* If the reverse is less than count, we have already visited this pair before */
    if ( Reverse < Count )
    {
#ifdef SHOW_TABLE_GENERATION
      printf("  already used\n");
#endif
      continue;
    }
 
    if ( SymmetricFlag == TRUE )
    {
      TableNof13[LUT_UpperIndex] = Count;
      LUT_UpperIndex -= 1;
    }
    else
    {
      TableNof13[LUT_LowerIndex] = Count;
      LUT_LowerIndex += 1;
      TableNof13[LUT_LowerIndex] = Reverse;
      LUT_LowerIndex += 1;
    }
  }
 
  /* We better have the exact correct number of table entries */
  if ( LUT_LowerIndex != (LUT_UpperIndex+1) )
    return FALSE;
 
#ifdef SHOW_TABLE_GENERATION
  for ( LUT_LowerIndex = 0; LUT_LowerIndex < TableLength; LUT_LowerIndex++ )
    printf("Index %4d  Value %4.4X\n",LUT_LowerIndex,TableNof13[LUT_LowerIndex]);
#endif
 
  return TRUE;
}
 
 
 
 
/*******************************************************************************
** GetNof13Table
*******************************************************************************/
 
static BOOLEAN
GetNof13Table( int   N                    ,
               int **TableArrayPtrPtr     ,
               int  *NumberOfTableEntries )
 
{
  switch ( N )
  {
    case 2:
      if ( Table2of13InitializedFlag == FALSE )
        if ( InitializeNof13Table( Table2of13, 2, TABLE_2_OF_13_SIZE) != TRUE )
          return FALSE;
      *TableArrayPtrPtr     = Table2of13;
      *NumberOfTableEntries = TABLE_2_OF_13_SIZE;
      Table2of13InitializedFlag = TRUE;
      return TRUE;
    case 5:
      if ( Table5of13InitializedFlag == FALSE )
        if ( InitializeNof13Table( Table5of13, 5, TABLE_5_OF_13_SIZE) != TRUE )
          return FALSE;
      *TableArrayPtrPtr     = Table5of13;
      *NumberOfTableEntries = TABLE_5_OF_13_SIZE;
      Table5of13InitializedFlag = TRUE;
      return TRUE;
    default:
      return FALSE;
  }
}
 
 
 
 
/*******************************************************************************
** GenerateCRC11FrameCheckSequence
*******************************************************************************/
 
static unsigned short
GenerateCRC11FrameCheckSequence( unsigned char  *ByteArrayPtr )
 
{
  unsigned short  GeneratorPolynomial = 0x0F35;
  unsigned short  FrameCheckSequence  = 0x07FF;
  unsigned short  Data;
  int             ByteIndex,Bit;
 
 
  /* Do most significant byte skipping most significant bit */
  Data = *ByteArrayPtr << 5;
  ByteArrayPtr++;
  for ( Bit = 2; Bit < 8; Bit++ )
  {
    if ( (FrameCheckSequence ^ Data) & 0x400 )
      FrameCheckSequence = (FrameCheckSequence << 1) ^ GeneratorPolynomial;
    else
      FrameCheckSequence = (FrameCheckSequence << 1);
    FrameCheckSequence &= 0x7FF;
    Data <<= 1;
  }
 
  /* Do rest of the bytes */
  for ( ByteIndex = 1; ByteIndex < 13; ByteIndex++ )
  {
    Data = *ByteArrayPtr << 3;
    ByteArrayPtr++;
    for ( Bit = 0; Bit < 8; Bit++ )
    {
      if ( (FrameCheckSequence ^ Data) & 0x0400 )
        FrameCheckSequence = (FrameCheckSequence << 1) ^ GeneratorPolynomial;
      else
        FrameCheckSequence = (FrameCheckSequence << 1);
      FrameCheckSequence &= 0x7FF;
      Data <<= 1;
    }
  }
 
  return FrameCheckSequence;
}
 
 
 
 
/*******************************************************************************
** Encode
*******************************************************************************/
 
static int
Encode( char *TrackingStringPtr ,
        char *RoutingStringPtr  ,
        char *BarStringPtr      )
 
{
  unsigned char     ByteArray[13];
  NumberRecordType  CodewordArray[10];
  NumberRecordType  CharacterArray[10];
  int               DigitIndex;
  int               CodewordIndex;
  int               CharacterIndex;
  int               BarIndex;
  int               BarTopArray[65],BarBottomArray[65];
  int              *Table2of13ArrayPtr;
  int               NumberOf2of13TableEntries;
  int              *Table5of13ArrayPtr;
  int               NumberOf5of13TableEntries;
  unsigned short    FrameCheckSequence11BitValue;
#ifdef USE_64_BIT_MATH
  unsigned64        ZipNumber;
#else
  NumberRecordType  ZipArray[12];
  NumberRecordType  AddArray[12];
#endif
#ifdef SHOW_INTERMEDIATES
  int               ByteIndex;
#endif
 
 
#ifdef SHOW_INTERMEDIATES
  printf("Tracking Data as digit string         \"%s\"\n",TrackingStringPtr);
  printf("Routing Data as digit string          \"%s\"\n",RoutingStringPtr);
#endif
 
#ifdef USE_64_BIT_MATH
  /* Convert ZIP from string to 64 bit value (only low 37 bits are needed) */
  ZipNumber = 0;
  for ( DigitIndex = 0; DigitIndex < strlen(RoutingStringPtr); DigitIndex++ )
    ZipNumber = ZipNumber * (unsigned long long)10 + (unsigned long long)(RoutingStringPtr[DigitIndex] - '0');
 
#ifdef SHOW_INTERMEDIATES
  printf("Routing Data as 37 bit Value          %lld\n",ZipNumber);
#endif
 
  /* Put length information into ZIP number */
  switch ( strlen( RoutingStringPtr ) )
  {
    case 0:
      /* Do nothing */
      break;
    case 5:
      /* Add 1 */
      ZipNumber += 1;
      break;
    case 9:
      /* Add 1 + 100000 */
      ZipNumber += 100001;
      break;
    case 11:
      /* Add 1 + 100000 + 1000000000 */
      ZipNumber += 1000100001;
      break;
    default:
      return USPS_FSB_ENCODER_API_ROUTE_STRING_BAD_LENGTH;
  }
 
#ifdef SHOW_INTERMEDIATES
  printf("Routing Data with embedded length     %lld\n",ZipNumber);
#endif
 
  /* Stuff ZIP into low end of ByteArray */
  memset( ByteArray, 0, 13 );
  ByteArray[12] = (unsigned char) ZipNumber;
  ByteArray[11] = (unsigned char) (ZipNumber >>  8);
  ByteArray[10] = (unsigned char) (ZipNumber >> 16);
  ByteArray[ 9] = (unsigned char) (ZipNumber >> 24);
  ByteArray[ 8] = (unsigned char) (ZipNumber >> 32);
 
#else
  /* Reset NumberRecord arrays before use */
  for ( DigitIndex = 0; DigitIndex < 12; DigitIndex++ )
  {
    ZipArray[DigitIndex].Base   = 10;
    ZipArray[DigitIndex].Number = 0;
    AddArray[DigitIndex].Base   = 10;
    AddArray[DigitIndex].Number = 0;
  }
 
  /* Fill out NumberRecord arrays according to routing length */
  switch ( strlen( RoutingStringPtr ) )
  {
    case 0:
      /* Do nothing, ZipArray and AddArray already set to zeros */
      break;
    case 5:
      for ( DigitIndex = 0; DigitIndex <  5; DigitIndex++ )
        ZipArray[DigitIndex+7].Number = (int) (RoutingStringPtr[DigitIndex] - '0');
      AddArray[11].Number = 1; /*          1 */
      break;
    case 9:
      for ( DigitIndex = 0; DigitIndex <  9; DigitIndex++ )
        ZipArray[DigitIndex+3].Number = (int) (RoutingStringPtr[DigitIndex] - '0');
      AddArray[11].Number = 1; /*          1 */
      AddArray[ 6].Number = 1; /*     100000 */
      break;
    case 11:
      for ( DigitIndex = 0; DigitIndex < 11; DigitIndex++ )
        ZipArray[DigitIndex+1].Number = (int) (RoutingStringPtr[DigitIndex] - '0');
      AddArray[11].Number = 1; /*          1 */
      AddArray[ 6].Number = 1; /*     100000 */
      AddArray[ 2].Number = 1; /* 1000000000 */
      break;
    default:
      return USPS_FSB_ENCODER_API_ROUTE_STRING_BAD_LENGTH;
  }
 
#ifdef SHOW_INTERMEDIATES
  printf("Routing Data as array                 ");
  for ( DigitIndex = 0; DigitIndex < 12; DigitIndex++ )
    printf("%1d",ZipArray[DigitIndex].Number);
  printf("\n");
  printf("Length Information as array           ");
  for ( DigitIndex = 0; DigitIndex < 12; DigitIndex++ )
    printf("%1d",AddArray[DigitIndex].Number);
  printf("\n");
#endif
 
  /* Add AddArray to ZipArray */
  for ( DigitIndex = 11; ; DigitIndex-- )
  {
    ZipArray[DigitIndex].Number += AddArray[DigitIndex].Number;
 
    if ( DigitIndex <= 0 )
      break;
 
    if ( ZipArray[DigitIndex].Number >= 10 )
    {
      ZipArray[DigitIndex  ].Number -= 10;
      ZipArray[DigitIndex-1].Number += 1;
    }
  }
 
#ifdef SHOW_INTERMEDIATES
  printf("Routing Data with embedded length     ");
  for ( DigitIndex = 0; DigitIndex < 12; DigitIndex++ )
    printf("%1d",ZipArray[DigitIndex].Number);
  printf("\n");
#endif
 
  /* Convert from 12 digits of base 10 to 13 bytes (only needs rightmost 37 bits at this point) */
  if ( ConvertFromMultiBaseToBytes( ZipArray, 12, ByteArray, 13 ) != TRUE )
    return USPS_FSB_ENCODER_API_BYTE_CONVERSION_FAILED;
 
#endif
 
#ifdef SHOW_INTERMEDIATES
  printf("Bytes with Routing Data               ");
  for ( ByteIndex = 0; ByteIndex < 13; ByteIndex++ )
    printf("%2.2X  ",ByteArray[ByteIndex]);
  printf("\n");
#endif
 
  /* Put tracking data into Byte Array */
  MultiplyBytesByShort( ByteArray, 13, (unsigned short) 10 );
  AddShortToBytes( ByteArray, 13, (unsigned short) (TrackingStringPtr[0] - '0') );
  MultiplyBytesByShort( ByteArray, 13, (unsigned short) 5 );
  AddShortToBytes( ByteArray, 13, (unsigned short) (TrackingStringPtr[1] - '0') );
  for ( DigitIndex = 2; DigitIndex < 20; DigitIndex++ )
  {
    MultiplyBytesByShort( ByteArray, 13, (unsigned short) 10 );
    AddShortToBytes( ByteArray, 13, (unsigned short) (TrackingStringPtr[DigitIndex] - '0') );
  }
 
#ifdef SHOW_INTERMEDIATES
  printf("Bytes with Routing and Tracking Data  ");
  for ( ByteIndex = 0; ByteIndex < 13; ByteIndex++ )
    printf("%2.2X  ",ByteArray[ByteIndex]);
  printf("\n");
#endif
 
  /* Generate a CRC FCS character on the 102 bit value */
   FrameCheckSequence11BitValue = GenerateCRC11FrameCheckSequence( ByteArray );
 
#ifdef SHOW_INTERMEDIATES
  printf("FCS (11 bits)                         %3.3X\n",FrameCheckSequence11BitValue);
#endif
 
  /* Get the 5 of 13 table we need */
  if ( GetNof13Table( 5, &Table5of13ArrayPtr, &NumberOf5of13TableEntries ) != TRUE )
    return USPS_FSB_ENCODER_API_RETRIEVE_TABLE_FAILED;
  /* Get the 2 of 13 table we need */
  if ( GetNof13Table( 2, &Table2of13ArrayPtr, &NumberOf2of13TableEntries ) != TRUE )
    return USPS_FSB_ENCODER_API_RETRIEVE_TABLE_FAILED;
 
  /* Convert to base that allows 5 or 2 of 13 representation. */
  for ( CodewordIndex = 0; CodewordIndex < 10; CodewordIndex++ )
  {
    CodewordArray[CodewordIndex].Base   = NumberOf5of13TableEntries + NumberOf2of13TableEntries;
    CodewordArray[CodewordIndex].Number = 0;
  }
  CodewordArray[0].Base = 659;
  CodewordArray[9].Base = 636;
  if ( ConvertFromBytesToMultiBase( ByteArray, 13, CodewordArray, 10 ) != TRUE )
    return USPS_FSB_ENCODER_API_CODEWORD_CONVERSION_FAILED;
 
#ifdef SHOW_INTERMEDIATES
  printf("Codewords,                            ");
  for ( CodewordIndex = 0; CodewordIndex < 10; CodewordIndex++ )
    printf("%4d  ",CodewordArray[CodewordIndex].Number);
  printf("\n");
#endif
 
  if ( CodewordArray[0].Number >= 659 )
    return USPS_FSB_ENCODER_API_CODEWORD_CONVERSION_FAILED;
  if ( CodewordArray[9].Number >= 636 )
    return USPS_FSB_ENCODER_API_CODEWORD_CONVERSION_FAILED;
 
  /* Put orientation information into the rightmost codeword */
  CodewordArray[9].Number = CodewordArray[9].Number * 2;
 
#ifdef SHOW_INTERMEDIATES
  printf("Codewords with orientation in Char J  ");
  for ( CodewordIndex = 0; CodewordIndex < 10; CodewordIndex++ )
    printf("%4d  ",CodewordArray[CodewordIndex].Number);
  printf("\n");
#endif
 
  /* Put the leftmost FCS bit into the leftmost codeword */
  if ( FrameCheckSequence11BitValue >> 10 )
    CodewordArray[0].Number += 659;
 
#ifdef SHOW_INTERMEDIATES
  printf("Codewords with orientation in Char J  ");
  for ( CodewordIndex = 0; CodewordIndex < 10; CodewordIndex++ )
    printf("%4d  ",CodewordArray[CodewordIndex].Number);
  printf("\n");
#endif
 
  /* Convert from codewords to 13 bit characters */
  for ( CharacterIndex = 0; CharacterIndex < 10; CharacterIndex++ )
  {
    if ( CodewordArray[CharacterIndex].Number >= NumberOf5of13TableEntries + NumberOf2of13TableEntries )
      return USPS_FSB_ENCODER_API_CHARACTER_RANGE_ERROR;
    else if ( CodewordArray[CharacterIndex].Number >= NumberOf5of13TableEntries )
    {
      CharacterArray[CharacterIndex].Base   = 8192;
      CharacterArray[CharacterIndex].Number = Table2of13ArrayPtr[CodewordArray[CharacterIndex].Number - NumberOf5of13TableEntries];
    }
    else
    {
      CharacterArray[CharacterIndex].Base   = 8192;
      CharacterArray[CharacterIndex].Number = Table5of13ArrayPtr[CodewordArray[CharacterIndex].Number];
    }
  }
 
#ifdef SHOW_INTERMEDIATES
  printf("Characters,                           ");
  for ( CharacterIndex = 0; CharacterIndex < 10; CharacterIndex++ )
    printf("%4.4X  ",CharacterArray[CharacterIndex].Number);
  printf("\n");
#endif
 
  /* Insert the FCS into the data by the following process:        */
  /*   for each character get the corresponding bit of the FCS     */
  /*     note that character 0 is the leftmost character while its */
  /*     corresponding FCS bit (0) is the rightmost in the FCS     */
  /*     if the bit value is:                                      */
  /*       0 - then leave the character as 5 of 13                 */
  /*       1 - reverse all bits values in the character which      */
  /*           makes it 8 of 13                                    */
  for ( CharacterIndex = 0; CharacterIndex < 10; CharacterIndex++ )
    if ( FrameCheckSequence11BitValue & (1 << CharacterIndex) )
      CharacterArray[CharacterIndex].Number = ~CharacterArray[CharacterIndex].Number & 0x1FFF;
 
#ifdef SHOW_INTERMEDIATES
  printf("Characters with FCS bits 0-9          ");
  for ( CharacterIndex = 0; CharacterIndex < 10; CharacterIndex++ )
    printf("%4.4X  ",CharacterArray[CharacterIndex].Number);
  printf("\n");
#endif
 
  /* Map 13 bit characters to their positions within the barcode */
  for ( BarIndex = 0; BarIndex < 65; BarIndex++ )
  {
    BarTopArray[BarIndex]    = (CharacterArray[BarTopCharacterIndexArray[BarIndex]].Number    >> BarTopCharacterShiftArray[BarIndex])    & 1;
    BarBottomArray[BarIndex] = (CharacterArray[BarBottomCharacterIndexArray[BarIndex]].Number >> BarBottomCharacterShiftArray[BarIndex]) & 1;
  }
 
  /* Convert the barcode to a string of characters representing the 4-state bars */
  for ( BarIndex = 0; BarIndex < 65; BarIndex++ )
    if ( BarTopArray[BarIndex] == 0 )
      if ( BarBottomArray[BarIndex] == 0 )
        BarStringPtr[BarIndex] = 'T';
      else
        BarStringPtr[BarIndex] = 'D';
    else
      if ( BarBottomArray[BarIndex] == 0 )
        BarStringPtr[BarIndex] = 'A';
      else
        BarStringPtr[BarIndex] = 'F';
/* BarStringPtr[65] = '\0';   TPG008 no Null Terminator */
 
#ifdef SHOW_INTERMEDIATES
  printf("Barcode,                              ");
  printf("%s\n",BarStringPtr);
#endif
 
  return USPS_FSB_ENCODER_API_SUCCESS;
}
 
 
 
 
/*******************************************************************************
**
** External Function Bodies
**
*******************************************************************************/
 
/*******************************************************************************
** encodetr
*******************************************************************************/
 
extern int                                    /* TPG005 */
usps4cb( char *TrackStringPtrI,
          char *RouteStringPtrI,
          char *BarStringPtrO )
 
{
 char TrackStringPtr[21];
 char RouteStringPtr[12];
 char BarStringPtr[66];
 
#ifdef SELF_TEST
  char SelfTestBarString[65+1];
#endif
  int  TrackIndex, RouteIndex, BarIndex;
  int  StringLength;
  int  EncRC;
  char TempTrack[20+1+1]; /* data plus null plus space for safety null */
  char TempRoute[11+1+1]; /* data plus null plus space for safety null */
 
  /* Check the parameters */
  if ( TrackStringPtrI == NULL )                      /* TPG003 */
    return USPS_FSB_ENCODER_API_TRACK_STRING_IS_NULL;
  if ( RouteStringPtrI == NULL )                      /* TPG003 */
    return USPS_FSB_ENCODER_API_ROUTE_STRING_IS_NULL;
  if ( BarStringPtrO == NULL )                        /* TPG003 */
    return USPS_FSB_ENCODER_API_BAR_STRING_IS_NULL;
 
  memset(TrackStringPtr, 0, sizeof(TrackStringPtr));  /* TPG001 */
  memset(RouteStringPtr, 0, sizeof(RouteStringPtr));  /* TPG001 */
  memcpy(TrackStringPtr, TrackStringPtrI, 20);        /* TPG001 */
  memcpy(RouteStringPtr, RouteStringPtrI, 11);        /* TPG001 */
 
  if (strchr(RouteStringPtr, ' ') != NULL)            /* TPG001 */
     *strchr(RouteStringPtr, ' ') = 0x00;             /* TPG001 */
 
#ifdef SELF_TEST
  /* Check for proper operation */
  if ( EncoderSelfTestedFlag != TRUE )
  {
    /* The following four tests are taken from the Specification Document */
 
    if ( Encode( "01234567094987654321", "", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "ATTFATTDTTADTAATTDTDTATTDAFDDFADFDFTFFFFFTATFAAAATDFFTDAADFTFDTDT", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    if ( Encode( "01234567094987654321", "01234", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "DTTAFADDTTFTDTFTFDTDDADADAFADFATDDFTAAAFDTTADFAAATDFDTDFADDDTDFFT", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    if ( Encode( "01234567094987654321", "012345678", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "ADFTTAFDTTTTFATTADTAAATFTFTATDAAAFDDADATATDTDTTDFDTDATADADTDFFTFA", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    if ( Encode( "01234567094987654321", "01234567891", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "AADTFFDFTDADTAADAATFDTDDAAADDTDTTDAFADADDDTFFFDDTTTADFAAADFTDAADA", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    EncoderSelfTestedFlag = TRUE;
  }
#endif
 
  /* Track String must be 20 ASCII digits with 2nd digit from left limited to 0-4 */
  /*   Put the data in a temporary area to make sure strlen will not wander into invalid memory */
  strncpy( TempTrack, TrackStringPtr, (20+1) );
  TempTrack[21] = '\0'; /* Insert safety null */
  if ( strlen( TempTrack ) != 20 )
    return USPS_FSB_ENCODER_API_TRACK_STRING_BAD_LENGTH;
  for ( TrackIndex = 0; TrackIndex < 20; TrackIndex++ )
    if ( (TempTrack[TrackIndex] < '0') || (TempTrack[TrackIndex] > '9') )
      return USPS_FSB_ENCODER_API_TRACK_STRING_HAS_INVALID_DATA;
  if ( (TempTrack[1] < '0') || (TempTrack[1] > '4') )
    return USPS_FSB_ENCODER_API_TRACK_STRING_HAS_INVALID_DIGIT2;
 
 
  /* Route String must be 0, 5, 9, or 11 ASCII digits */
  strncpy( TempRoute, RouteStringPtr, (11+1) );
  TempRoute[12] = '\0'; /* Insert safety null */
  StringLength = strlen( TempRoute );
  switch( StringLength )
  {
    case 0:
    case 5:
    case 9:
    case 11:
      /* Length is OK */
      break;
    default:
      return USPS_FSB_ENCODER_API_ROUTE_STRING_BAD_LENGTH;
  }
  for ( RouteIndex = 0; RouteIndex < StringLength; RouteIndex++ )
    if ( (TempRoute[RouteIndex] < '0') || (TempRoute[RouteIndex] > '9') )
      return USPS_FSB_ENCODER_API_ROUTE_STRING_HAS_INVALID_DATA;
 
  /* Now that the inputs check out OK, send it to the encoder */
 
  EncRC = Encode( TrackStringPtr, RouteStringPtr, BarStringPtr );
  memcpy(BarStringPtrO,BarStringPtr,65);
  return EncRC;
}
 
/**********************************************/
 
/*******************************************************************************
** USPSVCB
*******************************************************************************/
 
extern int
uspsvcb( char *TrackStringPtr ,
         char *RouteStringPtr ,
         char *BarStringPtr   )
 
{
#ifdef SELF_TEST
  char SelfTestBarString[65+1];
#endif
  int  TrackIndex, RouteIndex;
  int  StringLength;
  char TempTrack[20+1+1]; /* data plus null plus space for safety null */
  char TempRoute[11+1+1]; /* data plus null plus space for safety null */
 
 
#ifdef SELF_TEST
  /* Check for proper operation */
  if ( EncoderSelfTestedFlag != TRUE )
  {
    /* The following four tests are taken from the Specification Document */
 
    if ( Encode( "01234567094987654321", "", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "ATTFATTDTTADTAATTDTDTATTDAFDDFADFDFTFFFFFTATFAAAATDFFTDAADFTFDTDT", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    if ( Encode( "01234567094987654321", "01234", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "DTTAFADDTTFTDTFTFDTDDADADAFADFATDDFTAAAFDTTADFAAATDFDTDFADDDTDFFT", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    if ( Encode( "01234567094987654321", "012345678", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "ADFTTAFDTTTTFATTADTAAATFTFTATDAAAFDDADATATDTDTTDFDTDATADADTDFFTFA", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    if ( Encode( "01234567094987654321", "01234567891", SelfTestBarString ) != USPS_FSB_ENCODER_API_SUCCESS )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
    if ( strncmp( SelfTestBarString, "AADTFFDFTDADTAADAATFDTDDAAADDTDTTDAFADADDDTFFFDDTTTADFAAADFTDAADA", 65 ) != 0 )
      return USPS_FSB_ENCODER_API_SELFTEST_FAILED;
 
    EncoderSelfTestedFlag = TRUE;
  }
#endif
 
  /* Check the parameters */
  if ( TrackStringPtr == NULL )
    return USPS_FSB_ENCODER_API_TRACK_STRING_IS_NULL;
  if ( RouteStringPtr == NULL )
    return USPS_FSB_ENCODER_API_ROUTE_STRING_IS_NULL;
  if ( BarStringPtr == NULL )
    return USPS_FSB_ENCODER_API_BAR_STRING_IS_NULL;
 
  /* Track String must be 20 ASCII digits with 2nd digit from left limited to 0-4 */
  /*   Put the data in a temporary area to make sure strlen will not wander into invalid memory */
  strncpy( TempTrack, TrackStringPtr, (20+1) );
  TempTrack[21] = '\0'; /* Insert safety null */
  if ( strlen( TempTrack ) != 20 )
    return USPS_FSB_ENCODER_API_TRACK_STRING_BAD_LENGTH;
  for ( TrackIndex = 0; TrackIndex < 20; TrackIndex++ )
    if ( (TempTrack[TrackIndex] < '0') || (TempTrack[TrackIndex] > '9') )
      return USPS_FSB_ENCODER_API_TRACK_STRING_HAS_INVALID_DATA;
  if ( (TempTrack[1] < '0') || (TempTrack[1] > '4') )
    return USPS_FSB_ENCODER_API_TRACK_STRING_HAS_INVALID_DIGIT2;
 
  /* Route String must be 0, 5, 9, or 11 ASCII digits */
  strncpy( TempRoute, RouteStringPtr, (11+1) );
  TempRoute[12] = '\0'; /* Insert safety null */
  StringLength = strlen( TempRoute );
  switch( StringLength )
  {
    case 0:
    case 5:
    case 9:
    case 11:
      /* Length is OK */
      break;
    default:
      return USPS_FSB_ENCODER_API_ROUTE_STRING_BAD_LENGTH;
  }
  for ( RouteIndex = 0; RouteIndex < StringLength; RouteIndex++ )
    if ( (TempRoute[RouteIndex] < '0') || (TempRoute[RouteIndex] > '9') )
      return USPS_FSB_ENCODER_API_ROUTE_STRING_HAS_INVALID_DATA;
 
  /* Now that the inputs check out OK, send it to the encoder */
  return Encode( TrackStringPtr, RouteStringPtr, BarStringPtr );
}
