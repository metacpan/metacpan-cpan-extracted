#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
use strict;
use warnings;

return [
  {
    'element' => [
      'created1',
      {
        'type' => 'leaf',
        'value_type' => 'number'
      },
      'created2',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'Master::Created'
  }
]
;

