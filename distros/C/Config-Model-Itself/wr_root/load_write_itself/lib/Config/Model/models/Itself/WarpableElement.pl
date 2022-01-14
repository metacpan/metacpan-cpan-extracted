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
      'allow_keys_from',
      {
        'description' => 'this hash allows keys from the keys of the hash pointed by the path string',
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
      'allow_keys_matching',
      {
        'description' => 'Keys must match the specified regular expression.',
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
      'follow_keys_from',
      {
        'description' => 'this hash contains the same keys as the hash pointed by the path string',
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
      'warn_if_key_match',
      {
        'description' => 'Warn user if a key is created matching this regular expression',
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
      'warn_unless_key_match',
      {
        'description' => 'Warn user if a key is created not matching this regular expression',
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
      'ordered',
      {
        'description' => 'keep track of the order of the elements of this hash',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "hash" or $t eq "check_list"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'default_keys',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'description' => 'default keys hashes.',
        'level' => 'hidden',
        'type' => 'list',
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
      'auto_create_keys',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'description' => 'always create a set of keys specified in this list',
        'level' => 'hidden',
        'type' => 'list',
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
      'allow_keys',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'description' => 'specify a set of allowed keys',
        'level' => 'hidden',
        'type' => 'list',
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
      'auto_create_ids',
      {
        'description' => 'always create the number of id specified in this integer',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'string',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "list"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'default_with_init',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'description' => 'specify a set of keys to create and initialization on some elements . E.g. \' foo => "X=Av Y=Bv", bar => "Y=Av Z=Cz"\' ',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
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
      'max_nb',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'type' => '?type'
          },
          'rules' => [
            '$type eq "hash"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'replace',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'description' => 'Used for enum to substitute one value with another. This parameter must be used to enable user to upgrade a configuration with obsolete values. The old value is the key of the hash, the new one is the value of the hash',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "leaf" or $t eq "check_list"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'duplicates',
      {
        'choice' => [
          'allow',
          'suppress',
          'warn',
          'forbid'
        ],
        'description' => 'Specify the policy regarding duplicated values stored in the list or as hash values (valid only when cargo type is "leaf"). The policy can be "allow" (default), "suppress", "warn" (which offers the possibility to apply a fix), "forbid".',
        'level' => 'hidden',
        'type' => 'leaf',
        'upstream_default' => 'allow',
        'value_type' => 'enum',
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
      'help',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'string'
        },
        'description' => 'Specify help string applicable to values. The keys are regexp matched to the beginning of the value. See C<help> parameter of L<Config::Model::Value/DESCRIPTION> for more possibilities',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "leaf" or $t eq "check_list"',
            {
              'level' => 'normal'
            }
          ]
        }
      }
    ],
    'include' => [
      'Itself::CommonElement'
    ],
    'name' => 'Itself::WarpableElement'
  }
]
;

