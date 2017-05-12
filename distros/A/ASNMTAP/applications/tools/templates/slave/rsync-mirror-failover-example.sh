#!/bin/bash
# ------------------------------------------------------------------------------
# © Copyright 2003-2011 Alex Peeters [alex.peeters@citap.be]
# ------------------------------------------------------------------------------
# rsync-mirror-failover.sh for asnmtap, v2.001.xxx, mirror script for rsync
#   execution via ssh key for use with rsync-wrapper-failover.sh
# ------------------------------------------------------------------------------
# Step-by-step instructions for installation:
# 1) Install the rsync package
# 2) Install a command line ssh (openssh) tool
# 3) Make sure you can ssh to the remote systems.
# 4) Install rsync-mirror-failover.sh into /opt/asnmtap/applications/slave if it's not already there.
# 5) Copy rsync-mirror-failover-example.conf to /opt/asnmtap/applications/slave if there's not already one there.
#
# 6) Try a trial run:
#    onto the master server:
#    mkdir /tmp/master
#    echo "Some file content" >/tmp/master/onefile
#    vi /opt/asnmtap/applications/slave/rsync-mirror-failover-example.conf
#    uncomment #ape@asnmtap.citap.com:/tmp/master/  /tmp/slave/  -c -z
#    ./rsync_mirror-failover.sh
#
#    You should now see "Some file content" in the /tmp/slave/onefile over on slave server.
#
# 7) Edit /opt/asnmtap/applications/slave/rsync-mirror-failover.conf to include one line for every directory that
#    needs to be regularly mirrored. The rsync-mirror-failover-example.conf includes some sample lines.
# ------------------------------------------------------------------------------
#    parameters for /opt/asnmtap/applications/slave/rsync-mirror-failover.sh:
#
#    -c|-C  : config file name
#    -r|-R  : Operating in reverse mode, source and destination fields will be swapped
#    --nodel: no delete (rsync-wrapper-failover.sh don't allow this for the moment)
#
#  crontab -e
#    */5    * * * * /opt/asnmtap/applications/slave/rsync-mirror-failover.sh > /dev/null  <-- crontab op slave server
#  or
#    0-59/5 * * * * /opt/asnmtap/applications/slave/rsync-mirror-failover.sh > /dev/null  <-- crontab op slave server
#  or
#    1-59/15 * * * * /opt/asnmtap/applications/slave/rsync-mirror-failover-15.sh > /dev/null
#    2-59/10 * * * * /opt/asnmtap/applications/slave/rsync-mirror-failover-10.sh > /dev/null
#    3-59/5  * * * * /opt/asnmtap/applications/slave/rsync-mirror-failover-05.sh > /dev/null
#    4-59/2  * * * * /opt/asnmtap/applications/slave/rsync-mirror-failover-02.sh > /dev/null
#
#  vi /opt/asnmtap/applications/tools/templates/slave/rsync-mirror-failover-tmp.sh
#    #!/bin/bash
#    cd /opt/asnmtap/applications/tools/templates/slave/
#    ./rsync-mirror-failover-example.sh -C rsync-mirror-failover-example.conf
# ------------------------------------------------------------------------------
# Shedule only one rsync-mirror-failover.sh scripts at the same time, unless you have more
# then one of 'rsync-wrapper-failover.sh' script!  When needed, copy 'rsync-wrapper-failover.sh' to
# 'rsync-wrapper-failover-02.sh', 'rsync-wrapper-failover-05.sh', 'rsync-wrapper-failover-10.sh'
# & 'rsync-wrapper-failover-15.sh'
#
# authorized_keys -> command='/opt/asnmtap/applications/master/rsync-wrapper-failover-02.sh' ...
#                 -> command='/opt/asnmtap/applications/master/rsync-wrapper-failover-05.sh' ...
#                 -> command='/opt/asnmtap/applications/master/rsync-wrapper-failover-10.sh' ...
#                 -> command='/opt/asnmtap/applications/master/rsync-wrapper-failover-15.sh' ...
# ------------------------------------------------------------------------------
# vi hosts.allow
# rsync: <hostname slave failover servers>
#
# vi hosts.deny
# rsync: ALL
# ------------------------------------------------------------------------------
# Setup example:
#
# <slave server>:
#   ssh-keygen -q -t rsa -f /home/asnmtap/.ssh/rsync -N ""
# or
#   ssh-keygen -q -t dsa -f /home/asnmtap/.ssh/rsync -N ""
# 
# chmod go-w   /home/asnmtap/
# chmod 700    /home/asnmtap/.ssh
# chmod go-rwx /home/asnmtap/.ssh/*
# cat /home/asnmtap/.ssh/rsync.pub >> /home/asnmtap/.ssh/authorized_keys
# chmod 600 /home/asnmtap/.ssh/authorized_keys
# 
# vi /usr/local/etc/sshd_config or /etc/ssh/sshd_config
# PubkeyAuthentication yes
# PermitEmptyPasswords yes
# 
# <master server>:
# vi authorized_keys
# from="asnmtap.citap.be", command ="/opt/asnmtap/applications/master/rsync-wrapper-failover-asnmtap.citap.com.sh" ssh-rsa AAAAB3NzaC1yc2EAAAABIwAAAIEA5o5rh/yScb8506oLJSPRaKR2PCKfI4U/YOSylN7h8w5z5jIO/6W7qKTwWyJ9lPF3c/D6WM2N4cVkVbcprJq+59vxEPCV9jmDQjFKJDHBTQbDoOfb1mgbFZT1SZ0/xhDy05wqxVQ3GByWvbNjzWBYr+ohoVXZajqAS9uaFzD+3KM
#                                                                                                                            ^- rsync.pub
# Testing:
# /opt/asnmtap/applications/slave/rsync-mirror-failover-asnmtap.citap.be.sh
# ------------------------------------------------------------------------------

