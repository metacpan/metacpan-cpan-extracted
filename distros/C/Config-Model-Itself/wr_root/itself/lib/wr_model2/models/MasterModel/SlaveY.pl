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
      'std_id',
      {
        'cargo' => {
          'config_class_name' => 'MasterModel::SlaveZ',
          'type' => 'node'
        },
        'index_type' => 'string',
        'type' => 'hash'
      },
      'sub_slave',
      {
        'config_class_name' => 'MasterModel::SubSlave',
        'type' => 'node'
      },
      'warp2',
      {
        'config_class_name' => 'MasterModel::SubSlave',
        'morph' => '1',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            'f1' => '! tree_macro'
          },
          'rules' => [
            '$f1 eq \'mXY\'',
            {
              'config_class_name' => 'MasterModel::SubSlave2'
            },
            '$f1 eq \'XZ\'',
            {
              'config_class_name' => 'MasterModel::SubSlave2'
            }
          ]
        }
      },
      'Y',
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
    'include' => [
      'MasterModel::X_base_class'
    ],
    'name' => 'MasterModel::SlaveY'
  }
]
;

