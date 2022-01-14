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
      'Z',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv'
        ],
        'type' => 'leaf',
        'value_type' => 'enum'
      },
      'DX',
      {
        'choice' => [
          'Av',
          'Bv',
          'Cv',
          'Dv'
        ],
        'default' => 'Dv',
        'type' => 'leaf',
        'value_type' => 'enum'
      }
    ],
    'include' => [
      'MasterModel::X_base_class'
    ],
    'name' => 'MasterModel::SlaveZ'
  }
]
;

