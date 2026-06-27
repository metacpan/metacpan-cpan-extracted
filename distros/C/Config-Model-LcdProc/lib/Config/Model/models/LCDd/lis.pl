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
      'Brightness' => 'Set the initial brightness 
0-250 = 25%, 251-500 = 50%, 501-750 = 75%, 751-1000 = 100%',
      'Lastline' => 'Specifies if the last line is pixel addressable (yes) or it only controls an
underline effect (no). ',
      'ProductID' => 'USB Product ID 
Change only if testing a compatible device.',
      'Size' => 'Columns by lines ',
      'VendorID' => 'USB Vendor ID 
Change only if testing a compatible device.'
    },
    'element' => [
      'Brightness',
      {
        'max' => '1000',
        'min' => '0',
        'type' => 'leaf',
        'upstream_default' => '1000',
        'value_type' => 'integer'
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
      'ProductID',
      {
        'type' => 'leaf',
        'upstream_default' => '0x6001',
        'value_type' => 'uniline'
      },
      'Size',
      {
        'type' => 'leaf',
        'upstream_default' => '20x2',
        'value_type' => 'uniline'
      },
      'VendorID',
      {
        'type' => 'leaf',
        'upstream_default' => '0x0403',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::lis'
  }
]
;
