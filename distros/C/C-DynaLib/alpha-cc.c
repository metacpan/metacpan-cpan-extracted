#include <alloca.h>

long
dynalib_alpha_excuse_for_asm(long a0, long a1, long a2,
			     long a3, long a4, long a5,
			     int (*func)(), long n_extra, long *p_extra)
{
  long *lptr;
  if (n_extra > 0) {
    lptr = (long *) alloca(n_extra * sizeof (long));
    while (n_extra > 0) {
      *lptr++ = *p_extra++;
      n_extra --;
    }
  }
  asm("ldt $f16, %0" : : "m"(a0));
  asm("ldt $f17, %0" : : "m"(a1));
  asm("ldt $f18, %0" : : "m"(a2));
  asm("ldt $f19, %0" : : "m"(a3));
  asm("ldt $f20, %0" : : "m"(a4));
  asm("ldt $f21, %0" : : "m"(a5));
  return (*((long (*)()) func))(a0, a1, a2, a3, a4, a5);
}
