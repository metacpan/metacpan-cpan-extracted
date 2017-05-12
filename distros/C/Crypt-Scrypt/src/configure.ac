#                                               -*- Autoconf -*-
# Process this file with autoconf to produce a configure script.
m4_pattern_allow([AM_INIT_AUTOMAKE])
m4_pattern_allow([AC_PROG_LIBTOOL])

AC_PREREQ([2.63])
AC_INIT([libscrypt], [1.1.6], [http://www.tarsnap.com/scrypt.html])
AC_CONFIG_AUX_DIR([build-aux])
AC_CONFIG_MACRO_DIR([m4])
AC_CONFIG_SRCDIR([src/scrypt_platform.h])
AC_CONFIG_HEADERS([config.h])
AM_INIT_AUTOMAKE([foreign])

AC_PROG_LIBTOOL
AC_SUBST(enable_shared)
AC_SUBST(enable_static)
libtool_VERSION=1:0:0
AC_SUBST(libtool_VERSION)

# Checks for programs.
AC_PROG_CC

# Checks for libraries.
AC_CHECK_LIB(rt, clock_gettime)

# Checks for header files.
AC_CHECK_HEADERS([err.h fcntl.h inttypes.h memory.h stddef.h stdint.h stdlib.h string.h strings.h sys/endian.h sys/param.h sys/stat.h sys/sysinfo.h sys/time.h sys/types.h termios.h unistd.h])

# Checks for typedefs, structures, and compiler characteristics.
AC_C_INLINE
AC_TYPE_SIZE_T
AC_TYPE_SSIZE_T
AC_TYPE_UINT32_T
AC_TYPE_UINT64_T
AC_TYPE_UINT8_T
AC_CHECK_TYPES([struct sysinfo],[], [], [[#include <sys/sysinfo.h>]])
AC_CHECK_HEADER([sys/sysinfo.h], [
                 AC_CHECK_MEMBER(struct sysinfo.mem_unit,
                                 [AC_DEFINE([HAVE_STRUCT_SYSINFO_MEM_UNIT],[],[sys/sysinfo.mem_unit])],
                                 [],
                                 [#include <sys/sysinfo.h>])])
AC_CHECK_HEADER([sys/sysinfo.h], [
                 AC_CHECK_MEMBER(struct sysinfo.totalram,
                                 [AC_DEFINE([HAVE_STRUCT_SYSINFO_TOTALRAM],[],[sys/sysinfo.totalram])],
                                 [],
                                 [#include <sys/sysinfo.h>])])

# Checks for library functions.
AC_FUNC_MALLOC
AC_FUNC_MMAP
AC_FUNC_STRTOD
AC_CHECK_FUNCS([clock_gettime gettimeofday memmove memset munmap posix_memalign strcspn strdup strerror strtoumax sysinfo])

AC_CHECK_DECLS(be64enc)

# Check if we have a hw.usermem sysctl.
if sysctl hw.usermem >/dev/null 2>/dev/null; then

cat >>confdefs.h <<\_ACEOF
#define HAVE_SYSCTL_HW_USERMEM 1
_ACEOF

fi

AC_CONFIG_FILES([Makefile])
AC_OUTPUT
