#!/bin/bash

# PODNAME: dvsource_fw_tally.sh

# Filter for output of dvsource-firewire -t.
# Requires a serial device with an LED between DTR and GND.

#TALLY_DEVICE="hw:3,0"

#DVSOURCE_CMD="cat tally.txt"
TALLY_HW_DEV=`amidi -l | grep TallyLED | awk '{ print $2; exit }' `

RED_REC="90 3C 7F 90 3D 00"
RED_CUE="90 3C 00 90 3D 7F"
RED_OFF="90 3C 00 90 3D 00"

GREEN_ON="90 3F 7F"
GREEN_OFF="90 3F 00"

ALL_OFF="90 3C 00 90 3D 00 90 3E 00 90 3F 00"



if [  "XXX"${TALLY_HW_DEV} = "XXX" ]
then
  echo No Tally Light Found

  DVSOURCE_CMD="dvsource-firewire -h $1 -p $2 -c $3"

  $DVSOURCE_CMD
else
  echo Tally Light Found

  amidi -p $TALLY_HW_DEV -S $GREEN_ON

  trap "amidi -p $TALLY_HW_DEV -S $ALL_OFF"; killall dvsource-firewire EXIT

  DVSOURCE_CMD="dvsource-firewire -h $1 -p $2 -c $3 -t"

  $DVSOURCE_CMD | \
  while read line
    do
      case "$line" in
    'TALLY: on')
        # Turn on the Red Light
        #exec 3>"$TALLY_HW_DEV"
        amidi -p $TALLY_HW_DEV -S $RED_REC
        ;;
    'TALLY: cue')
        # Deassert DTR
        #exec 3>/dev/null
        amidi -p $TALLY_HW_DEV -S $RED_CUE
        ;;
    'TALLY: off')
        # Deassert DTR
        #exec 3>/dev/null
        amidi -p $TALLY_HW_DEV -S $RED_OFF
        ;;
    *)
        echo "$line"
        ;;
      esac
    done
  amidi -p $TALLY_HW_DEV -S $ALL_OFF
fi

__END__

=pod

=encoding UTF-8

=head1 NAME

dvsource_fw_tally.sh

=head1 VERSION

version 0.5

=head1 AUTHOR

Leon Wright < techman@cpan.org >

=head1 COPYRIGHT AND LICENSE

This software is Copyright (c) 2014 by Leon Wright.

This is free software, licensed under:

  The GNU Affero General Public License, Version 3, November 2007

=cut
