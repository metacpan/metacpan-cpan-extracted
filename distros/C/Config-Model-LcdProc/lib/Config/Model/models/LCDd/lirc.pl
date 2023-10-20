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
      'lircrc',
      {
        'description' => 'Specify an alternative location of the lircrc file ',
        'type' => 'leaf',
        'upstream_default' => '~/.lircrc',
        'value_type' => 'uniline'
      },
      'prog',
      {
        'description' => 'Must be the same as in your lircrc',
        'type' => 'leaf',
        'upstream_default' => 'lcdd',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::lirc'
  }
]
;

