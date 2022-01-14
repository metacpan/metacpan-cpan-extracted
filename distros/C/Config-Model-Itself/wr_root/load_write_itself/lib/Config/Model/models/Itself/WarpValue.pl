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
    'class_description' => 'Warp functionality enable a Value object to change its properties (i.e. default value or its type) dynamically according to the value of another Value object locate elsewhere in the configuration tree.',
    'element' => [
      'follow',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specify with the path of the configuration element that drives the warp, i.e .the elements that control the property change. These are specified using a variable name (used in the "rules" formula)and a path to fetch the actual value. Example $country => " ! country"',
        'index_type' => 'string',
        'type' => 'hash'
      },
      'rules',
      {
        'cargo' => {
          'type' => 'warped_node',
          'warp' => {
            'rules' => [
              '&get_type =~ /hash|list/',
              {
                'config_class_name' => 'Itself::WarpableCargoElement'
              },
              '&get_type !~ /hash|list/',
              {
                'config_class_name' => 'Itself::WarpOnlyElement'
              }
            ]
          }
        },
        'description' => 'Each key of the hash is a test (as formula using the variables defined in "follow" element) that are tried in sequences to apply its associated effects',
        'index_type' => 'string',
        'ordered' => 1,
        'type' => 'hash'
      }
    ],
    'name' => 'Itself::WarpValue'
  }
]
;

