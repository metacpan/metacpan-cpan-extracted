# -*- cperl -*-
#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#

# this file is used by test script

use strict;
use warnings;

return [
  {
    'class_description' => 'rather dummy class to check include',
    'element' => [
      'X',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'name' => 'MasterModel::X_base_class2'
  },
  {
    'include' => [
      'MasterModel::X_base_class2'
    ],
    'name' => 'MasterModel::X_base_class'
  }
]
;


