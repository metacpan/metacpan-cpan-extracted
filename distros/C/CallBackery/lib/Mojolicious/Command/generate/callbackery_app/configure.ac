% my $p = shift;
#  Copyright (C) <%= $p->{year} %> <%= $p->{fullName} %>

AC_INIT([<%= $p->{name} %>],m4_esyscmd([tr -d '\n' < VERSION]),[<%= $p->{email} %>])
AC_PREREQ([2.59])
AC_CONFIG_AUX_DIR(conftools)

MJ_CLASS=<%= $p->{class} %>
MJ_SCRIPT=<%= $p->{name} %>
QX_CLASS=<%= $p->{qxclass} %>

AC_SUBST(MJ_CLASS)
AC_SUBST(MJ_SCRIPT)
AC_SUBST(QX_CLASS)

# need this to allow long path names
AM_INIT_AUTOMAKE([1.9 tar-ustar foreign])
AM_MAINTAINER_MODE

m4_ifdef([AM_SILENT_RULES], [AM_SILENT_RULES([yes])])

AC_PREFIX_DEFAULT(/opt/$PACKAGE_NAME-$PACKAGE_VERSION)

AC_ARG_VAR(PERL,   [Path to local perl binary])
AC_PATH_PROG(PERL, perl, no)
AC_PATH_PROG(CURL, curl, no)
AC_PATH_PROG(WGET, wget, no)

URL_CAT="neither curl nor wget found"

if test -x "$CURL"; then
    URL_CAT="$CURL --location --insecure"
else
    if test -x "$WGET"; then
        URL_CAT="$WGET -O -"
    fi
fi

AC_SUBST(URL_CAT)


ac_perl_version="5.10.1"

if test "x$PERL" != "x"; then
  AC_MSG_CHECKING(for perl version greater than or equal to $ac_perl_version)
  $PERL -e "use $ac_perl_version;" >/dev/null 2>&1
  if test $? -ne 0; then
    AC_MSG_RESULT(no);
    AC_MSG_ERROR(at least version 5.10.1 is required to run mojolicious)
  else
    AC_MSG_RESULT(ok);
  fi
else
  AC_MSG_ERROR(could not find perl)
fi

AC_MSG_CHECKING(is perl reasonably complete)
if $PERL -MExtUtils::MakeMaker -e '' 2>/dev/null; then
  AC_MSG_RESULT(yes. ExtUtils::MakeMaker is available);
else
  AC_MSG_RESULT(no)
  AC_MSG_ERROR([a complete perl ('perl-core' in the redhat world) installation is required])
fi

AC_MSG_CHECKING([if we require a c compiler to get perl modules compiled])
if $PERL -MIO::Socket::IP -e 'exit($IO::Socket::IP::VERSION >= 0.37)' 2>/dev/null; then
    AC_MSG_RESULT(no)
else
    AC_MSG_RESULT(yes)
    perl_cc=`$PERL -MConfig -e 'print $Config{cc}'`
    AC_PATH_PROG(PERL_CC_PATH, $perl_cc, no)
    AC_MSG_CHECKING(is perls favorite c compiler ($perl_cc) available)
    if test x$PERL_CC_PATH = xno; then
      AC_MSG_RESULT(no)
      AC_MSG_ERROR([perl needs the '$perl_cc' compiler package to build dependencies])
    else
      AC_MSG_RESULT(yes)
    fi
fi


AC_PROG_GREP

AC_ARG_VAR(GMAKE,   [Path to local GNU Make binary])
AC_PATH_PROGS(GMAKE, [gnumake gmake make])

AC_MSG_CHECKING([for gnu make availablility])
if  ( $GMAKE --version 2> /dev/null | $GREP GNU  > /dev/null 2>&1 );  then
    AC_MSG_RESULT([$GMAKE is GNU make])
else
    AC_MSG_ERROR([GNU make not found. Try setting the GMAKE environment variable.])
fi

AC_ARG_ENABLE(pkgonly,
        AC_HELP_STRING([--enable-pkgonly],
                        [Skip all checking]))
AC_SUBST(enable_pkgonly)

actual_prefix=$prefix
if test x$actual_prefix = xNONE; then
    actual_prefix=$ac_default_prefix
fi

AC_MSG_CHECKING([Checking Install Prefix])
if test -f $actual_prefix/configure; then
    AC_MSG_ERROR([The install prefix must NOT point to the directory where you unpacked the source.])
else
    AC_MSG_RESULT([install Prefix is fine])
fi


AC_ARG_VAR(PERL5LIB,   [Colon separated list of perl library directories])
AC_SUBST(PERL5LIB)

QOOXDOO_PATH=
AC_ARG_WITH(qooxdoo-sdk-dir,AC_HELP_STRING([--with-qooxdoo-sdk-dir=DIR],[Where can we find the qooxdoo sdk (required to rebuild the web ui)]), [
        if test -d $withval/framework; then
             QOOXDOO_PATH=$withval
        else
        cat <<NOTES

** Aborting Configure ******************************

   You specified --with-qooxdoo-sdk-dir=DIR without pointing it
   to a copy of the qooxdoo sdk.
   Get your copy form www.qooxdoo.org.

NOTES
          exit 1
        fi
])

AC_SUBST(QOOXDOO_PATH)

AM_CONDITIONAL(BUILD_QOOXDOO_APP,[test x$QOOXDOO_PATH != x])

AC_CONFIG_FILES([
    Makefile
    etc/Makefile
    lib/Makefile
    bin/Makefile
    frontend/Makefile
    thirdparty/Makefile
])

AC_SUBST(VERSION)

AC_OUTPUT

if test x$QOOXDOO_PATH = x; then

cat <<NOTES

** WARNING ***********************************************

You did NOT specify --with-qooxdoo-sdk-dir.  It is therefore NOT
possible to re-compile the JavaScript parts (web interface)
of the application.

NOTES
fi


if test x$mod_ok = x0; then
    cat <<NOTES

** SOME PERL MODULES ARE MISSING ******************************

If you know where perl can find the missing modules, set
the PERL5LIB environment variable accordingly. Otherwise
just proceed and the missing modules will be installed
automatically.
NOTES

fi

cat <<NOTES

** CONFIGURE DONE **********************************************

Settings:

  PERL5LIB = ${PERL5LIB:-"not set"}
  PERL = $PERL

The Makefiles use GNU make functionality.
Continue installation with

  $GMAKE install

NOTES
