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
      'Config' => 'Select the configuration file to use',
      'Device' => 'in case of trouble with IrMan, try the Lirc emulator for IrMan
Select the input device to use'
    },
    'element' => [
      'Config',
      {
        'type' => 'leaf',
        'upstream_default' => '/etc/irman.cfg',
        'value_type' => 'uniline'
      },
      'Device',
      {
        'type' => 'leaf',
        'upstream_default' => '/dev/irman',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::IrMan'
  }
]
;
