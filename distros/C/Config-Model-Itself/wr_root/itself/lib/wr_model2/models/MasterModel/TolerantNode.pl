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
    'accept' => [
      'list.*',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'type' => 'list'
      },
      'str.*',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'element' => [
      'id',
      {
        'type' => 'leaf',
        'value_type' => 'uniline'
      }
    ],
    'name' => 'MasterModel::TolerantNode'
  }
]
;

