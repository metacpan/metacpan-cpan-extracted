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
      'ClearGraphic' => 'Clear graphic memory on start-up. ',
      'Port' => 'port to use legal: 0x200-0x400 ',
      'Size' => 'set display size in pixels ',
      'bidirectional' => 'Use LPT port in bi-directional mode. This should work on most LPT port and
is required for proper timing! ',
      'delayBus' => 'Insert additional delays into reads / writes. '
    },
    'element' => [
      'ClearGraphic',
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
        'type' => 'leaf',
        'upstream_default' => '0x378',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '128x64',
        'value_type' => 'uniline'
      },
      'bidirectional',
      {
        'type' => 'leaf',
        'upstream_default' => 'yes',
        'value_type' => 'boolean',
        'write_as' => [
          'no',
          'yes'
        ]
      },
      'delayBus',
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
    'name' => 'LCDd::t6963'
  }
]
;
