# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

[ -f $AMPATH/$AMCMD ] || exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

start() {
  # Start daemons
  if [ -f $PIDPATH/$PIDNAME ]
  then
    echo "'$AMNAME' already running, otherwise remove '$PIDNAME'"
  else
    echo "Start: '$AMNAME' ..."
    cd $AMPATH
    PATH=$PATH MANPATH=$MANPATH PERL5LIB=$PERL5LIB LD_LIBRARY_PATH=$LD_LIBRARY_PATH ./$AMCMD $AMPARA &
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

stop() {
  # Stop daemons
  if [ -f $PIDPATH/$PIDNAME ]
  then
    echo "Stop: '$AMNAME' ..."
    kill -QUIT `cat $PIDPATH/$PIDNAME`
    sleep 5
  else
    echo "'$AMNAME' already stopped"
  fi
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

restart() {
  while [ -f $PIDPATH/$PIDNAME ]
  do
    stop
  done

  start
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

reload() {
  echo "Reload: '$AMNAME' ..."
  kill -HUP `cat $PIDPATH/$PIDNAME`
}

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -

status() {
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