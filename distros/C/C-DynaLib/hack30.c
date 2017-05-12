/*
 * This function tries to convert Perl arguments to C arguments and
 * call the C function pointed to by func.
 *
 * It is used when `hack30' is specified explicitly or by default as
 * a calling convention for the C::DynaLib module.  The approach
 * is very simpleminded: the perl sub's args are concatenated and cast
 * to an array of 30 long integers, and the C function is called as if it
 * expected 30 longs.  (For efficiency, if the Perl args make up only
 * six longs or less, the C function is instead called as if it expected
 * six longs.)
 *
 * This method runs into problems if the C function
 *
 * - takes more arguments than can fit in the array,
 *
 * - takes some non-long arguments on a system that passes them
 *   differently from longs, or
 *
 * - cares how many arguments it was passed.  This appears to crash
 *   certain Win32 functions including RegisterClassA().
 *
 * Because of these problems, the hack30 calling convention is selected
 * only as a last resort by Makefile.PL.  A better solution would be to
 * write a similar function specific to your system and add it to the
 * module as a new calling convention.
 */
static int
hack30_pray(ax, items, func)
I32 ax;		/* used by the ST() macro */
I32 items;
void *func;
{
  STRLEN arg_len;
  void *arg_scalar;
  int i = 1;
  int nbytes = 0;
  long pseu[30];
  int check_len;

  for (i = DYNALIB_ARGSTART; i < items; i++) {
    arg_scalar = SvPV(ST(i), arg_len);
    check_len = nbytes + arg_len;
    if (check_len > sizeof pseu) {
      croak("Too many arguments.  The hack30 calling convention accepts up to 30 long-int-size arguments.");
    }
    Copy(arg_scalar, &((char *) (&pseu[0]))[nbytes], arg_len, char);
    nbytes = check_len;
  }
  if (nbytes <= 6 * sizeof (long)) {
    return (*((int (*)()) func))
      (pseu[0], pseu[1], pseu[2], pseu[3], pseu[4], pseu[5]);
  }
  return (*((int (*)()) func))
    (pseu[0], pseu[1], pseu[2], pseu[3], pseu[4], pseu[5],
     pseu[6], pseu[7], pseu[8], pseu[9], pseu[10], pseu[11],
     pseu[12], pseu[13], pseu[14], pseu[15], pseu[16], pseu[17],
     pseu[18], pseu[19], pseu[20], pseu[21], pseu[22], pseu[23],
     pseu[24], pseu[25], pseu[26], pseu[27], pseu[28], pseu[29]);
}

#if defined(__GNUC__) && __GNUC__ >= 3 && defined(__GNUC_MINOR__) && (__GNUC_MINOR__ >= 3)
#define hack30_CALL(func, type)						\
    ((*((int (*)()) hack30_pray))(ax,items,func))
#else
#define hack30_CALL(func, type)						\
    ((*((type (*)()) hack30_pray))(ax,items,func))
#endif
