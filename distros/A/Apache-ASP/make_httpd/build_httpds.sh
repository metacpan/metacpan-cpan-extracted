#!/bin/bash

getdir () {
  for file in $1*
  do
    if [ -d $file ]
    then 
      GETDIR=$file
      echo "Found install for $1* at ./$file"
      return 0
    fi
  done
  echo "exit build, no directory found for $1* at:" `pwd`
  exit
}

# FIND SOURCE IN LOCAL DIR
echo "======================================================"
getdir apache_
APACHE=$GETDIR
getdir mod_ssl-
MODSSL=$GETDIR
getdir mod_perl-
MODPERL=$GETDIR
echo "======================================================"
echo
sleep 1

# SSL
SSL_BASE=/usr/local/ssl
export SSL_BASE
cd $MODSSL
echo
echo "Configuring mod_ssl with OpenSSL at $SSL_BASE =========================="
echo
sleep 1
./configure \
    --with-apache=../$APACHE

# PERL
cd ../$MODPERL
echo
echo "Building mod_perl ============================"
echo
sleep 1
perl Makefile.PL \
    APACHE_SRC=../$APACHE/src \
    NO_HTTPD=1 \
    USE_APACI=1 \
    PREP_HTTPD=1 \
    EVERYTHING=1

make
#make test
make install

# APACHE
cd ../$APACHE
echo
echo "Building apache =============================="
echo
sleep 1;
./configure \
    --prefix=/usr/local/apache \
    --activate-module=src/modules/perl/libperl.a \
    --enable-module=ssl \
    --enable-module=proxy \
    --enable-module=so \
    --enable-module=rewrite \
    --disable-rule=EXPAT

#    --activate-module=src/modules/php4/libphp4.a \
#make certificate
#make clean
make
make install


