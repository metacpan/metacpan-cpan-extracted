#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, perfparse_debug.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then 
  source ~/.profile 
fi 

if [ -f ~/.bash_profile ]; then 
  source ~/.bash_profile 
fi 

AMPATH=/opt/asnmtap-3.001.xxx

if [ "$ASNMTAP_PATH" ]; then
  AMPATH=$ASNMTAP_PATH
fi

PERFPARSEPATH=/opt/asnmtap/perfparse

# Store file name 
FILE=$1 

# Make sure we get file name as command line argument else read it from standard input device 
if [ ! "$FILE" = "" ]; then
  if [ ! -f $FILE ]; then
    echo "$FILE: does not exist"
    exit 1
  elif [ ! -r $FILE ]; then
    echo "$FILE: can not be read"
    exit 2
  fi
else
  echo "Usage: `basename $0` filename"
fi

# read $FILE using the file descriptors 
exec 3<&0
exec 0<$FILE

while read line 
do 
  echo "$line" | $PERFPARSEPATH/bin/perfparse-log2mysql
done

exec 0<&3
exit 0

