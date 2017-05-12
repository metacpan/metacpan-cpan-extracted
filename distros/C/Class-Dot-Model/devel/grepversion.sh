#!/bin/bash
basedir=$(dirname $0);
curversion=$(perl $basedir/curversion);

quotemeta () {
    echo $(echo "$1" | perl -nle'print quotemeta');
} 

if [ ! -z "$1" ]; then
    curversion=$1;
fi

ack=$(which ack);
if [ ! -z "$ack" ]; then
    curversion=$(quotemeta "$curversion");
    ack "\b$curversion\b"
else
    grep -R "$curversion" * 
fi
    
