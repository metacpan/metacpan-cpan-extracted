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
      'CharMap',
      {
        'choice' => [
          'none',
          'hd44780_euro',
          'upd16314',
          'hd44780_koi8_r',
          'hd44780_cp1251',
          'hd44780_8859_5'
        ],
        'description' => 'Character map to to map ISO-8859-1 to the displays character set.
 (upd16314, hd44780_koi8_r,
hd44780_cp1251, hd44780_8859_5 are possible if compiled with additional
charmaps)',
        'type' => 'leaf',
        'upstream_default' => 'none',
        'value_type' => 'enum'
      },
      'Device',
      {
        'default' => '/dev/lcd0',
        'description' => 'select the device to use',
        'type' => 'leaf',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'default' => '16x2',
        'description' => 'display dimensions',
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::imon'
  }
]
;

