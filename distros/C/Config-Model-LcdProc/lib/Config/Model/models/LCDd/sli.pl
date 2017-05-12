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
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '1200',
          '2400',
          '9600',
          '19200',
          '38400',
          '57600',
          '115200'
        ],
        'description' => 'Set the communication speed ',
        'type' => 'leaf',
        'upstream_default' => '19200',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::sli'
  }
]
;

