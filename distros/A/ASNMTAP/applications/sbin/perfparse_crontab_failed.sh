#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, perfparse_crontab_failed.sh
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

for file in $( find $AMPATH/log/ -name 'perfdata-asnmtap.log-*-failed' ) 
do
  echo "Filename failed: '$file'";
# cat $file | $PERFPARSEPATH/bin/perfparse-log2mysql
# rv="$?"

# if [ ! "$rv" = "0" ]; then
    exec 3<&0
    exec 0<$file

    while read line
    do
      echo "$line" | $PERFPARSEPATH/bin/perfparse-log2mysql
        rv="$?"

        if [ ! "$rv" = "0" ]; then
          echo "$line" >> "$file-manual-action-needed"
        fi
    done

    exec 0<&3
# fi

  rm $file
done

exit 0
