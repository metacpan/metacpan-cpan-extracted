#!/usr/bin/env bash
#
# This is a senseless test script
#

QUOTE=""
while [ -n "$1" ] ; do
    case "$1" in
	--quote-character)
	    QUOTE="$2"
	    shift
	    shift
	    ;;
	--exit-with-error)
	    RC=1
	    [ -n "$2" ] && RC=$2
	    # shifting not necessary...
	    exit $RC
	    ;;
	--echo-to-stderr)
	    echo "$2" >&2
	    shift
	    shift
	    ;;
	--sleep)
	    sleep $2
	    shift
	    shift
	    ;;
	--printenv)
	    eval echo \$$2
	    shift
	    shift
	    ;;
	--)
	    shift
	    cat
	    ;;
	--*)
	    echo "ERROR: invalid option $1" >&2
	    exit 1
	    ;;
	*)
	    echo "${QUOTE}$1${QUOTE}"
	    shift
	    ;;
    esac
done
