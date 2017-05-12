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
      'Clock',
      {
        'choice' => [
          'no',
          'small',
          'big'
        ],
        'description' => 'Show self-running clock after LCDd shutdown
Possible values: ',
        'type' => 'leaf',
        'upstream_default' => 'no',
        'value_type' => 'enum'
      },
      'Dimming',
      {
        'description' => 'Dim display, no dimming gives full brightness ',
        'type' => 'leaf',
        'upstream_default' => 'no,legal:yes,no',
        'value_type' => 'uniline'
      },
      'OffDimming',
      {
        'description' => 'Dim display in case LCDd is inactive ',
        'type' => 'leaf',
        'upstream_default' => 'no,legal:yes,no',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::mdm166a'
  }
]
;

