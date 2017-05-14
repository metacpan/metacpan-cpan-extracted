#!/bin/sh

#############################################################################
# configuration to fill in (or to replace in your .staticperlrc)

STATICPERL=~/.staticperl
CPAN=http://mirror.netcologne.de/cpan # which mirror to use
EMAIL="read the documentation <rtfm@example.org>"
DLCACHE=

# perl build variables
MAKE=make
PERL_VERSION=5.12.4 # 5.8.9 is also a good choice
PERL_CC=cc
PERL_CONFIGURE="" # additional Configure arguments
PERL_CCFLAGS="-g -DPERL_DISABLE_PMC -DPERL_ARENA_SIZE=16376 -DNO_PERL_MALLOC_ENV -D_GNU_SOURCE -DNDEBUG"
PERL_OPTIMIZE="-Os" # -Os -ffunction-sections -fdata-sections -finline-limit=8 -ffast-math"

ARCH="$(uname -m)"

#case "$ARCH" in
#   i*86 | x86_64 | amd64 )
#      PERL_OPTIMIZE="$PERL_OPTIMIZE -mpush-args -mno-inline-stringops-dynamically -mno-align-stringops -mno-ieee-fp" # x86/amd64
#      case "$ARCH" in
#         i*86 )
#            PERL_OPTIMIZE="$PERL_OPTIMIZE -fomit-frame-pointer -march=pentium3 -mtune=i386" # x86 only
#            ;;
#      esac
#      ;;
#esac

# -Wl,--gc-sections makes it impossible to check for undefined references
# for some reason so we need to patch away the "-no" after Configure and before make :/
# --allow-multiple-definition exists to work around uclibc's pthread static linking bug
#PERL_LDFLAGS="-Wl,--no-gc-sections -Wl,--allow-multiple-definition"
PERL_LDFLAGS=
PERL_LIBS="-lm -lcrypt" # perl loves to add lotsa crap itself

# some configuration options for modules
PERL_MM_USE_DEFAULT=1
PERL_MM_OPT="MAN1PODS= MAN3PODS="
#CORO_INTERFACE=p # needed without nptl on x86, due to bugs in linuxthreads - very slow
#EV_EXTRA_DEFS='-DEV_FEATURES=4+8+16+64 -DEV_USE_SELECT=0 -DEV_USE_POLL=1 -DEV_USE_EPOLL=1 -DEV_NO_LOOPS -DEV_COMPAT3=0'
export PERL_MM_USE_DEFAULT PERL_MM_OPT

# which extra modules to install by default from CPAN that are
# required by mkbundle
STATICPERL_MODULES="ExtUtils::MakeMaker ExtUtils::CBuilder common::sense Pod::Strip PPI PPI::XS Pod::Usage"

# which extra modules you might want to install
EXTRA_MODULES=""

# overridable functions
preconfigure()  { : ; }
patchconfig()   { : ; }
postconfigure() { : ; }
postbuild()     { : ; }
postinstall()   { : ; }

# now source user config, if any
if [ "$STATICPERLRC" ]; then
   . "$STATICPERLRC"
else
   [ -r /etc/staticperlrc ] && . /etc/staticperlrc
   [ -r ~/.staticperlrc   ] && . ~/.staticperlrc
   [ -r "$STATICPERL/rc"  ] && . "$STATICPERL/rc"
fi

#############################################################################
# support

# work around ExtUtils::CBuilder and others
export CC="$PERL_CC"
export CFLAGS="$PERL_CFLASGS"
export LD="$PERL_CC"
export LDFLAGS="$PERL_LDFLAGS"
unset LIBS

PERL_PREFIX="${PERL_PREFIX:=$STATICPERL/perl}" # where the perl gets installed

unset PERL5OPT PERL5LIB PERLLIB PERL_UNICODE PERLIO_DEBUG
unset PERL_MB_OPT
LC_ALL=C; export LC_ALL # just to be on the safe side

# prepend PATH - not required by staticperl itself, but might make
# life easier when working in e.g. "staticperl cpan / look"
PATH="$PERL_PREFIX/perl/bin:$PATH"

