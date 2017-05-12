#ifndef FIX_INLINE_H_
#define FIX_INLINE_H_

/* We do this because it seems that PERL_STATIC_INLINE isn't defined
 * or something like that. I haven't figured out why not. 
 */

#ifndef PERL_STATIC_INLINE
#   ifdef NOINLINE
#       define PERL_STATIC_INLINE STATIC
#   elif defined(_MSC_VER)
#       define PERL_STATIC_INLINE STATIC __inline
#   else
#       define PERL_STATIC_INLINE STATIC inline
#   endif
#endif

#endif
