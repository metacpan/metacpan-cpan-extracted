dnl -*-m4-*-

AC_INIT([Authen::PAM],[0.16],[],[Authen-PAM])

AC_PREREQ([2.50])

AC_CONFIG_HEADERS([PAM_config.h])

AC_PROG_CC
AC_PROG_CPP

dnl Where is the PAM header file?

AC_MSG_CHECKING([for pam header files in])
AC_TRY_CPP([#include <security/pam_appl.h>],
	      [pam_inc=security
	       AC_DEFINE(HAVE_SECURITY_PAM_APPL_H,[1],
			 [pam_appl.h in /usr/include/security])],
AC_TRY_CPP([#include <pam/pam_appl.h>],
              [pam_inc=pam
	       AC_DEFINE(HAVE_PAM_PAM_APPL_H,[1],
	                 [pam_appl.h in /usr/include/pam])],
[pam_inc=no]))
AC_MSG_RESULT([$pam_inc])
if test $pam_inc = no; then
  AC_MSG_ERROR([cannot find the pam_appl.h file])
fi
pam_appl_h="@%:@include <$pam_inc/pam_appl.h>"

# This variable is only used in the tests and is not passed to the Makefile
LIBS="-lpam $LIBS"

# Checks if the pam library supports the environment handling functions
AC_CHECK_FUNCS(pam_getenv)

AC_CACHE_CHECK([if pam_strerror takes a pam_handle_t argument], 
[ac_cv_pam_strerror_needs_pamh],
AC_TRY_COMPILE([$pam_appl_h],
[pam_handle_t *pamh;
pam_strerror(pamh, PAM_SUCCESS)],
[ac_cv_pam_strerror_needs_pamh=yes],
[ac_cv_pam_strerror_needs_pamh=no]))
if test "$ac_cv_pam_strerror_needs_pamh" = yes; then
    AC_DEFINE(PAM_STRERROR_NEEDS_PAMH,[1],
    [Checks if pam_strerror() takes a pam_handle])
fi

dnl Checks for various PAM constants
AC_DEFUN(AC_CHECK_PAM_CONST,
[AC_CACHE_CHECK(for $1, ac_cv_have_$1,
AC_TRY_COMPILE([$pam_appl_h],
[int i = $1], 
[ac_cv_have_$1=yes], [ac_cv_have_$1=no]))
if test "$ac_cv_have_$1" = yes; then
    AC_DEFINE_UNQUOTED(HAVE_$1,[1],[Is the symbol $1 defined?])
fi
])

AC_CHECK_PAM_CONST(PAM_AUTHTOKEN_REQD)
AC_CHECK_PAM_CONST(PAM_NEW_AUTHTOK_REQD)
AC_CHECK_PAM_CONST(PAM_AUTHTOK_EXPIRED)
AC_CHECK_PAM_CONST(PAM_AUTHTOK_RECOVER)
AC_CHECK_PAM_CONST(PAM_AUTHTOK_RECOVERY)
AC_CHECK_PAM_CONST(PAM_BAD_ITEM)
AC_CHECK_PAM_CONST(PAM_CONV_AGAIN)
AC_CHECK_PAM_CONST(PAM_CRED_DELETE)
AC_CHECK_PAM_CONST(PAM_CRED_ESTABLISH)
AC_CHECK_PAM_CONST(PAM_CRED_REFRESH)
AC_CHECK_PAM_CONST(PAM_CRED_REINITIALIZE)
AC_CHECK_PAM_CONST(PAM_DELETE_CRED)
AC_CHECK_PAM_CONST(PAM_ESTABLISH_CRED)
AC_CHECK_PAM_CONST(PAM_REFRESH_CRED)
AC_CHECK_PAM_CONST(PAM_REINITIALIZE_CRED)
AC_CHECK_PAM_CONST(PAM_INCOMPLETE)
AC_CHECK_PAM_CONST(PAM_MODULE_UNKNOWN)
AC_CHECK_PAM_CONST(PAM_RADIO_TYPE)
AC_CHECK_PAM_CONST(PAM_BINARY_PROMPT)

# Checks if the dl library supports the RTLD_GLOBAL flag
# but only if perl was compiled with the dl_open library

if perl -V:dlsrc | grep dlopen >/dev/null 2>&1
then
  AC_CHECK_DECL([RTLD_GLOBAL],
                [DL_LOAD_FLAGS='sub dl_load_flags { 0x01 }'],
                [DL_LOAD_FLAGS=''],
		[#include<dlfcn.h>])
else
  DL_LOAD_FLAGS=''
fi
AC_SUBST(DL_LOAD_FLAGS)

AC_CONFIG_FILES([pam.cfg PAM.pm])
AC_OUTPUT
