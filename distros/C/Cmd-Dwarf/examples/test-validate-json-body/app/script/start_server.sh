#!/bin/sh
ROOT=${0%/*}/..
PID=$ROOT/starman.pid
PSGI=$ROOT/app.psgi
HOST=0.0.0.0
PORT=11022
MODE=debug
LOCAL=NO
USE_CARTON=0

# オプションをハンドリング
while getopts m:lch opt
do
	case $opt in
	m )    MODE=$OPTARG
	       ;;
	l )    LOCAL=YES
	       ;;
	c )    USE_CARTON=1
	       ;;
	h )    echo '% ./start_server.sh [<option>]
version 1.0
    	
option:
    -m mode
       if you pass production then this run starman. if not, this run plackup'
		   exit
		   ;;
    ? )    echo 'Usage -h'
		   exit
		   ;;
	esac
done

if [ ${LOCAL} = 'YES' ]
then
	/bin/sh -c "sleep 0.5; open -a Safari http://$HOST:$PORT" &
fi

if [ ${USE_CARTON} = '1' ]
then
	CARTON="local/bin/carton exec"
fi

cd $ROOT
if [ ${MODE} = 'production' ]
then
	$CARTON starman -I local/lib/perl5 -I lib -l $HOST:$PORT --pid $PID $PSGI
else
	$CARTON plackup -I local/lib/perl5 -I lib -R lib,tmpl --host $HOST --port $PORT $PSGI
fi
