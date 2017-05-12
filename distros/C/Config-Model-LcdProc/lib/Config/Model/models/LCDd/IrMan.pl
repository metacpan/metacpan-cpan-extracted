#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2016 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Config',
      {
        'description' => 'Select the configuration file to use',
        'type' => 'leaf',
        'upstream_default' => '/etc/irman.cfg',
        'value_type' => 'uniline'
      },
      'Device',
      {
        'description' => 'in case of trouble with IrMan, try the Lirc emulator for IrMan
Select the input device to use',
        'type' => 'leaf',
        'upstream_default' => '/dev/irman',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::IrMan'
  }
]
;

