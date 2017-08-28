#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2017 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'class_description' => 'generated from LCDd.conf',
    'element' => [
      'Port',
      {
        'description' => 'Port the device is connected to ',
        'type' => 'leaf',
        'upstream_default' => '0x378',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::stv5730'
  }
]
;