# set version in a way that Makefile.PL can extract
VERSION=VERSION; eval \
$VERSION="1.44"

BZ2=bz2
BZIP2=bzip2

fatal() {
   printf -- "\nFATAL: %s\n\n" "$*" >&2
   exit 1
}

verbose() {
   printf -- "%s\n" "$*"
}

verblock() {
   verbose
   verbose "***"
   while read line; do
      verbose "*** $line"
   done
   verbose "***"
   verbose
}

rcd() {
   cd "$1" || fatal "$1: cannot enter"
}

trace() {
   prefix="$1"; shift
#   "$@" 2>&1 | while read line; do
#      echo "$prefix: $line"
#   done
   "$@"
}

trap wait 0

#############################################################################
# clean

distclean() {
   verblock <<EOF
   deleting everything installed by this script (rm -rf $STATICPERL)
EOF

   rm -rf "$STATICPERL"
}

#############################################################################
# download/configure/compile/install perl

clean() {
   rm -rf "$STATICPERL/src"
}

realclean() {
   rm -f "$PERL_PREFIX/staticstamp.postinstall"
   rm -f "$PERL_PREFIX/staticstamp.install"
   rm -f "$STATICPERL/src/perl-"*"/staticstamp.configure"
}

fetch() {
   rcd "$STATICPERL"

   mkdir -p src
   rcd src

   if ! [ -d "perl-$PERL_VERSION" ]; then
      PERLTAR=perl-$PERL_VERSION.tar.$BZ2

      if ! [ -e $PERLTAR ]; then
         URL="$CPAN/src/5.0/$PERLTAR"

         verblock <<EOF
downloading perl
to manually download perl yourself, place
perl-$PERL_VERSION.tar.$BZ2 in $STATICPERL
trying $URL

either curl or wget is required for automatic download.
curl is tried first, then wget.

you can configure a download cache directory via DLCACHE
in your .staticperlrc to avoid repeated downloads.
EOF

         rm -f $PERLTAR~ # just to be on the safe side
         { [ "$DLCACHE" ] && cp "$DLCACHE"/$PERLTAR $PERLTAR~ >/dev/null 2>&1; } \
            || wget -O $PERLTAR~ "$URL" \
            || curl -f >$PERLTAR~ "$URL" \
            || fatal "$URL: unable to download"
         rm -f $PERLTAR
         mv $PERLTAR~ $PERLTAR
         if [ "$DLCACHE" ]; then
            mkdir -p "$DLCACHE"
            cp $PERLTAR "$DLCACHE"/$PERLTAR~$$~ && \
               mv "$DLCACHE"/$PERLTAR~$$~ "$DLCACHE"/$PERLTAR
         fi
      fi

      verblock <<EOF
unpacking perl
EOF

      mkdir -p unpack
      rm -rf unpack/perl-$PERL_VERSION
      $BZIP2 -d <$PERLTAR | ( cd unpack && tar xf - ) \
         || fatal "$PERLTAR: error during unpacking"
      chmod -R u+w unpack/perl-$PERL_VERSION
      mv unpack/perl-$PERL_VERSION perl-$PERL_VERSION
      rmdir -p unpack
   fi
}

# similar to GNU-sed -i or perl -pi
sedreplace() {
   sed -e "$1" <"$2" > "$2~" || fatal "error while running sed"
   rm -f "$2"
   mv "$2~" "$2"
}

configure_failure() {
   cat <<EOF


*** 
*** Configure failed - see above for the exact error message(s).
*** 
*** Most commonly, this is because the default PERL_CCFLAGS or PERL_OPTIMIZE
*** flags are not supported by your compiler. Less often, this is because
*** PERL_LIBS either contains a library not available on your system (such as
*** -lcrypt), or because it lacks a required library (e.g. -lsocket or -lnsl).
*** 
*** You can provide your own flags by creating a ~/.staticperlrc file with
*** variable assignments. For example (these are the actual values used):
***

PERL_CC="$PERL_CC"
PERL_CCFLAGS="$PERL_CCFLAGS"
PERL_OPTIMIZE="$PERL_OPTIMIZE"
PERL_LDFLAGS="$PERL_LDFLAGS"
PERL_LIBS="$PERL_LIBS"

EOF
   exit 1
}

