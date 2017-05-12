# Testing

To fully test this module you need the source code from the repository [1], all
necessary tools are not included in the CPAN source package.

Recommended distribution to test on is Ubuntu 12.04 and you must have both
SoftHSM versions 1.3.x and 2.x. If SoftHSM is version 1.3.7 or 2.0.0b2 or lower
then a small fix to MutexFactory.cpp needs to be applied (see SoftHSM below).

[1] https://github.com/dotse/p5-Crypt-PKCS11

## Dependencies

### Ubuntu Packages

```
sudo apt-get install -y build-essential libxml2-dev libsqlite3-dev sqlite3 \
libbotan1.10-dev libssl-dev autoconf automake libtool libcunit1-dev \
libxml2-utils libcppunit-dev wget ccache libtest-checkmanifest-perl \
libtest-leaktrace-perl libtest-pod-coverage-perl libdevel-cover-perl \
libcommon-sense-perl
```

### SoftHSM

```
wget --no-check-certificate http://www.opendnssec.org/files/source/softhsm-1.3.7.tar.gz && \
wget --no-check-certificate http://www.opendnssec.org/files/source/testing/softhsm-2.0.0b2.tar.gz && \
tar zxvf softhsm-1.3.7.tar.gz && \
( cd softhsm-1.3.7 && \
mv src/lib/MutexFactory.cpp src/lib/MutexFactory.cpp.orig && \
( sed 's%MutexFactory::i()->createMutex%MutexFactory::i()->CreateMutex%' src/lib/MutexFactory.cpp.orig | \
sed 's%MutexFactory::i()->destroyMutex%MutexFactory::i()->DestroyMutex%' | \
sed 's%MutexFactory::i()->lockMutex%MutexFactory::i()->LockMutex%' | \
sed 's%MutexFactory::i()->unlockMutex%MutexFactory::i()->UnlockMutex%' > src/lib/MutexFactory.cpp ) && \
./configure --with-botan=/usr && \
make && sudo make install ) && \
tar zxvf softhsm-2.0.0b2.tar.gz && \
( cd softhsm-2.0.0b2 && \
mv src/lib/common/MutexFactory.cpp src/lib/common/MutexFactory.cpp.orig && \
( sed 's%MutexFactory::i()->createMutex%MutexFactory::i()->CreateMutex%' src/lib/common/MutexFactory.cpp.orig | \
sed 's%MutexFactory::i()->destroyMutex%MutexFactory::i()->DestroyMutex%' | \
sed 's%MutexFactory::i()->lockMutex%MutexFactory::i()->LockMutex%' | \
sed 's%MutexFactory::i()->unlockMutex%MutexFactory::i()->UnlockMutex%' > src/lib/common/MutexFactory.cpp ) && \
./configure --disable-non-paged-memory && \
make && sudo make install )
```

## Environment Variables

```
export TEST_DEVEL_COVER=1 RELEASE_TESTING=1 PATH="/usr/lib/ccache:$PATH"
```

**TEST_DEVEL_COVER** enables coverage code within the XS and C code.
**RELEASE_TESTING** enables tests such as manifest.t . **PATH** is if you want
to use ccache.

## Build and Test

```
perl Makefile.PL
make all test
```

## Devel::Cover

```
make clean
gen/clean
perl Makefile.PL
MYPATH="$PWD/gen" PATH="$PWD/gen:$PATH" cover -test -ignore_re 'Carp\.pm' && chmod a+rx `find cover_db -type d`
```

**PATH** must be set to a `gcov` / `gcov2perl` wrapper that enables uncoverable
tags within the XS and C code using `gen/gcov-filter`.

## Test::LeakTrace

```
TEST_LEAKTRACE=1 make test
```

## Clean up

```
make clean
gen/clean
```

`gen/clean` cleans up after Devel::Cover.