RMVersion='3.002.003'
echo "rsync-mirror-failover version $RMVersion"

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ ! "$ASNMTAP_PATH" ]; then
  ASNMTAP_PATH=/opt/asnmtap-3.001.xxx
fi

PidPath="$ASNMTAP_PATH/pid"

Rsync=/usr/local/bin/rsync
RsyncPath=/usr/local/bin/rsync
KeyRsync=/home/asnmtap/.ssh/rsync
ConfFile=rsync-mirror-failover.conf
ConfPath="$ASNMTAP_PATH/applications/slave"
Delete=' --delete --delete-after '
# AdditionalParams=''                             # --numeric-ids, -H, -v and -R
Reverse=no                                        # 'yes' -> from slave to master
                                                  # 'no'  -> from master to slave

# ------------------------------------------------------------------------------
# DON'T TOUCH BELOW HERE UNLESS YOU KNOW WHAT YOU ARE DOING!
# ------------------------------------------------------------------------------

cTime=''

if [ -f ~/.profile ]; then
  source ~/.profile
fi

if [ -f ~/.bash_profile ]; then
  source ~/.bash_profile
fi

if [ -w "$PidPath" ]; then
  Lockfile="$PidPath/$ConfFile.pid"
else
  echo "Warning: $PidPath is not writable.  Please fix."
  Lockfile="/tmp/$ConfFile.pid"
fi

until [ -z "$1" ]; do
  case "$1" in
    -c|-C)
      if [ -z "$2" ]; then
        echo Missing config file name, exiting >&2
        exit 1
      elif [ ! -e "$ConfPath/$2" ]; then
        echo "Nonexistant config file \"$ConfPath/$2\", exiting" >&2
        exit 1
      fi

      ConfFile="$2"
      shift 2	
      ;;
    -r|-R)
      echo "Operating in reverse mode, source and destination fields will be swapped."
      Reverse="yes"
      shift
      ;;
    --nodel)
      echo 'Will NOT delete files at the remote end'
      Delete=''
      shift
      ;;
    --cTime)
      if [ -z "$2" ]; then
        echo 'Operating without cTime mode.'
        cTime=''
        shift
      else
        echo 'Operating in cTime mode.'
        cTime="$2"
        shift 2
      fi
      ;;
    *)
      echo "Unrecognized parameter \"$1\", exiting." >&2
      exit 1
      ;;
  esac
done

if [ ! -r "$ConfPath/$ConfFile" ]; then
  echo Missing or unreadable configuration file "$ConfPath/$ConfFile".  Exiting.
  exit 1
fi

if [ -f "$Lockfile" ]; then
  echo 'Warning! there may be another copy running, aborting!'
  exit 1
fi

if [ -f "$Lockfile" ] && [ ! -w "$Lockfile" ]; then
  echo 'Warning! Someone else appears to own'"$Lockfile"', aborting!'
  exit 1
fi

echo $$ >$Lockfile
Lock='yes'

(cat "$ConfPath/$ConfFile" | sed -e 's/#.*//' | grep -v '^$' ) | while read Source Target AdditionalParams; do
  if [ "$cTime" != "" ]; then
    Source="--files-from=<(cd ${Source}; find . -type f -ctime ${cTime}) ${Source}"
  fi

  if [ "$Reverse" = "yes" ]; then
    #FIXME - both source and dest need to be single (*/) directories or single files for reverse mode.
    Temp="$Source"
    Source="$Target"
    Target="$Temp"
  fi

  Command="${Rsync} --rsync-path=${RsyncPath} -e 'ssh -i ${KeyRsync}' -a ${Delete} ${AdditionalParams} ${Source} ${Target}"
  eval $Command
done

if [ "$Lock" = 'yes' ]; then
  rm -f "$Lockfile"
fi

# ------------------------------------------------------------------------------
