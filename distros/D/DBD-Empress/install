#!/bin/sh

USAGE="*** Usage *** $0 [perl_installation_directory]"

while :
do
	case $1 in
	 -static)	LINKTYPE=-static ; shift ;;
	 *)	break ;;
	esac
done

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

X=`uname -a`
TMPFILE=/tmp/temp$$

case $X in
 *SCO*)	MSSYS_PLATFORM=SYS_OS_UNIX_SCO
	sed -e '
s!^my $LIBS =.*!my $LIBS = "-L./lib -ldse -lms -lc";!
' < Makefile.PL > $TMPFILE
	;;
 *)
	sed -e '
s!^my $LIBS =.*!my $LIBS = "-L./lib -ldse -lms";!
' < Makefile.PL > $TMPFILE
	;;
esac

chmod +w Makefile.PL
mv $TMPFILE Makefile.PL

rm -fr Makefile
perl mklibms.pl

case $LINKTYPE in
 -static)	perl Makefile.PL LINKTYPE=static ;;
 *) perl Makefile.PL ;;
esac

rm *.o > /dev/null 2>&1
make
make install

case $LINKTYPE in
 -static)
	case $MSSYS_PLATFORM in
	  SYS_OS_UNIX_SCO)
		TMPFILE=/tmp/temp$$
		FILE=./blib/arch/auto/DBD/Empress/extralibs.all
		cat <<EOM
**************************************************************
SCO cc cannot work with -L correctly. 
Hacking $FILE
**************************************************************
EOM
		sed -e "
s!-L.*-ldse.*!./lib/libdse.a ./lib/libms.a!
" < $FILE > $TMPFILE
		chmod +w $FILE
		mv $TMPFILE $FILE
		;;
	esac

	make perl
	;;
esac
