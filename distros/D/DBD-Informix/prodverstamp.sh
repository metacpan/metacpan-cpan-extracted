#!/bin/ksh
#
#   @(#)$Id: prodverstamp.sh,v 2015.1 2015/08/31 00:55:23 jleffler Exp $
#
#   $Product: Informix Database Driver for Perl DBI Version 2018.1031 (2018-10-31) $
#
#   Product version stamping tool
#
#   (C) Copyright JLSS 2003,2007-10,2015

# Ensure we do not pick up stray environment variables!
BASEVRSN=
CM_DIRS=
JDCFILE=
LICENCE=
PRODCODE=
PRODDATE=
PRODMAIL=
PRODNAME=
PRODYEAR=
TAREXTN=
TARFILE=

Aflag=          # Other attribute
Cflag=no        # Print product codename [aka filename prefix]
Dflag=no        # Print date
Eflag=no        # Print email address
Fflag=no        # Final build (no _date)
Lflag=no        # Print licence name
Mflag=no        # Print list of CM directories to back up
Nflag=no        # Print product name
Pflag=no        # Print full product version stamp
Tflag=no        # Print tar file name
Vflag=no        # Print version
Xflag=no        # Print tar file extension
Yflag=no        # Print product year (copyright dates)
COPYRIGHT=      # Set copyright information
sflag=          # Set product suffix
uflag=0         # Do not delete licence (:LICEN[CS]E:) information
zflag=0         # Do not delete LICEN[CS]E or COPYING file names

# If there is an environment variable...
# This is crucial to the argument-less operation needed in NMD processing.
if [ "X$PRODVERSTAMPFLAGS" != "X" ]
then eval set -- "$@" $PRODVERSTAMPFLAGS
fi

usestr="Usage: $(basename $0 .sh) [-F][-huzCDELMNPTVX] [-A attribute] [-j file.jdc] \\
       [-c code][-d date][-e email][-l licence][-m cmdirs][-n name] \\
       [-r copyright][-s suffix][-t tarfile][-v version][-x tar-extn] \\
       [file ...]"

helpinfo()
{
    printf "$usestr\n"
    printf "\nCommand options:\n"
    printf "  -A attr Echo the named attribute\n"
    printf "  -C      Echo the product code (PRODCODE)\n"
    printf "  -D      Echo the product date (today)\n"
    printf "  -E      Echo the email address (jonathan.leffler@gmail.com)\n"
    printf "  -F      Final release (no date suffix to version number)\n"
    printf "  -L      Echo the licence string (GNU GPL v2)\n"
    printf "  -M      Echo the CM directories for the product\n"
    printf "  -N      Echo the product name (PRODUCT)\n"
    printf "  -P      Echo the product identifier string (PRODUCT Version VERSION (DATE))\n"
    printf "  -T      Echo the product tar file name (PRODCODE.VERSION.DATE.tgz)\n"
    printf "  -V      Echo the version number (VERSION.DATE)\n"
    printf "  -X      Echo the tar extension (.tgz)\n"
    printf "  -c code Set the product code\n"
    printf "  -d date Set the product date\n"
    printf "  -e mail Set the email address\n"
    printf "  -h      Echo this help information\n"
    printf "  -j file Name of JLSS Distribution Configuration file\n"
    printf "  -l lic  Set the licence string\n"
    printf "  -n name Set the product name\n"
    printf "  -r copy Set the copyright information string\n"
    printf "  -s sffx Set suffix to version number\n"
    printf "  -t tar  Set the product tar file name\n"
    printf "  -u      Delete licence (:LICEN[SC]E:) information\n"
    printf "  -v vrsn Set the version number\n"
    printf "  -x ext  Set the product tar file extension\n"
    printf "  -z      Delete licence file names (LICEN[CS]E, COPYING)\n"
    printf "\nNote that $(basename $0 .sh) can be used as a pure filter too\n"
    exit 0
}

