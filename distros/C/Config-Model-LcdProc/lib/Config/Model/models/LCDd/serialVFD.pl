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
      'Brightness',
      {
        'description' => 'Set the initial brightness 
(4 steps 0-250, 251-500, 501-750, 751-1000)',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
      },
      'Device',
      {
        'default' => '/dev/ttyS1',
        'description' => 'Device to use in serial mode. Usual values are /dev/ttyS0 and /dev/ttyS1',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'ISO_8859_1',
      {
        'description' => 'enable ISO 8859 1 compatibility ',
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'OffBrightness',
      {
        'description' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive
(4 steps 0-250, 251-500, 501-750, 751-1000)',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'integer'
      },
      'Port',
      {
        'default' => '0x378',
        'description' => 'Number of Custom-Characters. default is display type dependent
Custom-Characters=0
Portaddress where the LPT is. Used in parallel mode only. Usual values are
0x278, 0x378 and 0x3BC.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'PortWait',
      {
        'description' => 'Set parallel port timing delay (us). Used in parallel mode only.',
        'max' => '255',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '2',
        'value_type' => 'integer'
      },
      'Size',
      {
        'default' => '20x2',
        'description' => 'Specifies the size of the VFD.',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Speed',
      {
        'choice' => [
          '1200',
          '2400',
          '9600',
          '19200',
          '115200'
        ],
        'description' => 'set the serial port speed ',
        'type' => 'leaf',
        'upstream_default' => '9600',
        'value_type' => 'enum'
      },
      'Type',
      {
        'description' => 'Specifies the displaytype.
0 NEC (FIPC8367 based) VFDs.
1 KD Rev 2.1.
2 Noritake VFDs (*).
3 Futaba VFDs
4 IEE S03601-95B
5 IEE S03601-96-080 (*)
6 Futaba NA202SD08FA (allmost IEE compatible)
7 Samsung 20S207DA4 and 20S207DA6
8 Nixdorf BA6x / VT100
(* most should work, not tested yet.)',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'uniline'
      },
      'use_parallel',
      {
        'description' => '"no" if display connected serial, "yes" if connected parallel. 
I.e. serial by default',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::serialVFD'
  }
]
;