configure() {
   fetch

   rcd "$STATICPERL/src/perl-$PERL_VERSION"

   [ -e staticstamp.configure ] && return

   verblock <<EOF
configuring $STATICPERL/src/perl-$PERL_VERSION
EOF

   rm -f "$PERL_PREFIX/staticstamp.install"

   "$MAKE" distclean >/dev/null 2>&1

   sedreplace '/^#define SITELIB/d' config_h.SH

   # I hate them for this
   grep -q -- -fstack-protector Configure && \
      sedreplace 's/-fstack-protector/-fno-stack-protector/g' Configure

   # what did that bloke think
   grep -q -- usedl=.define hints/darwin.sh && \
      sedreplace '/^usedl=.define.;$/d' hints/darwin.sh

   preconfigure || fatal "preconfigure hook failed"

#   trace configure \
   sh Configure -Duselargefiles \
                -Uuse64bitint \
                -Dusemymalloc=n \
                -Uusedl \
                -Uusethreads \
                -Uuseithreads \
                -Uusemultiplicity \
                -Uusesfio \
                -Uuseshrplib \
                -Uinstallusrbinperl \
                -A ccflags=" $PERL_CCFLAGS" \
                -Dcc="$PERL_CC" \
                -Doptimize="$PERL_OPTIMIZE" \
                -Dldflags="$PERL_LDFLAGS" \
                -Dlibs="$PERL_LIBS" \
                -Dprefix="$PERL_PREFIX" \
                -Dbin="$PERL_PREFIX/bin" \
                -Dprivlib="$PERL_PREFIX/lib" \
                -Darchlib="$PERL_PREFIX/lib" \
                -Uusevendorprefix \
                -Dsitelib="$PERL_PREFIX/lib" \
                -Dsitearch="$PERL_PREFIX/lib" \
                -Uman1dir \
                -Uman3dir \
                -Usiteman1dir \
                -Usiteman3dir \
                -Dpager=/usr/bin/less \
                -Demail="$EMAIL" \
                -Dcf_email="$EMAIL" \
                -Dcf_by="$EMAIL" \
                $PERL_CONFIGURE \
                -Duseperlio \
                -dE || configure_failure

   sedreplace '
      s/-Wl,--no-gc-sections/-Wl,--gc-sections/g
      s/ *-fno-stack-protector */ /g
   ' config.sh

   patchconfig || fatal "patchconfig hook failed"

   sh Configure -S || fatal "Configure -S failed"

   postconfigure || fatal "postconfigure hook failed"

   : > staticstamp.configure
}

write_shellscript() {
   {
      echo "#!/bin/sh"
      echo "STATICPERL=\"$STATICPERL\""
      echo "PERL_PREFIX=\"$PERL_PREFIX\""
      echo "MAKE=\"$MAKE\""
      cat
   } >"$PERL_PREFIX/bin/$1"
   chmod 755 "$PERL_PREFIX/bin/$1"
}

build() {
   configure

   rcd "$STATICPERL/src/perl-$PERL_VERSION"

   verblock <<EOF
building $STATICPERL/src/perl-$PERL_VERSION
EOF

   rm -f "$PERL_PREFIX/staticstamp.install"

   "$MAKE" || fatal "make: error while building perl"

   postbuild || fatal "postbuild hook failed"
}

_postinstall() {
   if ! [ -e "$PERL_PREFIX/staticstamp.postinstall" ]; then
      NOCHECK_INSTALL=+
      instcpan $STATICPERL_MODULES
      [ "$EXTRA_MODULES" ] && instcpan $EXTRA_MODULES

      postinstall || fatal "postinstall hook failed"

      : > "$PERL_PREFIX/staticstamp.postinstall"
   fi
}

