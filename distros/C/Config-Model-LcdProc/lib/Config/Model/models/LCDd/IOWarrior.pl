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
      'ExtendedMode' => 'If you have an HD66712, a KS0073 or another \'almost HD44780-compatible\',
set this flag to get into extended mode (4-line linear).',
      'Lastline' => 'Specifies if the last line is pixel addressable (yes) or it controls an
underline effect (no). ',
      'SerialNumber' => 'serial number. Must be exactly as listed by usbview
(if not given, the 1st IOWarrior found gets used)',
      'Size' => 'display dimensions'
    },
    'element' => [
      'ExtendedMode',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'uniline'
      },
      'Lastline',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'SerialNumber',
      {
        'type' => 'leaf',
        'upstream_default' => '00000674',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'default' => '20x4',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::IOWarrior'
  }
]
;
