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
    'class_description' => 'Xorg Module contains the list of module to load.',
    'element' => [
      'bitmap',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'dbe',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'ddc',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'extmod',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'freetype',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'i2c',
      {
        'default' => '0',
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'int10',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'record',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'type1',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'vbe',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'glx',
      {
        'default' => 1,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'dri',
      {
        'default' => 0,
        'type' => 'leaf',
        'value_type' => 'boolean'
      },
      'v4l',
      {
        'default' => 0,
        'type' => 'leaf',
        'value_type' => 'boolean'
      }
    ],
    'name' => 'Xorg::Module'
  }
]
;

