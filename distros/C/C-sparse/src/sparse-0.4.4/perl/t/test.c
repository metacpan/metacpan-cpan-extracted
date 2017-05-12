#define VAL(A) int A = 1;
VAL(X)

#undef  DEFINE_A0
#define DEFINE_A0  int a; /*1;*/
#include "test.h"

#undef  DEFINE_A0
#define DEFINE_A0 int b; /*2;*/
#include "test.h"

#undef  DEFINE_A0
#define DEFINE_A0 int c; /*3;*/
#include "test.h"

#undef  DEFINE_A0
#define DEFINE_A0 int d; /*4;*/
#include "test.h"

