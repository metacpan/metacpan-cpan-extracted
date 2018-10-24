#
# This file is part of Config-Model-Xorg
#
# This software is Copyright (c) 2007-2018 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
[
  {
    'element' => [
      'DPMS',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'SyncOnGreen',
      {
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'PreferredMode',
      {
        'description' => 'This optional entry specifies a mode to be marked as the preferred initial mode of the monitor. (RandR 1.2-supporting drivers only).

FIXME: use available Modes + vesa standard',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'LeftOf',
      {
        'description' => 'This optional entry specifies that the monitor should be positioned to the left of the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'RightOf',
      {
        'description' => 'This optional entry specifies that the monitor should be positioned to the right of the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Above',
      {
        'description' => 'This optional entry specifies that the monitor should be positioned above the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Below',
      {
        'description' => 'This optional entry specifies that the monitor should be positioned below the output (not monitor) of the given name. (RandR 1.2-supporting drivers only)',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Ignore',
      {
        'choice' => [
          'false',
          'true'
        ],
        'description' => 'This optional entry specifies whether the monitor should be turned on at startup. By default, the server will attempt to enable all connected monitors. (RandR 1.2-supporting drivers only)',
        'type' => 'leaf',
        'upstream_default' => 'false',
        'value_type' => 'enum'
      }
    ],
    'name' => 'Xorg::Monitor::Option'
  }
]
;

