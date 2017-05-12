#!/bin/sh

USAGE="*** Usage *** $0 [perl_installation_directory]"

if test "$1" != ""
then
	PERLDIR=$1

	if test ! -f $PERLDIR/bin/perl
	then
		echo "'$PERLDIR' is not a perl installation directory. Abort ..."
		exit 1
	fi

	MSHYPERPATH=`cd $PERLDIR; cd .. ; pwd`
	export MSHYPERPATH

	PATH=$PERLDIR/bin:$PATH
	export PATH

fi


rm -fr Makefile
perl Makefile.PL
rm *.o > /dev/null 2>&1
make
make install

