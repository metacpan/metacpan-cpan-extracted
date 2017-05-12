#!/bin/bash
# ---------------------------------------------------------------
# © Copyright 2009-2011 Alex Peeters [alex.peeters@citap.be]
# ---------------------------------------------------------------
# This shell script takes care of starting and stopping

PATH_ASNMTAP=/opt/asnmtap

if [ "$ASNMTAP_PATH" ]; then
  PATH_ASNMTAP=$ASNMTAP_PATH
fi

AMNAME="Import Data Through Catalog ASNMTAP importDataThroughCatalog"
AMPATH=$PATH_ASNMTAP/applications
AMCMD=importDataThroughCatalog.pl
AMPARA="--type=ALL --mode=D --debug=F"
PIDPATH=$PATH_ASNMTAP/pid
PIDNAME=importDataThroughCatalog.pid

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ -f "$AMPATH/sbin/bash_stop_root.sh" ]; then
  source "$AMPATH/sbin/bash_stop_root.sh"
fi

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[ -f $AMPATH/bin/$AMCMD ] || exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

start() {
  echo "Start: 'All ASNMTAP Import Data Through Catalog' ..."

  # Start daemons
  if [ -f $PIDPATH/$PIDNAME ]
  then
    echo "'$AMNAME' already running, otherwise remove '$PIDNAME'"
  else
    echo "Start: '$AMNAME' ..."
    cd $AMPATH/bin
    PATH=$PATH MANPATH=$MANPATH PERL5LIB=$PERL5LIB LD_LIBRARY_PATH=$LD_LIBRARY_PATH ./$AMCMD $AMPARA &
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

stop() {
  echo "Stop: 'All ASNMTAP Import Data Through Catalog' ..."

  # Stop daemons
  if [ -f $PIDPATH/$PIDNAME ]
  then
    echo "Stop: '$AMNAME' ..."
    kill -QUIT `cat $PIDPATH/$PIDNAME`

    sleep 1
  else
    echo "'$AMNAME' already stopped"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

restart() {
  echo "Restart: 'All ASNMTAP Import Data Through Catalog' ..."

  while [ -f $PIDPATH/$PIDNAME ]
  do
    stop
  done

  start
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reload() {
  echo "Reload: 'All ASNMTAP Import Data Through Catalog' ..."

  echo "Reload: '$AMNAME' ..."
  kill -HUP `cat $PIDPATH/$PIDNAME`
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

status() {
  echo "Status: 'All ASNMTAP Import Data Through Catalog' ..."

  # Status daemons
  if [ -f $PIDPATH/$PIDNAME ]
  then
    echo "Status: '$AMNAME' is running"
    ps -ef | grep `cat $PIDPATH/$PIDNAME`
  else
    echo "Status: '$AMNAME' is not running"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

# See how we were called.
case "$1" in
  start)
           start
           ;;
  stop)
           stop
           ;;
  restart)
           restart
           ;;
  reload)
           reload
           ;;
  status)
           status
           ;;
  *)
           echo "Usage: '$AMNAME' {start|stop|restart|reload|status}"
           exit 1
esac

exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
