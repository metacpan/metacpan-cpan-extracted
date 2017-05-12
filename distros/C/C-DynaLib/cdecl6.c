/* cdecl.h is generated when you run `perl Makefile.PL DECL=cdecl' */
#include "cdecl.h"

/*
 * Convert Perl sub args to C args and pass them to (*func)().
 * Special slow case gcc for x86_64 with passing 6 args in regs.
 */
static int
cdecl6_pray(ax, items, func)
     I32 ax;		/* used by the ST() macro */
     I32 items;
     void *func;
{
#ifdef USE_THREADS
  dTHR;
#endif
  STRLEN arg_len;
  char *arg_scalar, *arg_on_stack;
  register int i;
  void* d1, *d2, *d3, *d4, *d5, *d6;
  d1 = d2 = d3 = d4 = d5 = d6 = NULL;
  STRLEN total_arg_len = 0;
  STRLEN stack_reserve_len = 0;

  if (!items)
    return ((int (*)()) func)();

#if CDECL_ONE_BY_ONE

#if CDECL_REVERSE
  for (i = CDECL_STACK_RESERVE; i < items; i++) {
#else  /* ! CDECL_REVERSE */
  for (i = items - 1; i >= CDECL_STACK_RESERVE; i--) {
#endif  /* ! CDECL_REVERSE */
    arg_scalar = SvPV(ST(i), arg_len);
    arg_on_stack = alloca(arg_len);
    Copy(arg_scalar, arg_on_stack, arg_len, char);
  }
#else  /* ! CDECL_ONE_BY_ONE */
  for (i = items; i-- > CDECL_STACK_RESERVE; ) {
    (void) SvPV(ST(i), arg_len);
    /* CDECL_ARG_ALIGN=8 for amd64 */
    total_arg_len += min(arg_len, CDECL_ARG_ALIGN);
  }
  for (i = CDECL_STACK_RESERVE; i-- > 0; ) {
    (void) SvPV(ST(i), arg_len);
    stack_reserve_len += arg_len;
  }
  arg_on_stack = (char *) alloca(total_arg_len);
  arg_on_stack += CDECL_ADJUST;
  arg_on_stack += stack_reserve_len;
#if CDECL_REVERSE
  for (i = items - 1; i >= CDECL_STACK_RESERVE; i--) {
#else  /* ! CDECL_REVERSE */
  for (i = CDECL_STACK_RESERVE; i < items; i++) {
#endif  /* ! CDECL_REVERSE */
    arg_scalar = SvPV(ST(i), arg_len);
#ifdef __x86_64__
    if (arg_len < 8) { 
      /* amd64 aligns to 8, so zero the values of smaller args.
	 http://blogs.msdn.com/oldnewthing/archive/2004/01/14/58579.aspx
      */
      memzero(arg_on_stack, 8);
    }
#endif
    Copy(arg_scalar, arg_on_stack, arg_len, char);
    arg_on_stack += min(arg_len, CDECL_ARG_ALIGN);
  }
#endif  /* ! CDECL_ONE_BY_ONE */

  if (items > 5) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    arg_scalar = SvPV(ST(2), arg_len);
    Copy(arg_scalar, &d3, arg_len, char);
    arg_scalar = SvPV(ST(3), arg_len);
    Copy(arg_scalar, &d4, arg_len, char);
    arg_scalar = SvPV(ST(4), arg_len);
    Copy(arg_scalar, &d5, arg_len, char);
    arg_scalar = SvPV(ST(5), arg_len);
    Copy(arg_scalar, &d6, arg_len, char);
    return ((int (*)()) func)(d1,d2,d3,d4,d5,d6);
  }
  else if (items > 4) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    arg_scalar = SvPV(ST(2), arg_len);
    Copy(arg_scalar, &d3, arg_len, char);
    arg_scalar = SvPV(ST(3), arg_len);
    Copy(arg_scalar, &d4, arg_len, char);
    arg_scalar = SvPV(ST(4), arg_len);
    Copy(arg_scalar, &d5, arg_len, char);
    return ((int (*)()) func)(d1,d2,d3,d4,d5);
  }
  else if (items > 3) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    arg_scalar = SvPV(ST(2), arg_len);
    Copy(arg_scalar, &d3, arg_len, char);
    arg_scalar = SvPV(ST(3), arg_len);
    Copy(arg_scalar, &d4, arg_len, char);
    return ((int (*)()) func)(d1,d2,d3,d4);
  }
  else if (items > 2) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    arg_scalar = SvPV(ST(2), arg_len);
    Copy(arg_scalar, &d3, arg_len, char);
    return ((int (*)()) func)(d1,d2,d3);
  }
  else if (items == 2) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    arg_scalar = SvPV(ST(1), arg_len);
    Copy(arg_scalar, &d2, arg_len, char);
    return ((int (*)()) func)(d1,d2);
  }
  else if (items == 1) {
    arg_scalar = SvPV(ST(0), arg_len);
    Copy(arg_scalar, &d1, arg_len, char);
    return ((int (*)()) func)(d1);
  }
  else {
    printf("invalid CDECL_STACK_RESERVE=%d\n", CDECL_STACK_RESERVE);
    exit (1);
  }
}

#if defined(__GNUC__) && __GNUC__ >= 3 && defined(__GNUC_MINOR__) && (__GNUC_MINOR__ >= 3)
#define cdecl6_CALL(func, type)						\
    (type)((*((int (*)()) cdecl6_pray))(ax,items,func))
#else
#define cdecl6_CALL(func, type)						\
    ((*((type (*)()) cdecl6_pray))(ax,items,func))
#endif
