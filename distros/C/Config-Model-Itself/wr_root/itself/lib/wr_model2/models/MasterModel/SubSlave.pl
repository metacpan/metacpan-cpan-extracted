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
      'aa',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ab',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ac',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'ad',
      {
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'sub_slave',
      {
        'config_class_name' => 'MasterModel::SubSlave2',
        'type' => 'node'
      }
    ],
    'name' => 'MasterModel::SubSlave'
  }
]
;

