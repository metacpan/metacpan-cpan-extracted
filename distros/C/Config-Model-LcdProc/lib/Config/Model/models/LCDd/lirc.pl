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
      'lircrc' => 'Specify an alternative location of the lircrc file ',
      'prog' => 'Must be the same as in your lircrc'
    },
    'element' => [
      'lircrc',
      {
        'type' => 'leaf',
        'upstream_default' => '~/.lircrc',
        'value_type' => 'uniline'
      },
      'prog',
      {
        'type' => 'leaf',
        'upstream_default' => 'lcdd',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'LCDd::lirc'
  }
]
;
