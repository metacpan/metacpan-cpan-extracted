#!/bin/bash

if [ -z "$BEEKEEPER_CONFIG_DIR" ]; then
    echo "Before running this example you need to setup the enviroment with:"
    echo "source setup.sh"
    exit 
fi

bkpr --pool-id "myapp" ${1-start}