install() {
   if ! [ -e "$PERL_PREFIX/staticstamp.install" ]; then
      build

      verblock <<EOF
installing $STATICPERL/src/perl-$PERL_VERSION
to $PERL_PREFIX
EOF

      ln -sf "perl/bin/" "$STATICPERL/bin"
      ln -sf "perl/lib/" "$STATICPERL/lib"

      mkdir "$STATICPERL/patched"

      ln -sf "$PERL_PREFIX" "$STATICPERL/perl" # might get overwritten
      rm -rf "$PERL_PREFIX"                    # by this rm -rf

      "$MAKE" install || fatal "make install: error while installing"

      rcd "$PERL_PREFIX"

      # create a "make install" replacement for CPAN
      write_shellscript SP-make-install-make <<'EOF'
#CAT make-install-make.sh
EOF

      # create a "patch modules" helper
      write_shellscript SP-patch-postinstall <<'EOF'
#CAT patch-postinstall.sh
EOF

      # immediately use it
      "$PERL_PREFIX/bin/SP-patch-postinstall"

      # help to trick CPAN into avoiding ~/.cpan completely
      echo 1 >"$PERL_PREFIX/lib/CPAN/MyConfig.pm"

      # we call cpan with -MCPAN::MyConfig in this script, which
      # is strictly unnecssary as we have to patch CPAN anyway,
      # so consider it "for good measure".
      "$PERL_PREFIX"/bin/perl -MCPAN::MyConfig -MCPAN -e '
         CPAN::Shell->o (conf => urllist => push => "'"$CPAN"'");
         CPAN::Shell->o (conf => q<cpan_home>, "'"$STATICPERL"'/cpan");
         CPAN::Shell->o (conf => q<init>);
         CPAN::Shell->o (conf => q<cpan_home>, "'"$STATICPERL"'/cpan");
         CPAN::Shell->o (conf => q<build_dir>, "'"$STATICPERL"'/cpan/build");
         CPAN::Shell->o (conf => q<prefs_dir>, "'"$STATICPERL"'/cpan/prefs");
         CPAN::Shell->o (conf => q<histfile> , "'"$STATICPERL"'/cpan/histfile");
         CPAN::Shell->o (conf => q<keep_source_where>, "'"$STATICPERL"'/cpan/sources");
         CPAN::Shell->o (conf => q<makepl_arg>, "MAP_TARGET=perl");
         CPAN::Shell->o (conf => q<make_install_make_command>, "'"$PERL_PREFIX"'/bin/SP-make-install-make");
         CPAN::Shell->o (conf => q<prerequisites_policy>, q<follow>);
         CPAN::Shell->o (conf => q<build_requires_install_policy>, q<yes>);
         CPAN::Shell->o (conf => q<prefer_installer>, "EUMM");
         CPAN::Shell->o (conf => q<commit>);
      ' || fatal "error while initialising CPAN"

      : > "$PERL_PREFIX/staticstamp.install"
   fi

   _postinstall
}

import() {
   IMPORT="$1"

   rcd "$STATICPERL"

   if ! [ -e "$PERL_PREFIX/staticstamp.install" ]; then
      verblock <<EOF
import perl from $IMPORT to $STATICPERL
EOF

      rm -rf bin cpan lib patched perl src
      mkdir -m 755 perl perl/bin
      ln -s perl/bin/ bin
      ln -s "$IMPORT" perl/bin/

      echo "$IMPORT" > "$PERL_PREFIX/.import"

      : > "$PERL_PREFIX/staticstamp.install"
   fi

   _postinstall
}

#############################################################################
# install a module from CPAN

instcpan() {
   [ $NOCHECK_INSTALL ] || install

   verblock <<EOF
installing modules from CPAN
$@
EOF

   MYCONFIG=
   [ -e "$PERL_PREFIX/.import" ] || MYCONFIG=-MCPAN::MyConfig

   "$PERL_PREFIX"/bin/perl $MYCONFIG -MCPAN -e 'notest (install => $_) for @ARGV' -- "$@" | tee "$STATICPERL/instcpan.log"

   if grep -q " -- NOT OK\$" "$STATICPERL/instcpan.log"; then
      fatal "failure while installing modules from CPAN ($@)"
   fi
   rm -f "$STATICPERL/instcpan.log"
}

