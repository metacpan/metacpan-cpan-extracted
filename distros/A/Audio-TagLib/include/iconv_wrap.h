#ifndef ICONV_WRAP_H
#define ICONV_WRAP_H 1
#include "iconv.h"

#ifdef __cplusplus
extern "C" {
#endif /* __cplusplus */

#ifdef _BSD_ICONV
    
size_t iconv_wrap(iconv_t cd,
                  char **inbuf,
                  size_t *inbytesleft,
                  char **outbuf,
                  size_t *outbytesleft)
{
	char *in = *inbuf;
    /* Mac does not like the cast */
#ifndef _DARWIN     /* RT 101294 */
	const char *in_c = const_cast<const char*>(in);
#endif /* _DARWIN  */
	return iconv(cd, 
                 &in_c,
                 inbytesleft,
                 outbuf,
                 outbytesleft);
}

#else
    
size_t iconv_wrap(iconv_t cd,
                  char **inbuf,
                  size_t *inbytesleft,
                  char **outbuf,
                  size_t *outbytesleft)
{
	return iconv(cd, 
		         inbuf,
                 inbytesleft,
		         outbuf,
                 outbytesleft);
}

#endif /* _BSD_ICONV */

#ifdef __cplusplus
}
#endif /* __cplusplus */

#endif /* ICONV_WRAP_H */
