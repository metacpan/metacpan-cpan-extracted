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
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/ttyUSB0',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::vlsys_m428'
  }
]
;

