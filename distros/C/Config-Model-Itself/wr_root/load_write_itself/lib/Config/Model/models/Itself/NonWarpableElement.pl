#
# This file is part of Config-Model-Itself
#
# This software is Copyright (c) 2007-2019 by Dominique Dumont.
#
# This is free software, licensed under:
#
#   The GNU Lesser General Public License, Version 2.1, February 1999
#
#    Copyright (c) 2007-2011 Dominique Dumont.
#
#    This file is part of Config-Model-Itself.
#
#    Config-Model-Itself is free software; you can redistribute it
#    and/or modify it under the terms of the GNU Lesser Public License
#    as published by the Free Software Foundation; either version 2.1
#    of the License, or (at your option) any later version.
#
#    Config-Model-Itself is distributed in the hope that it will be
#    useful, but WITHOUT ANY WARRANTY; without even the implied
#    warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.
#    See the GNU Lesser Public License for more details.
#
#    You should have received a copy of the GNU Lesser Public License
#    along with Config-Model-Itself; if not, write to the Free Software
#    Foundation, Inc., 51 Franklin St, Fifth Floor, Boston, MA

use strict;
use warnings;

return [
  {
    'element' => [
      'value_type',
      {
        'choice' => [
          'boolean',
          'enum',
          'integer',
          'reference',
          'number',
          'uniline',
          'string',
          'file',
          'dir'
        ],
        'help' => {
          'integer' => 'positive or negative integer',
          'uniline' => 'string with no embedded newline'
        },
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            't' => '- type'
          },
          'rules' => [
            '$t eq "leaf"',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      },
      'class',
      {
        'description' => 'Perl class name used to override the implementation of the configuration element. This override Perl class must inherit a Config::Model class that matches the element type, i.e. Config::Model::Value, Config::Model::HashId or Config::Model::ListId. Use with care.',
        'level' => 'hidden',
        'summary' => 'Override implementation of element',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warp' => {
          'follow' => {
            't' => '- type'
          },
          'rules' => [
            '$t and $t !~ /node/',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'morph',
      {
        'description' => 'When set, a recurse copy of the value from the old object to the new object is attempted. Old values are dropped when  a copy is not possible (usually because of mismatching types).',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'warp' => {
          'follow' => {
            'f1' => '- type'
          },
          'rules' => [
            '$f1 eq \'warped_node\'',
            {
              'level' => 'normal',
              'upstream_default' => 0
            }
          ]
        }
      },
      'refer_to',
      {
        'description' => 'points to an array or hash element in the configuration tree using L<grab syntax|Config::Model::Role::Grab>. The available choice of this reference value (or check list)is made from the available keys of the pointed hash element or the values of the pointed array element.',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warp' => {
          'follow' => {
            't' => '- type',
            'vt' => '- value_type'
          },
          'rules' => [
            '$t  eq "check_list" or $vt eq "reference"',
            {
              'level' => 'important'
            }
          ]
        }
      },
      'computed_refer_to',
      {
        'description' => 'points to an array or hash element in the configuration tree using a path computed with value from several other elements in the configuration tree. The available choice of this reference value (or check list) is made from the available keys of the pointed hash element or the values of the pointed array element. The keys of several hashes (or lists) can be combined by using the \'+\' operator in the formula. For instance, \'! host:$a lan + ! host:foobar lan\'. See L<Config::Model::IdElementReference> for more details.',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            't' => '- type',
            'vt' => '- value_type'
          },
          'rules' => [
            '$t  eq "check_list" or $vt eq "reference"',
            {
              'config_class_name' => 'Itself::ComputedValue',
              'level' => 'normal'
            }
          ]
        }
      },
      'replace_follow',
      {
        'description' => 'Path specifying a hash of value element in the configuration tree. The hash if used in a way similar to the replace parameter. In this case, the replacement is not coded in the model but specified by the configuration.',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warp' => {
          'follow' => {
            't' => '- type'
          },
          'rules' => [
            '$t  eq "leaf"',
            {
              'level' => 'important'
            }
          ]
        }
      },
      'compute',
      {
        'description' => 'compute the default value according to a formula and value from other elements in the configuration tree.',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            't' => '- type'
          },
          'rules' => [
            '$t  eq "leaf"',
            {
              'config_class_name' => 'Itself::ComputedValue',
              'level' => 'normal'
            }
          ]
        }
      },
      'migrate_from',
      {
        'description' => 'Specify an upgrade path from an old value and compute the value to store in the new element.',
        'level' => 'hidden',
        'type' => 'warped_node',
        'warp' => {
          'follow' => {
            't' => '- type'
          },
          'rules' => [
            '$t  eq "leaf"',
            {
              'config_class_name' => 'Itself::MigratedValue',
              'level' => 'normal'
            }
          ]
        }
      },
      'write_as',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specify how to write a boolean value. Example \'no\' \'yes\'.',
        'level' => 'hidden',
        'max_index' => 1,
        'type' => 'list',
        'warp' => {
          'follow' => {
            't' => '- type',
            'vt' => '- value_type'
          },
          'rules' => [
            '$t eq "leaf" and $vt eq "boolean"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'migrate_values_from',
      {
        'description' => 'Specifies that the values of the hash or list are copied from another hash or list in the configuration tree once configuration data are loaded.',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "hash" or $t eq "list"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'migrate_keys_from',
      {
        'description' => 'Specifies that the keys of the hash are copied from another hash in the configuration tree only when the hash is created.',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "hash"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'write_empty_value',
      {
        'description' => 'By default, hash entries without data are not saved in configuration files. Set this parameter to 1 if a key must be saved in the configuration file even if the hash contains no value for that key.',
        'level' => 'hidden',
        'type' => 'leaf',
        'upstream_default' => 0,
        'value_type' => 'boolean',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "hash"',
            {
              'level' => 'normal'
            }
          ]
        }
      }
    ],
    'name' => 'Itself::NonWarpableElement'
  }
]
;

