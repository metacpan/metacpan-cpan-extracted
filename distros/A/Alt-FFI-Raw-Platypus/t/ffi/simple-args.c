#include <stdlib.h>
#include <limits.h>
#include <stdint.h>
#include <string.h>
#include <inttypes.h>
#include <stdio.h>
#include <t2t/simple.h>

extern void
take_one_long(long x)
{
  ok(x == LONG_MIN, "get LONG_MIN");
}

extern void
take_one_ulong(unsigned long x)
{
  ok(x == ULONG_MAX, "got ULONG_MAX");
}

#ifdef LLONG_MIN
extern void
take_one_int64(int64_t x)
{
  ok(x == LLONG_MIN, "got LLONG_MIN");
}
#endif

#ifdef ULLONG_MAX
extern void
take_one_uint64(uint64_t x)
{
  ok(x == ULLONG_MAX, "got ULLONG_MAX");
}
#endif

extern void
take_one_int(int x)
{
  ok(x == INT_MIN, "got INT_MIN");
}

extern void
take_one_uint(unsigned int x)
{
  ok(x == UINT_MAX, "got UINT_MAX");
}

extern void
take_one_short(short x)
{
  ok(x == SHRT_MIN, "got SHRT_MIN");
}

extern void
take_one_ushort(unsigned short x)
{
  ok(x == USHRT_MAX, "got USHRT_MAX");
}

extern void
take_one_char(char x)
{
  ok(x == CHAR_MIN, "got CHAR_MIN");
}

extern void
take_one_uchar(unsigned char x)
{
  ok(x == UCHAR_MAX, "got UCHAR_MAX");
}

extern void
take_two_shorts(short x, short y)
{
  ok(x == 10, "x got 10");
  ok(y == 20, "y got 20");
}

extern void
take_misc_ints(int x, short y, char z)
{
  ok(x == 101, "x got 101");
  ok(y == 102, "y got 102");
  ok(z == 103, "z got 103");
}

extern void
take_one_double(double x)
{
  ok(fabs(-6.9 - x) < 0.001, "got double");
  if(fabs(-6.9 - x) < 0.001)
    notef("actual double = %lf", x);
  else
  {
    diagf("actual double = %lf", x);
    diagf("off by %lf", fabs(-6.9 - x));
  }
}

extern void
take_one_float(float x)
{
  ok(fabsf(4.2 - x) < 0.001, "got float");
  if(fabsf(4.2 - x) < 0.001)
    notef("actual float = %f", x);
  else
  {
    diagf("actual float = %f", x);
    diagf("off by %f", fabsf(4.2-x));
  }
}

extern void
take_one_string(char *pass_msg)
{
  ok(!strcmp(pass_msg, "ok - passed a string"), "got a string");
}
