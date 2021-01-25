#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2021 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/hiddev0',
        'value_type' => 'uniline'
      },
      'WaitAfterRefresh',
      {
        'description' => 'Time to wait in ms after the refresh screen has been sent ',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::mx5000'
  }
]
;

