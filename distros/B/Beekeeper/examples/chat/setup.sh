#!/usr/bin/env bash

EXAMPLE_DIR=$(readlink -f -n $(dirname "${BASH_SOURCE[0]}"))
PROJECT_DIR=$(readlink -f -n "$EXAMPLE_DIR/../../")

# Tell beekeeper to use the example config files
export BEEKEEPER_CONFIG_DIR="$EXAMPLE_DIR/config"
echo "Using configs from  $BEEKEEPER_CONFIG_DIR"

# Allow perl to find the example modules 
export PERL5LIB="$EXAMPLE_DIR/lib":"$PROJECT_DIR/lib"
echo "Using modules from  $PERL5LIB"

BEEKEEPER_BIN_DIR="$PROJECT_DIR/bin"
echo "Using commands from $BEEKEEPER_BIN_DIR"

case ":$PATH:" in
    *":$BEEKEEPER_BIN_DIR:"*) :;; # already added
    *) export PATH="$PATH:$BEEKEEPER_BIN_DIR";;
esac
