#!/bin/sh
#
#   @(#)$Id: hpux-gcc-build.sh,v 100.3 2002/11/21 22:14:48 jleffler Exp $
#
#   Script to build GCC 2.95.2 on HP-UX 10.20 using bundled C compiler
#	Assumes you have the following files available:
#       binutils-2.11.2.tar.gz
#       bison-1.28.tar.gz
#       flex-2.5.4a.tar.gz
#       gcc-3.2.tar.gz
#       gettext-0.10.35.tar.gz
#       make-3.79.1.tar.gz
#       sed-3.02.tar.gz
# Note: there are just enough inconsistencies in the way things have to
# be configured to make it difficult to generalize fully.  It is assumed
# that you have gunzip (or bunzip2) available if you have compressed
# files.  It is assumed that tar is available.
# Note that on HP-UX 11.11, some later versions of some of these
# utilities (bison, gettext) did not compile with the bundled C compiler
# when the script was run, but that manually rebuilding seemed to fix
# things -- no, I've no idea what the trouble was.

# All the GNU software will be placed under the $PREFIXDIR directory
PREFIXDIR=$HOME/hpux
CCSBIN=/usr/ccs/bin
PATH=$PREFIXDIR/bin:$CCSBIN:$PATH
export PATH

: ${GUNZIP:=gunzip}
: ${BUNZIP2:=bunzip2}

# The following lines configure the JLSS install script.  These values
# mean JL does not have to have be root for install to work.  You
# probably want the GNU version of install from fileutils-4.1.tar.gz.
# You might or might not want everything else from the GNU File
# Utilities package.
export CHOWN=:
export CHGRP=:

[ -d $PREFIXDIR ] || mkdir -p $PREFIXDIR

extract_from_tar(){
	basefile=$1
	if [ -f $basefile.tar.gz ]
	then $GUNZIP -c $basefile.tar.gz | tar -xf -
	elif [ -f $basefile.tar.bz2 ]
	then $GUNZIP -c $basefile.tar.bz2 | tar -xf -
	elif [ -f $basefile.tar ]
	then tar -xf $basefile.tar
	else
		echo "Cannot locate $basefile.tar{.bz2,.gz}" 1>&2
		exit 1
	fi
}

echo "Build of GCC for HPUX Starting"
date
echo

sed -e 's/#.*//' -e '/^[ 	]*$/d' <<! |

# Here is the list of packages you need, in the order you need...
# Update version numbers here to suit.
# The GNU File Utilities can be regarded as optional
# fileutils-4.1

gettext-0.10.35
# gettext-0.11.2
bison-1.28
# bison-1.35
flex-2.5.4a		flex-2.5.4		# Note that the directory name is different!
sed-3.02

# For binutils-2.9.1:
# Configure warns about ld not working...
# The build reported failures, but repeated attempts to rerun the
# make didn't produce useful info on where the build was failing.
# However, I decided to pretend that it was something to do with
# the warning about ld not working, and got on with the install.
# Everything seemed to work OK afterwards.
# binutils-2.9.1
binutils-2.11.2
make-3.79.1
!

while read basefile basedir
do
	[ -z "$basedir" ] && basedir=$basefile
	extract_from_tar $basefile
	date
	(
	echo Building $basefile
	cd $basedir
	./configure --prefix=$PREFIXDIR
	make
	make install
	)
	date
	rm -fr $basedir
	echo
done

# The build for GCC itself is different from the rest...
basefile=gcc-3.2
basedir=$basefile
extract_from_tar $basefile
date
(
echo $basefile
mkdir $basefile-obj
cd $basefile-obj
../$basedir/configure --prefix=$PREFIXDIR --with-gnu-as
make bootstrap -k
date
make install -k
)
date
rm -fr $basefile-obj $basedir

echo
date
echo "Build of GCC for HPUX Complete"
