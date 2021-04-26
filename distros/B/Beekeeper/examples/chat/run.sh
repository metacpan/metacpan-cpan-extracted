#!/bin/bash

if [ -z "$BEEKEEPER_CONFIG_DIR" ]; then
    echo "Before running this example you need to setup the enviroment with:"
    echo "source setup.sh"
    exit 
fi

case "$1" in
    'start')
        bkpr --pool-id "broker"  start
        bkpr --pool-id "myapp-A" start
        bkpr --pool-id "myapp-B" start
        ;;
    'stop')
        bkpr --pool-id "myapp-A" stop
        bkpr --pool-id "myapp-B" stop
        bkpr --pool-id "broker"  stop
        ;;
    'restart')
        bkpr --pool-id "myapp-A" restart
        bkpr --pool-id "myapp-B" restart
        ;;
    *)
        echo -e "Usage: $0 [start|stop|restart]"
        ;;
esac


