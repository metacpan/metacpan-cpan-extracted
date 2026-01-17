#!/bin/bash

set -o nounset

PJ_HOME=${0%/*}/..

cd $PJ_HOME
for f in $(git ls-files); do
    if [[ "$f" =~ .+\.(pl|pm|t)$ ]]; then
        carmel exec perltidy -pro="$PJ_HOME/.perltidyrc" -q -b "$PJ_HOME/$f"
        if [[ $? -eq 0 ]]; then
            rm -f "$PJ_HOME/$f.bak"
        fi
    fi
done
