#include <limits.h>
#include <stdint.h>

extern long
return_long()
{
  return LONG_MIN;
}

extern unsigned long
return_ulong()
{
  return ULONG_MAX;
}

#ifdef LLONG_MIN
extern int64_t
return_int64()
{
  return LLONG_MIN;
}
#endif

#ifdef ULLONG_MAX
extern uint64_t
return_uint64()
{
  return ULLONG_MAX;
}
#endif

extern int
return_int()
{
  return INT_MIN;
}

extern unsigned int
return_uint()
{
  return UINT_MAX;
}

extern short
return_short()
{
  return SHRT_MIN;
}

extern unsigned short
return_ushort()
{
  return USHRT_MAX;
}

extern char
return_char()
{
  return CHAR_MIN;
}

extern unsigned char
return_uchar()
{
  return UCHAR_MAX;
}

extern double
return_double()
{
  return (double) 9.9;
}

extern float
return_float()
{
  return (float) -4.5;
}

extern char *
return_string()
{
  return "epic cuteness";
}
