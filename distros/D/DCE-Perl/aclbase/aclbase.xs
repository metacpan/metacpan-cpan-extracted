#ifdef __cplusplus
extern "C" {
#endif
#include "EXTERN.h"
#include "perl.h"
#include "XSUB.h"
#ifdef __cplusplus
}
#endif

#include <dce/aclbase.h>

static int
not_here(s)
char *s;
{
    croak("%s not implemented on this architecture", s);
    return -1;
}

static long
constant(name, arg)
char *name;
int arg;
{
    errno = 0;
    switch (*name) {
    case 'a':
	break;
    case 'b':
	if (strEQ(name, "base_v0_0_included"))
#ifdef sec_acl_base_v0_0_included
	    return sec_acl_base_v0_0_included;
#else
	    goto not_there;
#endif
	break;
    case 'c':
	break;
    case 'd':
	if (strEQ(name, "default_handle"))
#ifdef sec_acl_default_handle
	    return sec_acl_default_handle;
#else
	    goto not_there;
#endif
	break;
    case 'e':
	if (strEQ(name, "e_type_max_nbr"))
#ifdef sec_acl_e_type_max_nbr
	    return sec_acl_e_type_max_nbr;
#else
	    goto not_there;
#endif
	break;
    case 'f':
	break;
    case 'g':
	break;
    case 'h':
	break;
    case 'i':
	break;
    case 'j':
	break;
    case 'k':
	break;
    case 'l':
	break;
    case 'm':
	break;
    case 'n':
	break;
    case 'o':
	break;
    case 'p':
	if (strEQ(name, "perm_control"))
#ifdef sec_acl_perm_control
	    return sec_acl_perm_control;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_delete"))
#ifdef sec_acl_perm_delete
	    return sec_acl_perm_delete;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_execute"))
#ifdef sec_acl_perm_execute
	    return sec_acl_perm_execute;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_insert"))
#ifdef sec_acl_perm_insert
	    return sec_acl_perm_insert;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_owner"))
#ifdef sec_acl_perm_owner
	    return sec_acl_perm_owner;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_read"))
#ifdef sec_acl_perm_read
	    return sec_acl_perm_read;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_test"))
#ifdef sec_acl_perm_test
	    return sec_acl_perm_test;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00000080"))
#ifdef sec_acl_perm_unused_00000080
	    return sec_acl_perm_unused_00000080;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00000100"))
#ifdef sec_acl_perm_unused_00000100
	    return sec_acl_perm_unused_00000100;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00000200"))
#ifdef sec_acl_perm_unused_00000200
	    return sec_acl_perm_unused_00000200;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00000400"))
#ifdef sec_acl_perm_unused_00000400
	    return sec_acl_perm_unused_00000400;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00000800"))
#ifdef sec_acl_perm_unused_00000800
	    return sec_acl_perm_unused_00000800;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00001000"))
#ifdef sec_acl_perm_unused_00001000
	    return sec_acl_perm_unused_00001000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00002000"))
#ifdef sec_acl_perm_unused_00002000
	    return sec_acl_perm_unused_00002000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00004000"))
#ifdef sec_acl_perm_unused_00004000
	    return sec_acl_perm_unused_00004000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00008000"))
#ifdef sec_acl_perm_unused_00008000
	    return sec_acl_perm_unused_00008000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00010000"))
#ifdef sec_acl_perm_unused_00010000
	    return sec_acl_perm_unused_00010000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00020000"))
#ifdef sec_acl_perm_unused_00020000
	    return sec_acl_perm_unused_00020000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00040000"))
#ifdef sec_acl_perm_unused_00040000
	    return sec_acl_perm_unused_00040000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00080000"))
#ifdef sec_acl_perm_unused_00080000
	    return sec_acl_perm_unused_00080000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00100000"))
#ifdef sec_acl_perm_unused_00100000
	    return sec_acl_perm_unused_00100000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00200000"))
#ifdef sec_acl_perm_unused_00200000
	    return sec_acl_perm_unused_00200000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00400000"))
#ifdef sec_acl_perm_unused_00400000
	    return sec_acl_perm_unused_00400000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_00800000"))
#ifdef sec_acl_perm_unused_00800000
	    return sec_acl_perm_unused_00800000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_01000000"))
#ifdef sec_acl_perm_unused_01000000
	    return sec_acl_perm_unused_01000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_02000000"))
#ifdef sec_acl_perm_unused_02000000
	    return sec_acl_perm_unused_02000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_04000000"))
#ifdef sec_acl_perm_unused_04000000
	    return sec_acl_perm_unused_04000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_08000000"))
#ifdef sec_acl_perm_unused_08000000
	    return sec_acl_perm_unused_08000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_10000000"))
#ifdef sec_acl_perm_unused_10000000
	    return sec_acl_perm_unused_10000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_20000000"))
#ifdef sec_acl_perm_unused_20000000
	    return sec_acl_perm_unused_20000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_40000000"))
#ifdef sec_acl_perm_unused_40000000
	    return sec_acl_perm_unused_40000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_unused_80000000"))
#ifdef sec_acl_perm_unused_80000000
	    return sec_acl_perm_unused_80000000;
#else
	    goto not_there;
#endif
	if (strEQ(name, "perm_write"))
#ifdef sec_acl_perm_write
	    return sec_acl_perm_write;
#else
	    goto not_there;
#endif
	if (strEQ(name, "posix_mask_obj"))
#ifdef sec_acl_posix_mask_obj
	    return sec_acl_posix_mask_obj;
#else
	    goto not_there;
#endif
	if (strEQ(name, "posix_no_semantics"))
#ifdef sec_acl_posix_no_semantics
	    return sec_acl_posix_no_semantics;
#else
	    goto not_there;
#endif
	if (strEQ(name, "posix_unused_0000002"))
#ifdef sec_acl_posix_unused_0000002
	    return sec_acl_posix_unused_0000002;
#else
	    goto not_there;
#endif
	if (strEQ(name, "posix_unused_0000004"))
#ifdef sec_acl_posix_unused_0000004
	    return sec_acl_posix_unused_0000004;
#else
	    goto not_there;
#endif
	if (strEQ(name, "posix_unused_0000008"))
#ifdef sec_acl_posix_unused_0000008
	    return sec_acl_posix_unused_0000008;
#else
	    goto not_there;
#endif
	if (strEQ(name, "printstring_help_len"))
#ifdef sec_acl_printstring_help_len
	    return sec_acl_printstring_help_len;
#else
	    goto not_there;
#endif
	if (strEQ(name, "printstring_len"))
#ifdef sec_acl_printstring_len
	    return sec_acl_printstring_len;
#else
	    goto not_there;
#endif
	break;
    case 'q':
	break;
    case 'r':
	break;
    case 's':
	break;
    case 't':
	break;
    case 'u':
	break;
    case 'v':
	break;
    case 'w':
	break;
    case 'x':
	break;
    case 'y':
	break;
    case 'z':
	break;
    }
    errno = EINVAL;
    return 0;

not_there:
    errno = ENOENT;
    return 0;
}


MODULE = DCE::aclbase		PACKAGE = DCE::aclbase		PREFIX = sec_acl_


double
constant(name,arg)
	char *		name
	int		arg

