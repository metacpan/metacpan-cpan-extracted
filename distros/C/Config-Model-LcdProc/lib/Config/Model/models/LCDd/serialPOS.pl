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
        'description' => 'Device to use in serial mode ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'description' => 'Specifies the size of the display in characters. ',
        'type' => 'leaf',
        'upstream_default' => '16x2',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '1200',
          '2400',
          '19200',
          '115200'
        ],
        'description' => 'communication baud rate with the display ',
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'enum'
      },
      'Type',
      {
        'choice' => [
          'IEE',
          'Epson',
          'Emax',
          'IBM',
          'LogicControls',
          'Ultimate'
        ],
        'description' => 'Set the communication protocol to use with the POS display.',
        'type' => 'leaf',
        'upstream_default' => 'AEDEX',
        'value_type' => 'enum'
      }
    ],
    'name' => 'LCDd::serialPOS'
  }
]
;