while getopts c:d:e:hj:l:m:n:r:s:t:uv:x:y:zA:CDEFLMNPTVXY opt
do
    case $opt in
    c)  PRODCODE="$OPTARG";;
    d)  PRODDATE="$OPTARG";;
    e)  PRODMAIL="$OPTARG";;
    h)  helpinfo;;
    j)  JDCFILE="$OPTARG";;
    l)  LICENCE="$OPTARG";;
    m)  CM_DIRS="$OPTARG";;
    n)  PRODNAME="$OPTARG";;
    r)  COPYRIGHT="$OPTARG";;
    s)  sflag="-$OPTARG";;
    t)  TARFILE="$OPTARG";;
    u)  uflag=1;;
    v)  BASEVRSN="$OPTARG";;
    x)  TAREXTN="$OPTARG";;
    y)  PRODYEAR="$OPTARG";;
    z)  zflag=1;;
    A)  Aflag="$OPTARG";;
    C)  Cflag=yes;;
    D)  Dflag=yes;;
    E)  Eflag=yes;;
    F)  Fflag=yes;;
    L)  Lflag=yes;;
    M)  Mflag=yes;;
    N)  Nflag=yes;;
    P)  Pflag=yes;;
    T)  Tflag=yes;;
    V)  Vflag=yes;;
    X)  Xflag=yes;;
    Y)  Yflag=yes;;
    *)  echo "$usestr" 1>&2; exit 1;;
    esac
done
shift `expr $OPTIND - 1`

if [ -z "$JDCFILE" ]
then JDCFILE=$(basename $(pwd) | sed -e 's/-MSD$//' -e 's/-[0-9][^-]*$//').jdc
fi

checkout_file()
{
    file=$1
    [ ! -f $file ] && ${CO:-co} ${COFLAGS:-'-q'} $file
    [ ! -f $file ] && echo "Did not find $file file" 1>&2 && exit 1
}

if [ "$JDCFILE" != "/dev/null" ]
then checkout_file $JDCFILE
fi

