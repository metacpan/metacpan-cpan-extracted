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
