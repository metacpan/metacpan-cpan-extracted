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
      'msg',
      {
        'description' => 'Warning message to show user. "$_" contains the bad value. Example "value $_ is bad". Leave blank or undef to use generated message',
        'type' => 'leaf',
        'value_type' => 'string'
      },
      'fix',
      {
        'description' => 'Perl instructions to fix the value. These instructions may be triggered by user. $_ contains the value to fix.  $_ is stored as the new value once the instructions are done. C<$self> contains the value object. Use with care.',
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'name' => 'Itself::CommonElement::WarnIfMatch'
  },
  {
    'element' => [
      'code',
      {
        'description' => 'Perl instructions to test the value. $_ contains the value to test. C<$self> contains the value object. Use with care.',
        'type' => 'leaf',
        'value_type' => 'string'
      }
    ],
    'include' => [
      'Itself::CommonElement::WarnIfMatch'
    ],
    'include_after' => 'code',
    'name' => 'Itself::CommonElement::Assert'
  },
  {
    'element' => [
      'mandatory',
      {
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'boolean',
        'warp' => {
          'follow' => {
            'f1' => '?type'
          },
          'rules' => [
            '$f1 eq \'leaf\'',
            {
              'level' => 'normal',
              'upstream_default' => 0
            }
          ]
        }
      },
      'config_class_name',
      {
        'level' => 'hidden',
        'refer_to' => '! class',
        'type' => 'leaf',
        'value_type' => 'reference',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t  eq "warped_node" ',
            {
              'level' => 'normal'
            },
            '$t  eq "node"',
            {
              'level' => 'normal',
              'mandatory' => 1
            }
          ]
        }
      },
      'choice',
      {
        'cargo' => {
          'type' => 'leaf',
          'value_type' => 'uniline'
        },
        'description' => 'Specify the possible values of an enum. This can also be used in a reference element so the possible enum value will be the combination of the specified choice and the referred to values',
        'level' => 'hidden',
        'type' => 'list',
        'warp' => {
          'follow' => {
            't' => '?type',
            'vt' => '?value_type'
          },
          'rules' => [
            '  ($t eq "leaf" and (   $vt eq "enum" 
                                                or $vt eq "reference")
                             )
                           or $t eq "check_list"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'min',
      {
        'description' => 'minimum value',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'number',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '    $type eq "leaf" 
                           and (    $vtype eq "integer" 
                                 or $vtype eq "number" 
                               )
                          ',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'max',
      {
        'description' => 'maximum value',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'number',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '    $type eq "leaf" 
                           and (    $vtype eq "integer" 
                                 or $vtype eq "number" 
                               )
                          ',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'min_index',
      {
        'description' => 'minimum number of keys',
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
      'max_index',
      {
        'description' => 'maximum number of keys',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'integer',
        'warp' => {
          'follow' => {
            'type' => '?type'
          },
          'rules' => [
            '$type eq "hash" or $type eq "list"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'default',
      {
        'description' => 'Specify default value. This default value is written in the configuration data',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'string',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "leaf"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'upstream_default',
      {
        'description' => 'Another way to specify a default value. But this default value is considered as "built_in" the application and is not written in the configuration data (unless modified)',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'string',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "leaf"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'convert',
      {
        'description' => 'Convert value or index to uppercase (uc) or lowercase (lc).',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'enum',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "leaf" or $t eq "hash"',
            {
              'choice' => [
                'uc',
                'lc'
              ],
              'level' => 'normal'
            }
          ]
        }
      },
      'match',
      {
        'description' => 'Perl regular expression to assert the validity of the value. To check the whole value, use C<^> and C<$>. For instance C<^foo|bar$> allows C<foo> or C<bar> but not C<foobar>. To be case insentive, use the C<(?i)> extended pattern. For instance, the regexp C<^(?i)foo|bar$> also allows the values C<Foo> and C<Bar>.',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'uniline',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf" and ($vtype eq "uniline" or $vtype eq "string" or $vtype eq "enum")',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'assert',
      {
        'cargo' => {
          'config_class_name' => 'Itself::CommonElement::Assert',
          'type' => 'node'
        },
        'description' => 'Raise an error if the test code snippet does returns false. Note this snippet is also run on undefined value, which may not be what you want.',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'warn_if',
      {
        'cargo' => {
          'config_class_name' => 'Itself::CommonElement::Assert',
          'type' => 'node'
        },
        'description' => 'Warn user if the code snippet returns true',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'warn_unless',
      {
        'cargo' => {
          'config_class_name' => 'Itself::CommonElement::Assert',
          'type' => 'node'
        },
        'description' => 'Warn user if the code snippet returns false',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'warn_if_match',
      {
        'cargo' => {
          'config_class_name' => 'Itself::CommonElement::WarnIfMatch',
          'type' => 'node'
        },
        'description' => 'Warn user if a I<defined> value matches the regular expression. ',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf" and ($vtype eq "uniline" or $vtype eq "string" or $vtype eq "enum")',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'warn_unless_match',
      {
        'cargo' => {
          'config_class_name' => 'Itself::CommonElement::WarnIfMatch',
          'type' => 'node'
        },
        'description' => 'Warn user if I<defined> value does not match the regular expression',
        'index_type' => 'string',
        'level' => 'hidden',
        'type' => 'hash',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf" and ($vtype eq "uniline" or $vtype eq "string" or $vtype eq "enum")',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'warn',
      {
        'description' => 'Unconditionally issue a warning with this string when this parameter is used. This should be used mostly with "accept"',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'string',
        'warp' => {
          'follow' => {
            't' => '?type'
          },
          'rules' => [
            '$t eq "leaf"',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'grammar',
      {
        'description' => 'Feed this grammar to Parse::RecDescent to perform validation',
        'level' => 'hidden',
        'type' => 'leaf',
        'value_type' => 'string',
        'warp' => {
          'follow' => {
            'type' => '?type',
            'vtype' => '?value_type'
          },
          'rules' => [
            '$type eq "leaf" and ($vtype eq "uniline" or $vtype eq "string" or $vtype eq "enum")',
            {
              'level' => 'normal'
            }
          ]
        }
      },
      'default_list',
      {
        'description' => 'Specify items checked by default',
        'level' => 'hidden',
        'refer_to' => '- choice',
        'type' => 'check_list',
        'warp' => {
          'follow' => {
            'o' => '?ordered',
            't' => '?type'
          },
          'rules' => [
            '$t eq "check_list" and not $o ',
            {
              'level' => 'normal'
            },
            '$t eq "check_list" and $o ',
            {
              'level' => 'normal',
              'ordered' => 1
            }
          ]
        }
      },
      'upstream_default_list',
      {
        'description' => 'Specify items checked by default in the application',
        'level' => 'hidden',
        'refer_to' => '- choice',
        'type' => 'check_list',
        'warp' => {
          'follow' => {
            'o' => '?ordered',
            't' => '?type'
          },
          'rules' => [
            '$t eq "check_list" and not $o ',
            {
              'level' => 'normal'
            },
            '$t eq "check_list" and $o ',
            {
              'level' => 'normal',
              'ordered' => 1
            }
          ]
        }
      }
    ],
    'name' => 'Itself::CommonElement'
  }
]
;



