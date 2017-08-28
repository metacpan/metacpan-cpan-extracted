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
      'ClearGraphic',
      {
        'description' => 'Clear graphic memory on start-up. ',
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
        'description' => 'port to use legal: 0x200-0x400 ',
        'type' => 'leaf',
        'upstream_default' => '0x378',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'description' => 'set display size in pixels ',
        'type' => 'leaf',
        'upstream_default' => '128x64',
        'value_type' => 'uniline'
      },
      'bidirectional',
      {
        'description' => 'Use LPT port in bi-directional mode. This should work on most LPT port and
is required for proper timing! ',
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
        'description' => 'Insert additional delays into reads / writes. ',
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

