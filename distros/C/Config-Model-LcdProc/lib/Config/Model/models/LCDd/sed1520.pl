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
      'DelayMult' => 'On fast machines it may be necessary to slow down transfer to the display.
If this value is set to zero, delay is disabled. Any value greater than
zero slows down each write by one microsecond. ',
      'HaveInverter' => 'The original wiring used an inverter to drive the control lines. If you do
not use an inverter set haveInverter to no. ',
      'InterfaceType' => 'Select the interface type (wiring) for the display. Supported values are
68 for 68-style connection (RESET level high) and 80 for 80-style connection
(RESET level low). ',
      'InvertedMapping' => 'On some displays column data in memory is mapped to segment lines from right
to left. This is called inverted mapping (not to be confused with
\'haveInverter\' from above). ',
      'Port' => 'Port where the LPT is. Usual values are 0x278, 0x378 and 0x3BC',
      'UseHardReset' => 'At least one display is reported (Everbouquet MG1203D) that requires sending
three times 0xFF before a reset during initialization.'
    },
    'element' => [
      'DelayMult',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'integer'
      },
      'HaveInverter',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'InterfaceType',
      {
        'choice' => [
          '68',
          '80'
        ],
        'type' => 'leaf',
        'upstream_default' => '80',
        'value_type' => 'enum'
      },
      'InvertedMapping',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'Port',
      {
        'default' => '0x378',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'UseHardReset',
      {
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      }
    ],
    'name' => 'LCDd::sed1520'
  }
]
;
