#
# This file is part of Config-Model-LcdProc
#
# This software is Copyright (c) 2013-2023 by Dominique Dumont.
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
        'description' => 'Set the initial brightness ',
        'max' => '1000',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
      },
      'Contrast',
      {
        'description' => 'Set the initial contrast 
Can be set but does not change anything internally',
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '500',
        'value_type' => 'integer'
      },
      'Mode',
      {
        'description' => 'svgalib mode to use 
legal values are supported svgalib modes',
        'type' => 'leaf',
        'upstream_default' => 'G320x240x256',
        'value_type' => 'uniline'
      },
      'OffBrightness',
      {
        'description' => 'Set the initial off-brightness 
This value is used when the display is normally
switched off in case LCDd is inactive',
        'max' => '1000',
        'min' => '1',
        'type' => 'leaf',
        'upstream_default' => '500',
        'value_type' => 'integer'
      },
      'Size',
      {
        'description' => 'set display size ',
        'type' => 'leaf',
        'upstream_default' => '20x4',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::svga'
  }
]
;

