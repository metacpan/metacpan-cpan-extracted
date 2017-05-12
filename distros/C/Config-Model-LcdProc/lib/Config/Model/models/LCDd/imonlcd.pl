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
      'Backlight',
      {
        'description' => 'Set the backlight state ',
        'type' => 'leaf',
        'upstream_default' => 'on',
        'value_type' => 'boolean',
        'write_as' => [
          'off',
          'on'
        ]
      },
      'Contrast',
      {
        'description' => 'Select the displays contrast ',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '200',
        'value_type' => 'integer'
      },
      'Device',
      {
        'description' => 'Select the output device to use ',
        'type' => 'leaf',
        'upstream_default' => '/dev/lcd0',
        'value_type' => 'uniline'
      },
      'DiscMode',
      {
        'choice' => [
          '0',
          '1'
        ],
        'description' => 'Set the disc mode 
0 => spin the "slim" disc - two disc segments,
1 => their complement spinning;',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'enum'
      },
      'OnExit',
      {
        'description' => 'Set the exit behavior 
0 means leave shutdown message,
1 means show the big clock,
2 means blank device',
        'max' => '2',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1',
        'value_type' => 'integer'
      },
      'Protocol',
      {
        'choice' => [
          '0',
          '1'
        ],
        'description' => 'Specify which iMon protocol should be used

Choose 0 for 15c2:ffdc device,
Choose 1 for 15c2:0038 device',
        'type' => 'leaf',
        'upstream_default' => '0',
        'value_type' => 'enum'
      },
      'Size',
      {
        'description' => 'Specify the size of the display in pixels ',
        'type' => 'leaf',
        'upstream_default' => '96x16',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::imonlcd'
  }
]
;

