#!/bin/bash
# ----------------------------------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ----------------------------------------------------------------------------------------------------------
# 2011/mm/dd, v3.002.003, archive.sh
# ----------------------------------------------------------------------------------------------------------

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

AMPATH=/opt/asnmtap

if [ "$ASNMTAP_PATH" ]; then
  AMPATH=$ASNMTAP_PATH
fi

# ----------------------------------------------------------------------------------------------------------

# Central Server ASNMTAP
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d T

# Distributed Server ASNMTAP
# cd $AMPATH/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d F

# or -------------------------------------------------------------------------------------------------------

# With Crontab Parameters
# cd $AMPATH/applications; /usr/bin/env perl archive.pl "$@"

# ==========================================================================================================

# Central Server Apache for user <apache>
# crontab -l
# 0 1 * * * cd /opt/monitoring/asnmtap/applications; /usr/bin/env perl archive.sh > /dev/null

# Distributed Server Apache for user <apache>
# crontab -l
# 0 1 * * * cd /opt/monitoring/asnmtap/applications; /usr/bin/env perl archive.sh > /dev/null

# or -------------------------------------------------------------------------------------------------------

# With Crontab Parameters 
# crontab -l
#
# Central Server ASNMTAP
#   0 1 * * * cd /opt/monitoring/asnmtap/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d T > /dev/null
#
# Distributed Server ASNMTAP
#   0 1 * * * cd /opt/monitoring/asnmtap/applications; /usr/bin/env perl archive.pl -A ArchiveCT -c F -r T -d F > /dev/null

# ----------------------------------------------------------------------------------------------------------
