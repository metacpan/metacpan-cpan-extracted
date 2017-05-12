#ifndef C_SCAN_CONSTANTS_TEST_DEFINES_H_
#define C_SCAN_CONSTANTS_TEST_DEFINES_H_

#include <string.h>

#ifdef  __cplusplus
extern "C" {
#endif

/* Some definitions we want to detect */
#define FREEZING_TEMP_F   32
#define BOILING_TEMP_C    100
#define MY_PI             (double)3.14
#define SECONDS_IN_HOUR   (short int)3600
#define PRICE_OF_GAS      ((float)2.099)
#define REALLY_COLD       (BOILING_TEMP_C - 140)
#define PI_APPROXIMATION  ((long double)(22/7.0))
#define NONSENSE          (double)( FREEZING_TEMP_F + (BOILING_TEMP_C/MY_PI)*SECONDS_IN_HOUR )

/* Then some we want to ignore */
#define ANSWER            "Forty-two"
#define LONGER_STR(s)     (strlen(s)+1)

#ifdef  __cplusplus
}
#endif

#endif /* defines.h */
