/* ***************************************************
   This header file was created 
     by scripts/create_cpp_undefs_redefs.pl 
     on Fri Jul 18 13:02:45 2003 GMT 

   This is a wrapper arround #include "emboss.h"
   ***************************************************
*/

/* undef Perl #define(s) colliding with Emboss */

#ifdef ELSE
#define ELSE_BACKUP_BIO_EMBOSS ELSE
#undef ELSE
#endif

#ifdef WORD
#define WORD_BACKUP_BIO_EMBOSS WORD
#undef WORD
#endif

#ifdef apply
#define apply_BACKUP_BIO_EMBOSS apply
#undef apply
#endif

#ifdef regexp
#define regexp_BACKUP_BIO_EMBOSS regexp
#undef regexp
#endif

#ifdef OP_NOT
#define OP_NOT_BACKUP_BIO_EMBOSS OP_NOT
#undef OP_NOT
#endif

#ifdef OP_REF
#define OP_REF_BACKUP_BIO_EMBOSS OP_REF
#undef OP_REF
#endif

#ifdef OP_REVERSE
#define OP_REVERSE_BACKUP_BIO_EMBOSS OP_REVERSE
#undef OP_REVERSE
#endif


/* redefine Emboss names, because of collisions with Perl names */

#define regexp BIO_EMBOSS_regexp

#define OP_NOT BIO_EMBOSS_OP_NOT

#define OP_REF BIO_EMBOSS_OP_REF

#define OP_REVERSE BIO_EMBOSS_OP_REVERSE


/* include Emboss headers */

#include "emboss.h"


/* undefine redefinitions */

#undef regexp

#undef OP_NOT

#undef OP_REF

#undef OP_REVERSE


/* undo undefs */

#ifdef regexp_BACKUP_BIO_EMBOSS

#ifdef regexp
#undef regexp
#endif

#define regexp regexp_BACKUP_BIO_EMBOSS
/* #undef regexp_BACKUP_BIO_EMBOSS */
#endif

#ifdef OP_NOT_BACKUP_BIO_EMBOSS

#ifdef OP_NOT
#undef OP_NOT
#endif

#define OP_NOT OP_NOT_BACKUP_BIO_EMBOSS
/* #undef OP_NOT_BACKUP_BIO_EMBOSS */
#endif

#ifdef OP_REF_BACKUP_BIO_EMBOSS

#ifdef OP_REF
#undef OP_REF
#endif

#define OP_REF OP_REF_BACKUP_BIO_EMBOSS
/* #undef OP_REF_BACKUP_BIO_EMBOSS */
#endif

#ifdef OP_REVERSE_BACKUP_BIO_EMBOSS

#ifdef OP_REVERSE
#undef OP_REVERSE
#endif

#define OP_REVERSE OP_REVERSE_BACKUP_BIO_EMBOSS
/* #undef OP_REVERSE_BACKUP_BIO_EMBOSS */
#endif

#ifdef ELSE_BACKUP_BIO_EMBOSS

#ifdef ELSE
#undef ELSE
#endif

#define ELSE ELSE_BACKUP_BIO_EMBOSS
/* #undef ELSE_BACKUP_BIO_EMBOSS */
#endif

#ifdef WORD_BACKUP_BIO_EMBOSS

#ifdef WORD
#undef WORD
#endif

#define WORD WORD_BACKUP_BIO_EMBOSS
/* #undef WORD_BACKUP_BIO_EMBOSS */
#endif

#ifdef apply_BACKUP_BIO_EMBOSS

#ifdef apply
#undef apply
#endif

#define apply apply_BACKUP_BIO_EMBOSS
/* #undef apply_BACKUP_BIO_EMBOSS */
#endif

