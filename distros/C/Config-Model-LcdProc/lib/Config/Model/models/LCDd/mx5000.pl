#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023, 2026 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;
use v5.20;
use utf8;

return [
  {
    'class_description' => 'generated from LCDd.conf',
    'description' => {
      'Device' => 'Select the output device to use ',
      'WaitAfterRefresh' => 'Time to wait in ms after the refresh screen has been sent '
    },
    'element' => [
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/hiddev0',
        'value_type' => 'uniline'
      },
      'WaitAfterRefresh',
      {
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::mx5000'
  }
]
;
