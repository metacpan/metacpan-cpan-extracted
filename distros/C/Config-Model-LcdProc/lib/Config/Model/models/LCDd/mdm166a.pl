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
      'Clock' => 'Show self-running clock after LCDd shutdown
Possible values: ',
      'Dimming' => 'Dim display, no dimming gives full brightness ',
      'OffDimming' => 'Dim display in case LCDd is inactive '
    },
    'element' => [
      'Clock',
      {
        'choice' => [
          'no',
          'small',
          'big'
        ],
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'Dimming',
      {
        'type' => 'leaf',
        'upstream_default' => 'no,legal:yes,no',
        'value_type' => 'uniline'
      },
      'OffDimming',
      '*Dimming'
    ],
    'name' => 'LCDd::mdm166a'
  }
]
;
