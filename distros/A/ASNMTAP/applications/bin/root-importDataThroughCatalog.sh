#!/bin/sh

AMPATH=/opt/asnmtap

if [ "$ASNMTAP_PATH" ]; then
  AMPATH=$ASNMTAP_PATH
fi

su - asnmtap -c "cd $AMPATH/applications/bin; ./asnmtap-importDataThroughCatalog.sh $1"
exit 0

# - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