#############################################################################
# install a module from unpacked sources

instsrc() {
   [ $NOCHECK_INSTALL ] || install

   verblock <<EOF
installing modules from source
$@
EOF

   for mod in "$@"; do
      echo
      echo $mod
      (
         rcd $mod
         "$MAKE" -f Makefile.aperl map_clean >/dev/null 2>&1
         "$MAKE" distclean >/dev/null 2>&1
         "$PERL_PREFIX"/bin/perl Makefile.PL || fatal "$mod: error running Makefile.PL"
         "$MAKE" || fatal "$mod: error building module"
         "$PERL_PREFIX"/bin/SP-make-install-make install || fatal "$mod: error installing module"
         "$MAKE" distclean >/dev/null 2>&1
         exit 0
      ) || exit $?
   done
}

#############################################################################
# main

podusage() {
   echo

   if [ -e "$PERL_PREFIX/bin/perl" ]; then
      "$PERL_PREFIX/bin/perl" -MPod::Usage -e \
         'pod2usage -input => *STDIN, -output => *STDOUT, -verbose => '$1', -exitval => 0, -noperldoc => 1' <"$0" \
         2>/dev/null && exit
   fi

   # try whatever perl we can find
   perl -MPod::Usage -e \
      'pod2usage -input => *STDIN, -output => *STDOUT, -verbose => '$1', -exitval => 0, -noperldoc => 1' <"$0" \
      2>/dev/null && exit

   fatal "displaying documentation requires a working perl - try '$0 install' to build one in a safe location"
}

usage() {
   podusage 0
}

catmkbundle() {
   {
      read dummy
      echo "#!$PERL_PREFIX/bin/perl"
      cat
   } <<'MKBUNDLE'
#CAT mkbundle
MKBUNDLE
}

bundle() {
   MKBUNDLE="${MKBUNDLE:=$PERL_PREFIX/bin/SP-mkbundle}"
   catmkbundle >"$MKBUNDLE~" || fatal "$MKBUNDLE~: cannot create"
   chmod 755 "$MKBUNDLE~" && mv "$MKBUNDLE~" "$MKBUNDLE"
   CACHE="$STATICPERL/cache"
   mkdir -p "$CACHE"
   "$PERL_PREFIX/bin/perl" -- "$MKBUNDLE" --cache "$CACHE" "$@"
}

if [ $# -gt 0 ]; then
   while [ $# -gt 0 ]; do
      mkdir -p "$STATICPERL" || fatal "$STATICPERL: cannot create"
      mkdir -p "$PERL_PREFIX" || fatal "$PERL_PREFIX: cannot create"

      command="${1#--}"; shift
      case "$command" in
         version )
            echo "staticperl version $VERSION"
            ;;
         fetch | configure | build | install | clean | realclean | distclean )
            ( "$command" ) || exit
            ;;
         import )
            ( import "$1" ) || exit
            shift
            ;;
         instsrc )
            ( instsrc "$@" ) || exit
            exit
            ;;
         instcpan )
            ( instcpan "$@" ) || exit
            exit
            ;;
         perl )
            ( install ) || exit
            exec "$PERL_PREFIX/bin/perl" "$@"
            exit
            ;;
         cpan )
            ( install ) || exit
            PERL="$PERL_PREFIX/bin/perl"
            export PERL
            exec "$PERL_PREFIX/bin/cpan" "$@"
            exit
            ;;
         mkbundle )
            ( install ) || exit
            bundle "$@"
            exit
            ;;
         mkperl )
            ( install ) || exit
            bundle --perl "$@"
            exit
            ;;
         mkapp )
            ( install ) || exit
            bundle --app "$@"
            exit
            ;;
         help )
            podusage 2
            ;;
         * )
            exec 1>&2
            echo
            echo "Unknown command: $command"
            podusage 0
            ;;
      esac
   done
else
   usage
fi

exit 0

#CAT staticperl.pod