# Convert JDC file into a set of shell variable settings
# This is risky - we're executing user-supplied content.
tmp=${TMPDIR:-/tmp}/pvs.$$
trap "rm -f $tmp; exit 1" 1 2 3 13 15
${PERL:-perl} -n -e 's/#.*//;
    next unless m/^\s*\w+\s*=/;
    s/\s*=\s*/=/;
    s/\s*$/\n/;
    s/=([^"].*)/="$1"/;
    print;
    ' $JDCFILE > $tmp
. $tmp
rm -f $tmp
trap 1 2 3 13 15

# Arguably, should not evaluate a value until it is demonstrably needed (eg CM_DIRS).
: ${BASEVRSN:="${VERSION:?'VERSION not set in $JDCFILE'}"}
: ${PRODDATE:=`date +%Y-%m-%d`}
: ${PRODYEAR:=`date +%Y`}
: ${PRODNAME:="${NAME:-${PRODNAME:?'NAME not set in $JDCFILE'}}"}
: ${PRODCODE:="${CODE:-${PRODCODE:?'CODE not set in $JDCFILE'}}"}
: ${TAREXTN:=".tgz"}
: ${LICENCE:="GNU General Public Licence Version 3"}
: ${PRODAUTH:="${AUTHOR:-Jonathan Leffler}"}
: ${PRODMAIL:="${EMAIL:-jonathan.leffler@gmail.com}"}
CM_DIRS="$CMDIRECTORIES"
[ -z "$CM_DIRS" ] && CM_DIRS=$([ -d RCS ] && echo RCS; [ -d SCCS ] && echo SCCS;)

# Final build - use base version only
if [ $Fflag = yes ]
then PRODVRSN="${BASEVRSN}"
else PRODVRSN="${BASEVRSN}.`date +%Y%m%d`" # Beware SCCS!
fi
if [ -n "$sflag" ]
then PRODVRSN="${PRODVRSN}$sflag"
fi

VERSION="$PRODNAME Version $PRODVRSN ($PRODDATE)"
: ${TARFILE:="$PRODCODE.$PRODVRSN$TAREXTN"}

# Display components of version information
[ $Cflag = yes ] && echo "$PRODCODE"
[ $Dflag = yes ] && echo "$PRODDATE"
[ $Eflag = yes ] && echo "$PRODMAIL"
[ $Lflag = yes ] && echo "$LICENCE"
[ $Mflag = yes ] && echo "$CM_DIRS"
[ $Nflag = yes ] && echo "$PRODNAME"
[ $Pflag = yes ] && echo "$VERSION"
[ $Tflag = yes ] && echo "$TARFILE"
[ $Vflag = yes ] && echo "$PRODVRSN"
[ $Xflag = yes ] && echo "$TAREXTN"
[ $Yflag = yes ] && echo "$PRODYEAR"
[ -n "$Aflag"  ] && { eval echo "\${$Aflag}"; Aflag=yes; }

case "$Cflag$Dflag$Eflag$Lflag$Mflag$Nflag$Pflag$Tflag$Vflag$Xflag$Aflag" in
*yes*)  exit 0;;
esac

# Edit file(s) to set version strings.
# NB: The script below must be immune from change when prodverstamp is
#     run on itself (which is non-trivial to achieve!).
# NB: The $UCPRODCODE line below nominally handles old projects with
#     codes like :RMK: in the files.
# NB: Files (such as this one) may include the RCS-like keyword Product
#     enclosed with dollar signs, and prodverstamp will then expand it.
UCPRODCODE=`echo $PRODCODE | tr '[a-z]' '[A-Z]'`

# Be careful with the quotes!
rvalue=0
[ -n "$COPYRIGHT" ] && rvalue=1
${PERL:-perl} -we '
use strict;
use constant del_licence => '$uflag';
use constant del_copying => '$zflag';
use constant map_copyright => '$rvalue';
my $COPYRIGHT  = q{'"$COPYRIGHT"'};
my $LICENCE    = q{'"$LICENCE"'};
my $PRODAUTH   = q{'"$PRODAUTH"'};
my $PRODCODE   = q{'"$PRODCODE"'};
my $PRODDATE   = q{'"$PRODDATE"'};
my $PRODMAIL   = q{'"$PRODMAIL"'};
my $PRODNAME   = q{'"$PRODNAME"'};
my $PRODVRSN   = q{'"$PRODVRSN"'};
my $PRODYEAR   = q{'"$PRODYEAR"'};
my $TAREXTN    = q{'"$TAREXTN"'};
my $TARFILE    = q{'"$TARFILE"'};
my $VERSION    = q{'"$VERSION"'};
my $UCPRODCODE = q{'"$UCPRODCODE"'};

while (<>)
{
    next if del_licence && m%:LICEN[CS]E:%;
    next if del_copying && m%(?:^|/)(?:COPYING|LICEN[CS]E)\b%;

    s%\$Product: [^\$]* \$%\$Product\$%;
    s%\$Product\$%\$Product: $VERSION \$%;
    s%[:]$UCPRODCODE:%$VERSION%;
    s%[:]LICEN[CS]E:%$LICENCE%;
    s%[:]PRODAUTH:%$PRODAUTH%;
    s%[:]PRODCODE:%$PRODCODE%;
    s%[:]PRODDATE:%$PRODDATE%;
    s%[:]PRODMAIL:%$PRODMAIL%;
    s%[:]PRODNAME:%$PRODNAME%;
    s%[:]PRODUCT:%$VERSION%;
    s%[:]PRODVRSN:%$PRODVRSN%;
    s%[:]PRODYEAR:%$PRODYEAR%;
    s%[:]TAREXTN:%$TAREXTN%;
    s%[:]TARFILE:%$TARFILE%;
    s%[:]VERSION:%$PRODVRSN%;

    if (map_copyright)
    {
        if (!m/Copyright/i)
        {
            print;
            next;
        }
        if (s/"\(C\)\s*Copyright\s+J[^"]*L[^"]*\s\d[^"]*"/"$COPYRIGHT"/)
        {
            print;
            next;
        }
        s/(@\(#\)\s*Copyright\s*:\s*).*/$1$COPYRIGHT/;
        s/\(C\)\s*Copyright\s*JLSS\s*\d.*/$COPYRIGHT/;
        s/\(C\)\s*Copyright\s*\d[-\d,]+\s*JLSS/$COPYRIGHT/;
    }

    print;
}
' "$@"
