#!/bin/sh

NAME="Config-Record"

set -e

# Make things clean.

make -k realclean ||:
rm -rf MANIFEST blib

# Make makefiles.
perl Makefile.PL PREFIX=$AUTOBUILD_INSTALL_ROOT

# Build the RPM.
make
make manifest

# Run test suite
perl -MDevel::Cover -e '' 1>/dev/null 2>&1 && USE_COVER=1 || USE_COVER=0
if [ "$USE_COVER" = "1" ]; then
  cover -delete
  HARNESS_PERL_SWITCHES=-MDevel::Cover make test
  cover
  mkdir blib/coverage
  cp -a cover_db/*.html cover_db/*.css blib/coverage
  mv blib/coverage/coverage.html blib/coverage/index.html
else
  make test
fi

# Install to virtual root
make install

# Make distribution & packages
rm -f $NAME-*.tar.gz
make dist

if [ -f /usr/bin/rpmbuild ]; then
  if [ -n "$AUTOBUILD_COUNTER" ]; then
    EXTRA_RELEASE=".auto$AUTOBUILD_COUNTER"
  else
    NOW=`date +"%s"`
    EXTRA_RELEASE=".$USER$NOW"
  fi
  rpmbuild -ta --define "extra_release $EXTRA_RELEASE" --clean $NAME-*.tar.gz
fi

if [ -f /usr/bin/fakeroot -a -f /etc/debian_version -a -n "$AUTOBUILD_PACKAGE_ROOT" ]; then
  fakeroot debian/rules clean
  fakeroot debian/rules DESTDIR=$AUTOBUILD_PACKAGE_ROOT/debian binary
fi
