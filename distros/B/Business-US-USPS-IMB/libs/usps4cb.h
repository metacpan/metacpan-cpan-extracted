#ifndef ENCAPI
#define ENCAPI
 
/*******************************************************************************
** EncAPI.h
**
*******************************************************************************/
 
 
 
 
/*******************************************************************************
**
** Return Codes
**
*******************************************************************************/
 
#define USPS_FSB_ENCODER_API_SUCCESS                           0
#define USPS_FSB_ENCODER_API_SELFTEST_FAILED                   1
#define USPS_FSB_ENCODER_API_BAR_STRING_IS_NULL                2
#define USPS_FSB_ENCODER_API_BYTE_CONVERSION_FAILED            3
#define USPS_FSB_ENCODER_API_RETRIEVE_TABLE_FAILED             4
#define USPS_FSB_ENCODER_API_CODEWORD_CONVERSION_FAILED        5
#define USPS_FSB_ENCODER_API_CHARACTER_RANGE_ERROR             6
#define USPS_FSB_ENCODER_API_TRACK_STRING_IS_NULL              7
#define USPS_FSB_ENCODER_API_ROUTE_STRING_IS_NULL              8
#define USPS_FSB_ENCODER_API_TRACK_STRING_BAD_LENGTH           9
#define USPS_FSB_ENCODER_API_TRACK_STRING_HAS_INVALID_DATA    10
#define USPS_FSB_ENCODER_API_TRACK_STRING_HAS_INVALID_DIGIT2  11
#define USPS_FSB_ENCODER_API_ROUTE_STRING_BAD_LENGTH          12
#define USPS_FSB_ENCODER_API_ROUTE_STRING_HAS_INVALID_DATA    13
 
 
 
 
/*******************************************************************************
**
** External Function Prototypes
**
*******************************************************************************/
 
#ifdef __cplusplus
extern "C" {
#endif
 
/*******************************************************************************
** encodetr
**
** The name "encodetr" was cased and limited to 8 characters in an attempt to
** be compatible with mainframe linkers.
**
** Inputs:
**   TrackStringPtr - address of array of 20 ASCII digits plus null terminator.
**   RouteStringPtr - address of array of 0, 5, 9, or 11 ASCII digits plus null
**                    terminator.
**
** Outputs
**   return int     - see Return Codes above
**   BarStringPtr   - address at which 65 ASCII characters representing bars are
**                    stored plus a null terminator.  Characters will be 'T',
**                    'F', 'A', or 'D' where:
**                    T is Tracker (neither ascender nor descender)
**                    F is Full (tracker plus ascender and descender)
**                    A is Ascender (tracker plus ascender)
**                    D is Descender(tracker plus descender)
**                    Note that the leftmost bar is the first bar in the string.
*******************************************************************************/
 
extern int
usps4cb( char *TrackStringPtr ,
         char *RouteStringPtr ,
         char *BarStringPtr   );
 
 
 
 
#ifdef __cplusplus
}
#endif
 
#endif
