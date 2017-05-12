#!/bin/sh

AMPATH=/opt/asnmtap-3.001.xxx
ASNMTAPUSER=asnmtap
WWWUSER=apache                                               # nobody

echo "chown -R $ASNMTAPUSER:$ASNMTAPUSER $AMPATH"
chown -R $ASNMTAPUSER:$ASNMTAPUSER $AMPATH

echo "chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/nav"
chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/nav

echo "chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/pdf"
chown -R $ASNMTAPUSER:$WWWUSER $AMPATH/applications/htmlroot/pdf

echo "chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/applications/tmp"
chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/applications/tmp

echo "chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/plugins/tmp"
chown -R $WWWUSER:$ASNMTAPUSER $AMPATH/plugins/tmp

echo "cd $AMPATH"
cd $AMPATH

find $AMPATH -type d                   -exec chmod 755 {} \; 

find $AMPATH -type f                   -exec chmod 644 {} \;

find $AMPATH -type f -name '*.p12'     -exec chmod 600 {} \;

find $AMPATH -type f -name '*.cgi'     -exec chmod 755 {} \;
find $AMPATH -type f -name '*.js'      -exec chmod 755 {} \;
find $AMPATH -type f -name '*.pl'      -exec chmod 755 {} \;
find $AMPATH -type f -name '*.php'     -exec chmod 755 {} \;
find $AMPATH -type f -name '*.sh'      -exec chmod 755 {} \;
find $AMPATH -type f -name 'perf*.png' -exec chmod 755 {} \;

