/*
 * Author: Marc A. Lehmann <xsthreadpool@schmorp.de>
 * License: public domain, or where this is not possible/at your option,
 *          CC0 (https://creativecommons.org/publicdomain/zero/1.0/)
 *
 * Full documentation can be found at http://perlmulticore.schmorp.de/
 * The newest version of this header can be downloaded from
 * http://perlmulticore.schmorp.de/perlmulticore.h
 */

#ifndef PERL_MULTICORE_H
#define PERL_MULTICORE_H

/*

=head1 NAME

perlmulticore.h - implements the Perl Multicore Specification

=head1 SYNOPSIS

  #include "perlmulticore.h"

  // in your XS function:

  perlinterp_release ();
  do_the_C_thing ();
  perlinterp_acquire ();

=head1 DESCRIPTION

This documentation is the abridged version of the full documention at
L<http://perlmulticore.schmorp.de/>. It's recommended to go there instead
of reading this document.

This header file implements a very low overhead (both in code and runtime)
mechanism for XS modules to allow re-use of the perl interpreter for other
threads while doing some lengthy operation, such as cryptography, SQL
queries, disk I/O and so on.

The newest version of the header file itself, can be downloaded from
L<http://perlmulticore.schmorp.de/perlmulticore.h>.

=head1 HOW DO I USE THIS IN MY MODULES?

The usage is very simple - you include this header file in your XS module. Then, before you
do your lengthy operation, you release the perl interpreter:

   perlinterp_release ();

And when you are done with your computation, you acquire it again:

   perlinterp_acquire ();

And that's it. This doesn't load any modules and consists of only a few
machine instructions when no module to take advantage of it is loaded.

More documentation and examples can be found at the perl multicore site at
L<http://perlmulticore.schmorp.de>.

=head1 THE HARD AND FAST RULES

As with everything, there are a number of rules to follow.

=over 4

=item I<Never> touch any perl data structures after calling C<perlinterp_release>.

Anything perl is completely off-limits after C<perlinterp_release>, until
you call C<perlinterp_acquire>, after which you can access perl stuff
again.

That includes anything in the perl interpreter that you didn't prove to be
safe, and didn't prove to be safe in older and future versions of perl:
global variables, local perl scalars, even if you are sure nobody accesses
them and you only try to "read" their value.

=item I<Always> call C<perlinterp_release> and C<perlinterp_acquire> in pairs.

For each C<perlinterp_release> call there must be a C<perlinterp_acquire>
call. They don't have to be in the same function, and you can have
multiple calls to them, as long as every C<perlinterp_release> call is
followed by exactly one C<perlinterp_acquire> call at runtime.

=item I<Never> nest calls to C<perlinterp_release> and C<perlinterp_acquire>.

That simply means that after calling C<perlinterp_release>, you must
call C<perlinterp_acquire> before calling C<perlinterp_release>
again. Likewise, after C<perlinterp_acquire>, you can call
C<perlinterp_release> but not another C<perlinterp_acquire>.

=item I<Always> call C<perlinterp_release> first.

You I<must not> call C<perlinterp_acquire> without having called
C<perlinterp_release> before.

=item I<Never> underestimate threads.

While it's easy to add parallel execution ability to your XS module, it
doesn't mean it is safe. After you release the perl interpreter, it's
perfectly possible that it will call your XS function in another thread,
even while your original function still executes. In other words: your C
code must be thread safe, and if you use any library, that library must be
thread-safe, too.

Always assume that the code between C<perlinterp_release> and
C<perlinterp_acquire> is executed in parallel on multiple CPUs at the same
time.

=back


=head1 DISABLING PERL MULTICORE AT COMPILE TIME

You can disable the complete perl multicore API by defining the
symbol C<PERL_MULTICORE_DISABLE> to C<1> (e.g. by specifying
F<-DPERL_MULTICORE_DISABLE> as compiler argument).

This could be added to perl's C<CPPFLAGS> when configuring perl on
platforms that do not support threading at all for example.


=head1 AUTHOR

   Marc A. Lehmann <perlmulticore@schmorp.de>
   http://perlmulticore.schmorp.de/

=head1 LICENSE

The F<perlmulticore.h> header file is put into the public
domain. Where this is legally not possible, or at your
option, it can be licensed under creativecommons CC0
license: L<https://creativecommons.org/publicdomain/zero/1.0/>.

=cut

*/

#define PERL_MULTICORE_MAJOR 1 /* bumped on incompatible changes */
#define PERL_MULTICORE_MINOR 1 /* bumped on every change */

#if PERL_MULTICORE_DISABLE

#define perlinterp_release() do { } while (0)
#define perlinterp_acquire() do { } while (0)

#else

START_EXTERN_C

/* this struct is shared between all modules, and currently */
/* contain only the two function pointers for release/acquire */
struct perl_multicore_api
{
  void (*pmapi_release)(void);
  void (*pmapi_acquire)(void);
};

static void perl_multicore_init (void);

static const struct perl_multicore_api perl_multicore_api_init
   = { perl_multicore_init, 0 };

static struct perl_multicore_api *perl_multicore_api
   = (struct perl_multicore_api *)&perl_multicore_api_init;

#define perlinterp_release() perl_multicore_api->pmapi_release ()
#define perlinterp_acquire() perl_multicore_api->pmapi_acquire ()

/* this is the release/acquire implementation used as fallback */
static void
perl_multicore_nop (void)
{
}

static const char perl_multicore_api_key[] = "perl_multicore_api";

/* this is the initial implementation of "release" - it initialises */
/* the api and then calls the real release function */
static void
perl_multicore_init (void)
{
  dTHX;

  /* check for existing API struct in PL_modglobal */
  SV **api_svp = hv_fetch (PL_modglobal, perl_multicore_api_key,
                           sizeof (perl_multicore_api_key) - 1, 1);

  if (SvPOKp (*api_svp))
    perl_multicore_api = (struct perl_multicore_api *)SvPVX (*api_svp); /* we have one, use the existing one */
  else
    {
      /* create a new one with a dummy nop implementation */
      #ifdef NEWSV
      SV *api_sv = NEWSV (0, sizeof (*perl_multicore_api));
      #else
      SV *api_sv = newSV (   sizeof (*perl_multicore_api));
      #endif
      SvCUR_set (api_sv, sizeof (*perl_multicore_api));
      SvPOK_only (api_sv);
      perl_multicore_api = (struct perl_multicore_api *)SvPVX (api_sv);
      perl_multicore_api->pmapi_release =
      perl_multicore_api->pmapi_acquire = perl_multicore_nop;
      *api_svp = api_sv;
    }

  /* call the real (or dummy) implementation now */
  perlinterp_release ();
}

END_EXTERN_C

#endif

#endif

