#!/bin/bash

BASEDIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )/.." >/dev/null 2>&1 && pwd )"

pod2markdown $BASEDIR/lib/AnyEvent/Discord.pm > $BASEDIR/doc/AnyEvent-Discord.md
pod2markdown $BASEDIR/lib/AnyEvent/Discord/Payload.pm > $BASEDIR/doc/AnyEvent-Discord-Payload.md
