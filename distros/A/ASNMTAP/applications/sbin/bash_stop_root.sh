#!/bin/bash

STOP_ROOT=TRUE

ASNMPTAP_UID=32006
ASNMPTAP_USER=asnmtap

HTTPD_UID=99

uid=`echo $UID`
user=`echo $USER`

if [ "$uid" -eq 0 -a "$STOP_ROOT" = "TRUE" ]; then
  echo "*** NOTICE: ASNMPTAP has been configured not to run as root ! ***"
  exit 1
elif [ "$uid" -eq 0 -a "$STOP_ROOT" != "TRUE" ]; then
  echo "*** WARNING: Running ASNMPTAP as root is not recommended ! ***"
elif [ $uid != "$ASNMPTAP_UID" -a "$user" != "$ASNMPTAP_USER" -a $uid != "$HTTPD_UID" ]; then
  echo "*** NOTICE: ASNMPTAP must be started with shell uid(user) $ASNMPTAP_UID($ASNMPTAP_USER) or with httpd uid $HTTPD_UID"
  exit 1
fi

